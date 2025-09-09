package com.ainovel.server.web.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Token估算响应DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TokenEstimationResponse {

    /**
     * 估算的输入Token数量
     */
    private Long inputTokens;

    /**
     * 估算的输出Token数量
     */
    private Long outputTokens;

    /**
     * 总Token数量
     */
    private Long totalTokens;

    /**
     * 估算成本（美元）
     */
    private Double estimatedCost;

    /**
     * 使用的模型名称
     */
    private String modelName;

    /**
     * 估算是否成功
     */
    private Boolean success = true;

    /**
     * 错误信息（如果估算失败）
     */
    private String errorMessage;

    /**
     * 警告信息
     */
    private String warnings;
} 