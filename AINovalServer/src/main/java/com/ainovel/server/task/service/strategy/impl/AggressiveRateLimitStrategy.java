package com.ainovel.server.task.service.strategy.impl;

import com.ainovel.server.config.ProviderRateLimitConfig;
import com.ainovel.server.task.service.strategy.IRateLimitStrategy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.util.concurrent.ConcurrentHashMap;

/**
 * 激进限流策略
 * 高性能、高并发的限流实现
 * 
 * 适用场景：
 * - 高配额的付费API
 * - 大规模并发场景
 * - 性能优先的应用
 */
@Slf4j
@Component
public class AggressiveRateLimitStrategy implements IRateLimitStrategy {
    
    private final ConcurrentHashMap<String, EnhancedTokenBucket> buckets = new ConcurrentHashMap<>();
    
    @Override
    public Mono<Boolean> tryAcquire(ProviderRateLimitConfig config, String requestId) {
        String key = config.getRateLimiterKey();
        
        // 激进策略：使用更大的速率和容量
        double enhancedRate = config.getEffectiveRate() * 2.0;
        int enhancedCapacity = config.getEffectiveBurstCapacity() * 2;
        
        EnhancedTokenBucket bucket = buckets.computeIfAbsent(key, k -> 
            new EnhancedTokenBucket(enhancedRate, enhancedCapacity));
        
        boolean acquired = bucket.tryConsume();
        
        if (acquired) {
            log.debug("激进策略许可获取成功: key={}, enhancedRate={}, requestId={}", 
                    key, enhancedRate, requestId);
        } else {
            log.warn("激进策略许可获取失败: key={}, available={}, requestId={}", 
                    key, bucket.getAvailableTokens(), requestId);
        }
        
        return Mono.just(acquired);
    }
    
    @Override
    public Mono<Void> release(ProviderRateLimitConfig config, String requestId) {
        // 激进策略不需要主动释放
        return Mono.empty();
    }
    
    @Override
    public Mono<Integer> getAvailablePermits(ProviderRateLimitConfig config) {
        String key = config.getRateLimiterKey();
        EnhancedTokenBucket bucket = buckets.get(key);
        int available = bucket != null ? bucket.getAvailableTokens() : 0;
        
        log.debug("激进策略可用许可: key={}, available={}", key, available);
        return Mono.just(available);
    }
    
    @Override
    public Mono<Void> recordError(ProviderRateLimitConfig config, String errorType, String requestId) {
        String key = config.getRateLimiterKey();
        EnhancedTokenBucket bucket = buckets.get(key);
        
        if (bucket != null && (errorType.contains("429") || errorType.contains("quota"))) {
            // 遇到配额错误时，临时降低速率
            bucket.temporarySlowdown();
            log.warn("激进策略临时降速: key={}, errorType={}, requestId={}", key, errorType, requestId);
        }
        
        return Mono.empty();
    }
    
    @Override
    public Mono<Void> recordSuccess(ProviderRateLimitConfig config, String requestId) {
        String key = config.getRateLimiterKey();
        EnhancedTokenBucket bucket = buckets.get(key);
        
        if (bucket != null) {
            bucket.recordSuccess();
        }
        
        log.debug("激进策略记录成功: key={}, requestId={}", key, requestId);
        return Mono.empty();
    }
    
    @Override
    public Mono<Void> reset(ProviderRateLimitConfig config) {
        String key = config.getRateLimiterKey();
        buckets.remove(key);
        log.info("激进策略重置: key={}", key);
        return Mono.empty();
    }
    
    @Override
    public String getStrategyName() {
        return "AGGRESSIVE";
    }
    
    /**
     * 增强型令牌桶实现
     * 支持动态调整和快速恢复
     */
    private static class EnhancedTokenBucket {
        private final double baseRate;
        private final int baseCapacity;
        private volatile double currentRate;
        private volatile double tokens;
        private volatile long lastRefill;
        private volatile long lastSlowdown = 0;
        private volatile int successCount = 0;
        
        // 激进策略参数
        private static final long SLOWDOWN_DURATION = 10000; // 10秒降速期
        private static final double SLOWDOWN_FACTOR = 0.3;   // 降速到30%
        private static final int RECOVERY_THRESHOLD = 5;     // 5次成功后恢复
        
        public EnhancedTokenBucket(double rate, int capacity) {
            this.baseRate = rate;
            this.baseCapacity = capacity;
            this.currentRate = rate;
            this.tokens = capacity;
            this.lastRefill = System.currentTimeMillis();
        }
        
        public synchronized boolean tryConsume() {
            refill();
            if (tokens >= 1.0) {
                tokens -= 1.0;
                return true;
            }
            return false;
        }
        
        private void refill() {
            long now = System.currentTimeMillis();
            double elapsed = (now - lastRefill) / 1000.0;
            
            // 检查是否需要恢复正常速率
            if (now - lastSlowdown > SLOWDOWN_DURATION && successCount >= RECOVERY_THRESHOLD) {
                currentRate = baseRate;
                successCount = 0;
            }
            
            tokens = Math.min(baseCapacity, tokens + elapsed * currentRate);
            lastRefill = now;
        }
        
        public void temporarySlowdown() {
            currentRate = baseRate * SLOWDOWN_FACTOR;
            lastSlowdown = System.currentTimeMillis();
            successCount = 0;
        }
        
        public void recordSuccess() {
            successCount++;
        }
        
        public int getAvailableTokens() {
            refill();
            return (int) tokens;
        }
    }
} 