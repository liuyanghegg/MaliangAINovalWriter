package com.ainovel.server.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.util.HashMap;
import java.util.Map;

/**
 * 限流配置管理器
 * 统一管理不同维度和策略的限流配置
 * 
 * 配置层次：
 * 1. 全局默认配置
 * 2. 供应商特定配置
 * 3. 任务类型特定配置
 * 4. 动态运行时配置
 */
@Slf4j
@Component
@ConfigurationProperties(prefix = "task.ratelimiter")
@RequiredArgsConstructor
public class RateLimitConfigurationManager {
    
    // 维度配置映射
    private Map<String, RateLimitDimensionEnum> dimensions = new HashMap<>();
    
    // 默认配置
    private DefaultConfig defaultConfig = new DefaultConfig();
    
    // 供应商配置
    private Map<String, ProviderConfig> providers = new HashMap<>();
    
    // 任务类型配置
    private Map<String, TaskConfig> tasks = new HashMap<>();
    
    @PostConstruct
    public void init() {
        log.info("初始化限流配置管理器");
        
        // 设置默认维度配置
        if (dimensions.isEmpty()) {
            dimensions.put("default", RateLimitDimensionEnum.USER_PROVIDER_MODEL);
            dimensions.put("gemini", RateLimitDimensionEnum.GLOBAL);
            dimensions.put("sensitive_tasks", RateLimitDimensionEnum.HYBRID);
            dimensions.put("high_performance", RateLimitDimensionEnum.PROVIDER_MODEL);
        }
        
        // 验证配置
        validateConfiguration();
        
        log.info("限流配置管理器初始化完成: 维度={}, 供应商={}, 任务={}", 
                dimensions.size(), providers.size(), tasks.size());
    }
    
    /**
     * 创建供应商特定的限流配置
     */
    public ProviderRateLimitConfig createProviderConfig(AIProviderEnum provider, String userId, 
                                                       String modelName, String taskType) {
        // 1. 获取供应商特定配置
        ProviderConfig providerConfig = providers.get(provider.getCode().toLowerCase());
        if (providerConfig == null) {
            log.debug("未找到供应商{}的特定配置，使用默认配置", provider.getCode());
            providerConfig = createDefaultProviderConfig();
        }
        
        // 2. 获取任务类型配置
        TaskConfig taskConfig = tasks.get(taskType);
        
        // 3. 合并配置优先级：任务配置 > 供应商配置 > 默认配置
        ProviderRateLimitConfig config = ProviderRateLimitConfig.builder()
                .provider(provider)
                .rateLimitStrategy(determineStrategy(providerConfig, taskConfig))
                .retryStrategy(determineRetryStrategy(providerConfig, taskConfig))
                .dimension(determineDimension(provider, taskType, providerConfig, taskConfig))
                .userId(userId)
                .modelName(modelName)
                .taskType(taskType)
                .build();
        
        // 动态设置运行时参数
        config.getCurrentRate().set(determineRate(providerConfig, taskConfig));
        config.getCurrentBurstCapacity().set(determineBurstCapacity(providerConfig, taskConfig));
        
        // 设置监控指标
        config.updateMetrics("maxRetryAttempts", determineMaxRetryAttempts(providerConfig, taskConfig));
        config.updateMetrics("timeoutMillis", determineTimeoutMillis(providerConfig, taskConfig));
        // 注入日限额和安全缓冲配置，供限流策略动态读取
        if (providerConfig.getDailyLimit() != null) {
            config.updateMetrics("dailyLimit", providerConfig.getDailyLimit());
        }
        if (providerConfig.getSafetyBuffer() != null) {
            config.updateMetrics("safetyBuffer", providerConfig.getSafetyBuffer());
        }
        
        return config;
    }
    
    /**
     * 确定限流维度
     */
    private RateLimitDimensionEnum determineDimension(AIProviderEnum provider, String taskType,
                                                     ProviderConfig providerConfig, TaskConfig taskConfig) {
        // 任务配置优先
        if (taskConfig != null && taskConfig.getDimension() != null) {
            return taskConfig.getDimension();
        }
        
        // 供应商配置次之
        if (providerConfig.getDimension() != null) {
            return providerConfig.getDimension();
        }
        
        // 特殊规则：Gemini使用全局维度
        if (provider == AIProviderEnum.GEMINI) {
            return RateLimitDimensionEnum.GLOBAL;
        }
        
        // 默认配置
        return dimensions.getOrDefault("default", RateLimitDimensionEnum.USER_PROVIDER_MODEL);
    }
    
    /**
     * 确定限流策略
     */
    private RateLimitStrategyEnum determineStrategy(ProviderConfig providerConfig, TaskConfig taskConfig) {
        if (taskConfig != null && taskConfig.getStrategy() != null) {
            return taskConfig.getStrategy();
        }
        
        if (providerConfig.getStrategy() != null) {
            return providerConfig.getStrategy();
        }
        
        return RateLimitStrategyEnum.STANDARD;
    }
    
    /**
     * 确定重试策略
     */
    private RetryStrategyEnum determineRetryStrategy(ProviderConfig providerConfig, TaskConfig taskConfig) {
        if (taskConfig != null && taskConfig.getRetryStrategy() != null) {
            return taskConfig.getRetryStrategy();
        }
        
        if (providerConfig.getRetryStrategy() != null) {
            return providerConfig.getRetryStrategy();
        }
        
        return RetryStrategyEnum.LINEAR_BACKOFF;
    }
    
    /**
     * 确定速率限制
     */
    private double determineRate(ProviderConfig providerConfig, TaskConfig taskConfig) {
        if (taskConfig != null && taskConfig.getRate() != null) {
            return taskConfig.getRate();
        }
        
        if (providerConfig.getRate() != null) {
            return providerConfig.getRate();
        }
        
        return defaultConfig.getRate();
    }
    
    /**
     * 确定突发容量
     */
    private int determineBurstCapacity(ProviderConfig providerConfig, TaskConfig taskConfig) {
        if (taskConfig != null && taskConfig.getBurstCapacity() != null) {
            return taskConfig.getBurstCapacity();
        }
        
        if (providerConfig.getBurstCapacity() != null) {
            return providerConfig.getBurstCapacity();
        }
        
        return defaultConfig.getBurstCapacity();
    }
    
    /**
     * 确定最大重试次数
     */
    private int determineMaxRetryAttempts(ProviderConfig providerConfig, TaskConfig taskConfig) {
        if (taskConfig != null && taskConfig.getMaxRetryAttempts() != null) {
            return taskConfig.getMaxRetryAttempts();
        }
        
        if (providerConfig.getMaxRetryAttempts() != null) {
            return providerConfig.getMaxRetryAttempts();
        }
        
        return 3;
    }
    
    /**
     * 确定超时时间
     */
    private long determineTimeoutMillis(ProviderConfig providerConfig, TaskConfig taskConfig) {
        if (taskConfig != null && taskConfig.getDefaultTimeoutMillis() != null) {
            return taskConfig.getDefaultTimeoutMillis();
        }
        
        if (providerConfig.getDefaultTimeoutMillis() != null) {
            return providerConfig.getDefaultTimeoutMillis();
        }
        
        return defaultConfig.getDefaultTimeoutMillis();
    }
    
    /**
     * 创建默认供应商配置
     */
    private ProviderConfig createDefaultProviderConfig() {
        ProviderConfig config = new ProviderConfig();
        config.setStrategy(RateLimitStrategyEnum.STANDARD);
        config.setDimension(RateLimitDimensionEnum.USER_PROVIDER_MODEL);
        config.setRate(defaultConfig.getRate());
        config.setBurstCapacity(defaultConfig.getBurstCapacity());
        config.setRetryStrategy(RetryStrategyEnum.LINEAR_BACKOFF);
        config.setMaxRetryAttempts(3);
        config.setDefaultTimeoutMillis(defaultConfig.getDefaultTimeoutMillis());
        return config;
    }
    
    /**
     * 验证配置
     */
    private void validateConfiguration() {
        // 验证维度配置
        for (Map.Entry<String, RateLimitDimensionEnum> entry : dimensions.entrySet()) {
            if (entry.getValue() == null) {
                log.warn("维度配置{}的值为null，将使用默认值", entry.getKey());
                entry.setValue(RateLimitDimensionEnum.USER_PROVIDER_MODEL);
            }
        }
        
        // 验证供应商配置
        for (Map.Entry<String, ProviderConfig> entry : providers.entrySet()) {
            ProviderConfig config = entry.getValue();
            if (config.getRate() != null && config.getRate() <= 0) {
                log.warn("供应商{}的速率配置无效: {}", entry.getKey(), config.getRate());
            }
        }
    }
    
    /**
     * 获取配置摘要
     */
    public Map<String, Object> getConfigurationSummary() {
        Map<String, Object> summary = new HashMap<>();
        summary.put("dimensions", dimensions.size());
        summary.put("providers", providers.size());
        summary.put("tasks", tasks.size());
        summary.put("defaultRate", defaultConfig.getRate());
        summary.put("defaultBurstCapacity", defaultConfig.getBurstCapacity());
        return summary;
    }
    
    // Getters and Setters
    
    public Map<String, RateLimitDimensionEnum> getDimensions() {
        return dimensions;
    }
    
    public void setDimensions(Map<String, RateLimitDimensionEnum> dimensions) {
        this.dimensions = dimensions;
    }
    
    public DefaultConfig getDefaultConfig() {
        return defaultConfig;
    }
    
    public void setDefaultConfig(DefaultConfig defaultConfig) {
        this.defaultConfig = defaultConfig;
    }
    
    public Map<String, ProviderConfig> getProviders() {
        return providers;
    }
    
    public void setProviders(Map<String, ProviderConfig> providers) {
        this.providers = providers;
    }
    
    public Map<String, TaskConfig> getTasks() {
        return tasks;
    }
    
    public void setTasks(Map<String, TaskConfig> tasks) {
        this.tasks = tasks;
    }
    
    /**
     * 默认配置
     */
    @lombok.Data
    public static class DefaultConfig {
        private double rate = 10.0;
        private int burstCapacity = 20;
        private long defaultTimeoutMillis = 5000;
        private RateLimitDimensionEnum dimension = RateLimitDimensionEnum.USER_PROVIDER_MODEL;
    }
    
    /**
     * 供应商配置
     */
    @lombok.Data
    public static class ProviderConfig {
        private RateLimitStrategyEnum strategy;
        private RateLimitDimensionEnum dimension;
        private Double rate;
        private Integer burstCapacity;
        private RetryStrategyEnum retryStrategy;
        private Integer maxRetryAttempts;
        private Long defaultTimeoutMillis;
        private Integer dailyLimit;
        private Integer safetyBuffer;
    }
    
    /**
     * 任务配置
     */
    @lombok.Data
    public static class TaskConfig {
        private RateLimitStrategyEnum strategy;
        private RateLimitDimensionEnum dimension;
        private Double rate;
        private Integer burstCapacity;
        private RetryStrategyEnum retryStrategy;
        private Integer maxRetryAttempts;
        private Long defaultTimeoutMillis;
    }
} 