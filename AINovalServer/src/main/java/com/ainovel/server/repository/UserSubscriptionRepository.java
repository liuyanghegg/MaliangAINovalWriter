package com.ainovel.server.repository;

import java.time.LocalDateTime;

import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.UserSubscription;
import com.ainovel.server.domain.model.UserSubscription.SubscriptionStatus;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 用户订阅数据访问层
 */
@Repository
public interface UserSubscriptionRepository extends ReactiveMongoRepository<UserSubscription, String> {
    
    /**
     * 根据用户ID查找当前有效的订阅
     * 
     * @param userId 用户ID
     * @return 当前有效订阅
     */
    Mono<UserSubscription> findByUserIdAndStatusIn(String userId, SubscriptionStatus... statuses);
    
    /**
     * 根据用户ID查找所有订阅历史
     * 
     * @param userId 用户ID
     * @return 订阅历史列表
     */
    Flux<UserSubscription> findByUserIdOrderByCreatedAtDesc(String userId);
    
    /**
     * 根据用户ID查找活跃的订阅
     * 
     * @param userId 用户ID
     * @return 活跃订阅
     */
    Mono<UserSubscription> findByUserIdAndStatus(String userId, SubscriptionStatus status);
    
    /**
     * 查找所有即将过期的订阅（7天内）
     * 
     * @param endDate 结束时间
     * @return 即将过期的订阅列表
     */
    Flux<UserSubscription> findByStatusAndEndDateBetween(SubscriptionStatus status, LocalDateTime startTime, LocalDateTime endTime);
    
    /**
     * 查找所有已过期的订阅
     * 
     * @param currentTime 当前时间
     * @return 已过期的订阅列表
     */
    Flux<UserSubscription> findByStatusAndEndDateBefore(SubscriptionStatus status, LocalDateTime currentTime);
    
    /**
     * 根据订阅计划ID查找所有订阅
     * 
     * @param planId 订阅计划ID
     * @return 订阅列表
     */
    Flux<UserSubscription> findByPlanId(String planId);
    
    /**
     * 根据支付交易ID查找订阅
     * 
     * @param transactionId 交易ID
     * @return 订阅信息
     */
    Mono<UserSubscription> findByTransactionId(String transactionId);
    
    /**
     * 查找试用期内的订阅
     * 
     * @return 试用期订阅列表
     */
    Flux<UserSubscription> findByIsTrialTrueAndStatus(SubscriptionStatus status);
    
    /**
     * 查找设置了自动续费的订阅
     * 
     * @return 自动续费订阅列表
     */
    Flux<UserSubscription> findByAutoRenewalTrueAndStatus(SubscriptionStatus status);
    
    /**
     * 统计用户的订阅次数
     * 
     * @param userId 用户ID
     * @return 订阅次数
     */
    Mono<Long> countByUserId(String userId);
    
    /**
     * 统计指定计划的订阅次数
     * 
     * @param planId 计划ID
     * @return 订阅次数
     */
    Mono<Long> countByPlanIdAndStatus(String planId, SubscriptionStatus status);
}