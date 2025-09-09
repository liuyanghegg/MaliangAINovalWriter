package com.ainovel.server.service;

import org.springframework.data.domain.Pageable;

import com.ainovel.server.controller.AdminUserController.UserStatistics;
import com.ainovel.server.controller.AdminUserController.UserUpdateRequest;
import com.ainovel.server.domain.model.User;
import com.ainovel.server.domain.model.User.AccountStatus;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 管理员用户管理服务接口
 */
public interface AdminUserService {
    
    /**
     * 查找所有用户（分页）
     * 
     * @param pageable 分页信息
     * @return 用户列表
     */
    Flux<User> findAllUsers(Pageable pageable);
    
    /**
     * 搜索用户
     * 
     * @param search 搜索关键词
     * @param pageable 分页信息
     * @return 用户列表
     */
    Flux<User> searchUsers(String search, Pageable pageable);
    
    /**
     * 根据ID查找用户
     * 
     * @param id 用户ID
     * @return 用户信息
     */
    Mono<User> findUserById(String id);
    
    /**
     * 更新用户信息
     * 
     * @param id 用户ID
     * @param request 更新请求
     * @return 更新的用户
     */
    Mono<User> updateUser(String id, UserUpdateRequest request);
    
    /**
     * 更新用户状态
     * 
     * @param id 用户ID
     * @param status 新状态
     * @return 更新的用户
     */
    Mono<User> updateUserStatus(String id, AccountStatus status);
    
    /**
     * 为用户分配角色
     * 
     * @param userId 用户ID
     * @param roleId 角色ID
     * @return 更新的用户
     */
    Mono<User> assignRoleToUser(String userId, String roleId);
    
    /**
     * 移除用户角色
     * 
     * @param userId 用户ID
     * @param roleId 角色ID
     * @return 更新的用户
     */
    Mono<User> removeRoleFromUser(String userId, String roleId);
    
    /**
     * 获取用户统计信息
     * 
     * @return 统计信息
     */
    Mono<UserStatistics> getUserStatistics();
    
    /**
     * 批量更新用户状态
     * 
     * @param userIds 用户ID列表
     * @param status 新状态
     * @return 更新结果
     */
    Mono<Long> batchUpdateUserStatus(java.util.List<String> userIds, AccountStatus status);
    
    /**
     * 删除用户（软删除）
     * 
     * @param id 用户ID
     * @return 删除结果
     */
    Mono<Void> deleteUser(String id);
}