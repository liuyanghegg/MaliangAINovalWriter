package com.ainovel.server.web.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 导入步骤DTO
 * 用于详细跟踪导入的各个步骤
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ImportStep {

    /**
     * 步骤名称
     */
    private String stepName;

    /**
     * 步骤状态：PENDING, RUNNING, COMPLETED, FAILED, SKIPPED
     */
    private String status;

    /**
     * 步骤描述
     */
    private String description;

    /**
     * 开始时间
     */
    private LocalDateTime startTime;

    /**
     * 完成时间
     */
    private LocalDateTime endTime;

    /**
     * 步骤进度百分比（0-100）
     */
    private Integer progress;

    /**
     * 详细信息或错误消息
     */
    private String details;

    /**
     * 是否为关键步骤（关键步骤失败会导致整个导入失败）
     */
    private Boolean critical = true;

    /**
     * 估算时间（秒）
     */
    private Integer estimatedDurationSeconds;

    /**
     * 实际耗时（秒）
     */
    private Integer actualDurationSeconds;
} 