package com.ainovel.server.service.pay;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.PaymentOrder;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

@Component
@Slf4j
public class WeChatPayStrategy implements PaymentChannelStrategy {

    @Override
    public Mono<String> createPaymentUrl(PaymentOrder order) {
        // 预留：调用微信支付统一下单，生成 code_url
        // 参数：商户号、AppId、API v3 key、证书序列号、notifyUrl、amount(分)、outTradeNo、描述、时间戳与签名
        log.info("[WeChat] 生成支付URL(模拟): outTradeNo={}", order.getOutTradeNo());
        return Mono.just("weixin://wxpay/bizpayurl?pr=" + order.getOutTradeNo());
    }

    @Override
    public Mono<Boolean> handleNotify(PaymentOrder order, String rawNotifyPayload) {
        // 预留：根据HTTP头部/平台证书+签名校验（Wechatpay-Timestamp/Wechatpay-Nonce/Wechatpay-Signature/Wechatpay-Serial）
        log.info("[WeChat] 回调验签通过(模拟): outTradeNo={}", order.getOutTradeNo());
        return Mono.just(true);
    }

    @Override
    public Mono<PaymentOrder> queryTransaction(PaymentOrder order) {
        // 预留：调用微信交易查询接口，根据返回更新status/transactionId
        return Mono.just(order);
    }

    @Override
    public Mono<Boolean> closeOrder(PaymentOrder order) {
        // 预留：调用微信关单接口
        return Mono.just(true);
    }

    @Override
    public Mono<Boolean> refund(PaymentOrder order, String refundNo, java.math.BigDecimal amount, String reason) {
        // 预留：调用微信退款接口
        return Mono.just(true);
    }
}



