package com.ainovel.server.service.impl;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;

import com.ainovel.server.domain.model.PaymentOrder;
import com.ainovel.server.domain.model.SubscriptionPlan;
import com.ainovel.server.domain.model.User;
import com.ainovel.server.domain.model.UserSubscription;
import com.ainovel.server.domain.model.UserSubscription.SubscriptionStatus;
import com.ainovel.server.repository.SubscriptionPlanRepository;
import com.ainovel.server.repository.UserRepository;
import com.ainovel.server.repository.UserSubscriptionRepository;
import com.ainovel.server.service.SubscriptionAssignmentService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

@Service
@RequiredArgsConstructor
@Slf4j
public class SubscriptionAssignmentServiceImpl implements SubscriptionAssignmentService {

    private final UserSubscriptionRepository userSubscriptionRepository;
    private final SubscriptionPlanRepository planRepository;
    private final UserRepository userRepository;

    @Override
    public Mono<Void> assignSubscription(PaymentOrder order) {
        if (order.getOrderType() == PaymentOrder.OrderType.CREDIT_PACK) {
            // 若为积分包，简单累加积分（此处要求把planId当作creditPackId使用，或扩展PaymentOrder字段）
            // 为简化演示：从订阅计划取creditsGranted作为积分包额度
            return planRepository.findById(order.getPlanId())
                .flatMap(plan -> userRepository.findById(order.getUserId())
                    .map(user -> { user.addCredits(plan.getCreditsGranted() != null ? plan.getCreditsGranted() : 0L); return user; })
                    .flatMap(userRepository::save))
                .then();
        }
        return planRepository.findById(order.getPlanId())
            .switchIfEmpty(Mono.error(new IllegalArgumentException("订阅计划不存在: " + order.getPlanId())))
            .flatMap(plan -> grantToUser(order, plan))
            .then();
    }

    private Mono<User> grantToUser(PaymentOrder order, SubscriptionPlan plan) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime end = switch (plan.getBillingCycle()) {
            case MONTHLY -> now.plusMonths(1);
            case QUARTERLY -> now.plusMonths(3);
            case YEARLY -> now.plusYears(1);
            case LIFETIME -> now.plusYears(100);
        };

        // 创建或续期用户订阅
        UserSubscription subscription = UserSubscription.builder()
            .userId(order.getUserId())
            .planId(plan.getId())
            .startDate(now)
            .endDate(end)
            .status(SubscriptionStatus.ACTIVE)
            .autoRenewal(false)
            .paymentMethod(order.getChannel().name())
            .transactionId(order.getTransactionId())
            .totalCredits(plan.getCreditsGranted() != null ? plan.getCreditsGranted() : 0L)
            .creditsUsed(0L)
            .createdAt(now)
            .updatedAt(now)
            .build();

        return userSubscriptionRepository.save(subscription)
            .flatMap(saved -> userRepository.findById(order.getUserId())
                .map(user -> {
                    // 授予角色
                    if (plan.getRoleId() != null && !user.getRoleIds().contains(plan.getRoleId())) {
                        user.getRoleIds().add(plan.getRoleId());
                    }
                    user.setCurrentSubscriptionId(saved.getId());
                    // 发放积分（累加）
                    Long grant = plan.getCreditsGranted() != null ? plan.getCreditsGranted() : 0L;
                    if (grant > 0) {
                        user.addCredits(grant);
                    }
                    user.setUpdatedAt(LocalDateTime.now());
                    return user;
                })
                .flatMap(userRepository::save)
                .doOnSuccess(u -> log.info("订阅授予成功: userId={}, plan={}, subscriptionId={}", u.getId(), plan.getPlanName(), subscription.getId())));
    }
}



