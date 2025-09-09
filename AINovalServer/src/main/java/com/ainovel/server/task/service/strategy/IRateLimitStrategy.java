package com.ainovel.server.task.service.strategy;

import com.ainovel.server.config.ProviderRateLimitConfig;
import reactor.core.publisher.Mono;

/**
 * 限流策略接口
 * 定义不同的限流策略实现
 */
public interface IRateLimitStrategy {
    
    /**
     * 尝试获取限流许可
     * 
     * @param config 供应商配置
     * @param requestId 请求ID，用于日志追踪
     * @return 是否获取到许可
     */
    Mono<Boolean> tryAcquire(ProviderRateLimitConfig config, String requestId);
    
    /**
     * 释放许可 (如果策略需要)
     * 
     * @param config 供应商配置
     * @param requestId 请求ID
     */
    Mono<Void> release(ProviderRateLimitConfig config, String requestId);
    
    /**
     * 获取当前许可数量
     * 
     * @param config 供应商配置
     * @return 当前可用许可数
     */
    Mono<Integer> getAvailablePermits(ProviderRateLimitConfig config);
    
    /**
     * 记录错误，用于自适应调整
     * 
     * @param config 供应商配置
     * @param errorType 错误类型
     * @param requestId 请求ID
     */
    Mono<Void> recordError(ProviderRateLimitConfig config, String errorType, String requestId);
    
    /**
     * 记录成功，用于自适应调整
     * 
     * @param config 供应商配置
     * @param requestId 请求ID
     */
    Mono<Void> recordSuccess(ProviderRateLimitConfig config, String requestId);
    
    /**
     * 重置限流器状态
     * 
     * @param config 供应商配置
     */
    Mono<Void> reset(ProviderRateLimitConfig config);
    
    /**
     * 获取策略名称
     */
    String getStrategyName();
} 