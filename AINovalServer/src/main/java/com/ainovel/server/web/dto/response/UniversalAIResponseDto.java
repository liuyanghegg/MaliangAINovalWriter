package com.ainovel.server.web.dto.response;

import java.time.LocalDateTime;
import java.util.Map;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

/**
 * 通用AI响应DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UniversalAIResponseDto {

    /**
     * 响应ID
     */
    private String id;

    /**
     * 对应的请求类型
     */
    private String requestType;

    /**
     * 生成的内容
     */
    private String content;

    /**
     * 完成原因
     */
    private String finishReason;

    /**
     * Token使用情况
     */
    private TokenUsageDto tokenUsage;

    /**
     * 使用的模型
     */
    private String model;

    /**
     * 创建时间
     */
    private LocalDateTime createdAt;

    /**
     * 元数据
     */
    private Map<String, Object> metadata;

    /**
     * Token使用情况DTO
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class TokenUsageDto {
        private Integer promptTokens;
        private Integer completionTokens;
        private Integer totalTokens;
    }
} 