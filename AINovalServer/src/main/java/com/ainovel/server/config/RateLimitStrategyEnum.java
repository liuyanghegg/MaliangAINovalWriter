package com.ainovel.server.config;

import lombok.Getter;

/**
 * 限流策略枚举
 * 定义不同的限流策略及其参数配置
 */
@Getter
public enum RateLimitStrategyEnum {
    
    /**
     * 保守策略 - 用于免费API或配额限制严格的服务
     */
    CONSERVATIVE(
        0.2,    // 每秒0.2个请求
        1,      // 突发容量1
        30000,  // 30秒超时
        4.0,    // 4倍重试间隔增长
        5       // 最大重试次数
    ),
    
    /**
     * 标准策略 - 用于付费API的一般场景
     */
    STANDARD(
        2.0,    // 每秒2个请求
        5,      // 突发容量5
        10000,  // 10秒超时
        2.0,    // 2倍重试间隔增长
        3       // 最大重试次数
    ),
    
    /**
     * 激进策略 - 用于高配额付费API
     */
    AGGRESSIVE(
        10.0,   // 每秒10个请求
        20,     // 突发容量20
        5000,   // 5秒超时
        1.5,    // 1.5倍重试间隔增长
        2       // 最大重试次数
    ),
    
    /**
     * 自适应策略 - 根据历史错误率动态调整
     */
    ADAPTIVE(
        1.0,    // 初始每秒1个请求
        3,      // 突发容量3
        15000,  // 15秒超时
        3.0,    // 3倍重试间隔增长
        4       // 最大重试次数
    );
    
    private final double ratePerSecond;
    private final int burstCapacity;
    private final long timeoutMillis;
    private final double retryBackoffMultiplier;
    private final int maxRetryAttempts;
    
    RateLimitStrategyEnum(double ratePerSecond, int burstCapacity, long timeoutMillis, 
                         double retryBackoffMultiplier, int maxRetryAttempts) {
        this.ratePerSecond = ratePerSecond;
        this.burstCapacity = burstCapacity;
        this.timeoutMillis = timeoutMillis;
        this.retryBackoffMultiplier = retryBackoffMultiplier;
        this.maxRetryAttempts = maxRetryAttempts;
    }
    
    /**
     * 根据错误率动态调整策略
     */
    public RateLimitStrategyEnum adjustForErrorRate(double errorRate) {
        if (this == ADAPTIVE) {
            if (errorRate > 0.3) {
                return CONSERVATIVE;
            } else if (errorRate > 0.1) {
                return STANDARD;
            } else {
                return AGGRESSIVE;
            }
        }
        return this;
    }
} 