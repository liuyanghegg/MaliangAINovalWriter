package com.ainovel.server.service.billing;

import org.springframework.data.mongodb.ReactiveMongoTransactionManager;
import org.springframework.stereotype.Service;
import org.springframework.transaction.reactive.TransactionalOperator;

import com.ainovel.server.domain.model.billing.CreditTransaction;
import com.ainovel.server.repository.CreditTransactionRepository;
import com.ainovel.server.service.CreditService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

@Service
@RequiredArgsConstructor
@Slf4j
public class ReversalService {

    private final CreditTransactionRepository txRepo;
    private final CreditService creditService;
    private final ReactiveMongoTransactionManager tm;

    /**
     * 对指定traceId的已扣费交易执行冲正（负向交易）。
     */
    public Mono<CreditTransaction> reverseByTraceId(String traceId, String operatorUserId, String reason) {
        return txRepo.findByTraceId(traceId)
            .switchIfEmpty(Mono.error(new IllegalArgumentException("未找到原交易: " + traceId)))
            .flatMap(orig -> {
                if (!"DEDUCTED".equals(orig.getStatus()) && !"COMPENSATED".equals(orig.getStatus())) {
                    return Mono.error(new IllegalStateException("仅支持对已扣费交易进行冲正"));
                }
                long credits = orig.getCreditsDeducted() != null ? orig.getCreditsDeducted() : 0L;
                if (credits <= 0) {
                    return Mono.error(new IllegalStateException("原交易无有效扣费"));
                }

                CreditTransaction reversal = CreditTransaction.builder()
                    .traceId(orig.getTraceId() + "#REV-" + java.util.UUID.randomUUID())
                    .userId(orig.getUserId())
                    .provider(orig.getProvider())
                    .modelId(orig.getModelId())
                    .featureType(orig.getFeatureType())
                    .inputTokens(orig.getInputTokens())
                    .outputTokens(orig.getOutputTokens())
                    .creditsDeducted(-credits)
                    .status("DEDUCTED")
                    .reversalOfTraceId(orig.getTraceId())
                    .operatorUserId(operatorUserId)
                    .auditNote(reason)
                    .build();

                // 使用事务确保加回积分与写入冲正记录的一致性，外层添加有限重试（处理瞬时事务错误）
                return TransactionalOperator.create(tm).execute(tx ->
                    creditService.addCredits(orig.getUserId(), credits, "REVERSAL:" + reason)
                        .flatMap(ok -> {
                            if (!ok) return Mono.error(new RuntimeException("加回积分失败"));
                            return txRepo.save(reversal);
                        })
                ).single()
                 .retryWhen(
                    reactor.util.retry.Retry.max(2)
                        .filter(err -> {
                            String m = err.getMessage() != null ? err.getMessage() : "";
                            return m.contains("NoSuchTransaction") || m.contains("TransientTransactionError") || m.contains("251");
                        })
                        .onRetryExhaustedThrow((spec, signal) -> signal.failure())
                 );
            });
    }
}


