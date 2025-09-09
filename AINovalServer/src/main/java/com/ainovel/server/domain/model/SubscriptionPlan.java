package com.ainovel.server.domain.model;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 订阅计划实体类
 * 用于定义商业化套餐和定价策略
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "subscription_plans")
public class SubscriptionPlan {
    
    @Id
    private String id;
    
    /**
     * 套餐名称
     */
    private String planName;
    
    /**
     * 套餐描述
     */
    private String description;
    
    /**
     * 价格
     */
    private BigDecimal price;
    
    /**
     * 货币单位
     */
    private String currency;
    
    /**
     * 计费周期
     */
    private BillingCycle billingCycle;
    
    /**
     * 购买该套餐后用户获得的角色ID
     */
    private String roleId;
    
    /**
     * 每个计费周期授予的积分数
     */
    private Long creditsGranted;
    
    /**
     * 套餐是否可供购买
     */
    @Builder.Default
    private Boolean active = true;
    
    /**
     * 套餐是否推荐
     */
    @Builder.Default
    private Boolean recommended = false;
    
    /**
     * 套餐优先级（用于排序显示）
     */
    @Builder.Default
    private Integer priority = 0;
    
    /**
     * 套餐特性列表
     */
    @Builder.Default
    private Map<String, Object> features = new HashMap<>();
    
    /**
     * 试用期天数（0表示无试用期）
     */
    @Builder.Default
    private Integer trialDays = 0;
    
    /**
     * 最大用户数限制（-1表示无限制）
     */
    @Builder.Default
    private Integer maxUsers = -1;
    
    /**
     * 创建时间
     */
    private LocalDateTime createdAt;
    
    /**
     * 更新时间
     */
    private LocalDateTime updatedAt;
    
    /**
     * 计费周期枚举
     */
    public enum BillingCycle {
        /**
         * 月度计费
         */
        MONTHLY,
        
        /**
         * 季度计费
         */
        QUARTERLY,
        
        /**
         * 年度计费
         */
        YEARLY,
        
        /**
         * 一次性付费
         */
        LIFETIME
    }
    
    /**
     * 获取套餐的月度等价价格（用于比较）
     * 
     * @return 月度等价价格
     */
    public BigDecimal getMonthlyEquivalentPrice() {
        if (price == null) {
            return BigDecimal.ZERO;
        }
        
        return switch (billingCycle) {
            case MONTHLY -> price;
            case QUARTERLY -> price.divide(BigDecimal.valueOf(3), 2, RoundingMode.HALF_UP);
            case YEARLY -> price.divide(BigDecimal.valueOf(12), 2, RoundingMode.HALF_UP);
            case LIFETIME -> price.divide(BigDecimal.valueOf(120), 2, RoundingMode.HALF_UP); // 假设10年使用期
        };
    }
    
    /**
     * 添加特性
     * 
     * @param key 特性键
     * @param value 特性值
     */
    public void addFeature(String key, Object value) {
        if (features == null) {
            features = new HashMap<>();
        }
        features.put(key, value);
    }
    
    /**
     * 移除特性
     * 
     * @param key 特性键
     */
    public void removeFeature(String key) {
        if (features != null) {
            features.remove(key);
        }
    }
    
    /**
     * 检查是否有指定特性
     * 
     * @param key 特性键
     * @return 是否存在该特性
     */
    public boolean hasFeature(String key) {
        return features != null && features.containsKey(key);
    }
}