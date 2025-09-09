package com.ainovel.server.web.dto.request;

import java.util.Map;
import java.util.List;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

/**
 * 通用AI请求DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UniversalAIRequestDto {

    /**
     * 请求类型：chat, expansion, summary, refactor, generation
     */
    @NotBlank(message = "请求类型不能为空")
    private String requestType;

    /**
     * 用户ID
     */
    @NotBlank(message = "用户ID不能为空")
    private String userId;

    /**
     * 会话ID（聊天类型时必需）
     */
    private String sessionId;

    /**
     * 小说ID
     */
    private String novelId;

    /**
     * 场景ID
     */
    private String sceneId;

    /**
     * 章节ID
     */
    private String chapterId;

    /**
     * 模型配置ID
     */
    private String modelConfigId;

    /**
     * 用户输入的提示内容
     */
    private String prompt;

    /**
     * 操作指令（用于扩写、总结、重构等）
     */
    private String instructions;

    /**
     * 选中的文本（扩写、总结、重构时使用）
     */
    private String selectedText;

    /**
     * 上下文选择数据
     */
    private List<ContextSelectionDto> contextSelections;

    /**
     * 请求参数（温度、最大token等）
     */
    private Map<String, Object> parameters;

    /**
     * 元数据（其他附加信息）
     */
    private Map<String, Object> metadata;

    /**
     * 设定生成会话ID（方案A：后端用来拉取会话并落库为NovelSettingItem）
     */
    private String settingSessionId;

    /**
     * 上下文选择DTO
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ContextSelectionDto {
        private String id;
        private String title;
        private String type;
        private Map<String, Object> metadata;
    }
} 