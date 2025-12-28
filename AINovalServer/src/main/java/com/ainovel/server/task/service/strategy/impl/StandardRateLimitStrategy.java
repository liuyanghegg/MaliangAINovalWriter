package com.ainovel.server.task.service.strategy.impl;

import com.ainovel.server.config.ProviderRateLimitConfig;
import com.ainovel.server.task.service.strategy.IRateLimitStrategy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.util.concurrent.ConcurrentHashMap;

/**
 * 标准限流策略
 * 基于令牌桶算法的标准限流实现
 * 
 * 适用场景：
 * - 付费API的一般限流需求
 * - 中等规模的并发控制
 * - 标准的QPS限制
 */
@Slf4j
@Component
public class StandardRateLimitStrategy implements IRateLimitStrategy {
    
    private final ConcurrentHashMap<String, TokenBucket> buckets = new ConcurrentHashMap<>();
    
    @Override
    public Mono<Boolean> tryAcquire(ProviderRateLimitConfig config, String requestId) {
        String key = config.getRateLimiterKey();
        TokenBucket bucket = buckets.computeIfAbsent(key, k -> 
            new TokenBucket(config.getEffectiveRate(), config.getEffectiveBurstCapacity()));
        
        boolean acquired = bucket.tryConsume();
        
        if (acquired) {
            log.debug("标准策略许可获取成功: key={}, requestId={}", key, requestId);
        } else {
            log.warn("标准策略许可获取失败: key={}, available={}, requestId={}", 
                    key, bucket.getAvailableTokens(), requestId);
        }
        
        return Mono.just(acquired);
    }
    
    @Override
    public Mono<Void> release(ProviderRateLimitConfig config, String requestId) {
        // 标准策略基于时间窗口，不需要主动释放
        return Mono.empty();
    }
    
    @Override
    public Mono<Integer> getAvailablePermits(ProviderRateLimitConfig config) {
        String key = config.getRateLimiterKey();
        TokenBucket bucket = buckets.get(key);
        int available = bucket != null ? bucket.getAvailableTokens() : 0;
        
        log.debug("标准策略可用许可: key={}, available={}", key, available);
        return Mono.just(available);
    }
    
    @Override
    public Mono<Void> recordError(ProviderRateLimitConfig config, String errorType, String requestId) {
        // 标准策略不根据错误调整
        log.debug("标准策略记录错误: key={}, errorType={}, requestId={}", 
                config.getRateLimiterKey(), errorType, requestId);
        return Mono.empty();
    }
    
    @Override
    public Mono<Void> recordSuccess(ProviderRateLimitConfig config, String requestId) {
        // 标准策略不根据成功调整
        log.debug("标准策略记录成功: key={}, requestId={}", 
                config.getRateLimiterKey(), requestId);
        return Mono.empty();
    }
    
    @Override
    public Mono<Void> reset(ProviderRateLimitConfig config) {
        String key = config.getRateLimiterKey();
        buckets.remove(key);
        log.info("标准策略重置: key={}", key);
        return Mono.empty();
    }
    
    @Override
    public String getStrategyName() {
        return "STANDARD";
    }
    
    /**
     * 令牌桶实现
     */
    private static class TokenBucket {
        private final double rate;
        private final int capacity;
        private volatile double tokens;
        private volatile long lastRefill;
        
        public TokenBucket(double rate, int capacity) {
            this.rate = rate;
            this.capacity = capacity;
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
            tokens = Math.min(capacity, tokens + elapsed * rate);
            lastRefill = now;
        }
        
        public int getAvailableTokens() {
            refill();
            return (int) tokens;
        }
    }
} 