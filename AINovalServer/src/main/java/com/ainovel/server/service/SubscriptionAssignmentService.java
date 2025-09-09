package com.ainovel.server.service;

import com.ainovel.server.domain.model.PaymentOrder;

import reactor.core.publisher.Mono;

/**
 * 订阅授予服务：支付成功后授予用户对应的角色、积分与配额阈值
 */
public interface SubscriptionAssignmentService {

    /**
     * 根据支付订单授予订阅（包含创建/续期 UserSubscription、更新 User、授予角色、发放积分等）
     */
    Mono<Void> assignSubscription(PaymentOrder order);
}




