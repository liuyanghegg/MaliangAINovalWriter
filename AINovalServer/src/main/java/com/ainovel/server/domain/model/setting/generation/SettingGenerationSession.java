package com.ainovel.server.domain.model.setting.generation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.*;

/**
 * 设定生成会话
 * 管理整个设定生成过程的状态和数据
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SettingGenerationSession {
    /**
     * 会话ID
     */
    private String sessionId;
    
    /**
     * 用户ID
     */
    private String userId;
    
    /**
     * 小说ID（如果是为现有小说生成设定）
     */
    private String novelId;
    
    /**
     * 初始提示词
     */
    private String initialPrompt;
    
    /**
     * 生成策略（基础策略ID）
     */
    private String strategy;
    
    /**
     * 提示词模板ID（用户选择的模板）
     */
    private String promptTemplateId;
    
    /**
     * 会话状态
     */
    private SessionStatus status;
    
    /**
     * 是否基于现有历史记录创建
     */
    @Builder.Default
    private boolean fromExistingHistory = false;
    
    /**
     * 源历史记录ID（如果是从历史记录创建的话）
     */
    private String sourceHistoryId;
    
    /**
     * 生成的设定节点（临时存储）
     */
    @Builder.Default
    private Map<String, SettingNode> generatedNodes = new HashMap<>();
    
    /**
     * 根节点ID列表
     */
    @Builder.Default
    private List<String> rootNodeIds = new ArrayList<>();
    
    /**
     * 会话元数据
     */
    @Builder.Default
    private Map<String, Object> metadata = new HashMap<>();
    
    /**
     * 创建时间
     */
    private LocalDateTime createdAt;
    
    /**
     * 最后更新时间
     */
    private LocalDateTime updatedAt;
    
    /**
     * 过期时间
     */
    private LocalDateTime expiresAt;
    
    /**
     * 错误信息（如果有）
     */
    private String errorMessage;
    
    /**
     * 会话状态枚举
     */
    public enum SessionStatus {
        /**
         * 初始化
         */
        INITIALIZING,
        /**
         * 生成中
         */
        GENERATING,
        /**
         * 已完成
         */
        COMPLETED,
        /**
         * 错误
         */
        ERROR,
        /**
         * 已取消
         */
        CANCELLED,
        /**
         * 已保存
         */
        SAVED
    }
    
    /**
     * 添加生成的节点
     */
    public void addNode(SettingNode node) {
        generatedNodes.put(node.getId(), node);
        if (node.getParentId() == null) {
            rootNodeIds.add(node.getId());
        }
    }
    
    /**
     * 获取节点的所有子节点ID
     */
    public List<String> getChildrenIds(String nodeId) {
        List<String> childrenIds = new ArrayList<>();
        for (SettingNode node : generatedNodes.values()) {
            if (nodeId.equals(node.getParentId())) {
                childrenIds.add(node.getId());
            }
        }
        return childrenIds;
    }
    
    /**
     * 删除节点及其所有子孙节点
     */
    public void removeNodeAndDescendants(String nodeId) {
        Set<String> toRemove = new HashSet<>();
        collectDescendants(nodeId, toRemove);
        toRemove.add(nodeId);
        
        toRemove.forEach(id -> {
            generatedNodes.remove(id);
            rootNodeIds.remove(id);
        });
    }

    /**
     * 检查是否基于现有历史记录创建
     */
    public boolean isFromExistingHistory() {
        return fromExistingHistory;
    }

    /**
     * 设置为基于现有历史记录创建
     */
    public void setFromExistingHistory(boolean fromExistingHistory) {
        this.fromExistingHistory = fromExistingHistory;
    }

    /**
     * 设置源历史记录ID
     */
    public void setSourceHistoryId(String historyId) {
        this.sourceHistoryId = historyId;
        if (historyId != null) {
            this.fromExistingHistory = true;
        }
    }
    
    private void collectDescendants(String nodeId, Set<String> descendants) {
        List<String> children = getChildrenIds(nodeId);
        for (String childId : children) {
            descendants.add(childId);
            collectDescendants(childId, descendants);
        }
    }
}