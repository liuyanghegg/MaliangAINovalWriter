package com.ainovel.server.service;

import com.ainovel.server.domain.model.User;

import reactor.core.publisher.Mono;

/**
 * 用户服务接口
 */
public interface UserService {
    
    /**
     * 创建用户
     * @param user 用户信息
     * @return 创建的用户
     */
    Mono<User> createUser(User user);
    
    /**
     * 根据ID查找用户
     * @param id 用户ID
     * @return 用户信息
     */
    Mono<User> findUserById(String id);
    
    /**
     * 根据用户名查找用户
     * @param username 用户名
     * @return 用户信息
     */
    Mono<User> findUserByUsername(String username);
    
    /**
     * 根据邮箱查找用户
     * @param email 邮箱
     * @return 用户信息
     */
    Mono<User> findUserByEmail(String email);
    
    /**
     * 根据手机号查找用户
     * @param phone 手机号
     * @return 用户信息
     */
    Mono<User> findUserByPhone(String phone);
    
    /**
     * 检查用户名是否存在
     * @param username 用户名
     * @return 是否存在
     */
    Mono<Boolean> existsByUsername(String username);
    
    /**
     * 检查邮箱是否存在
     * @param email 邮箱
     * @return 是否存在
     */
    Mono<Boolean> existsByEmail(String email);
    
    /**
     * 检查手机号是否存在
     * @param phone 手机号
     * @return 是否存在
     */
    Mono<Boolean> existsByPhone(String phone);
    
    /**
     * 更新用户信息
     * @param id 用户ID
     * @param user 更新的用户信息
     * @return 更新后的用户
     */
    Mono<User> updateUser(String id, User user);
    
    /**
     * 删除用户
     * @param id 用户ID
     * @return 操作结果
     */
    Mono<Void> deleteUser(String id);
    
    /**
     * 更新用户密码（传入已加密的密码）
     * @param id 用户ID
     * @param encodedPassword 已加密密码
     * @return 更新后的用户
     */
    Mono<User> updateUserPassword(String id, String encodedPassword);
    

} 