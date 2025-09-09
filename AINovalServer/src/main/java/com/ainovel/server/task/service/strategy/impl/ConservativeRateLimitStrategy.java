package com.ainovel.server.task.service.strategy.impl;

import com.ainovel.server.config.ProviderRateLimitConfig;
import com.ainovel.server.task.service.strategy.IRateLimitStrategy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

/**
 * 保守限流策略
 * 专门用于配额敏感的API，如Gemini免费层(200次/天)
 * 
 * 特点:
 * 1. 严格的日限额控制
 * 2. 时间窗口重置
 * 3. 并发安全的计数器
 * 4. 自动错误恢复
 */
@Slf4j
@Component
public class ConservativeRateLimitStrategy implements IRateLimitStrategy {
    
    // 并发安全的计数器 - 按配置键分组
    private final ConcurrentHashMap<String, AtomicInteger> dailyCounters = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, AtomicLong> lastResetTime = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, AtomicInteger> consecutiveErrors = new ConcurrentHashMap<>();
    
    // Gemini特定限制
    private static final int GEMINI_DAILY_LIMIT = 20000000;
    private static final int GEMINI_SAFETY_BUFFER = 2000; // 保留20次作为安全缓冲
    
    @Override
    public Mono<Boolean> tryAcquire(ProviderRateLimitConfig config, String requestId) {
        String key = config.getRateLimiterKey();
        
        return checkAndResetDaily(key)
                .flatMap(reset -> {
                    // 检查日限额
                    AtomicInteger counter = dailyCounters.computeIfAbsent(key, k -> new AtomicInteger(0));
                    int currentCount = counter.get();
                    
                    // 动态限制：根据错误率调整
                    int effectiveLimit = calculateEffectiveLimit(config, key);
                    
                    if (currentCount >= effectiveLimit) {
                        log.warn("达到日限额: key={}, count={}, limit={}, requestId={}", 
                                key, currentCount, effectiveLimit, requestId);
                        return Mono.just(false);
                    }
                    
                    // 原子性增加计数
                    int newCount = counter.incrementAndGet();
                    
                    // 双重检查，防止竞争条件
                    if (newCount > effectiveLimit) {
                        counter.decrementAndGet(); // 回滚
                        log.warn("并发竞争导致超限，回滚: key={}, newCount={}, limit={}, requestId={}", 
                                key, newCount, effectiveLimit, requestId);
                        return Mono.just(false);
                    }
                    
                    log.debug("获取限流许可成功: key={}, count={}, requestId={}", key, newCount, requestId);
                    return Mono.just(true);
                })
                .onErrorResume(ex -> {
                    log.error("限流检查失败: key={}, requestId={}, error={}", key, requestId, ex.getMessage());
                    return Mono.just(false); // 保守策略：出错时拒绝请求
                });
    }
    
    @Override
    public Mono<Void> release(ProviderRateLimitConfig config, String requestId) {
        // 保守策略通常不需要释放许可，因为基于时间窗口
        return Mono.empty();
    }
    
    @Override
    public Mono<Integer> getAvailablePermits(ProviderRateLimitConfig config) {
        String key = config.getRateLimiterKey();
        AtomicInteger counter = dailyCounters.get(key);
        int used = counter != null ? counter.get() : 0;
        int limit = calculateEffectiveLimit(config, key);
        return Mono.just(Math.max(0, limit - used));
    }
    
    @Override
    public Mono<Void> recordError(ProviderRateLimitConfig config, String errorType, String requestId) {
        String key = config.getRateLimiterKey();
        
        // 记录连续错误
        AtomicInteger errors = consecutiveErrors.computeIfAbsent(key, k -> new AtomicInteger(0));
        int errorCount = errors.incrementAndGet();
        
        log.warn("记录API错误: key={}, errorType={}, consecutiveErrors={}, requestId={}", 
                key, errorType, errorCount, requestId);
        
        // 如果是配额错误，触发紧急限制
        if (errorType.contains("429") || errorType.contains("quota") || errorType.contains("RESOURCE_EXHAUSTED")) {
            return triggerEmergencyLimit(config, requestId);
        }
        
        return Mono.empty();
    }
    
    @Override
    public Mono<Void> recordSuccess(ProviderRateLimitConfig config, String requestId) {
        String key = config.getRateLimiterKey();
        
        // 重置连续错误计数
        AtomicInteger errors = consecutiveErrors.get(key);
        if (errors != null) {
            errors.set(0);
        }
        
        log.debug("记录API成功: key={}, requestId={}", key, requestId);
        return Mono.empty();
    }
    
    @Override
    public Mono<Void> reset(ProviderRateLimitConfig config) {
        String key = config.getRateLimiterKey();
        
        dailyCounters.remove(key);
        lastResetTime.remove(key);
        consecutiveErrors.remove(key);
        
        log.info("重置限流器状态: key={}", key);
        return Mono.empty();
    }
    
    @Override
    public String getStrategyName() {
        return "CONSERVATIVE";
    }
    
    /**
     * 检查并重置日计数器
     */
    private Mono<Boolean> checkAndResetDaily(String key) {
        AtomicLong lastReset = lastResetTime.computeIfAbsent(key, k -> new AtomicLong(0));
        long now = System.currentTimeMillis();
        long resetTime = lastReset.get();
        
        // 检查是否需要重置 (新的一天)
        if (shouldResetDaily(resetTime, now)) {
            synchronized (lastReset) {
                // 双重检查锁定
                if (shouldResetDaily(lastReset.get(), now)) {
                    dailyCounters.remove(key);
                    consecutiveErrors.remove(key);
                    lastReset.set(now);
                    
                    log.info("重置日限额计数器: key={}", key);
                    return Mono.just(true);
                }
            }
        }
        
        return Mono.just(false);
    }
    
    /**
     * 判断是否应该重置日计数器
     */
    private boolean shouldResetDaily(long lastResetTime, long currentTime) {
        if (lastResetTime == 0) return true;
        
        LocalDateTime lastReset = LocalDateTime.ofInstant(
                java.time.Instant.ofEpochMilli(lastResetTime), 
                java.time.ZoneId.systemDefault());
        LocalDateTime now = LocalDateTime.ofInstant(
                java.time.Instant.ofEpochMilli(currentTime), 
                java.time.ZoneId.systemDefault());
        
        return !lastReset.toLocalDate().equals(now.toLocalDate());
    }
    
    /**
     * 计算有效限制（考虑错误率和安全缓冲）
     */
    private int calculateEffectiveLimit(ProviderRateLimitConfig config, String key) {
        // 允许通过配置动态调整日限额和安全缓冲
        Object dailyLimitObj = config.getMetric("dailyLimit");
        Object safetyBufferObj = config.getMetric("safetyBuffer");

        int baseLimit = dailyLimitObj instanceof Number ? ((Number) dailyLimitObj).intValue() : GEMINI_DAILY_LIMIT;
        int safetyBuffer = safetyBufferObj instanceof Number ? ((Number) safetyBufferObj).intValue() : GEMINI_SAFETY_BUFFER;

        // 应用安全缓冲
        int safeLimit = baseLimit - safetyBuffer;
        
        // 根据连续错误调整
        AtomicInteger errors = consecutiveErrors.get(key);
        if (errors != null) {
            int errorCount = errors.get();
            if (errorCount > 3) {
                // 连续错误过多，进一步限制
                safeLimit = (int) (safeLimit * 0.5);
                log.warn("因连续错误调整限制: key={}, errors={}, newLimit={}", key, errorCount, safeLimit);
            }
        }
        
        return Math.max(1, safeLimit); // 至少保留1次机会
    }
    
    /**
     * 触发紧急限制
     */
    private Mono<Void> triggerEmergencyLimit(ProviderRateLimitConfig config, String requestId) {
        String key = config.getRateLimiterKey();
        
        // 立即设置为接近限制（保留5次机会）
        Object dailyLimitObj = config.getMetric("dailyLimit");
        int baseLimit = dailyLimitObj instanceof Number ? ((Number) dailyLimitObj).intValue() : GEMINI_DAILY_LIMIT;

        AtomicInteger counter = dailyCounters.get(key);
        if (counter != null) {
            counter.set(Math.max(0, baseLimit - 5));
        }
        
        log.error("触发紧急限制: key={}, requestId={}", key, requestId);
        return Mono.empty();
    }
    

} 