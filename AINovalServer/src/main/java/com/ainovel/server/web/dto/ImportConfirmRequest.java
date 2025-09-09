package com.ainovel.server.web.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 导入确认请求DTO
 * 用于用户确认导入配置后开始正式导入
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ImportConfirmRequest {

    /**
     * 预览会话ID
     */
    private String previewSessionId;

    /**
     * 最终确认的小说标题
     */
    private String finalTitle;

    /**
     * 选中要导入的章节索引列表
     */
    private List<Integer> selectedChapterIndexes;

    /**
     * 是否启用智能上下文（RAG索引）
     */
    private Boolean enableSmartContext;

    /**
     * 是否启用AI自动生成摘要
     */
    private Boolean enableAISummary;

    /**
     * AI模型配置ID
     */
    private String aiConfigId;

    /**
     * 用户ID
     */
    private String userId;

    /**
     * 用户确认的风险和成本
     */
    private Boolean acknowledgeRisks = false;
} 