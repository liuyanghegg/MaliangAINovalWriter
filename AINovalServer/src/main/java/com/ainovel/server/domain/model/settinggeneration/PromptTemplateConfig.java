package com.ainovel.server.domain.model.settinggeneration;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * 提示词模板配置
 * 简化的提示词配置，专注于核心模板内容
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PromptTemplateConfig {
    
    /**
     * 工具使用说明模板
     */
    private String toolUsageInstructions;
    
    /**
     * 修改节点时的提示词模板
     */
    private String modificationPromptTemplate;
    
    /**
     * 工具调用示例
     */
    private String toolCallExamples;
    
    /**
     * 支持的占位符列表
     */
    @Builder.Default
    private List<String> supportedPlaceholders = new ArrayList<>();
}