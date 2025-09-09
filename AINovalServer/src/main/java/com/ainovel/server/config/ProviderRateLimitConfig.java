package com.ainovel.server.config;

import lombok.Builder;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;

import java.time.Duration;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicReference;

/**
 * 供应商限流配置
 * 每个AI供应商的详细限流配置
 */
@Data
@Builder
@Slf4j
public class ProviderRateLimitConfig {
    
    private final AIProviderEnum provider;
    private final RateLimitStrategyEnum rateLimitStrategy;
    private final RetryStrategyEnum retryStrategy;
    private final RateLimitDimensionEnum dimension;
    private final String userId;
    private final String modelName;
    private final String taskType;
    
    // 动态配置 - 可根据运行时状态调整
    @Builder.Default
    private final AtomicReference<Double> currentRate = new AtomicReference<>();
    @Builder.Default
    private final AtomicReference<Integer> currentBurstCapacity = new AtomicReference<>();
    
    // 监控指标
    @Builder.Default
    private final ConcurrentHashMap<String, Object> metrics = new ConcurrentHashMap<>();
    
    /**
     * 获取当前有效的限流速率
     */
    public double getEffectiveRate() {
        Double current = currentRate.get();
        return current != null ? current : rateLimitStrategy.getRatePerSecond();
    }
    
    /**
     * 获取当前有效的突发容量
     */
    public int getEffectiveBurstCapacity() {
        Integer current = currentBurstCapacity.get();
        return current != null ? current : rateLimitStrategy.getBurstCapacity();
    }
    
    /**
     * 获取限流器键值
     */
    public String getRateLimiterKey() {
        RateLimitDimensionEnum.RateLimitKeyContext context = RateLimitDimensionEnum.RateLimitKeyContext.of(
                provider.getCode(), userId, modelName, taskType);
        return dimension.generateKey(context);
    }
    
    /**
     * 获取RabbitMQ重试队列名称
     */
    public String getRetryQueueName() {
        return String.format("ai.retry.%s.dlx", provider.getCode());
    }
    
    /**
     * 动态调整限流参数
     */
    public void adjustRateLimit(double errorRate, int consecutiveErrors) {
        if (rateLimitStrategy == RateLimitStrategyEnum.ADAPTIVE) {
            double adjustmentFactor = calculateAdjustmentFactor(errorRate, consecutiveErrors);
            double baseRate = rateLimitStrategy.getRatePerSecond();
            double newRate = baseRate * adjustmentFactor;
            
            // 限制调整范围
            newRate = Math.max(0.1, Math.min(newRate, baseRate * 2));
            
            currentRate.set(newRate);
            
            log.info("动态调整限流参数: provider={}, errorRate={}, newRate={}", 
                    provider.getCode(), errorRate, newRate);
        }
    }
    
    /**
     * 计算调整因子
     */
    private double calculateAdjustmentFactor(double errorRate, int consecutiveErrors) {
        // 基于错误率的调整
        double errorFactor = 1.0;
        if (errorRate > 0.3) {
            errorFactor = 0.3; // 高错误率，大幅降低
        } else if (errorRate > 0.1) {
            errorFactor = 0.6; // 中等错误率，适度降低
        } else if (errorRate < 0.01) {
            errorFactor = 1.5; // 低错误率，适度提高
        }
        
        // 基于连续错误的调整
        double consecutiveFactor = Math.max(0.2, 1.0 - consecutiveErrors * 0.1);
        
        return errorFactor * consecutiveFactor;
    }
    
    /**
     * 更新监控指标
     */
    public void updateMetrics(String metricName, Object value) {
        metrics.put(metricName, value);
        metrics.put("lastUpdated", System.currentTimeMillis());
    }
    
    /**
     * 获取监控指标
     */
    public Object getMetric(String metricName) {
        return metrics.get(metricName);
    }
    
    /**
     * 重置为默认配置
     */
    public void resetToDefault() {
        currentRate.set(null);
        currentBurstCapacity.set(null);
        metrics.clear();
        log.info("重置供应商配置为默认值: provider={}", provider.getCode());
    }
    
    /**
     * 创建默认配置
     */
    public static ProviderRateLimitConfig createDefault(AIProviderEnum provider, String userId, String modelName) {
        return ProviderRateLimitConfig.builder()
                .provider(provider)
                .rateLimitStrategy(provider.getDefaultRateLimitStrategy())
                .retryStrategy(provider.getDefaultRetryStrategy())
                .dimension(RateLimitDimensionEnum.USER_PROVIDER_MODEL) // 默认用户+供应商+模型维度
                .userId(userId)
                .modelName(modelName)
                .build();
    }
    
    /**
     * 创建Gemini特定配置 (针对免费层限制)
     */
    public static ProviderRateLimitConfig createGeminiConfig(String userId, String modelName) {
        return ProviderRateLimitConfig.builder()
                .provider(AIProviderEnum.GEMINI)
                .rateLimitStrategy(RateLimitStrategyEnum.CONSERVATIVE) // 保守策略应对200次/天限制
                .retryStrategy(RetryStrategyEnum.EXPONENTIAL_BACKOFF)  // 4倍指数退避
                .dimension(RateLimitDimensionEnum.GLOBAL) // Gemini使用全局维度限流(因为免费层共享配额)
                .userId(userId)
                .modelName(modelName)
                .build();
    }
    
    /**
     * 创建任务级配置
     */
    public static ProviderRateLimitConfig createTaskConfig(AIProviderEnum provider, String userId, String modelName, String taskType) {
        return ProviderRateLimitConfig.builder()
                .provider(provider)
                .rateLimitStrategy(provider.getDefaultRateLimitStrategy())
                .retryStrategy(provider.getDefaultRetryStrategy())
                .dimension(RateLimitDimensionEnum.HYBRID) // 使用混合维度
                .userId(userId)
                .modelName(modelName)
                .taskType(taskType)
                .build();
    }
} 