package com.ainovel.server.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import com.ainovel.server.domain.model.AIFeatureType;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 公共模型配置详细信息DTO
 * 包含模型配置、定价信息和使用统计
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PublicModelConfigDetailsDTO {
    
    /**
     * 配置ID
     */
    private String id;
    
    /**
     * 提供商名称
     */
    private String provider;
    
    /**
     * 模型ID
     */
    private String modelId;
    
    /**
     * 模型显示名称
     */
    private String displayName;
    
    /**
     * 是否启用
     */
    private Boolean enabled;
    
    /**
     * API Endpoint
     */
    private String apiEndpoint;
    
    /**
     * 整体验证状态
     */
    private Boolean isValidated;
    
    /**
     * API Key池状态摘要 (格式: "有效数量/总数量")
     */
    private String apiKeyPoolStatus;
    
    /**
     * API Key池详情（不包含实际的Key值）
     */
    @Builder.Default
    private List<ApiKeyStatusDTO> apiKeyStatuses = new ArrayList<>();
    
    /**
     * 授权功能列表
     */
    @Builder.Default
    private List<AIFeatureType> enabledForFeatures = new ArrayList<>();
    
    /**
     * 积分汇率乘数
     */
    private Double creditRateMultiplier;
    
    /**
     * 最大并发请求数
     */
    private Integer maxConcurrentRequests;
    
    /**
     * 每日请求限制
     */
    private Integer dailyRequestLimit;
    
    /**
     * 每小时请求限制
     */
    private Integer hourlyRequestLimit;
    
    /**
     * 优先级
     */
    private Integer priority;
    
    /**
     * 描述
     */
    private String description;
    
    /**
     * 标签
     */
    @Builder.Default
    private List<String> tags = new ArrayList<>();
    
    /**
     * 创建时间
     */
    private LocalDateTime createdAt;
    
    /**
     * 更新时间
     */
    private LocalDateTime updatedAt;
    
    /**
     * 创建者用户ID
     */
    private String createdBy;
    
    /**
     * 最后修改者用户ID
     */
    private String updatedBy;
    
    /**
     * 定价信息
     */
    private PricingInfoDTO pricingInfo;
    
    /**
     * 使用统计信息
     */
    private UsageStatisticsDTO usageStatistics;
    
    /**
     * API Key状态DTO（不包含实际Key值）
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApiKeyStatusDTO {
        /**
         * 是否验证通过
         */
        private Boolean isValid;
        
        /**
         * 验证错误信息
         */
        private String validationError;
        
        /**
         * 最近验证时间
         */
        private LocalDateTime lastValidatedAt;
        
        /**
         * 备注
         */
        private String note;
    }
    
    /**
     * 定价信息DTO
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PricingInfoDTO {
        /**
         * 模型名称
         */
        private String modelName;
        
        /**
         * 输入token价格（每1000个token的美元价格）
         */
        private Double inputPricePerThousandTokens;
        
        /**
         * 输出token价格（每1000个token的美元价格）
         */
        private Double outputPricePerThousandTokens;
        
        /**
         * 统一价格（如果输入输出使用相同价格）
         */
        private Double unifiedPricePerThousandTokens;
        
        /**
         * 最大上下文token数
         */
        private Integer maxContextTokens;
        
        /**
         * 是否支持流式输出
         */
        private Boolean supportsStreaming;
        
        /**
         * 定价数据更新时间
         */
        private LocalDateTime pricingUpdatedAt;
        
        /**
         * 是否有定价数据
         */
        private Boolean hasPricingData;
    }
    
    /**
     * 使用统计信息DTO
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UsageStatisticsDTO {
        /**
         * 总请求数
         */
        @Builder.Default
        private Long totalRequests = 0L;
        
        /**
         * 总输入token数
         */
        @Builder.Default
        private Long totalInputTokens = 0L;
        
        /**
         * 总输出token数
         */
        @Builder.Default
        private Long totalOutputTokens = 0L;
        
        /**
         * 总token数
         */
        @Builder.Default
        private Long totalTokens = 0L;
        
        /**
         * 总成本
         */
        @Builder.Default
        private BigDecimal totalCost = BigDecimal.ZERO;
        
        /**
         * 平均每请求成本
         */
        @Builder.Default
        private BigDecimal averageCostPerRequest = BigDecimal.ZERO;
        
        /**
         * 平均每token成本
         */
        @Builder.Default
        private BigDecimal averageCostPerToken = BigDecimal.ZERO;
        
        /**
         * 最近30天请求数
         */
        @Builder.Default
        private Long last30DaysRequests = 0L;
        
        /**
         * 最近30天成本
         */
        @Builder.Default
        private BigDecimal last30DaysCost = BigDecimal.ZERO;
        
        /**
         * 是否有使用数据
         */
        private Boolean hasUsageData;
    }
}