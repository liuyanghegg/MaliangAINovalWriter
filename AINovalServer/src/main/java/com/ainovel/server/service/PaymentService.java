package com.ainovel.server.service;

import com.ainovel.server.domain.model.PaymentOrder;

import reactor.core.publisher.Mono;

/**
 * 支付服务（抽象层）
 * 使用策略模式对接不同支付渠道（微信 / 支付宝）
 */
public interface PaymentService {

    /**
     * 创建支付订单并返回支付URL（二维码或跳转链接）
     */
    Mono<PaymentOrder> createOrder(String userId, String planId, PaymentOrder.PayChannel channel);

    /**
     * 创建支付订单并指定订单类型（订阅/积分包）
     */
    Mono<PaymentOrder> createOrder(String userId, String planId, PaymentOrder.PayChannel channel, PaymentOrder.OrderType orderType);

    /**
     * 处理支付回调（验签、更新订单并派发订阅授予）
     */
    Mono<Boolean> handleNotify(PaymentOrder.PayChannel channel, String outTradeNo, String rawNotifyPayload);
}



