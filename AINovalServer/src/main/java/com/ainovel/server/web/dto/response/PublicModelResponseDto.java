package com.ainovel.server.web.dto.response;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.util.List;
import java.util.Map;

/**
 * 公共模型响应DTO
 * 只包含向前端暴露的安全信息，不含API Keys等敏感数据
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PublicModelResponseDto {

    /**
     * 模型ID
     */
    private String id;

    /**
     * 提供商 (如: openai, anthropic, google等)
     */
    private String provider;

    /**
     * 模型标识符 (如: gpt-4, claude-3-sonnet)
     */
    private String modelId;

    /**
     * 显示名称
     */
    private String displayName;

    /**
     * 模型描述
     */
    private String description;

    /**
     * 积分倍率 (如: 1.0 表示标准倍率, 1.5 表示1.5倍积分)
     */
    private Double creditRateMultiplier;

    /**
     * 支持的AI功能列表
     */
    private List<String> supportedFeatures;

    /**
     * 模型标签 (如: ["快速", "高质量", "多语言"])
     */
    private List<String> tags;

    /**
     * 性能指标
     */
    private PerformanceMetrics performanceMetrics;

    /**
     * 限制信息
     */
    private LimitationInfo limitations;

    /**
     * 优先级 (用于前端排序)
     */
    private Integer priority;

    /**
     * 是否推荐使用
     */
    private Boolean recommended;

    /**
     * 性能指标内部类
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class PerformanceMetrics {
        /**
         * 最大上下文长度 (tokens)
         */
        private Integer maxContextLength;

        /**
         * 最大输出长度 (tokens)
         */
        private Integer maxOutputLength;

        /**
         * 平均响应时间 (毫秒)
         */
        private Integer averageResponseTime;

        /**
         * 输入价格 (USD per 1k tokens)
         */
        private Double inputPricePerThousandTokens;

        /**
         * 输出价格 (USD per 1k tokens)
         */
        private Double outputPricePerThousandTokens;
    }

    /**
     * 限制信息内部类
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LimitationInfo {
        /**
         * 每分钟请求限制
         */
        private Integer requestsPerMinute;

        /**
         * 每日请求限制
         */
        private Integer requestsPerDay;

        /**
         * 每月请求限制
         */
        private Integer requestsPerMonth;

        /**
         * 特殊限制说明
         */
        private String specialLimitations;
    }
} 