package com.ainovel.server.dto;

import java.util.ArrayList;
import java.util.List;

import com.ainovel.server.domain.model.AIFeatureType;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 公共模型配置请求DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PublicModelConfigRequestDTO {
    
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
    @Builder.Default
    private Boolean enabled = true;
    
    /**
     * API Key列表
     */
    @Builder.Default
    private List<ApiKeyRequestDTO> apiKeys = new ArrayList<>();
    
    /**
     * API Endpoint
     */
    private String apiEndpoint;
    
    /**
     * 授权功能列表
     */
    @Builder.Default
    private List<AIFeatureType> enabledForFeatures = new ArrayList<>();
    
    /**
     * 积分汇率乘数
     */
    @Builder.Default
    private Double creditRateMultiplier = 1.0;
    
    /**
     * 最大并发请求数
     */
    @Builder.Default
    private Integer maxConcurrentRequests = -1;
    
    /**
     * 每日请求限制
     */
    @Builder.Default
    private Integer dailyRequestLimit = -1;
    
    /**
     * 每小时请求限制
     */
    @Builder.Default
    private Integer hourlyRequestLimit = -1;
    
    /**
     * 优先级
     */
    @Builder.Default
    private Integer priority = 0;
    
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
     * API Key请求DTO
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApiKeyRequestDTO {
        /**
         * API Key
         */
        private String apiKey;
        
        /**
         * 备注
         */
        private String note;
    }
}