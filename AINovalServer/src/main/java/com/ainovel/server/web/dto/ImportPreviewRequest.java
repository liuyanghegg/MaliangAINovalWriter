package com.ainovel.server.web.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 导入预览请求DTO
 * 用于接收前端的导入配置和预览请求
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ImportPreviewRequest {

    /**
     * 临时文件ID或上传会话ID
     */
    private String fileSessionId;

    /**
     * 自定义的小说标题（可选，如果不提供则使用文件名）
     */
    private String customTitle;

    /**
     * 导入章节数量限制（默认为-1表示全部导入）
     */
    private Integer chapterLimit = -1;

    /**
     * 是否启用智能上下文（RAG索引）
     */
    private Boolean enableSmartContext = true;

    /**
     * 是否启用AI自动生成摘要
     */
    private Boolean enableAISummary = false;

    /**
     * AI模型配置ID（如果启用AI功能）
     */
    private String aiConfigId;

    /**
     * 用户ID
     */
    private String userId;

    /**
     * 预览章节数量（默认返回前10章）
     */
    private Integer previewChapterCount = 10;
} 