package com.ainovel.server.security;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.ReactiveAuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.User;
import com.ainovel.server.service.JwtService;
import com.ainovel.server.service.UserService;

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import reactor.core.publisher.Mono;

/**
 * JWT认证管理器
 * 负责验证JWT令牌并创建认证对象
 */
@Component
public class JwtAuthenticationManager implements ReactiveAuthenticationManager {
    
    private static final Logger log = LoggerFactory.getLogger(JwtAuthenticationManager.class);
    
    private final JwtService jwtService;
    private final UserService userService;
    
    @Autowired
    public JwtAuthenticationManager(JwtService jwtService, UserService userService) {
        this.jwtService = jwtService;
        this.userService = userService;
    }
    
    @Override
    public Mono<Authentication> authenticate(Authentication authentication) {
        String token = authentication.getCredentials().toString();
        
        try {
            String username = jwtService.extractUsername(token);
            log.debug("尝试认证用户: {}", username);
            
            return userService.findUserByUsername(username)
                    .filter(user -> {
                        boolean isValid = jwtService.validateToken(token, user);
                        log.debug("用户 {} 的token验证结果: {}", username, isValid);
                        return isValid;
                    })
                    .map(user -> {
                        log.debug("用户 {} 认证成功", username);
                        return createAuthentication(user, token);
                    })
                    .switchIfEmpty(Mono.fromRunnable(() -> 
                        log.debug("用户 {} 认证失败或token无效", username)));
        } catch (ExpiredJwtException e) {
            // JWT过期异常，抛出BadCredentialsException让Spring Security返回401
            log.warn("JWT token已过期: {}", e.getMessage());
            return Mono.error(new BadCredentialsException("JWT token已过期", e));
        } catch (JwtException e) {
            // JWT格式错误或其他JWT相关异常
            log.warn("JWT token格式错误: {}", e.getMessage());
            return Mono.error(new BadCredentialsException("JWT token无效", e));
        } catch (Exception e) {
            // 其他异常，记录日志但抛出BadCredentialsException避免500错误
            log.error("JWT认证过程中发生异常", e);
            return Mono.error(new BadCredentialsException("认证失败", e));
        }
    }
    
    private Authentication createAuthentication(User user, String token) {
        // 从JWT中提取角色和权限
        List<String> roles = jwtService.extractRoles(token);
        List<String> permissions = jwtService.extractPermissions(token);
        
        // 创建权限列表
        List<SimpleGrantedAuthority> authorities = new ArrayList<>();
        
        // 添加角色权限（Spring Security约定以ROLE_开头）
        for (String role : roles) {
            if (!role.startsWith("ROLE_")) {
                authorities.add(new SimpleGrantedAuthority("ROLE_" + role));
            } else {
                authorities.add(new SimpleGrantedAuthority(role));
            }
        }
        
        // 添加功能权限
        for (String permission : permissions) {
            authorities.add(new SimpleGrantedAuthority(permission));
        }
        
        // 如果没有任何权限，至少添加一个默认角色
        if (authorities.isEmpty()) {
            authorities.add(new SimpleGrantedAuthority("ROLE_USER"));
        }
        
        log.debug("用户 {} 的权限: {}", user.getUsername(), authorities);
        
        // 创建认证对象，包含用户信息和权限
        return new UsernamePasswordAuthenticationToken(
                user,
                token,
                authorities
        );
    }
} 