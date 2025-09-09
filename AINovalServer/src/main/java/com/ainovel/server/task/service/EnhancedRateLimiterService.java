package com.ainovel.server.task.service;

import com.ainovel.server.config.AIProviderEnum;
import com.ainovel.server.config.ProviderRateLimitConfig;
import com.ainovel.server.task.service.factory.RateLimitStrategyFactory;
import com.ainovel.server.task.service.retry.RabbitMQRetryManager;
import com.ainovel.server.task.service.strategy.IRateLimitStrategy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import com.ainovel.server.config.RateLimitConfigurationManager;

import java.util.concurrent.ConcurrentHashMap;

/**
 * 增强的限流服务
 * 整合策略模式、重试机制、供应商配置管理
 * 
 * 核心功能:
 * 1. 枚举驱动的供应商配置
 * 2. 策略模式的限流控制  
 * 3. RabbitMQ重试机制集成
 * 4. 并发安全的配置管理
 * 5. 智能错误处理和监控
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EnhancedRateLimiterService {
    
    private final RateLimitStrategyFactory strategyFactory;
    private final RabbitMQRetryManager retryManager;
    private final RateLimitConfigurationManager rateLimitConfigurationManager;
    
    // 配置缓存 - 按用户和模型分组
    private final ConcurrentHashMap<String, ProviderRateLimitConfig> configCache = new ConcurrentHashMap<>();
    
    /**
     * 尝试获取AI服务限流许可
     * 
     * @param providerCode 供应商代码
     * @param userId 用户ID
     * @param modelName 模型名称
     * @param requestId 请求ID
     * @return 许可获取结果
     */
    public Mono<PermitResult> tryAcquirePermit(String providerCode, String userId, String modelName, String requestId) {
        try {
            // 获取供应商配置
            ProviderRateLimitConfig config = getOrCreateConfig(providerCode, userId, modelName);
            
            // 获取限流策略
            IRateLimitStrategy strategy = strategyFactory.getStrategy(config.getRateLimitStrategy());
            
            // 尝试获取许可
            return strategy.tryAcquire(config, requestId)
                    .map(permitted -> {
                        if (permitted) {
                            log.debug("限流许可获取成功: provider={}, user={}, model={}, requestId={}", 
                                    providerCode, userId, modelName, requestId);
                            return PermitResult.success(config, strategy.getStrategyName());
                        } else {
                            log.warn("限流许可获取失败: provider={}, user={}, model={}, requestId={}", 
                                    providerCode, userId, modelName, requestId);
                            return PermitResult.rejected(config, "限流器拒绝请求");
                        }
                    })
                    .onErrorResume(ex -> {
                        log.error("限流检查出错: provider={}, user={}, requestId={}, error={}", 
                                providerCode, userId, requestId, ex.getMessage(), ex);
                        return Mono.just(PermitResult.error(config, ex.getMessage()));
                    });
            
        } catch (NoClassDefFoundError err) {
            log.error("限流服务致命错误(类缺失): provider={}, user={}, requestId={}, missing={}",
                    providerCode, userId, requestId, err.getMessage(), err);
            return Mono.just(PermitResult.error(null, "类缺失: " + err.getMessage()));
        } catch (Throwable ex) {
            log.error("限流服务异常: provider={}, user={}, requestId={}, error={}",
                    providerCode, userId, requestId, ex.getMessage(), ex);
            return Mono.just(PermitResult.error(null, ex.getMessage()));
        }
    }
    
    /**
     * 记录API调用成功
     */
    public Mono<Void> recordSuccess(String providerCode, String userId, String modelName, String requestId) {
        ProviderRateLimitConfig config = getConfigFromCache(providerCode, userId, modelName);
        if (config != null) {
            IRateLimitStrategy strategy = strategyFactory.getStrategy(config.getRateLimitStrategy());
            return strategy.recordSuccess(config, requestId);
        }
        return Mono.empty();
    }
    
    /**
     * 记录API调用错误并处理重试
     */
    public Mono<RetryResult> recordErrorAndRetry(String providerCode, String userId, String modelName, 
                                               String requestId, String errorType, Object originalPayload) {
        ProviderRateLimitConfig config = getConfigFromCache(providerCode, userId, modelName);
        if (config == null) {
            return Mono.just(RetryResult.failed("配置不存在"));
        }
        
        IRateLimitStrategy strategy = strategyFactory.getStrategy(config.getRateLimitStrategy());
        
        // 记录错误
        return strategy.recordError(config, errorType, requestId)
                .then(Mono.defer(() -> {
                    // 检查是否应该重试
                    if (retryManager.shouldRetry(config, errorType, requestId)) {
                        // 调度重试任务
                        return retryManager.scheduleRetry(config, originalPayload, errorType, requestId)
                                .map(scheduled -> {
                                    if (scheduled) {
                                        long nextRetryTime = retryManager.calculateNextRetryTime(config, errorType, 
                                                retryManager.getCurrentRetryCount(requestId));
                                        return RetryResult.scheduled(nextRetryTime, retryManager.getCurrentRetryCount(requestId));
                                    } else {
                                        return RetryResult.failed("重试调度失败");
                                    }
                                });
                    } else {
                        // 超过重试限制
                        return retryManager.clearRetryCount(requestId)
                                .then(Mono.just(RetryResult.exhausted("重试次数已达上限")));
                    }
                }))
                .onErrorResume(ex -> {
                    log.error("错误记录和重试处理失败: requestId={}, error={}", requestId, ex.getMessage(), ex);
                    return Mono.just(RetryResult.failed("处理失败: " + ex.getMessage()));
                });
    }
    
    /**
     * 获取限流器状态
     */
    public Mono<RateLimiterStatus> getStatus(String providerCode, String userId, String modelName) {
        ProviderRateLimitConfig config = getConfigFromCache(providerCode, userId, modelName);
        if (config == null) {
            return Mono.just(RateLimiterStatus.notFound());
        }
        
        IRateLimitStrategy strategy = strategyFactory.getStrategy(config.getRateLimitStrategy());
        
        return strategy.getAvailablePermits(config)
                .map(availablePermits -> RateLimiterStatus.builder()
                        .provider(config.getProvider())
                        .strategyName(strategy.getStrategyName())
                        .effectiveRate(config.getEffectiveRate())
                        .effectiveBurstCapacity(config.getEffectiveBurstCapacity())
                        .availablePermits(availablePermits)
                        .retryCount(retryManager.getCurrentRetryCount(config.getRateLimiterKey()))
                        .metrics(config.getMetrics())
                        .build());
    }
    
    /**
     * 重置限流器状态
     */
    public Mono<Void> resetRateLimiter(String providerCode, String userId, String modelName) {
        ProviderRateLimitConfig config = getConfigFromCache(providerCode, userId, modelName);
        if (config != null) {
            IRateLimitStrategy strategy = strategyFactory.getStrategy(config.getRateLimitStrategy());
            return strategy.reset(config)
                    .then(retryManager.clearRetryCount(config.getRateLimiterKey()))
                    .doOnSuccess(v -> {
                        config.resetToDefault();
                        log.info("重置限流器: provider={}, user={}, model={}", providerCode, userId, modelName);
                    });
        }
        return Mono.empty();
    }
    
    /**
     * 获取或创建供应商配置
     */
    private ProviderRateLimitConfig getOrCreateConfig(String providerCode, String userId, String modelName) {
        String cacheKey = buildCacheKey(providerCode, userId, modelName);

        ProviderRateLimitConfig existing = configCache.get(cacheKey);
        if (existing != null) {
            // 如果缺少日限额或安全缓冲指标，尝试补充
            if (existing.getMetric("dailyLimit") == null || existing.getMetric("safetyBuffer") == null) {
                AIProviderEnum provider = AIProviderEnum.fromCode(providerCode);
                ProviderRateLimitConfig newConfig = rateLimitConfigurationManager.createProviderConfig(provider, userId, modelName, null);
                configCache.put(cacheKey, newConfig);
                return newConfig;
            }
            return existing;
        }

        // 不存在则创建
        AIProviderEnum provider = AIProviderEnum.fromCode(providerCode);
        ProviderRateLimitConfig newConfig = rateLimitConfigurationManager.createProviderConfig(provider, userId, modelName, null);
        configCache.put(cacheKey, newConfig);
        return newConfig;
    }
    
    /**
     * 从缓存获取配置
     */
    private ProviderRateLimitConfig getConfigFromCache(String providerCode, String userId, String modelName) {
        String cacheKey = buildCacheKey(providerCode, userId, modelName);
        return configCache.get(cacheKey);
    }
    
    /**
     * 构建缓存键
     */
    private String buildCacheKey(String providerCode, String userId, String modelName) {
        return String.format("%s:%s:%s", providerCode, userId != null ? userId : "system", 
                modelName != null ? modelName : "default");
    }
    
    /**
     * 许可获取结果
     */
    @lombok.Data
    @lombok.Builder
    public static class PermitResult {
        private final boolean success;
        private final String message;
        private final ProviderRateLimitConfig config;
        private final String strategyName;
        private final long timestamp;
        
        public static PermitResult success(ProviderRateLimitConfig config, String strategyName) {
            return PermitResult.builder()
                    .success(true)
                    .message("许可获取成功")
                    .config(config)
                    .strategyName(strategyName)
                    .timestamp(System.currentTimeMillis())
                    .build();
        }
        
        public static PermitResult rejected(ProviderRateLimitConfig config, String reason) {
            return PermitResult.builder()
                    .success(false)
                    .message(reason)
                    .config(config)
                    .timestamp(System.currentTimeMillis())
                    .build();
        }
        
        public static PermitResult error(ProviderRateLimitConfig config, String error) {
            return PermitResult.builder()
                    .success(false)
                    .message("错误: " + error)
                    .config(config)
                    .timestamp(System.currentTimeMillis())
                    .build();
        }
    }
    
    /**
     * 重试结果
     */
    @lombok.Data
    @lombok.Builder
    public static class RetryResult {
        private final boolean scheduled;
        private final String message;
        private final long nextRetryTime;
        private final int attemptNumber;
        
        public static RetryResult scheduled(long nextRetryTime, int attemptNumber) {
            return RetryResult.builder()
                    .scheduled(true)
                    .message("重试已调度")
                    .nextRetryTime(nextRetryTime)
                    .attemptNumber(attemptNumber)
                    .build();
        }
        
        public static RetryResult exhausted(String reason) {
            return RetryResult.builder()
                    .scheduled(false)
                    .message(reason)
                    .build();
        }
        
        public static RetryResult failed(String error) {
            return RetryResult.builder()
                    .scheduled(false)
                    .message("重试失败: " + error)
                    .build();
        }
    }
    
    /**
     * 限流器状态
     */
    @lombok.Data
    @lombok.Builder
    public static class RateLimiterStatus {
        private final AIProviderEnum provider;
        private final String strategyName;
        private final double effectiveRate;
        private final int effectiveBurstCapacity;
        private final int availablePermits;
        private final int retryCount;
        private final java.util.concurrent.ConcurrentHashMap<String, Object> metrics;
        
        public static RateLimiterStatus notFound() {
            return RateLimiterStatus.builder()
                    .strategyName("NOT_FOUND")
                    .build();
        }
    }
} 