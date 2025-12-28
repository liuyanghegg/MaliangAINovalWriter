package com.ainovel.server.domain.model;

import java.time.LocalDateTime;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 用户订阅信息实体类
 * 用于跟踪用户的订阅状态和历史
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "user_subscriptions")
public class UserSubscription {
    
    @Id
    private String id;
    
    /**
     * 用户ID
     */
    @Indexed
    private String userId;
    
    /**
     * 订阅计划ID
     */
    private String planId;
    
    /**
     * 订阅开始时间
     */
    private LocalDateTime startDate;
    
    /**
     * 订阅结束时间
     */
    private LocalDateTime endDate;
    
    /**
     * 订阅状态
     */
    private SubscriptionStatus status;
    
    /**
     * 是否自动续费
     */
    @Builder.Default
    private Boolean autoRenewal = false;
    
    /**
     * 支付方式
     */
    private String paymentMethod;
    
    /**
     * 支付交易ID
     */
    private String transactionId;
    
    /**
     * 已使用的积分数
     */
    @Builder.Default
    private Long creditsUsed = 0L;
    
    /**
     * 总可用积分数
     */
    @Builder.Default
    private Long totalCredits = 0L;
    
    /**
     * 取消时间
     */
    private LocalDateTime canceledAt;
    
    /**
     * 取消原因
     */
    private String cancelReason;
    
    /**
     * 试用期结束时间
     */
    private LocalDateTime trialEndDate;
    
    /**
     * 是否在试用期
     */
    @Builder.Default
    private Boolean isTrial = false;
    
    /**
     * 创建时间
     */
    private LocalDateTime createdAt;
    
    /**
     * 更新时间
     */
    private LocalDateTime updatedAt;
    
    /**
     * 订阅状态枚举
     */
    public enum SubscriptionStatus {
        /**
         * 活跃状态
         */
        ACTIVE,
        
        /**
         * 试用期
         */
        TRIAL,
        
        /**
         * 已取消（但未到期）
         */
        CANCELED,
        
        /**
         * 已过期
         */
        EXPIRED,
        
        /**
         * 暂停
         */
        SUSPENDED,
        
        /**
         * 退款
         */
        REFUNDED
    }
    
    /**
     * 检查订阅是否有效
     * 
     * @return 是否有效
     */
    public boolean isValid() {
        LocalDateTime now = LocalDateTime.now();
        return (status == SubscriptionStatus.ACTIVE || 
                status == SubscriptionStatus.TRIAL) && 
               (endDate == null || endDate.isAfter(now));
    }
    
    /**
     * 检查是否在试用期
     * 
     * @return 是否在试用期
     */
    public boolean isInTrial() {
        LocalDateTime now = LocalDateTime.now();
        return isTrial && 
               status == SubscriptionStatus.TRIAL && 
               (trialEndDate == null || trialEndDate.isAfter(now));
    }
    
    /**
     * 获取剩余积分
     * 
     * @return 剩余积分
     */
    public long getRemainingCredits() {
        return Math.max(0, totalCredits - creditsUsed);
    }
    
    /**
     * 检查积分是否充足
     * 
     * @param requiredCredits 需要的积分数
     * @return 是否充足
     */
    public boolean hasEnoughCredits(long requiredCredits) {
        return getRemainingCredits() >= requiredCredits;
    }
    
    /**
     * 使用积分
     * 
     * @param credits 使用的积分数
     * @return 是否成功
     */
    public boolean useCredits(long credits) {
        if (!hasEnoughCredits(credits)) {
            return false;
        }
        creditsUsed += credits;
        return true;
    }
    
    /**
     * 检查订阅是否即将过期（7天内）
     * 
     * @return 是否即将过期
     */
    public boolean isExpiringSoon() {
        if (endDate == null) {
            return false;
        }
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime sevenDaysLater = now.plusDays(7);
        return endDate.isBefore(sevenDaysLater) && endDate.isAfter(now);
    }
}