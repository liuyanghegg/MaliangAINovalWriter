package com.ainovel.server.task.service.factory;

import com.ainovel.server.config.RateLimitStrategyEnum;
import com.ainovel.server.task.service.strategy.IRateLimitStrategy;
import com.ainovel.server.task.service.strategy.impl.ConservativeRateLimitStrategy;
import com.ainovel.server.task.service.strategy.impl.StandardRateLimitStrategy;
import com.ainovel.server.task.service.strategy.impl.AggressiveRateLimitStrategy;
import com.ainovel.server.task.service.strategy.impl.AdaptiveRateLimitStrategy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.concurrent.ConcurrentHashMap;

/**
 * 限流策略工厂
 * 根据策略枚举创建对应的限流策略实例
 * 
 * 重构说明：
 * 1. 移除内部类实现，改为注入独立的策略类
 * 2. 使用Spring依赖注入管理策略实例
 * 3. 提供策略缓存机制，确保单例使用
 * 4. 简化工厂职责，专注于策略创建和管理
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RateLimitStrategyFactory {
    
    // 注入各种策略实现
    private final ConservativeRateLimitStrategy conservativeStrategy;
    private final StandardRateLimitStrategy standardStrategy;
    private final AggressiveRateLimitStrategy aggressiveStrategy;
    private final AdaptiveRateLimitStrategy adaptiveStrategy;
    
    // 策略实例缓存 - 确保单例
    private final ConcurrentHashMap<RateLimitStrategyEnum, IRateLimitStrategy> strategyCache = new ConcurrentHashMap<>();
    
    /**
     * 根据策略枚举获取限流策略
     * 
     * @param strategyEnum 策略枚举
     * @return 限流策略实例
     */
    public IRateLimitStrategy getStrategy(RateLimitStrategyEnum strategyEnum) {
        return strategyCache.computeIfAbsent(strategyEnum, this::createStrategy);
    }
    
    /**
     * 创建策略实例
     * 
     * @param strategyEnum 策略枚举
     * @return 策略实例
     */
    private IRateLimitStrategy createStrategy(RateLimitStrategyEnum strategyEnum) {
        switch (strategyEnum) {
            case CONSERVATIVE:
                log.debug("获取保守限流策略实例");
                return conservativeStrategy;
                
            case STANDARD:
                log.debug("获取标准限流策略实例");
                return standardStrategy;
                
            case AGGRESSIVE:
                log.debug("获取激进限流策略实例");
                return aggressiveStrategy;
                
            case ADAPTIVE:
                log.debug("获取自适应限流策略实例");
                return adaptiveStrategy;
                
            default:
                log.warn("未知的限流策略: {}, 使用保守策略作为默认", strategyEnum);
                return conservativeStrategy;
        }
    }
    
    /**
     * 获取所有可用的策略
     * 
     * @return 策略信息
     */
    public java.util.Map<String, String> getAllStrategies() {
        java.util.Map<String, String> strategies = new java.util.HashMap<>();
        
        for (RateLimitStrategyEnum strategy : RateLimitStrategyEnum.values()) {
            IRateLimitStrategy impl = getStrategy(strategy);
            strategies.put(strategy.name(), impl.getStrategyName());
        }
        
        return strategies;
    }
    
    /**
     * 清理策略缓存
     * 主要用于测试或特殊情况下的重置
     */
    public void clearCache() {
        strategyCache.clear();
        log.info("限流策略缓存已清理");
    }
    
    /**
     * 获取缓存状态信息
     * 
     * @return 缓存状态
     */
    public java.util.Map<String, Object> getCacheStatus() {
        java.util.Map<String, Object> status = new java.util.HashMap<>();
        status.put("cachedStrategies", strategyCache.size());
        status.put("availableStrategies", RateLimitStrategyEnum.values().length);
        status.put("cacheKeys", strategyCache.keySet().toString());
        
        return status;
    }
} 