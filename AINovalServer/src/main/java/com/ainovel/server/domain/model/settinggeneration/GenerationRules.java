package com.ainovel.server.domain.model.settinggeneration;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 生成规则配置
 * 简化的生成规则，专注于核心约束
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GenerationRules {
    
    /**
     * 批量创建节点的首选数量
     */
    @Builder.Default
    private Integer preferredBatchSize = 20;
    
    /**
     * 最大批量创建数量
     */
    @Builder.Default
    private Integer maxBatchSize = 200;
    
    /**
     * 最小描述长度（字符数）
     */
    @Builder.Default
    private Integer minDescriptionLength = 50;
    
    /**
     * 最大描述长度（字符数）
     */
    @Builder.Default
    private Integer maxDescriptionLength = 500;
    
    /**
     * 是否要求节点间相互关联
     */
    @Builder.Default
    private Boolean requireInterConnections = true;
    
    /**
     * 是否允许动态调整结构
     */
    @Builder.Default
    private Boolean allowDynamicStructure = true;
}