package com.ainovel.server.service;

import java.util.List;

import com.ainovel.server.domain.model.User;

/**
 * JWT服务接口
 */
public interface JwtService {
    
    /**
     * 生成JWT令牌
     * @param user 用户
     * @return JWT令牌
     */
    String generateToken(User user);
    
    /**
     * 生成包含角色和权限的JWT令牌
     * @param user 用户
     * @param roles 角色列表
     * @param permissions 权限列表
     * @return JWT令牌
     */
    String generateTokenWithRolesAndPermissions(User user, List<String> roles, List<String> permissions);
    
    /**
     * 生成刷新令牌
     * @param user 用户
     * @return 刷新令牌
     */
    String generateRefreshToken(User user);
    
    /**
     * 从令牌中提取用户名
     * @param token JWT令牌
     * @return 用户名
     */
    String extractUsername(String token);
    
    /**
     * 从令牌中提取用户ID
     * @param token JWT令牌
     * @return 用户ID
     */
    String extractUserId(String token);
    
    /**
     * 从令牌中提取角色列表
     * @param token JWT令牌
     * @return 角色列表
     */
    List<String> extractRoles(String token);
    
    /**
     * 从令牌中提取权限列表
     * @param token JWT令牌
     * @return 权限列表
     */
    List<String> extractPermissions(String token);
    
    /**
     * 验证令牌是否有效
     * @param token JWT令牌
     * @param user 用户
     * @return 是否有效
     */
    boolean validateToken(String token, User user);
    
    /**
     * 检查令牌是否过期
     * @param token JWT令牌
     * @return 是否过期
     */
    boolean isTokenExpired(String token);
} 