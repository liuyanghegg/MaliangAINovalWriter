package com.ainovel.server.repository;

import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.SubscriptionPlan;
import com.ainovel.server.domain.model.SubscriptionPlan.BillingCycle;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 订阅计划数据访问层
 */
@Repository
public interface SubscriptionPlanRepository extends ReactiveMongoRepository<SubscriptionPlan, String> {
    
    /**
     * 查找所有激活的订阅计划
     * 
     * @return 激活的订阅计划列表
     */
    Flux<SubscriptionPlan> findByActiveTrue();
    
    /**
     * 根据计费周期查找订阅计划
     * 
     * @param billingCycle 计费周期
     * @return 订阅计划列表
     */
    Flux<SubscriptionPlan> findByBillingCycle(BillingCycle billingCycle);
    
    /**
     * 查找所有激活的订阅计划，按优先级降序排列
     * 
     * @return 按优先级排序的激活订阅计划列表
     */
    Flux<SubscriptionPlan> findByActiveTrueOrderByPriorityDesc();
    
    /**
     * 根据角色ID查找订阅计划
     * 
     * @param roleId 角色ID
     * @return 订阅计划列表
     */
    Flux<SubscriptionPlan> findByRoleId(String roleId);
    
    /**
     * 查找推荐的订阅计划
     * 
     * @return 推荐的订阅计划列表
     */
    Flux<SubscriptionPlan> findByRecommendedTrueAndActiveTrue();
    
    /**
     * 根据套餐名称查找订阅计划
     * 
     * @param planName 套餐名称
     * @return 订阅计划
     */
    Mono<SubscriptionPlan> findByPlanName(String planName);
    
    /**
     * 检查套餐名称是否存在
     * 
     * @param planName 套餐名称
     * @return 是否存在
     */
    Mono<Boolean> existsByPlanName(String planName);
}