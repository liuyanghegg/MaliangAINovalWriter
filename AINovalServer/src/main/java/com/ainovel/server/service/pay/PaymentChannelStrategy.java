package com.ainovel.server.service.pay;

import com.ainovel.server.domain.model.PaymentOrder;

import reactor.core.publisher.Mono;

/**
 * 支付渠道策略接口（策略模式）
 */
public interface PaymentChannelStrategy {

    /**
     * 生成支付URL（二维码/跳转链接）
     */
    Mono<String> createPaymentUrl(PaymentOrder order);

    /**
     * 处理支付回调
     */
    Mono<Boolean> handleNotify(PaymentOrder order, String rawNotifyPayload);

    /** 查询交易状态并返回更新后的订单（需要填充transactionId与状态映射） */
    Mono<PaymentOrder> queryTransaction(PaymentOrder order);

    /** 主动关单 */
    Mono<Boolean> closeOrder(PaymentOrder order);

    /** 退款（部分/全额） */
    Mono<Boolean> refund(PaymentOrder order, String refundNo, java.math.BigDecimal amount, String reason);
}



