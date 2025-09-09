package com.ainovel.server.domain.model.settinggeneration;

import com.ainovel.server.domain.model.SettingType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 节点模板配置
 * 定义设定生成过程中各类节点的模板和约束
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NodeTemplateConfig {
    
    /**
     * 模板ID
     */
    private String id;
    
    /**
     * 节点名称
     */
    private String name;
    
    /**
     * 节点类型
     */
    private SettingType type;
    
    /**
     * 节点描述
     */
    private String description;
    
    /**
     * 最小子节点数量
     */
    @Builder.Default
    private Integer minChildren = 0;
    
    /**
     * 最大子节点数量
     */
    @Builder.Default
    private Integer maxChildren = -1; // -1表示无限制
    
    /**
     * 节点属性约束
     */
    @Builder.Default
    private Map<String, Object> attributes = new HashMap<>();
    
    /**
     * 最小描述长度
     */
    @Builder.Default
    private Integer minDescriptionLength = 50;
    
    /**
     * 最大描述长度
     */
    @Builder.Default
    private Integer maxDescriptionLength = 500;
    
    /**
     * 是否为根节点模板
     */
    @Builder.Default
    private Boolean isRootTemplate = false;
    
    /**
     * 节点生成优先级
     */
    @Builder.Default
    private Integer priority = 0;
    
    /**
     * 节点标签
     */
    @Builder.Default
    private List<String> tags = new ArrayList<>();
    
    /**
     * 节点生成提示
     */
    private String generationHint;
    
    /**
     * 允许的父节点类型
     */
    @Builder.Default
    private List<SettingType> allowedParentTypes = new ArrayList<>();
    
    /**
     * 推荐的子节点类型
     */
    @Builder.Default
    private List<SettingType> recommendedChildTypes = new ArrayList<>();
}