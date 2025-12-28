package com.ainovel.server.service;

import com.ainovel.server.domain.model.SubscriptionPlan;
import com.ainovel.server.domain.model.SubscriptionPlan.BillingCycle;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 订阅计划服务接口
 */
public interface SubscriptionPlanService {
    
    /**
     * 创建订阅计划
     * 
     * @param plan 订阅计划信息
     * @return 创建的订阅计划
     */
    Mono<SubscriptionPlan> createPlan(SubscriptionPlan plan);
    
    /**
     * 更新订阅计划
     * 
     * @param id 计划ID
     * @param plan 订阅计划信息
     * @return 更新的订阅计划
     */
    Mono<SubscriptionPlan> updatePlan(String id, SubscriptionPlan plan);
    
    /**
     * 删除订阅计划
     * 
     * @param id 计划ID
     * @return 删除结果
     */
    Mono<Void> deletePlan(String id);
    
    /**
     * 根据ID查找订阅计划
     * 
     * @param id 计划ID
     * @return 订阅计划
     */
    Mono<SubscriptionPlan> findById(String id);
    
    /**
     * 查找所有订阅计划
     * 
     * @return 订阅计划列表
     */
    Flux<SubscriptionPlan> findAll();
    
    /**
     * 查找所有激活的订阅计划
     * 
     * @return 激活的订阅计划列表
     */
    Flux<SubscriptionPlan> findActiveePlans();
    
    /**
     * 根据计费周期查找订阅计划
     * 
     * @param billingCycle 计费周期
     * @return 订阅计划列表
     */
    Flux<SubscriptionPlan> findByBillingCycle(BillingCycle billingCycle);
    
    /**
     * 查找推荐的订阅计划
     * 
     * @return 推荐的订阅计划列表
     */
    Flux<SubscriptionPlan> findRecommendedPlans();
    
    /**
     * 切换订阅计划状态
     * 
     * @param id 计划ID
     * @param active 是否激活
     * @return 更新的订阅计划
     */
    Mono<SubscriptionPlan> togglePlanStatus(String id, boolean active);
    
    /**
     * 检查计划名称是否存在
     * 
     * @param planName 计划名称
     * @return 是否存在
     */
    Mono<Boolean> existsByPlanName(String planName);
}