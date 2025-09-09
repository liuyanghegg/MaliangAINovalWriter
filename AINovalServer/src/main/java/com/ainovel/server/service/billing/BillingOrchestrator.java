package com.ainovel.server.service.billing;

import org.springframework.context.event.EventListener;
import org.springframework.data.mongodb.ReactiveMongoTransactionManager;
import org.springframework.stereotype.Service;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.billing.CreditTransaction;
import com.ainovel.server.domain.model.observability.LLMTrace;
import com.ainovel.server.repository.CreditTransactionRepository;
import com.ainovel.server.service.CreditService;
import com.ainovel.server.service.ai.observability.events.BillingRequestedEvent;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

@Service
@RequiredArgsConstructor
@Slf4j
public class BillingOrchestrator {

    private final CreditService creditService;
    private final CreditTransactionRepository txRepo;
    private final ReactiveMongoTransactionManager tm;

    @EventListener
    public void onBillingRequested(BillingRequestedEvent evt) {
        LLMTrace t = evt.getTrace();
        if (t == null || t.getRequest() == null || t.getRequest().getParameters() == null
                || t.getRequest().getParameters().getProviderSpecific() == null) {
            return;
        }

        String traceId = t.getTraceId();
        String userId = t.getUserId();
        String provider = t.getProvider();
        String modelId = t.getModel();

        var ps = t.getRequest().getParameters().getProviderSpecific();
        Object flag = ps.get(BillingKeys.REQUIRES_POST_STREAM_DEDUCTION);
        Object used = ps.get(BillingKeys.USED_PUBLIC_MODEL);
        Object ft = ps.get(BillingKeys.STREAM_FEATURE_TYPE);
        if (!Boolean.TRUE.equals(flag) || !Boolean.TRUE.equals(used) || ft == null) {
            return;
        }

        var token = t.getResponse() != null && t.getResponse().getMetadata() != null ? t.getResponse().getMetadata().getTokenUsage() : null;
        int in = token != null && token.getInputTokenCount() != null ? token.getInputTokenCount() : 0;
        int out = token != null && token.getOutputTokenCount() != null ? token.getOutputTokenCount() : 0;
        AIFeatureType featureType = AIFeatureType.valueOf(ft.toString());

        log.info("🧾 BillingOrchestrator 收到扣费请求: traceId={}, userId={}, provider={}, modelId={}, featureType={}, inTokens={}, outTokens={}",
                traceId, userId, provider, modelId, featureType, in, out);

        // 先查现有交易：若存在并为ESTIMATED，则做ADJUSTMENT；否则走正常扣费流
        txRepo.findByTraceId(traceId)
            .flatMap(existing -> {
                if (existing != null && Boolean.TRUE.equals(existing.getEstimated())) {
                    // 已做过估算扣费，基于实际用量做差额调整
                    return creditService.calculateCreditCost(provider, modelId, featureType, in, out)
                        .flatMap(actualCredits -> {
                            long prev = existing.getCreditsDeducted() != null ? existing.getCreditsDeducted() : 0L;
                            long diff = actualCredits - prev;
                            if (diff == 0L) {
                                log.info("估算与实际一致，无需调整: traceId={} actual={} prev={}", traceId, actualCredits, prev);
                                return Mono.empty();
                            }
                            Mono<Boolean> op = diff > 0
                                ? creditService.deductCredits(userId, diff)
                                : creditService.addCredits(userId, -diff, "ADJUSTMENT for " + traceId);
                            return op.flatMap(ok -> {
                                if (!ok) return Mono.error(new RuntimeException("调整扣减失败"));
                                CreditTransaction adjust = CreditTransaction.builder()
                                        .traceId(traceId + ":adjust")
                                        .userId(userId)
                                        .provider(provider)
                                        .modelId(modelId)
                                        .featureType(featureType.name())
                                        .inputTokens(in)
                                        .outputTokens(out)
                                        .creditsDeducted(diff)
                                        .status("ADJUSTED")
                                        .billingMode("ADJUSTMENT")
                                        .estimated(Boolean.FALSE)
                                        .reversalOfTraceId(traceId)
                                        .updatedAt(java.time.Instant.now())
                                        .build();
                                return txRepo.save(adjust).then();
                            });
                        })
                        .onErrorResume(e -> { log.error("调整失败: traceId={}, err={}", traceId, e.getMessage()); return Mono.empty(); });
                }
                // 不是估算交易，跳过（避免重复）；若需要可扩展为幂等等
                log.info("已存在交易且非估算，跳过新扣费: traceId={}", traceId);
                return Mono.empty();
            })
            .switchIfEmpty(Mono.defer(() -> {
                // 创建PENDING事务并按实际扣费
                CreditTransaction pending = CreditTransaction.builder()
                        .traceId(traceId)
                        .userId(userId)
                        .provider(provider)
                        .modelId(modelId)
                        .featureType(featureType.name())
                        .inputTokens(in)
                        .outputTokens(out)
                        .status("PENDING")
                        .billingMode("ACTUAL")
                        .estimated(Boolean.FALSE)
                        .build();

                return txRepo.save(pending)
                    .then(Mono.defer(() -> Mono.from(
                        org.springframework.transaction.reactive.TransactionalOperator.create(tm)
                            .execute(status ->
                                creditService.deductCreditsForAI(userId, provider, modelId, featureType, in, out)
                                    .flatMap(res -> {
                                        if (res.isSuccess()) {
                                            return txRepo.findByTraceId(traceId)
                                                .flatMap(tx -> { tx.setStatus("DEDUCTED"); tx.setCreditsDeducted(res.getCreditsDeducted()); tx.setBillingMode("ACTUAL"); tx.setEstimated(Boolean.FALSE); tx.setUpdatedAt(java.time.Instant.now()); return txRepo.save(tx); })
                                                .then(Mono.<Void>empty());
                                        } else {
                                            return txRepo.findByTraceId(traceId)
                                                .flatMap(tx -> { tx.setStatus("FAILED"); tx.setErrorMessage(res.getMessage()); tx.setUpdatedAt(java.time.Instant.now()); return txRepo.save(tx); })
                                                .then(Mono.<Void>error(new RuntimeException("扣费失败: " + res.getMessage())));
                                        }
                                    })
                            )
                    ))
                        .retryWhen(
                            reactor.util.retry.Retry.max(2)
                                .filter(err -> {
                                    String m = err.getMessage() != null ? err.getMessage() : "";
                                    return m.contains("NoSuchTransaction") || m.contains("TransientTransactionError") || m.contains("251");
                                })
                                .onRetryExhaustedThrow((spec, signal) -> signal.failure())
                        )
                    )
                    .onErrorResume(e -> {
                        log.error("BillingOrchestrator 扣费事务失败: traceId={}, err={}", traceId, e.getMessage());
                        return txRepo.findByTraceId(traceId)
                            .flatMap(tx -> { tx.setStatus("FAILED"); tx.setErrorMessage(e.getMessage()); tx.setUpdatedAt(java.time.Instant.now()); return txRepo.save(tx); })
                            .then();
                    });
            }))
            .subscribe();
    }
}


