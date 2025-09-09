package com.ainovel.server.dto;

import java.util.List;

import com.ainovel.server.domain.model.AIFeatureType;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 创建用户提示词模板请求DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreatePromptTemplateRequest {

    /**
     * 模板名称
     */
    @NotBlank(message = "模板名称不能为空")
    private String name;

    /**
     * 模板描述
     */
    private String description;

    /**
     * 功能类型
     */
    @NotNull(message = "功能类型不能为空")
    private AIFeatureType featureType;

    /**
     * 系统提示词
     */
    private String systemPrompt;

    /**
     * 用户提示词
     */
    private String userPrompt;

    /**
     * 标签列表
     */
    private List<String> tags;

    /**
     * 分类列表
     */
    private List<String> categories;
} 