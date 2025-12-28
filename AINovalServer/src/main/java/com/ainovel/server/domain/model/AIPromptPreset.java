package com.ainovel.server.domain.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * AI提示词预设实体
 * 用于存储用户创建的AI配置预设
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "ai_prompt_presets")
@CompoundIndexes({
    @CompoundIndex(name = "user_feature_idx", def = "{'userId': 1, 'aiFeatureType': 1}"),
    @CompoundIndex(name = "user_name_idx", def = "{'userId': 1, 'presetName': 1}"),
    @CompoundIndex(name = "system_feature_idx", def = "{'isSystem': 1, 'aiFeatureType': 1}"),
    @CompoundIndex(name = "quick_access_idx", def = "{'showInQuickAccess': 1, 'aiFeatureType': 1}"),
    @CompoundIndex(name = "user_quick_access_idx", def = "{'userId': 1, 'showInQuickAccess': 1, 'aiFeatureType': 1}")
})
public class AIPromptPreset {

    @Id
    private String id;

    @Field("preset_id")
    @Indexed(unique = true)
    private String presetId; // UUID，唯一业务ID

    @Field("user_id")
    @Indexed
    private String userId; // 用户ID

    @Field("novel_id")
    @Indexed
    private String novelId; // 小说ID（可选，为null表示全局预设）

    // 🚀 新增：用户定义的预设信息
    @Field("preset_name")
    private String presetName; // 用户自定义预设名称
    
    @Field("preset_description")
    private String presetDescription; // 预设描述
    
    @Field("preset_tags")
    private List<String> presetTags; // 标签列表，便于分类管理
    
    @Field("is_favorite")
    @Builder.Default
    private Boolean isFavorite = false; // 是否收藏
    
    @Field("is_public")
    @Builder.Default
    private Boolean isPublic = false; // 是否公开（未来可分享给其他用户）
    
    @Field("use_count")
    @Builder.Default
    private Integer useCount = 0; // 使用次数统计

    @Field("preset_hash")
    private String presetHash; // 配置内容的哈希值 (SHA-256)

    @Field("request_data")
    private String requestData; // 存储完整的 UniversalAIRequestDto JSON

    /**
     * 【快照字段】根据配置和模板生成的系统提示词最终版本。
     * 此字段存储的是填充了动态数据（如上下文、选中文本等）后的提示词快照，主要用于预览和历史追溯。
     * 在实际AI请求中，应优先通过模板ID重新生成以确保上下文的实时性。
     */
    @Field("system_prompt")
    private String systemPrompt;

    /**
     * 【快照字段】根据配置和模板生成的用户提示词最终版本。
     * 此字段存储的是填充了动态数据（如上下文、选中文本等）后的提示词快照，主要用于预览和历史追溯。
     * 在实际AI请求中，应优先通过模板ID重新生成以确保上下文的实时性。
     */
    @Field("user_prompt")
    private String userPrompt;

    @Field("ai_feature_type")
    private String aiFeatureType; // 功能类型 (e.g., 'CHAT')

    // 🚀 新增：提示词自定义配置
    @Field("custom_system_prompt")
    private String customSystemPrompt; // 用户自定义的系统提示词
    
    @Field("custom_user_prompt")
    private String customUserPrompt; // 用户自定义的用户提示词
    
    @Field("prompt_customized")
    @Builder.Default
    private Boolean promptCustomized = false; // 是否自定义了提示词

    // 🚀 新增：模板关联字段
    @Field("template_id")
    private String templateId; // 关联的EnhancedUserPromptTemplate模板ID

    // 🚀 新增：系统预设和快捷访问字段
    @Field("is_system")
    @Builder.Default
    private Boolean isSystem = false; // 是否为系统预设

    @Field("show_in_quick_access")
    @Builder.Default
    private Boolean showInQuickAccess = false; // 是否在快捷访问列表中显示

    @Field("created_at")
    private LocalDateTime createdAt; // 创建时间

    @Field("updated_at")
    private LocalDateTime updatedAt; // 更新时间
    
    @Field("last_used_at")
    private LocalDateTime lastUsedAt; // 最后使用时间
    
    /**
     * 获取生效的系统提示词
     */
    public String getEffectiveSystemPrompt() {
        return (promptCustomized && customSystemPrompt != null && !customSystemPrompt.isEmpty()) 
               ? customSystemPrompt : systemPrompt;
    }
    
    /**
     * 获取生效的用户提示词
     */
    public String getEffectiveUserPrompt() {
        return (promptCustomized && customUserPrompt != null && !customUserPrompt.isEmpty()) 
               ? customUserPrompt : userPrompt;
    }
    
    /**
     * 增加使用次数
     */
    public void incrementUseCount() {
        this.useCount = (this.useCount == null ? 0 : this.useCount) + 1;
        this.lastUsedAt = LocalDateTime.now();
    }
} 