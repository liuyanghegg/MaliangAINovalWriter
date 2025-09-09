package com.ainovel.server.service;

import java.util.List;

import com.ainovel.server.domain.model.Role;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 角色管理服务接口
 */
public interface RoleService {
    
    /**
     * 创建角色
     * 
     * @param role 角色信息
     * @return 创建的角色
     */
    Mono<Role> createRole(Role role);
    
    /**
     * 更新角色
     * 
     * @param id 角色ID
     * @param role 角色信息
     * @return 更新的角色
     */
    Mono<Role> updateRole(String id, Role role);
    
    /**
     * 删除角色
     * 
     * @param id 角色ID
     * @return 删除结果
     */
    Mono<Void> deleteRole(String id);
    
    /**
     * 根据ID查找角色
     * 
     * @param id 角色ID
     * @return 角色信息
     */
    Mono<Role> findById(String id);
    
    /**
     * 根据角色名称查找角色
     * 
     * @param roleName 角色名称
     * @return 角色信息
     */
    Mono<Role> findByRoleName(String roleName);
    
    /**
     * 查找所有角色
     * 
     * @return 角色列表
     */
    Flux<Role> findAll();
    
    /**
     * 查找所有启用的角色
     * 
     * @return 启用的角色列表
     */
    Flux<Role> findAllEnabled();
    
    /**
     * 根据角色ID列表查找角色
     * 
     * @param roleIds 角色ID列表
     * @return 角色列表
     */
    Flux<Role> findByIds(List<String> roleIds);
    
    /**
     * 为角色添加权限
     * 
     * @param roleId 角色ID
     * @param permission 权限标识符
     * @return 更新结果
     */
    Mono<Role> addPermissionToRole(String roleId, String permission);
    
    /**
     * 从角色移除权限
     * 
     * @param roleId 角色ID
     * @param permission 权限标识符
     * @return 更新结果
     */
    Mono<Role> removePermissionFromRole(String roleId, String permission);
    
    /**
     * 检查角色是否存在
     * 
     * @param roleName 角色名称
     * @return 是否存在
     */
    Mono<Boolean> existsByRoleName(String roleName);
    
    /**
     * 获取用户的所有权限
     * 
     * @param roleIds 用户的角色ID列表
     * @return 权限列表
     */
    Mono<List<String>> getUserPermissions(List<String> roleIds);
}