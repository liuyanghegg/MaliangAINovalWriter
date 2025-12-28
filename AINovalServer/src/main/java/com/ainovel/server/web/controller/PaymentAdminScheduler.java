package com.ainovel.server.web.controller;

import java.time.LocalDateTime;

import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.PaymentOrder;
import com.ainovel.server.repository.PaymentOrderRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

@Component
@EnableScheduling
@RequiredArgsConstructor
@Slf4j
public class PaymentAdminScheduler {

    private final PaymentOrderRepository paymentOrderRepository;

    /**
     * 简化的超时关单任务：每5分钟扫描一次，超过30分钟未支付的订单标记为EXPIRED
     * 真实场景建议调用支付平台关单API
     */
    @Scheduled(fixedDelay = 300000)
    public void closeExpiredOrders() {
        LocalDateTime now = LocalDateTime.now();
        paymentOrderRepository.findAll()
            .filter(o -> o.getStatus() == PaymentOrder.PayStatus.CREATED || o.getStatus() == PaymentOrder.PayStatus.PENDING)
            .filter(o -> o.getExpireAt() != null && o.getExpireAt().isBefore(now))
            .flatMap(o -> {
                o.setStatus(PaymentOrder.PayStatus.EXPIRED);
                o.setUpdatedAt(now);
                return paymentOrderRepository.save(o)
                    .doOnSuccess(x -> log.info("订单过期: {}", o.getOutTradeNo()));
            })
            .onErrorResume(e -> {
                log.error("关单任务异常: {}", e.getMessage(), e);
                return Mono.empty();
            })
            .subscribe();
    }
}


