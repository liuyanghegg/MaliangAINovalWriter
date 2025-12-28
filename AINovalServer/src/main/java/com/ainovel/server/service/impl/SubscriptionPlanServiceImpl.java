package com.ainovel.server.service.impl;

import java.time.LocalDateTime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ainovel.server.domain.model.SubscriptionPlan;
import com.ainovel.server.domain.model.SubscriptionPlan.BillingCycle;
import com.ainovel.server.repository.SubscriptionPlanRepository;
import com.ainovel.server.service.SubscriptionPlanService;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 订阅计划服务实现
 */
@Service
public class SubscriptionPlanServiceImpl implements SubscriptionPlanService {
    
    private final SubscriptionPlanRepository subscriptionPlanRepository;
    
    @Autowired
    public SubscriptionPlanServiceImpl(SubscriptionPlanRepository subscriptionPlanRepository) {
        this.subscriptionPlanRepository = subscriptionPlanRepository;
    }
    
    @Override
    @Transactional
    public Mono<SubscriptionPlan> createPlan(SubscriptionPlan plan) {
        return subscriptionPlanRepository.existsByPlanName(plan.getPlanName())
                .flatMap(exists -> {
                    if (exists) {
                        return Mono.error(new IllegalArgumentException("订阅计划名称已存在: " + plan.getPlanName()));
                    }
                    
                    plan.setCreatedAt(LocalDateTime.now());
                    plan.setUpdatedAt(LocalDateTime.now());
                    
                    return subscriptionPlanRepository.save(plan);
                });
    }
    
    @Override
    @Transactional
    public Mono<SubscriptionPlan> updatePlan(String id, SubscriptionPlan plan) {
        return subscriptionPlanRepository.findById(id)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("订阅计划不存在: " + id)))
                .flatMap(existingPlan -> {
                    // 检查计划名称是否被其他计划使用
                    if (!existingPlan.getPlanName().equals(plan.getPlanName())) {
                        return subscriptionPlanRepository.existsByPlanName(plan.getPlanName())
                                .flatMap(exists -> {
                                    if (exists) {
                                        return Mono.error(new IllegalArgumentException("订阅计划名称已存在: " + plan.getPlanName()));
                                    }
                                    return updatePlanFields(existingPlan, plan);
                                });
                    } else {
                        return updatePlanFields(existingPlan, plan);
                    }
                })
                .flatMap(subscriptionPlanRepository::save);
    }
    
    private Mono<SubscriptionPlan> updatePlanFields(SubscriptionPlan existingPlan, SubscriptionPlan newPlan) {
        existingPlan.setPlanName(newPlan.getPlanName());
        existingPlan.setDescription(newPlan.getDescription());
        existingPlan.setPrice(newPlan.getPrice());
        existingPlan.setCurrency(newPlan.getCurrency());
        existingPlan.setBillingCycle(newPlan.getBillingCycle());
        existingPlan.setRoleId(newPlan.getRoleId());
        existingPlan.setCreditsGranted(newPlan.getCreditsGranted());
        existingPlan.setActive(newPlan.getActive());
        existingPlan.setRecommended(newPlan.getRecommended());
        existingPlan.setPriority(newPlan.getPriority());
        existingPlan.setFeatures(newPlan.getFeatures());
        existingPlan.setTrialDays(newPlan.getTrialDays());
        existingPlan.setMaxUsers(newPlan.getMaxUsers());
        existingPlan.setUpdatedAt(LocalDateTime.now());
        
        return Mono.just(existingPlan);
    }
    
    @Override
    @Transactional
    public Mono<Void> deletePlan(String id) {
        return subscriptionPlanRepository.findById(id)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("订阅计划不存在: " + id)))
                .flatMap(plan -> {
                    // TODO: 检查是否有用户正在使用此计划
                    return subscriptionPlanRepository.deleteById(id);
                });
    }
    
    @Override
    public Mono<SubscriptionPlan> findById(String id) {
        return subscriptionPlanRepository.findById(id);
    }
    
    @Override
    public Flux<SubscriptionPlan> findAll() {
        return subscriptionPlanRepository.findByActiveTrueOrderByPriorityDesc();
    }
    
    @Override
    public Flux<SubscriptionPlan> findActiveePlans() {
        return subscriptionPlanRepository.findByActiveTrue();
    }
    
    @Override
    public Flux<SubscriptionPlan> findByBillingCycle(BillingCycle billingCycle) {
        return subscriptionPlanRepository.findByBillingCycle(billingCycle);
    }
    
    @Override
    public Flux<SubscriptionPlan> findRecommendedPlans() {
        return subscriptionPlanRepository.findByRecommendedTrueAndActiveTrue();
    }
    
    @Override
    @Transactional
    public Mono<SubscriptionPlan> togglePlanStatus(String id, boolean active) {
        return subscriptionPlanRepository.findById(id)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("订阅计划不存在: " + id)))
                .flatMap(plan -> {
                    plan.setActive(active);
                    plan.setUpdatedAt(LocalDateTime.now());
                    return subscriptionPlanRepository.save(plan);
                });
    }
    
    @Override
    public Mono<Boolean> existsByPlanName(String planName) {
        return subscriptionPlanRepository.existsByPlanName(planName);
    }
}