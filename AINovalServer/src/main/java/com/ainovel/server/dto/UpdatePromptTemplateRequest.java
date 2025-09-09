package com.ainovel.server.dto;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 更新用户提示词模板请求DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdatePromptTemplateRequest {

    /**
     * 模板名称
     */
    private String name;

    /**
     * 模板描述
     */
    private String description;

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