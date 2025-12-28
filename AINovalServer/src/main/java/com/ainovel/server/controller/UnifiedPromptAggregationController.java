package com.ainovel.server.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.UnifiedPromptAggregationService;
import com.ainovel.server.service.prompt.impl.VirtualThreadPlaceholderResolver;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * 统一提示词聚合API控制器
 * 为前端提供一站式的提示词获取和缓存接口
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/prompt-aggregation")
@Tag(name = "提示词聚合", description = "统一的前端提示词聚合接口")
public class UnifiedPromptAggregationController {

    @Autowired
    private UnifiedPromptAggregationService aggregationService;
    
    @Autowired
    private VirtualThreadPlaceholderResolver virtualThreadResolver;

    /**
     * 获取功能的完整提示词包
     * 包含系统默认、用户自定义、公开模板、最近使用等全部信息
     */
    @GetMapping("/package/{featureType}")
    @Operation(summary = "获取完整提示词包", description = "一次性获取功能的所有提示词信息，便于前端缓存")
    public Mono<ApiResponse<UnifiedPromptAggregationService.PromptPackage>> getCompletePromptPackage(
            @PathVariable AIFeatureType featureType,
            @RequestParam(defaultValue = "true") boolean includePublic,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("前端请求完整提示词包: featureType={}, userId={}, includePublic={}", 
                featureType, userId, includePublic);
        
        return aggregationService.getCompletePromptPackage(featureType, userId, includePublic)
                .map(promptPackage -> {
                    log.info("返回提示词包: featureType={}, 用户模板数={}, 公开模板数={}, 占位符数={}", 
                            featureType, 
                            promptPackage.getUserPrompts().size(),
                            promptPackage.getPublicPrompts().size(),
                            promptPackage.getSupportedPlaceholders().size());
                    
                    return ApiResponse.success(promptPackage);
                })
                .onErrorResume(error -> {
                    log.error("获取提示词包失败: featureType={}, error={}", featureType, error.getMessage());
                    return Mono.just(ApiResponse.error("获取提示词包失败: " + error.getMessage()));
                });
    }

    /**
     * 获取用户的提示词概览
     * 跨功能统计信息，用于用户Dashboard
     */
    @GetMapping("/overview")
    @Operation(summary = "获取用户提示词概览", description = "获取用户的跨功能提示词统计信息")
    public Mono<ApiResponse<UnifiedPromptAggregationService.UserPromptOverview>> getUserPromptOverview(
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("前端请求用户提示词概览: userId={}", userId);
        
        return aggregationService.getUserPromptOverview(userId)
                .map(overview -> {
                    log.info("返回用户概览: userId={}, 总使用次数={}, 功能数={}, 收藏数={}", 
                            userId, 
                            overview.getTotalUsageCount(),
                            overview.getPromptCountsByFeature().size(),
                            overview.getFavoritePrompts().size());
                    
                    return ApiResponse.success(overview);
                })
                .onErrorResume(error -> {
                    log.error("获取用户概览失败: userId={}, error={}", userId, error.getMessage());
                    return Mono.just(ApiResponse.error("获取用户概览失败: " + error.getMessage()));
                });
    }

    /**
     * 批量获取多个功能的提示词包
     * 用于前端初始化时一次性获取所有需要的数据
     */
    @GetMapping("/packages/batch")
    @Operation(summary = "批量获取提示词包", description = "一次性获取多个功能的提示词包，减少网络请求")
    public Mono<ApiResponse<Map<AIFeatureType, UnifiedPromptAggregationService.PromptPackage>>> getBatchPromptPackages(
            @RequestParam(required = false) AIFeatureType[] featureTypes,
            @RequestParam(defaultValue = "true") boolean includePublic,
            @RequestHeader("X-User-Id") String userId) {
        
        AIFeatureType[] targetTypes = featureTypes != null ? featureTypes : AIFeatureType.values();
        
        log.info("🚀 前端请求批量提示词包: userId={}, 功能数={}, includePublic={}", 
                userId, targetTypes.length, includePublic);
        
        return reactor.core.publisher.Flux.fromArray(targetTypes)
                .flatMap(featureType -> 
                    aggregationService.getCompletePromptPackage(featureType, userId, includePublic)
                            .map(pkg -> {
                                // 详细记录每个功能包的信息
                                log.info("📦 功能包详情: featureType={}, 用户模板数={}, 公开模板数={}", 
                                        featureType, pkg.getUserPrompts().size(), pkg.getPublicPrompts().size());
                                
                                // 记录用户模板中的默认模板信息
                                long defaultCount = pkg.getUserPrompts().stream()
                                        .filter(p -> p.isDefault())
                                        .count();
                                log.info("🌟 功能包默认模板: featureType={}, 默认模板数={}", featureType, defaultCount);
                                
                                if (defaultCount > 0) {
                                    pkg.getUserPrompts().stream()
                                            .filter(p -> p.isDefault())
                                            .forEach(p -> log.info("   ⭐ 默认模板: id={}, name={}", p.getId(), p.getName()));
                                }
                                
                                return Map.entry(featureType, pkg);
                            })
                            .onErrorResume(error -> {
                                log.warn("功能包获取失败: featureType={}, error={}", featureType, error.getMessage());
                                return Mono.empty(); // 跳过失败的功能
                            })
                )
                .collectMap(Map.Entry::getKey, Map.Entry::getValue)
                .map(packagesMap -> {
                    log.info("✅ 返回批量提示词包: userId={}, 成功获取功能数={}", userId, packagesMap.size());
                    
                    // 统计所有功能包的默认模板总数
                    int totalDefaultCount = packagesMap.values().stream()
                            .mapToInt(pkg -> (int) pkg.getUserPrompts().stream()
                                    .filter(p -> p.isDefault())
                                    .count())
                            .sum();
                    log.info("📈 总体统计: 所有功能包默认模板总数={}", totalDefaultCount);
                    
                    return ApiResponse.success(packagesMap);
                })
                .onErrorResume(error -> {
                    log.error("❌ 批量获取提示词包失败: userId={}, error={}", userId, error.getMessage());
                    return Mono.just(ApiResponse.error("批量获取失败: " + error.getMessage()));
                });
    }

    /**
     * 预热用户缓存
     * 系统启动或用户登录时调用，提升后续响应速度
     */
    @PostMapping("/cache/warmup")
    @Operation(summary = "预热提示词缓存", description = "预热用户的提示词缓存，提升后续访问速度")
    public Mono<ApiResponse<UnifiedPromptAggregationService.CacheWarmupResult>> warmupCache(
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("前端请求缓存预热: userId={}", userId);
        
        return aggregationService.warmupCache(userId)
                .map(result -> {
                    log.info("缓存预热完成: userId={}, 成功={}, 耗时={}ms, 预热功能数={}", 
                            userId, result.isSuccess(), result.getDuration(), result.getWarmedFeatures());
                    
                    return ApiResponse.success(result);
                })
                .onErrorResume(error -> {
                    log.error("缓存预热失败: userId={}, error={}", userId, error.getMessage());
                    return Mono.just(ApiResponse.error("缓存预热失败: " + error.getMessage()));
                });
    }

    /**
     * 获取系统缓存统计
     * 用于系统监控和性能分析
     */
    @GetMapping("/cache/stats")
    @Operation(summary = "获取缓存统计", description = "获取聚合服务的缓存统计信息")
    public Mono<ApiResponse<UnifiedPromptAggregationService.AggregationCacheStats>> getCacheStats() {
        
        log.info("前端请求缓存统计");
        
        return aggregationService.getCacheStats()
                .map(stats -> {
                    log.info("返回缓存统计: 缓存大小={}, 缓存键数量={}", 
                            stats.getTotalCacheSize(), stats.getCacheHitCounts().size());
                    
                    return ApiResponse.success(stats);
                })
                .onErrorResume(error -> {
                    log.error("获取缓存统计失败: error={}", error.getMessage());
                    return Mono.just(ApiResponse.error("获取缓存统计失败: " + error.getMessage()));
                });
    }

    /**
     * 获取虚拟线程性能统计
     * 用于监控占位符解析性能
     */
    @GetMapping("/performance/placeholder")
    @Operation(summary = "获取占位符性能统计", description = "获取虚拟线程占位符解析的性能统计")
    public Mono<ApiResponse<VirtualThreadPlaceholderResolver.PlaceholderPerformanceStats>> getPlaceholderPerformanceStats() {
        
        log.info("前端请求占位符性能统计");
        
        return virtualThreadResolver.getPerformanceStats()
                .map(stats -> {
                    log.info("返回占位符性能统计: 总解析次数={}, 并行解析次数={}, 平均耗时={}ms", 
                            stats.getTotalResolveCount(), stats.getParallelResolveCount(), stats.getAverageResolveTime());
                    
                    return ApiResponse.success(stats);
                })
                .onErrorResume(error -> {
                    log.error("获取占位符性能统计失败: error={}", error.getMessage());
                    return Mono.just(ApiResponse.error("获取性能统计失败: " + error.getMessage()));
                });
    }

    /**
     * 清除提示词聚合缓存
     * 用于调试和强制刷新缓存
     */
    @PostMapping("/cache/clear")
    @Operation(summary = "清除聚合缓存", description = "清除所有提示词聚合缓存，强制重新加载数据")
    public Mono<ApiResponse<String>> clearCache(
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("前端请求清除聚合缓存: userId={}", userId);
        
        return aggregationService.clearAllCaches()
                .map(result -> {
                    log.info("缓存清除完成: userId={}, result={}", userId, result);
                    return ApiResponse.success(result);
                })
                .onErrorResume(error -> {
                    log.error("清除缓存失败: userId={}, error={}", userId, error.getMessage());
                    return Mono.just(ApiResponse.error("清除缓存失败: " + error.getMessage()));
                });
    }

    /**
     * 健康检查接口
     * 检查聚合服务是否正常工作
     */
    @GetMapping("/health")
    @Operation(summary = "聚合服务健康检查", description = "检查提示词聚合服务的健康状态")
    public Mono<ApiResponse<Map<String, Object>>> healthCheck() {
        
        return Mono.fromCallable(() -> {
            Map<String, Object> health = Map.of(
                    "status", "UP",
                    "timestamp", System.currentTimeMillis(),
                    "service", "UnifiedPromptAggregationService",
                    "version", "1.0"
            );
            
            log.info("聚合服务健康检查: status=UP");
            return ApiResponse.success(health);
        })
        .onErrorReturn(ApiResponse.error("聚合服务不可用"));
    }
} 