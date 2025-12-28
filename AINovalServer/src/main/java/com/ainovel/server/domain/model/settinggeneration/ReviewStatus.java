package com.ainovel.server.domain.model.settinggeneration;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 审核状态
 * 管理策略分享的审核流程
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReviewStatus {
    
    /**
     * 审核状态
     */
    @Builder.Default
    private Status status = Status.DRAFT;
    
    /**
     * 审核员ID
     */
    private String reviewerId;
    
    /**
     * 审核意见
     */
    private String reviewComment;
    
    /**
     * 审核时间
     */
    private LocalDateTime reviewedAt;
    
    /**
     * 提交审核时间
     */
    private LocalDateTime submittedAt;
    
    /**
     * 审核历史记录
     */
    @Builder.Default
    private List<ReviewRecord> reviewHistory = new ArrayList<>();
    
    /**
     * 拒绝原因列表
     */
    @Builder.Default
    private List<String> rejectionReasons = new ArrayList<>();
    
    /**
     * 改进建议列表
     */
    @Builder.Default
    private List<String> improvementSuggestions = new ArrayList<>();
    
    /**
     * 审核优先级
     */
    @Builder.Default
    private Priority priority = Priority.NORMAL;
    
    /**
     * 审核状态枚举
     */
    public enum Status {
        DRAFT,          // 草稿
        PENDING,        // 待审核
        APPROVED,       // 已通过
        REJECTED,       // 已拒绝
        REVISION_REQUIRED, // 需要修订
        WITHDRAWN       // 已撤回
    }
    
    /**
     * 审核优先级枚举
     */
    public enum Priority {
        LOW,            // 低优先级
        NORMAL,         // 普通优先级
        HIGH,           // 高优先级
        URGENT          // 紧急
    }
}