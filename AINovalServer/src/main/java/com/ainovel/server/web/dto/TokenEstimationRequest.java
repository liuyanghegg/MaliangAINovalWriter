package com.ainovel.server.web.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Token估算请求DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TokenEstimationRequest {

    /**
     * 要估算的文本内容
     */
    private String content;

    /**
     * AI模型配置ID
     */
    private String aiConfigId;

    /**
     * 用户ID
     */
    private String userId;

    /**
     * 估算类型（SUMMARY_GENERATION, CONTENT_ANALYSIS等）
     */
    private String estimationType = "SUMMARY_GENERATION";
} 