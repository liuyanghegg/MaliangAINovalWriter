package com.ainovel.server.web.dto.response;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

/**
 * 通用AI预览响应DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UniversalAIPreviewResponseDto {

    /**
     * 预览内容（完整的提示词）
     */
    private String preview;

    /**
     * 系统提示词
     */
    private String systemPrompt;

    /**
     * 用户提示词
     */
    private String userPrompt;

    /**
     * 上下文信息
     */
    private String context;

    /**
     * 估计的Token数量
     */
    private Integer estimatedTokens;

    /**
     * 将要使用的模型名称
     */
    private String modelName;

    /**
     * 将要使用的模型提供商
     */
    private String modelProvider;

    /**
     * 模型配置ID
     */
    private String modelConfigId;
} 