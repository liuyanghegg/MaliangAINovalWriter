package com.ainovel.server.task.service.strategy.impl;

import com.ainovel.server.config.ProviderRateLimitConfig;
import com.ainovel.server.task.service.strategy.IRateLimitStrategy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.util.concurrent.ConcurrentHashMap;

/**
 * 自适应限流策略
 * 根据错误率和成功率动态调整限流参数
 * 
 * 适用场景：
 * - 未知API限制的探索性使用
 * - 需要智能调整的复杂场景
 * - 多变的网络环境
 */
@Slf4j
@Component
public class AdaptiveRateLimitStrategy implements IRateLimitStrategy {
    
    private final ConcurrentHashMap<String, AdaptiveTokenBucket> buckets = new ConcurrentHashMap<>();
    
    @Override
    public Mono<Boolean> tryAcquire(ProviderRateLimitConfig config, String requestId) {
        String key = config.getRateLimiterKey();
        AdaptiveTokenBucket bucket = buckets.computeIfAbsent(key, k -> 
            new AdaptiveTokenBucket(config.getEffectiveRate(), config.getEffectiveBurstCapacity()));
        
        boolean acquired = bucket.tryConsume();
        
        if (acquired) {
            log.debug("自适应策略许可获取成功: key={}, currentRate={}, requestId={}", 
                    key, bucket.getCurrentRate(), requestId);
        } else {
            log.warn("自适应策略许可获取失败: key={}, available={}, errorRate={}, requestId={}", 
                    key, bucket.getAvailableTokens(), bucket.getErrorRate(), requestId);
        }
        
        return Mono.just(acquired);
    }
    
    @Override
    public Mono<Void> release(ProviderRateLimitConfig config, String requestId) {
        // 自适应策略不需要主动释放
        return Mono.empty();
    }
    
    @Override
    public Mono<Integer> getAvailablePermits(ProviderRateLimitConfig config) {
        String key = config.getRateLimiterKey();
        AdaptiveTokenBucket bucket = buckets.get(key);
        int available = bucket != null ? bucket.getAvailableTokens() : 0;
        
        log.debug("自适应策略可用许可: key={}, available={}", key, available);
        return Mono.just(available);
    }
    
    @Override
    public Mono<Void> recordError(ProviderRateLimitConfig config, String errorType, String requestId) {
        String key = config.getRateLimiterKey();
        AdaptiveTokenBucket bucket = buckets.get(key);
        
        if (bucket != null) {
            bucket.recordError(errorType);
            log.info("自适应策略记录错误: key={}, errorType={}, newRate={}, requestId={}", 
                    key, errorType, bucket.getCurrentRate(), requestId);
        }
        
        return Mono.empty();
    }
    
    @Override
    public Mono<Void> recordSuccess(ProviderRateLimitConfig config, String requestId) {
        String key = config.getRateLimiterKey();
        AdaptiveTokenBucket bucket = buckets.get(key);
        
        if (bucket != null) {
            bucket.recordSuccess();
            log.debug("自适应策略记录成功: key={}, newRate={}, requestId={}", 
                    key, bucket.getCurrentRate(), requestId);
        }
        
        return Mono.empty();
    }
    
    @Override
    public Mono<Void> reset(ProviderRateLimitConfig config) {
        String key = config.getRateLimiterKey();
        buckets.remove(key);
        log.info("自适应策略重置: key={}", key);
        return Mono.empty();
    }
    
    @Override
    public String getStrategyName() {
        return "ADAPTIVE";
    }
    
    /**
     * 自适应令牌桶实现
     * 支持根据错误率动态调整速率
     */
    private static class AdaptiveTokenBucket {
        private final double baseRate;
        private final int baseCapacity;
        private volatile double currentRate;
        private volatile double tokens;
        private volatile long lastRefill;
        
        // 统计信息
        private volatile int errorCount = 0;
        private volatile int successCount = 0;
        private volatile int totalRequests = 0;
        private volatile long lastAdjustment = System.currentTimeMillis();
        
        // 自适应参数
        private static final int MIN_SAMPLES = 10;           // 最小样本数
        private static final long ADJUSTMENT_INTERVAL = 30000; // 30秒调整间隔
        private static final double MAX_RATE_MULTIPLIER = 2.0; // 最大速率倍数
        private static final double MIN_RATE_MULTIPLIER = 0.1; // 最小速率倍数
        
        public AdaptiveTokenBucket(double rate, int capacity) {
            this.baseRate = rate;
            this.baseCapacity = capacity;
            this.currentRate = rate;
            this.tokens = capacity;
            this.lastRefill = System.currentTimeMillis();
        }
        
        public synchronized boolean tryConsume() {
            refill();
            adjustRateIfNeeded();
            
            if (tokens >= 1.0) {
                tokens -= 1.0;
                totalRequests++;
                return true;
            }
            return false;
        }
        
        private void refill() {
            long now = System.currentTimeMillis();
            double elapsed = (now - lastRefill) / 1000.0;
            tokens = Math.min(baseCapacity, tokens + elapsed * currentRate);
            lastRefill = now;
        }
        
        public void recordError(String errorType) {
            errorCount++;
            totalRequests++;
            
            // 立即调整策略对严重错误
            if (errorType.contains("429") || errorType.contains("quota")) {
                currentRate = Math.max(baseRate * MIN_RATE_MULTIPLIER, currentRate * 0.5);
                log.warn("自适应策略紧急降速: errorType={}, newRate={}", errorType, currentRate);
            }
        }
        
        public void recordSuccess() {
            successCount++;
            totalRequests++;
        }
        
        private void adjustRateIfNeeded() {
            long now = System.currentTimeMillis();
            
            // 检查是否需要调整
            if (now - lastAdjustment < ADJUSTMENT_INTERVAL || totalRequests < MIN_SAMPLES) {
                return;
            }
            
            double errorRate = (double) errorCount / totalRequests;
            double newRateMultiplier = calculateRateMultiplier(errorRate);
            double newRate = baseRate * newRateMultiplier;
            
            // 限制调整范围
            newRate = Math.max(baseRate * MIN_RATE_MULTIPLIER, 
                    Math.min(baseRate * MAX_RATE_MULTIPLIER, newRate));
            
            if (Math.abs(newRate - currentRate) > 0.01) {
                log.info("自适应策略调整速率: errorRate={}, oldRate={}, newRate={}, samples={}", 
                        errorRate, currentRate, newRate, totalRequests);
                currentRate = newRate;
            }
            
            // 重置统计信息
            lastAdjustment = now;
            // 保留部分历史数据用于平滑调整
            errorCount = errorCount / 2;
            successCount = successCount / 2;
            totalRequests = totalRequests / 2;
        }
        
        private double calculateRateMultiplier(double errorRate) {
            if (errorRate > 0.3) {
                return 0.2; // 高错误率，大幅降低
            } else if (errorRate > 0.15) {
                return 0.5; // 中等错误率，适度降低
            } else if (errorRate > 0.05) {
                return 0.8; // 低错误率，稍微降低
            } else if (errorRate < 0.01) {
                return 1.5; // 很低错误率，适度提高
            } else {
                return 1.0; // 正常错误率，保持不变
            }
        }
        
        public double getCurrentRate() {
            return currentRate;
        }
        
        public double getErrorRate() {
            return totalRequests > 0 ? (double) errorCount / totalRequests : 0.0;
        }
        
        public int getAvailableTokens() {
            refill();
            return (int) tokens;
        }
    }
} 