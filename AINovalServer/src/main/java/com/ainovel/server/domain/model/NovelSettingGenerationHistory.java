package com.ainovel.server.domain.model;

import com.ainovel.server.domain.model.setting.generation.SettingGenerationSession;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 设定生成历史记录
 * 记录用户每次生成设定的完整过程和结果
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "novel_setting_generation_histories")
@CompoundIndexes({
    @CompoundIndex(name = "novel_user_idx", def = "{'novelId': 1, 'userId': 1}"),
    @CompoundIndex(name = "novel_created_idx", def = "{'novelId': 1, 'createdAt': -1}"),
    @CompoundIndex(name = "session_idx", def = "{'originalSessionId': 1}")
})
public class NovelSettingGenerationHistory {
    
    @Id
    private String historyId;
    
    // ==================== 基础信息 ====================
    
    @Indexed
    private String userId;
    
    @Indexed
    private String novelId;
    
    /**
     * 历史记录标题（自动生成或用户定义）
     */
    private String title;
    
    /**
     * 历史记录描述
     */
    private String description;
    
    // ==================== 生成参数 ====================
    
    /**
     * 初始提示词
     */
    private String initialPrompt;
    
    /**
     * 生成策略
     */
    private String strategy;
    
    /**
     * 提示词模板ID（新架构）
     */
    private String promptTemplateId;
    
    /**
     * 使用的模型配置ID
     */
    private String modelConfigId;
    
    // ==================== 会话信息 ====================
    
    /**
     * 原始会话ID（用于追踪）
     */
    private String originalSessionId;
    
    /**
     * 最终会话状态
     */
    private SettingGenerationSession.SessionStatus status;
    
    // ==================== 生成结果 ====================
    
    /**
     * 生成的设定条目ID列表（引用实际的NovelSettingItem）
     */
    private List<String> generatedSettingIds;
    
    /**
     * 根节点ID列表
     */
    private List<String> rootSettingIds;
    
    /**
     * 树形结构信息（父子关系映射，用于快速重建树结构）
     */
    private Map<String, List<String>> parentChildMap;
    
    // ==================== 统计信息 ====================
    
    /**
     * 生成的设定数量
     */
    private Integer settingsCount;
    
    /**
     * 生成结果状态
     */
    private String generationResult; // SUCCESS, PARTIAL_SUCCESS, FAILED
    
    /**
     * 错误信息（如果失败）
     */
    private String errorMessage;
    
    /**
     * 生成耗时
     */
    private Duration generationDuration;
    
    // ==================== 历史链信息 ====================
    
    /**
     * 源历史记录ID（如果是复制/基于其他历史记录创建的）
     */
    private String sourceHistoryId;
    
    /**
     * 复制原因/说明
     */
    private String copyReason;
    
    // ==================== 时间信息 ====================
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // ==================== 元数据 ====================
    
    /**
     * 额外元数据
     */
    private Map<String, Object> metadata;
} 