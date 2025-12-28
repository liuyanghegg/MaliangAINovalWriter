package com.ainovel.server.domain.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 积分补充包（一次性购买）
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "credit_packs")
public class CreditPack {

    @Id
    private String id;

    @Indexed(unique = true)
    private String name;

    private String description;

    private Long credits;

    private BigDecimal price;

    @Builder.Default
    private String currency = "CNY";

    @Builder.Default
    private Boolean active = true;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}



