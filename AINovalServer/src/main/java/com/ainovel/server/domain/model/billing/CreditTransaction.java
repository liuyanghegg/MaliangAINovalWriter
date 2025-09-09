package com.ainovel.server.domain.model.billing;

import java.time.Instant;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "credit_transactions")
public class CreditTransaction {
    @Id
    private String id;

    @Indexed(unique = true)
    private String traceId;

    private String userId;
    private String provider;
    private String modelId;
    private String featureType;

    private Integer inputTokens;
    private Integer outputTokens;
    private Long creditsDeducted;

    @Indexed
    private String status; // PENDING, DEDUCTED, FAILED, COMPENSATED, ADJUSTED
    private String errorMessage;

    // 计费模式：ACTUAL=基于真实用量；ESTIMATED=基于估算；ADJUSTMENT=差额调整
    private String billingMode; // ACTUAL, ESTIMATED, ADJUSTMENT
    // 向后兼容标识（可选）：是否为估算
    private Boolean estimated;

    // 冲正支持：若为冲正记录，指向被冲正的原交易traceId
    private String reversalOfTraceId;
    // 审计：操作人/原因
    private String operatorUserId;
    private String auditNote;

    @Builder.Default
    private Instant createdAt = Instant.now();
    private Instant updatedAt;
}


