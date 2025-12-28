package com.ainovel.server.controller;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.dto.PresetPackage;
import com.ainovel.server.service.UnifiedPresetAggregationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.Arrays;
import java.util.Map;

/**
 * 统一预设聚合API控制器
 * 为前端提供一站式的预设获取和缓存接口
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/preset-aggregation")
@Tag(name = "预设聚合", description = "统一的前端预设聚合接口")
public class UnifiedPresetAggregationController {

    @Autowired
    private UnifiedPresetAggregationService aggregationService;

    /**
     * 获取功能的完整预设包
     * 包含系统预设、用户预设、快捷访问预设等全部信息
     */
    @GetMapping("/package/{featureType}")
    @Operation(summary = "获取完整预设包", description = "一次性获取功能的所有预设信息，便于前端缓存")
    public Mono<ApiResponse<PresetPackage>> getCompletePresetPackage(
            @PathVariable AIFeatureType featureType,
            @RequestParam(required = false) String novelId,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("前端请求完整预设包: featureType={}, userId={}, novelId={}", 
                featureType, userId, novelId);
        
        return aggregationService.getCompletePresetPackage(featureType, userId, novelId)
                .map(presetPackage -> {
                    log.info("返回预设包: featureType={}, 系统预设数={}, 用户预设数={}, 快捷访问数={}", 
                            featureType, 
                            presetPackage.getSystemPresets().size(),
                            presetPackage.getUserPresets().size(),
                            presetPackage.getQuickAccessPresets().size());
                    
                    return ApiResponse.success(presetPackage);
                })
                .onErrorResume(error -> {
                    log.error("获取预设包失败: featureType={}, error={}", featureType, error.getMessage());
                    return Mono.just(ApiResponse.error("获取预设包失败: " + error.getMessage()));
                });
    }

    /**
     * 获取用户的预设概览
     * 跨功能统计信息，用于用户Dashboard
     */
    @GetMapping("/overview")
    @Operation(summary = "获取用户预设概览", description = "获取用户的跨功能预设统计信息")
    public Mono<ApiResponse<UnifiedPresetAggregationService.UserPresetOverview>> getUserPresetOverview(
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("前端请求用户预设概览: userId={}", userId);
        
        return aggregationService.getUserPresetOverview(userId)
                .map(overview -> {
                    log.info("返回用户概览: userId={}, 总预设数={}, 功能数={}, 快捷访问数={}", 
                            userId, 
                            overview.getTotalPresetCount(),
                            overview.getPresetCountsByFeature().size(),
                            overview.getQuickAccessPresetCount());
                    
                    return ApiResponse.success(overview);
                })
                .onErrorResume(error -> {
                    log.error("获取用户概览失败: userId={}, error={}", userId, error.getMessage());
                    return Mono.just(ApiResponse.error("获取用户概览失败: " + error.getMessage()));
                });
    }

    /**
     * 批量获取多个功能的预设包
     * 用于前端初始化时一次性获取所有需要的数据
     */
    @GetMapping("/packages/batch")
    @Operation(summary = "批量获取预设包", description = "一次性获取多个功能的预设包，减少网络请求")
    public Mono<ApiResponse<Map<AIFeatureType, PresetPackage>>> getBatchPresetPackages(
            @RequestParam(required = false) AIFeatureType[] featureTypes,
            @RequestParam(required = false) String novelId,
            @RequestHeader("X-User-Id") String userId) {
        
        AIFeatureType[] targetTypes = featureTypes != null ? featureTypes : AIFeatureType.values();
        
        log.info("🚀 前端请求批量预设包: userId={}, 功能数={}, novelId={}", 
                userId, targetTypes.length, novelId);
        
        return aggregationService.getBatchPresetPackages(Arrays.asList(targetTypes), userId, novelId)
                .map(packagesMap -> {
                    log.info("✅ 返回批量预设包: userId={}, 成功获取功能数={}", userId, packagesMap.size());
                    
                    // 统计所有功能包的系统预设总数
                    int totalSystemCount = packagesMap.values().stream()
                            .mapToInt(pkg -> pkg.getSystemPresets().size())
                            .sum();
                    
                    // 统计所有功能包的快捷访问预设总数
                    int totalQuickAccessCount = packagesMap.values().stream()
                            .mapToInt(pkg -> pkg.getQuickAccessPresets().size())
                            .sum();
                    
                    log.info("📈 总体统计: 系统预设总数={}, 快捷访问预设总数={}", totalSystemCount, totalQuickAccessCount);
                    
                    return ApiResponse.success(packagesMap);
                })
                .onErrorResume(error -> {
                    log.error("❌ 批量获取预设包失败: userId={}, error={}", userId, error.getMessage());
                    return Mono.just(ApiResponse.error("批量获取失败: " + error.getMessage()));
                });
    }

    /**
     * 预热用户缓存
     * 系统启动或用户登录时调用，提升后续响应速度
     */
    @PostMapping("/cache/warmup")
    @Operation(summary = "预热预设缓存", description = "预热用户的预设缓存，提升后续访问速度")
    public Mono<ApiResponse<UnifiedPresetAggregationService.CacheWarmupResult>> warmupCache(
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
    public Mono<ApiResponse<UnifiedPresetAggregationService.AggregationCacheStats>> getCacheStats() {
        
        log.info("前端请求缓存统计");
        
        return aggregationService.getCacheStats()
                .map(stats -> {
                    log.info("返回缓存统计: 缓存大小={}, 总请求数={}, 命中率={}%", 
                            stats.getTotalCacheSize(), stats.getTotalRequests(), stats.getHitRate());
                    
                    return ApiResponse.success(stats);
                })
                .onErrorResume(error -> {
                    log.error("获取缓存统计失败: error={}", error.getMessage());
                    return Mono.just(ApiResponse.error("获取缓存统计失败: " + error.getMessage()));
                });
    }

    /**
     * 清除预设聚合缓存
     * 用于调试和强制刷新缓存
     */
    @PostMapping("/cache/clear")
    @Operation(summary = "清除聚合缓存", description = "清除所有预设聚合缓存，强制重新加载数据")
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
     * 🚀 获取用户的所有预设聚合数据
     * 一次性返回用户的所有预设相关数据，避免多次API调用
     */
    @GetMapping("/all-data")
    @Operation(summary = "获取所有预设聚合数据", description = "一次性获取用户的所有预设相关数据，用于前端缓存")
    public Mono<ApiResponse<UnifiedPresetAggregationService.AllUserPresetData>> getAllUserPresetData(
            @RequestParam(required = false) String novelId,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("🚀 前端请求所有预设聚合数据: userId={}, novelId={}", userId, novelId);
        
        return aggregationService.getAllUserPresetData(userId, novelId)
                .map(allData -> {
                    log.info("✅ 返回完整预设聚合数据: userId={}, 耗时={}ms", userId, allData.getCacheDuration());
                    log.info("📊 数据概览: 概览统计={}, 功能包数={}, 系统预设{}个, 用户预设分组{}个", 
                            allData.getOverview() != null ? "已包含" : "未包含",
                            allData.getPackagesByFeatureType().size(),
                            allData.getSystemPresets().size(),
                            allData.getUserPresetsByFeatureType().size());
                    
                    return ApiResponse.success(allData);
                })
                .onErrorResume(error -> {
                    log.error("❌ 获取所有预设聚合数据失败: userId={}, error={}", userId, error.getMessage());
                    return Mono.just(ApiResponse.error("获取聚合数据失败: " + error.getMessage()));
                });
    }

    /**
     * 健康检查接口
     * 检查聚合服务是否正常工作
     */
    @GetMapping("/health")
    @Operation(summary = "聚合服务健康检查", description = "检查预设聚合服务的健康状态")
    public Mono<ApiResponse<Map<String, Object>>> healthCheck() {
        
        return Mono.fromCallable(() -> {
            Map<String, Object> health = Map.of(
                    "status", "UP",
                    "timestamp", System.currentTimeMillis(),
                    "service", "UnifiedPresetAggregationService",
                    "version", "1.0"
            );
            
            log.info("预设聚合服务健康检查: status=UP");
            return ApiResponse.success(health);
        })
        .onErrorReturn(ApiResponse.error("聚合服务不可用"));
    }
}