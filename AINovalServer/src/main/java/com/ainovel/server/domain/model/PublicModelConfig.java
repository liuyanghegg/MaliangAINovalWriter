package com.ainovel.server.domain.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 公共模型配置实体类
 * 用于管理哪些AI模型可作为公共模型使用，以及相关的业务规则
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "public_model_configs")
@CompoundIndexes({
    @CompoundIndex(name = "provider_model_idx", def = "{'provider' : 1, 'modelId' : 1}", unique = true)
})
public class PublicModelConfig {
    
    @Id
    private String id;
    
    /**
     * 提供商名称（关联 ModelPricing 的 provider）
     */
    private String provider;
    
    /**
     * 模型ID（关联 ModelPricing 的 modelId）
     */
    private String modelId;
    
    /**
     * 模型显示名称（用于UI显示）
     */
    private String displayName;
    
    /**
     * 是否将此模型作为公共模型开放
     */
    @Builder.Default
    private Boolean enabled = true;
    
    /**
     * 该模型被授权可用于哪些AI功能
     */
    @Builder.Default
    private List<AIFeatureType> enabledForFeatures = new ArrayList<>();
    
    /**
     * 积分汇率乘数，默认为 1.0
     * 用于对特定模型进行积分成本的微调
     * 例如：设置为 0.5 表示该模型的积分消耗减半
     *      设置为 2.0 表示该模型的积分消耗翻倍
     */
    @Builder.Default
    private Double creditRateMultiplier = 1.0;
    
    /**
     * 最大并发请求数限制（-1表示无限制）
     */
    @Builder.Default
    private Integer maxConcurrentRequests = -1;
    
    /**
     * 每日请求次数限制（-1表示无限制）
     */
    @Builder.Default
    private Integer dailyRequestLimit = -1;
    
    /**
     * 每小时请求次数限制（-1表示无限制）
     */
    @Builder.Default
    private Integer hourlyRequestLimit = -1;
    
    /**
     * 模型优先级（数值越高，优先级越高）
     */
    @Builder.Default
    private Integer priority = 0;
    
    /**
     * 配置描述
     */
    private String description;
    
    /**
     * 配置标签（用于分类和筛选）
     */
    @Builder.Default
    private List<String> tags = new ArrayList<>();
    
    /**
     * API Key 池，取代单一的 apiKey 字段
     */
    @Builder.Default
    private List<ApiKeyEntry> apiKeys = new ArrayList<>();

    /**
     * 可选的 API Endpoint/Base URL
     * 注意：如果池中所有Key共享一个Endpoint，则使用此字段
     */
    private String apiEndpoint;

    /**
     * 整体配置是否可用 (当池中至少有一个Key验证通过时，此值为true)
     */
    @Builder.Default
    private Boolean isValidated = false;
    
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
     * 检查模型是否可用于指定功能
     * 
     * @param featureType AI功能类型
     * @return 是否可用
     */
    public boolean isEnabledForFeature(AIFeatureType featureType) {
        return enabled && 
               enabledForFeatures != null && 
               enabledForFeatures.contains(featureType);
    }
    
    /**
     * 添加支持的功能类型
     * 
     * @param featureType AI功能类型
     */
    public void addEnabledFeature(AIFeatureType featureType) {
        if (enabledForFeatures == null) {
            enabledForFeatures = new ArrayList<>();
        }
        if (!enabledForFeatures.contains(featureType)) {
            enabledForFeatures.add(featureType);
        }
    }
    
    /**
     * 移除支持的功能类型
     * 
     * @param featureType AI功能类型
     */
    public void removeEnabledFeature(AIFeatureType featureType) {
        if (enabledForFeatures != null) {
            enabledForFeatures.remove(featureType);
        }
    }
    
    /**
     * 添加标签
     * 
     * @param tag 标签
     */
    public void addTag(String tag) {
        if (tags == null) {
            tags = new ArrayList<>();
        }
        if (!tags.contains(tag)) {
            tags.add(tag);
        }
    }
    
    /**
     * 移除标签
     * 
     * @param tag 标签
     */
    public void removeTag(String tag) {
        if (tags != null) {
            tags.remove(tag);
        }
    }
    
    /**
     * 检查是否有指定标签
     * 
     * @param tag 标签
     * @return 是否存在该标签
     */
    public boolean hasTag(String tag) {
        return tags != null && tags.contains(tag);
    }
    
    /**
     * 获取模型的唯一键
     * 
     * @return 模型唯一键
     */
    public String getModelKey() {
        return provider + ":" + modelId;
    }
    
    /**
     * 添加API Key到池中
     * 
     * @param apiKey API Key
     * @param note 备注
     */
    public void addApiKey(String apiKey, String note) {
        if (apiKeys == null) {
            apiKeys = new ArrayList<>();
        }
        apiKeys.add(ApiKeyEntry.builder()
                .apiKey(apiKey)
                .note(note)
                .isValid(false)
                .build());
    }
    
    /**
     * 移除API Key
     * 
     * @param apiKey API Key
     */
    public void removeApiKey(String apiKey) {
        if (apiKeys != null) {
            apiKeys.removeIf(entry -> entry.getApiKey().equals(apiKey));
        }
    }
    
    /**
     * 获取所有有效的API Key
     * 
     * @return 有效的API Key列表
     */
    public List<ApiKeyEntry> getValidApiKeys() {
        if (apiKeys == null) {
            return new ArrayList<>();
        }
        return apiKeys.stream()
                .filter(entry -> Boolean.TRUE.equals(entry.getIsValid()))
                .collect(Collectors.toList());
    }
    
    /**
     * 随机获取一个有效的API Key
     * 
     * @return 随机的有效API Key，如果没有则返回null
     */
    public ApiKeyEntry getRandomValidApiKey() {
        List<ApiKeyEntry> validKeys = getValidApiKeys();
        if (validKeys.isEmpty()) {
            return null;
        }
        return validKeys.get(new Random().nextInt(validKeys.size()));
    }
    
    /**
     * 获取API Key池状态摘要
     * 
     * @return 格式为 "有效数量/总数量"
     */
    public String getApiKeyPoolStatus() {
        int totalCount = apiKeys != null ? apiKeys.size() : 0;
        int validCount = getValidApiKeys().size();
        return validCount + "/" + totalCount;
    }
    
    /**
     * 更新整体验证状态
     * 根据池中是否有有效的Key来设置isValidated字段
     */
    public void updateValidationStatus() {
        this.isValidated = !getValidApiKeys().isEmpty();
    }
    
    /**
     * 内嵌文档，用于管理池中的每一个 API Key
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApiKeyEntry {
        /**
         * 用于调用该模型的 API Key (将进行加密存储)
         */
        private String apiKey;

        /**
         * 此 Key 是否已验证通过
         */
        @Builder.Default
        private Boolean isValid = false;

        /**
         * 验证失败时的错误信息
         */
        private String validationError;

        /**
         * 最近一次验证的时间
         */
        private LocalDateTime lastValidatedAt;

        /**
         * 备注，方便管理员识别 (例如："Key-A-备用", "Key-B-主力")
         */
        private String note;
    }
}