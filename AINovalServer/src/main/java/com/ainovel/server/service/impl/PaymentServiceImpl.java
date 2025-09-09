package com.ainovel.server.service.impl;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.ainovel.server.domain.model.PaymentOrder;
import com.ainovel.server.repository.PaymentOrderRepository;
import com.ainovel.server.repository.SubscriptionPlanRepository;
import com.ainovel.server.service.PaymentService;
import com.ainovel.server.service.SubscriptionAssignmentService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * 支付服务实现
 * 说明：此处演示生成支付URL的流程与回调更新逻辑，具体微信/支付宝SDK对接可在此处或独立子类中完成。
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentServiceImpl implements PaymentService {

    private final PaymentOrderRepository paymentOrderRepository;
    private final SubscriptionPlanRepository planRepository;
    private final SubscriptionAssignmentService subscriptionAssignmentService;
    private final com.ainovel.server.service.pay.WeChatPayStrategy weChatPayStrategy;
    private final com.ainovel.server.service.pay.AliPayStrategy aliPayStrategy;

    @Override
    public Mono<PaymentOrder> createOrder(String userId, String planId, PaymentOrder.PayChannel channel) {
        return createOrder(userId, planId, channel, PaymentOrder.OrderType.SUBSCRIPTION);
    }

    public Mono<PaymentOrder> createOrder(String userId, String planId, PaymentOrder.PayChannel channel, PaymentOrder.OrderType orderType) {
        if (StringUtils.isBlank(userId) || StringUtils.isBlank(planId)) {
            return Mono.error(new IllegalArgumentException("用户或计划不能为空"));
        }
        return planRepository.findById(planId)
            .switchIfEmpty(Mono.error(new IllegalArgumentException("订阅计划不存在: " + planId)))
            .flatMap(plan -> {
                String outTradeNo = UUID.randomUUID().toString().replace("-", "");
                PaymentOrder order = PaymentOrder.builder()
                    .outTradeNo(outTradeNo)
                    .userId(userId)
                    .planId(plan.getId())
                    .planNameSnapshot(plan.getPlanName())
                    .priceSnapshot(plan.getPrice())
                    .currencySnapshot(plan.getCurrency())
                    .billingCycleSnapshot(plan.getBillingCycle())
                    .amount(plan.getPrice() != null ? plan.getPrice() : BigDecimal.ZERO)
                    .currency(StringUtils.defaultIfBlank(plan.getCurrency(), "CNY"))
                    .channel(channel)
                    .status(PaymentOrder.PayStatus.CREATED)
                    .orderType(orderType)
                    .createdAt(LocalDateTime.now())
                    .updatedAt(LocalDateTime.now())
                    .expireAt(LocalDateTime.now().plusMinutes(30))
                    .build();

                return paymentOrderRepository.save(order)
                    .flatMap(saved -> {
                        Mono<String> urlMono = switch (channel) {
                            case WECHAT -> weChatPayStrategy.createPaymentUrl(saved);
                            case ALIPAY -> aliPayStrategy.createPaymentUrl(saved);
                        };
                        return urlMono.map(url -> {
                            saved.setPaymentUrl(url);
                            return saved;
                        }).flatMap(paymentOrderRepository::save);
                    });
            });
    }

    @Override
    public Mono<Boolean> handleNotify(PaymentOrder.PayChannel channel, String outTradeNo, String rawNotifyPayload) {
        // 实际生产中：先验签，再处理
        return paymentOrderRepository.findByOutTradeNo(outTradeNo)
            .switchIfEmpty(Mono.error(new IllegalArgumentException("订单不存在: " + outTradeNo)))
            .flatMap(order -> {
                if (order.getStatus() == PaymentOrder.PayStatus.SUCCESS) {
                    return Mono.just(true); // 幂等
                }
                Mono<Boolean> verifyMono = switch (channel) {
                    case WECHAT -> weChatPayStrategy.handleNotify(order, rawNotifyPayload);
                    case ALIPAY -> aliPayStrategy.handleNotify(order, rawNotifyPayload);
                };
                return verifyMono.flatMap(verified -> {
                    if (!verified) return Mono.just(false);
                order.setNotifyPayload(rawNotifyPayload);
                order.setStatus(PaymentOrder.PayStatus.SUCCESS);
                order.setPaidAt(LocalDateTime.now());
                order.setUpdatedAt(LocalDateTime.now());

                return paymentOrderRepository.save(order)
                    .doOnSuccess(saved -> log.info("订单支付成功: {}", saved.getOutTradeNo()))
                    .then(subscriptionAssignmentService.assignSubscription(order))
                    .thenReturn(true);
                });
            })
            .onErrorResume(e -> {
                log.error("处理支付回调失败: {}", e.getMessage(), e);
                return Mono.just(false);
            });
    }
}


