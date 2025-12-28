package com.ainovel.server.web.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 导入预览响应DTO  
 * 包含解析后的章节预览和导入估算信息
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ImportPreviewResponse {

    /**
     * 预览会话ID，用于后续的确认导入
     */
    private String previewSessionId;

    /**
     * 解析出的小说标题
     */
    private String detectedTitle;

    /**
     * 总章节数量
     */
    private Integer totalChapterCount;

    /**
     * 章节预览列表
     */
    private List<ChapterPreview> chapterPreviews;

    /**
     * 总估算字数
     */
    private Integer totalWordCount;

    /**
     * AI功能相关估算
     */
    private AIEstimation aiEstimation;

    /**
     * 警告信息列表
     */
    private List<String> warnings;

    /**
     * AI功能估算信息
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class AIEstimation {
        
        /**
         * 是否支持AI功能
         */
        private Boolean supported;

        /**
         * 估算的Token数量
         */
        private Long estimatedTokens;

        /**
         * 估算的成本（美元）
         */
        private Double estimatedCost;

        /**
         * 估算的处理时间（分钟）
         */
        private Integer estimatedTimeMinutes;

        /**
         * 使用的AI模型信息
         */
        private String selectedModel;

        /**
         * 限制或警告信息
         */
        private String limitations;
    }
} 