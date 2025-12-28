package com.ainovel.server.config;

import lombok.Getter;

/**
 * 重试策略枚举
 * 定义不同的重试策略及其参数配置
 */
@Getter
public enum RetryStrategyEnum {
    
    /**
     * 指数退避 - 用于配额限制敏感的服务
     */
    EXPONENTIAL_BACKOFF(
        1000,   // 初始延迟1秒
        4.0,    // 4倍增长因子 (按用户要求)
        120000, // 最大延迟2分钟
        true,   // 启用抖动
        true,   // 使用RabbitMQ延迟队列
        5       // 最大重试次数
    ),
    
    /**
     * 线性退避 - 用于一般重试场景
     */
    LINEAR_BACKOFF(
        2000,   // 初始延迟2秒
        2.0,    // 2倍增长因子
        30000,  // 最大延迟30秒
        true,   // 启用抖动
        false,  // 不使用RabbitMQ延迟队列
        3       // 最大重试次数
    ),
    
    /**
     * 固定间隔 - 用于网络错误等临时问题
     */
    FIXED_INTERVAL(
        5000,   // 固定5秒延迟
        1.0,    // 不增长
        5000,   // 最大延迟也是5秒
        false,  // 不启用抖动
        false,  // 不使用RabbitMQ延迟队列
        2       // 最大重试次数
    ),
    
    /**
     * 智能退避 - 根据错误类型动态调整
     */
    INTELLIGENT_BACKOFF(
        3000,   // 初始延迟3秒
        3.0,    // 3倍增长因子
        60000,  // 最大延迟1分钟
        true,   // 启用抖动
        true,   // 使用RabbitMQ延迟队列
        4       // 最大重试次数
    );
    
    private final long initialDelayMillis;
    private final double backoffMultiplier;
    private final long maxDelayMillis;
    private final boolean enableJitter;
    private final boolean useRabbitMQDelay;
    private final int maxRetryAttempts;
    
    RetryStrategyEnum(long initialDelayMillis, double backoffMultiplier, long maxDelayMillis,
                     boolean enableJitter, boolean useRabbitMQDelay, int maxRetryAttempts) {
        this.initialDelayMillis = initialDelayMillis;
        this.backoffMultiplier = backoffMultiplier;
        this.maxDelayMillis = maxDelayMillis;
        this.enableJitter = enableJitter;
        this.useRabbitMQDelay = useRabbitMQDelay;
        this.maxRetryAttempts = maxRetryAttempts;
    }
    
    /**
     * 计算下次重试延迟时间
     */
    public long calculateDelay(int attemptNumber) {
        long delay;
        
        switch (this) {
            case EXPONENTIAL_BACKOFF:
            case INTELLIGENT_BACKOFF:
                delay = (long) (initialDelayMillis * Math.pow(backoffMultiplier, attemptNumber - 1));
                break;
            case LINEAR_BACKOFF:
                delay = initialDelayMillis * attemptNumber;
                break;
            case FIXED_INTERVAL:
            default:
                delay = initialDelayMillis;
                break;
        }
        
        // 限制最大延迟
        delay = Math.min(delay, maxDelayMillis);
        
        // 添加抖动避免惊群效应
        if (enableJitter) {
            double jitter = Math.random() * 0.1; // 10%抖动
            delay = (long) (delay * (1 + jitter));
        }
        
        return delay;
    }
    
    /**
     * 根据错误类型调整重试策略
     */
    public RetryStrategyEnum adjustForErrorType(String errorType) {
        if (this == INTELLIGENT_BACKOFF) {
            if (errorType.contains("429") || errorType.contains("quota")) {
                return EXPONENTIAL_BACKOFF;
            } else if (errorType.contains("500") || errorType.contains("502")) {
                return LINEAR_BACKOFF;
            } else if (errorType.contains("timeout")) {
                return FIXED_INTERVAL;
            }
        }
        return this;
    }
} 