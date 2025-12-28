package com.ainovel.server.repository;

import java.time.LocalDateTime;

import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.User;
import com.ainovel.server.domain.model.User.AccountStatus;
import com.ainovel.server.repository.custom.CustomUserRepository;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 用户仓库接口
 */
@Repository
public interface UserRepository extends ReactiveMongoRepository<User, String>, CustomUserRepository {
    
    /**
     * 根据用户名查找用户
     * @param username 用户名
     * @return 用户信息
     */
    Mono<User> findByUsername(String username);
    
    /**
     * 根据邮箱查找用户
     * @param email 邮箱
     * @return 用户信息
     */
    Mono<User> findByEmail(String email);
    
    /**
     * 根据手机号码查找用户
     * @param phone 手机号码
     * @return 用户信息
     */
    Mono<User> findByPhone(String phone);
    
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
     * 检查手机号码是否存在
     * @param phone 手机号码
     * @return 是否存在
     */
    Mono<Boolean> existsByPhone(String phone);
    
    /**
     * 根据用户名或邮箱模糊查询
     * @param username 用户名关键词
     * @param email 邮箱关键词
     * @return 用户列表
     */
    Flux<User> findByUsernameContainingIgnoreCaseOrEmailContainingIgnoreCase(String username, String email);
    
    /**
     * 根据账户状态统计用户数量
     * @param status 账户状态
     * @return 用户数量
     */
    Mono<Long> countByAccountStatus(AccountStatus status);
    
    /**
     * 统计指定时间之后创建的用户数量
     * @param createdAt 创建时间
     * @return 用户数量
     */
    Mono<Long> countByCreatedAtAfter(LocalDateTime createdAt);
    
    /**
     * 统计指定时间范围内创建的用户数量
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 用户数量
     */
    Mono<Long> countByCreatedAtBetween(LocalDateTime startTime, LocalDateTime endTime);
    
    /**
     * 根据最后登录时间查找活跃用户
     * @param lastLoginAfter 最后登录时间之后
     * @return 活跃用户列表
     */
    Flux<User> findByAccountStatusAndLastLoginAtAfter(AccountStatus status, LocalDateTime lastLoginAfter);
    
    /**
     * 统计指定时间之后登录的用户数量
     * @param lastLoginAfter 最后登录时间之后
     * @return 用户数量
     */
    Mono<Long> countByAccountStatusAndLastLoginAtAfter(AccountStatus status, LocalDateTime lastLoginAfter);
    
    /**
     * 查找最近注册的用户
     * @param limit 数量限制
     * @return 用户列表
     */
    Flux<User> findTop10ByOrderByCreatedAtDesc();
    
    /**
     * 查找所有有消费积分记录的用户
     * @return 用户列表
     */
    Flux<User> findByTotalCreditsUsedGreaterThan(Long credits);
} 