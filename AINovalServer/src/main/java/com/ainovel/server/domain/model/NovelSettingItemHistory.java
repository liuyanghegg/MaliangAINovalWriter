package com.ainovel.server.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

/**
 * 设定节点历史记录
 * 记录单个设定节点的变更历史
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "novel_setting_item_histories")
@CompoundIndexes({
    @CompoundIndex(name = "setting_version_idx", def = "{'settingItemId': 1, 'version': 1}"),
    @CompoundIndex(name = "history_time_idx", def = "{'historyId': 1, 'createdAt': -1}"),
    @CompoundIndex(name = "setting_history_idx", def = "{'settingItemId': 1, 'historyId': 1}")
})
public class NovelSettingItemHistory {
    
    @Id
    private String id;
    
    // ==================== 关联信息 ====================
    
    /**
     * 关联的设定条目ID
     */
    @Indexed
    private String settingItemId;
    
    /**
     * 所属的历史记录ID
     */
    @Indexed
    private String historyId;
    
    /**
     * 用户ID
     */
    @Indexed
    private String userId;
    
    // ==================== 操作信息 ====================
    
    /**
     * 操作类型
     */
    private String operationType; // CREATE, UPDATE, DELETE, MODIFY, RESTORE
    
    /**
     * 版本号（在该设定条目的变更序列中）
     */
    private Integer version;
    
    // ==================== 变更内容 ====================
    
    /**
     * 变更前的内容
     */
    private NovelSettingItem beforeContent;
    
    /**
     * 变更后的内容
     */
    private NovelSettingItem afterContent;
    
    /**
     * 变更描述
     */
    private String changeDescription;
    
    // ==================== 操作上下文 ====================
    
    /**
     * 修改提示词（如果是AI修改）
     */
    private String modificationPrompt;
    
    /**
     * 父节点路径（用于显示上下文）
     */
    private String parentPath;
    
    /**
     * 操作来源
     */
    private String operationSource; // AI_GENERATION, USER_EDIT, HISTORY_RESTORE
    
    // ==================== 时间信息 ====================
    
    private LocalDateTime createdAt;
} 