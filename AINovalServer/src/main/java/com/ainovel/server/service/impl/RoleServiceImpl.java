package com.ainovel.server.service.impl;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ainovel.server.domain.model.Role;
import com.ainovel.server.repository.RoleRepository;
import com.ainovel.server.service.RoleService;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 角色管理服务实现
 */
@Service
public class RoleServiceImpl implements RoleService {
    
    private final RoleRepository roleRepository;
    
    @Autowired
    public RoleServiceImpl(RoleRepository roleRepository) {
        this.roleRepository = roleRepository;
    }
    
    @Override
    @Transactional
    public Mono<Role> createRole(Role role) {
        return roleRepository.existsByRoleName(role.getRoleName())
                .flatMap(exists -> {
                    if (exists) {
                        return Mono.error(new IllegalArgumentException("角色名称已存在: " + role.getRoleName()));
                    }
                    
                    role.setCreatedAt(LocalDateTime.now());
                    role.setUpdatedAt(LocalDateTime.now());
                    
                    return roleRepository.save(role);
                });
    }
    
    @Override
    @Transactional
    public Mono<Role> updateRole(String id, Role role) {
        return roleRepository.findById(id)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("角色不存在: " + id)))
                .flatMap(existingRole -> {
                    // 检查角色名称是否被其他角色使用
                    if (!existingRole.getRoleName().equals(role.getRoleName())) {
                        return roleRepository.existsByRoleName(role.getRoleName())
                                .flatMap(exists -> {
                                    if (exists) {
                                        return Mono.error(new IllegalArgumentException("角色名称已存在: " + role.getRoleName()));
                                    }
                                    return updateRoleFields(existingRole, role);
                                });
                    } else {
                        return updateRoleFields(existingRole, role);
                    }
                })
                .flatMap(roleRepository::save);
    }
    
    private Mono<Role> updateRoleFields(Role existingRole, Role newRole) {
        existingRole.setRoleName(newRole.getRoleName());
        existingRole.setDisplayName(newRole.getDisplayName());
        existingRole.setDescription(newRole.getDescription());
        existingRole.setPermissions(newRole.getPermissions());
        existingRole.setEnabled(newRole.getEnabled());
        existingRole.setPriority(newRole.getPriority());
        existingRole.setUpdatedAt(LocalDateTime.now());
        
        return Mono.just(existingRole);
    }
    
    @Override
    @Transactional
    public Mono<Void> deleteRole(String id) {
        return roleRepository.findById(id)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("角色不存在: " + id)))
                .flatMap(role -> {
                    // TODO: 检查是否有用户正在使用此角色
                    return roleRepository.deleteById(id);
                });
    }
    
    @Override
    public Mono<Role> findById(String id) {
        return roleRepository.findById(id);
    }
    
    @Override
    public Mono<Role> findByRoleName(String roleName) {
        return roleRepository.findByRoleName(roleName);
    }
    
    @Override
    public Flux<Role> findAll() {
        return roleRepository.findAllByOrderByPriorityDesc();
    }
    
    @Override
    public Flux<Role> findAllEnabled() {
        return roleRepository.findByEnabledTrue();
    }
    
    @Override
    public Flux<Role> findByIds(List<String> roleIds) {
        return roleRepository.findAllById(roleIds);
    }
    
    @Override
    @Transactional
    public Mono<Role> addPermissionToRole(String roleId, String permission) {
        return roleRepository.findById(roleId)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("角色不存在: " + roleId)))
                .flatMap(role -> {
                    role.addPermission(permission);
                    role.setUpdatedAt(LocalDateTime.now());
                    return roleRepository.save(role);
                });
    }
    
    @Override
    @Transactional
    public Mono<Role> removePermissionFromRole(String roleId, String permission) {
        return roleRepository.findById(roleId)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("角色不存在: " + roleId)))
                .flatMap(role -> {
                    role.removePermission(permission);
                    role.setUpdatedAt(LocalDateTime.now());
                    return roleRepository.save(role);
                });
    }
    
    @Override
    public Mono<Boolean> existsByRoleName(String roleName) {
        return roleRepository.existsByRoleName(roleName);
    }
    
    @Override
    public Mono<List<String>> getUserPermissions(List<String> roleIds) {
        if (roleIds == null || roleIds.isEmpty()) {
            return Mono.just(new ArrayList<>());
        }
        
        return roleRepository.findAllById(roleIds)
                .filter(Role::getEnabled)
                .map(Role::getPermissions)
                .collectList()
                .map(permissionLists -> {
                    Set<String> allPermissions = new HashSet<>();
                    for (List<String> permissions : permissionLists) {
                        if (permissions != null) {
                            allPermissions.addAll(permissions);
                        }
                    }
                    return new ArrayList<>(allPermissions);
                });
    }
}