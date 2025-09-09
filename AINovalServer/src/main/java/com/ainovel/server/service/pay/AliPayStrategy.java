package com.ainovel.server.service.pay;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.PaymentOrder;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

@Component
@Slf4j
public class AliPayStrategy implements PaymentChannelStrategy {

    @Override
    public Mono<String> createPaymentUrl(PaymentOrder order) {
        // 预留：调用支付宝统一收单下单并返回二维码链接，签名算法RSA2
        log.info("[AliPay] 生成支付URL(模拟): outTradeNo={}", order.getOutTradeNo());
        return Mono.just("alipayqr://platformapi/startapp?saId=10000007&qrcode=" + order.getOutTradeNo());
    }

    @Override
    public Mono<Boolean> handleNotify(PaymentOrder order, String rawNotifyPayload) {
        // 预留：根据支付平台返回参数对 sign 与 sign_type 校验
        log.info("[AliPay] 回调验签通过(模拟): outTradeNo={}", order.getOutTradeNo());
        return Mono.just(true);
    }

    @Override
    public Mono<PaymentOrder> queryTransaction(PaymentOrder order) {
        // 预留：调用支付宝交易查询接口
        return Mono.just(order);
    }

    @Override
    public Mono<Boolean> closeOrder(PaymentOrder order) {
        // 预留：调用支付宝关单接口
        return Mono.just(true);
    }

    @Override
    public Mono<Boolean> refund(PaymentOrder order, String refundNo, java.math.BigDecimal amount, String reason) {
        // 预留：调用支付宝退款接口
        return Mono.just(true);
    }
}



