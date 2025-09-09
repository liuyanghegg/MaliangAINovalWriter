package com.ainovel.server.repository;

import java.util.List;

import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.Role;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 角色数据访问层
 */
@Repository
public interface RoleRepository extends ReactiveMongoRepository<Role, String> {
    
    /**
     * 根据角色名称查找角色
     * 
     * @param roleName 角色名称
     * @return 角色信息
     */
    Mono<Role> findByRoleName(String roleName);
    
    /**
     * 根据角色名称列表查找角色
     * 
     * @param roleNames 角色名称列表
     * @return 角色列表
     */
    Flux<Role> findByRoleNameIn(List<String> roleNames);
    
    /**
     * 查找所有启用的角色
     * 
     * @return 启用的角色列表
     */
    Flux<Role> findByEnabledTrue();
    
    /**
     * 根据优先级降序查找所有角色
     * 
     * @return 按优先级排序的角色列表
     */
    Flux<Role> findAllByOrderByPriorityDesc();
    
    /**
     * 检查角色名称是否存在
     * 
     * @param roleName 角色名称
     * @return 是否存在
     */
    Mono<Boolean> existsByRoleName(String roleName);
    
    /**
     * 根据权限查找拥有该权限的角色
     * 
     * @param permission 权限标识符
     * @return 拥有该权限的角色列表
     */
    Flux<Role> findByPermissionsContaining(String permission);
}