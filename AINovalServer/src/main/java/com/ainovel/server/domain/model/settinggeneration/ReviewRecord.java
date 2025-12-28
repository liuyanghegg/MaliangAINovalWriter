package com.ainovel.server.domain.model.settinggeneration;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 审核记录
 * 记录单次审核的详细信息
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReviewRecord {
    
    /**
     * 审核员ID
     */
    private String reviewerId;
    
    /**
     * 审核员姓名
     */
    private String reviewerName;
    
    /**
     * 审核时间
     */
    private LocalDateTime reviewTime;
    
    /**
     * 审核动作
     */
    private ReviewAction action;
    
    /**
     * 审核意见
     */
    private String comment;
    
    /**
     * 审核分数（1-5分）
     */
    private Integer score;
    
    /**
     * 版本号
     */
    private String version;
    
    /**
     * 审核动作枚举
     */
    public enum ReviewAction {
        SUBMITTED,          // 提交审核
        APPROVED,           // 通过
        REJECTED,           // 拒绝
        REVISION_REQUIRED,  // 要求修订
        WITHDRAWN,          // 撤回
        RESUBMITTED        // 重新提交
    }
}