package com.ainovel.server.dto;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import com.ainovel.server.domain.model.AIFeatureType;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 公共模型配置响应DTO（包含API Keys）
 * 仅供管理员使用，包含敏感的API Key信息
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PublicModelConfigWithKeysDTO {
    
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
     * API Key池详情（包含实际的Key值）
     */
    @Builder.Default
    private List<ApiKeyWithStatusDTO> apiKeyStatuses = new ArrayList<>();
    
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
     * API Key状态DTO（包含实际Key值）
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApiKeyWithStatusDTO {
        /**
         * API Key值
         */
        private String apiKey;
        
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
} 