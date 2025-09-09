package com.ainovel.server.domain.model.setting.generation;

import com.ainovel.server.domain.model.SettingType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

/**
 * 设定节点
 * 表示生成过程中的单个设定项
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SettingNode {
    /**
     * 节点ID（临时ID，保存时会重新生成）
     */
    private String id;
    
    /**
     * 父节点ID
     */
    private String parentId;
    
    /**
     * 设定名称
     */
    private String name;
    
    /**
     * 设定类型
     */
    private SettingType type;
    
    /**
     * 设定描述
     */
    private String description;
    
    /**
     * 自定义属性
     */
    @Builder.Default
    private Map<String, Object> attributes = new HashMap<>();
    
    /**
     * 生成策略特定的元数据
     */
    @Builder.Default
    private Map<String, Object> strategyMetadata = new HashMap<>();
    
    /**
     * 生成状态
     */
    private GenerationStatus generationStatus;
    
    /**
     * 错误信息（如果生成失败）
     */
    private String errorMessage;
    
    /**
     * 生成时使用的提示词（用于追踪）
     */
    private String generationPrompt;
    
    /**
     * 子节点列表，用于构建树形结构
     */
    @Builder.Default
    private List<SettingNode> children = new ArrayList<>();
    
    /**
     * 生成状态枚举
     */
    public enum GenerationStatus {
        /**
         * 待生成
         */
        PENDING,
        /**
         * 生成中
         */
        GENERATING,
        /**
         * 已完成
         */
        COMPLETED,
        /**
         * 生成失败
         */
        FAILED,
        /**
         * 已修改
         */
        MODIFIED
    }
}