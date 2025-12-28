package com.ainovel.server.web.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 小说导入状态DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ImportStatus {

    /**
     * 状态码：PROCESSING, SAVING, INDEXING, COMPLETED, FAILED, ERROR, CANCELLED
     */
    private String status;

    /**
     * 状态详细信息
     */
    private String message;

    /**
     * 进度百分比（可选）
     */
    private Double progress;

    /**
     * 当前步骤名称
     */
    private String currentStep;

    /**
     * 详细步骤列表
     */
    private List<ImportStep> steps;

    /**
     * 估算剩余时间（秒）
     */
    private Integer estimatedRemainingSeconds;

    /**
     * 处理的章节数量
     */
    private Integer processedChapters;

    /**
     * 总章节数量
     */
    private Integer totalChapters;

    /**
     * 已生成摘要的章节数量
     */
    private Integer summarizedChapters;

    /**
     * 错误列表
     */
    private List<String> errors;

    /**
     * 警告列表
     */
    private List<String> warnings;

    // 保持向后兼容的构造函数
    public ImportStatus(String status, String message) {
        this.status = status;
        this.message = message;
        this.progress = null;
    }

    public ImportStatus(String status, String message, Double progress) {
        this.status = status;
        this.message = message;
        this.progress = progress;
    }
}
