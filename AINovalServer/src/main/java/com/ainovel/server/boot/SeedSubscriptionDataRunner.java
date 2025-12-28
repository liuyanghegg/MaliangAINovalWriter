package com.ainovel.server.boot;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.SubscriptionPlan;
import com.ainovel.server.domain.model.SubscriptionPlan.BillingCycle;
import com.ainovel.server.repository.SubscriptionPlanRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

@Component
@Order(10)
@RequiredArgsConstructor
@Slf4j
public class SeedSubscriptionDataRunner implements ApplicationRunner {

    private final SubscriptionPlanRepository planRepository;

    @Override
    public void run(ApplicationArguments args) {
        log.info("Starting subscription data seeding...");
        seedIfEmpty().subscribe(
            ok -> log.info("✅ Subscription seed completed successfully: {}", ok),
            err -> log.error("❌ Subscription seed failed (this may be due to MongoDB map-key-dot-replacement configuration)", err)
        );
    }

    private Mono<Boolean> seedIfEmpty() {
        return planRepository.findByActiveTrue().hasElements().flatMap(exists -> {
            if (exists) return Mono.just(true);

            // Free（展示为0元，受限能力）
            SubscriptionPlan free = SubscriptionPlan.builder()
                .planName("Free")
                .description("基础功能，适合体验与轻度使用")
                .price(BigDecimal.ZERO)
                .currency("CNY")
                .billingCycle(BillingCycle.MONTHLY)
                .priority(10)
                .active(true)
                .recommended(false)
                .features(new LinkedHashMap<>(Map.of(
                    "ai.daily.calls", 10,
                    "import.daily.limit", 1,
                    "novel.max.count", 3
                )))
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

            // Pro（月付）
            SubscriptionPlan pro = SubscriptionPlan.builder()
                .planName("Pro")
                .description("更高的AI调用与导入额度，适合稳定创作")
                .price(new BigDecimal("29.00"))
                .currency("CNY")
                .billingCycle(BillingCycle.MONTHLY)
                .priority(100)
                .active(true)
                .recommended(true)
                .creditsGranted(200000L)
                .features(new LinkedHashMap<>(Map.of(
                    "ai.daily.calls", 200,
                    "import.daily.limit", 10,
                    "novel.max.count", 30
                )))
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

            // Pro（年付）
            SubscriptionPlan proYearly = SubscriptionPlan.builder()
                .planName("Pro Yearly")
                .description("年度优惠，适合长期创作")
                .price(new BigDecimal("288.00"))
                .currency("CNY")
                .billingCycle(BillingCycle.YEARLY)
                .priority(90)
                .active(true)
                .recommended(false)
                .creditsGranted(2500000L)
                .features(new LinkedHashMap<>(Map.of(
                    "ai.daily.calls", 300,
                    "import.daily.limit", 20,
                    "novel.max.count", 100
                )))
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

            // Lifetime
            SubscriptionPlan lifetime = SubscriptionPlan.builder()
                .planName("Lifetime")
                .description("一次购买，长期使用")
                .price(new BigDecimal("999.00"))
                .currency("CNY")
                .billingCycle(BillingCycle.LIFETIME)
                .priority(80)
                .active(true)
                .recommended(false)
                .creditsGranted(10000000L)
                .features(new LinkedHashMap<>(Map.of(
                    "ai.daily.calls", 1000,
                    "import.daily.limit", 100,
                    "novel.max.count", 1000
                )))
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

            return planRepository.save(free)
                .then(planRepository.save(pro))
                .then(planRepository.save(proYearly))
                .then(planRepository.save(lifetime))
                .thenReturn(true);
        });
    }
}



