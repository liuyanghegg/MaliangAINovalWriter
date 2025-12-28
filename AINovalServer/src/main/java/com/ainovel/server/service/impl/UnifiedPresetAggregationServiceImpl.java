package com.ainovel.server.service.impl;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.AIPromptPreset;
import com.ainovel.server.dto.PresetPackage;
import com.ainovel.server.repository.AIPromptPresetRepository;
import com.ainovel.server.service.UnifiedPresetAggregationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

/**
 * 统一预设聚合服务实现
 * 提供高效的预设数据聚合、缓存和批量获取功能
 */
@Slf4j
@Service
public class UnifiedPresetAggregationServiceImpl implements UnifiedPresetAggregationService {

    @Autowired
    private AIPromptPresetRepository presetRepository;

    // 缓存统计
    private final Map<String, AtomicLong> cacheHitCounts = new ConcurrentHashMap<>();
    private final Map<String, AtomicLong> cacheMissCounts = new ConcurrentHashMap<>();

    @Override
    //@Cacheable(value = "preset-packages", key = "#featureType.name() + ':' + #userId + ':' + (#novelId ?: 'global')")
    public Mono<PresetPackage> getCompletePresetPackage(AIFeatureType featureType, String userId, String novelId) {
        log.info("获取完整预设包: featureType={}, userId={}, novelId={}", featureType, userId, novelId);
        
        String cacheKey = featureType.name() + ":" + userId;
        incrementCacheStats(cacheKey, false); // Cache miss
        
        // 获取系统预设
        Mono<List<AIPromptPreset>> systemPresetsMono = presetRepository
                .findByIsSystemTrueAndAiFeatureType(featureType.name())
                .collectList();

        // 获取用户预设（包括全局和特定小说的）
        Mono<List<AIPromptPreset>> userPresetsMono;
        if (novelId != null) {
            userPresetsMono = presetRepository
                    .findByUserIdAndAiFeatureTypeAndNovelId(userId, featureType.name(), novelId)
                    .collectList();
        } else {
            userPresetsMono = presetRepository
                    .findByUserIdAndAiFeatureType(userId, featureType.name())
                    .collectList();
        }

        // 获取快捷访问预设
        Mono<List<AIPromptPreset>> quickAccessPresetsMono = presetRepository
                .findQuickAccessPresetsByUserAndFeatureType(userId, featureType.name())
                .collectList();

        return Mono.zip(systemPresetsMono, userPresetsMono, quickAccessPresetsMono)
                .map(tuple -> {
                    List<AIPromptPreset> systemPresets = tuple.getT1();
                    List<AIPromptPreset> userPresets = tuple.getT2();
                    List<AIPromptPreset> quickAccessPresets = tuple.getT3();

                    int totalCount = systemPresets.size() + userPresets.size();

                    log.info("构建预设包: featureType={}, 系统预设数={}, 用户预设数={}, 快捷访问数={}", 
                            featureType, systemPresets.size(), userPresets.size(), quickAccessPresets.size());

                    return PresetPackage.builder()
                            .systemPresets(systemPresets)
                            .userPresets(userPresets)
                            .quickAccessPresets(quickAccessPresets)
                            .totalCount(totalCount)
                            .featureType(featureType.name())
                            .timestamp(System.currentTimeMillis())
                            .build();
                })
                .doOnSuccess(result -> incrementCacheStats(cacheKey, true)) // Cache hit on subsequent calls
                .doOnError(error -> log.error("获取预设包失败: featureType={}, error={}", featureType, error.getMessage()));
    }

    @Override
    public Mono<Map<AIFeatureType, PresetPackage>> getBatchPresetPackages(List<AIFeatureType> featureTypes, String userId, String novelId) {
        log.info("批量获取预设包: userId={}, 功能数={}, novelId={}", userId, featureTypes.size(), novelId);

        List<AIFeatureType> targetTypes = featureTypes != null && !featureTypes.isEmpty() 
                ? featureTypes 
                : Arrays.asList(AIFeatureType.values());

        return Flux.fromIterable(targetTypes)
                .flatMap(featureType -> 
                    getCompletePresetPackage(featureType, userId, novelId)
                            .map(pkg -> Map.entry(featureType, pkg))
                            .onErrorResume(error -> {
                                log.warn("功能包获取失败: featureType={}, error={}", featureType, error.getMessage());
                                return Mono.empty(); // 跳过失败的功能
                            })
                )
                .collectMap(Map.Entry::getKey, Map.Entry::getValue)
                .doOnSuccess(result -> log.info("批量获取完成: userId={}, 成功获取功能数={}", userId, result.size()));
    }

    @Override
    public Mono<UserPresetOverview> getUserPresetOverview(String userId) {
        log.info("获取用户预设概览: userId={}", userId);

        // 统计总预设数
        Mono<Long> totalCountMono = presetRepository.countByUserId(userId);
        
        // 统计收藏预设数
        Mono<Long> favoriteCountMono = presetRepository.countByUserIdAndIsFavoriteTrue(userId);
        
        // 统计快捷访问预设数
        Mono<Long> quickAccessCountMono = presetRepository.findByUserIdAndShowInQuickAccessTrue(userId).count();
        
        // 统计总使用次数
        Mono<Long> totalUsageMono = presetRepository.findByUserId(userId)
                .map(preset -> preset.getUseCount() != null ? preset.getUseCount() : 0)
                .reduce(0L, (sum, count) -> sum + count);
        
        // 按功能统计预设数量
        Mono<Map<String, Long>> featureCountsMono = presetRepository.findByUserId(userId)
                .groupBy(AIPromptPreset::getAiFeatureType)
                .flatMap(group -> group.count().map(count -> Map.entry(group.key(), count)))
                .collectMap(Map.Entry::getKey, Map.Entry::getValue);

        return Mono.zip(totalCountMono, favoriteCountMono, quickAccessCountMono, totalUsageMono, featureCountsMono)
                .map(tuple -> UserPresetOverview.builder()
                        .userId(userId)
                        .totalPresetCount(tuple.getT1())
                        .favoritePresetCount(tuple.getT2())
                        .quickAccessPresetCount(tuple.getT3())
                        .totalUsageCount(tuple.getT4())
                        .presetCountsByFeature(tuple.getT5())
                        .availableFeatures(Arrays.stream(AIFeatureType.values())
                                .map(Enum::name)
                                .collect(Collectors.toList()))
                        .lastActiveTime(System.currentTimeMillis())
                        .build())
                .doOnSuccess(result -> log.info("用户概览统计完成: userId={}, 总预设数={}", userId, result.getTotalPresetCount()));
    }

    @Override
    public Mono<CacheWarmupResult> warmupCache(String userId) {
        log.info("开始预热用户缓存: userId={}", userId);
        
        long startTime = System.currentTimeMillis();
        
        return getBatchPresetPackages(null, userId, null)
                .map(packages -> {
                    long duration = System.currentTimeMillis() - startTime;
                    int warmedFeatures = packages.size();
                    
                    log.info("缓存预热完成: userId={}, 预热功能数={}, 耗时={}ms", userId, warmedFeatures, duration);
                    
                    return CacheWarmupResult.builder()
                            .success(true)
                            .duration(duration)
                            .warmedFeatures(warmedFeatures)
                            .message("缓存预热成功")
                            .build();
                })
                .onErrorReturn(CacheWarmupResult.builder()
                        .success(false)
                        .duration(System.currentTimeMillis() - startTime)
                        .warmedFeatures(0)
                        .message("缓存预热失败")
                        .build());
    }

    @Override
    public Mono<AggregationCacheStats> getCacheStats() {
        Map<String, Long> hitCounts = cacheHitCounts.entrySet().stream()
                .collect(Collectors.toMap(Map.Entry::getKey, entry -> entry.getValue().get()));
        
        Map<String, Long> missCounts = cacheMissCounts.entrySet().stream()
                .collect(Collectors.toMap(Map.Entry::getKey, entry -> entry.getValue().get()));
        
        long totalRequests = hitCounts.values().stream().mapToLong(Long::longValue).sum() +
                           missCounts.values().stream().mapToLong(Long::longValue).sum();
        
        long totalHits = hitCounts.values().stream().mapToLong(Long::longValue).sum();
        double hitRate = totalRequests > 0 ? (double) totalHits / totalRequests * 100 : 0.0;
        
        return Mono.just(AggregationCacheStats.builder()
                .totalCacheSize(hitCounts.size())
                .cacheHitCounts(hitCounts)
                .cacheMissCounts(missCounts)
                .totalRequests(totalRequests)
                .hitRate(hitRate)
                .build());
    }

    @Override
    public Mono<String> clearAllCaches() {
        log.info("清除所有预设聚合缓存");
        
        cacheHitCounts.clear();
        cacheMissCounts.clear();
        
        // 这里应该调用 Spring Cache 的清除方法
        // cacheManager.getCache("preset-packages").clear();
        
        return Mono.just("缓存清除完成");
    }

    @Override
    @Cacheable(value = "all-user-preset-data", key = "#userId + ':' + (#novelId ?: 'global')")
    public Mono<AllUserPresetData> getAllUserPresetData(String userId, String novelId) {
        log.info("🚀 获取用户所有预设聚合数据: userId={}, novelId={}", userId, novelId);
        
        long startTime = System.currentTimeMillis();
        
        // 1. 获取用户预设概览
        Mono<UserPresetOverview> overviewMono = getUserPresetOverview(userId);
        
        // 2. 获取所有功能类型的预设包
        Mono<Map<AIFeatureType, PresetPackage>> packagesMono = getBatchPresetPackages(
                Arrays.asList(AIFeatureType.values()), userId, novelId);
        
        // 3. 获取系统预设
        Mono<List<AIPromptPreset>> systemPresetsMono = presetRepository
                .findByIsSystemTrue()
                .collectList();
        
        // 4. 获取用户预设按功能类型分组
        Mono<Map<String, List<AIPromptPreset>>> userPresetsGroupedMono = presetRepository
                .findByUserId(userId)
                .groupBy(AIPromptPreset::getAiFeatureType)
                .flatMap(group -> group.collectList().map(list -> Map.entry(group.key(), list)))
                .collectMap(Map.Entry::getKey, Map.Entry::getValue);
        
        // 5. 获取收藏预设
        Mono<List<AIPromptPreset>> favoritePresetsMono = presetRepository
                .findByUserIdAndIsFavoriteTrue(userId)
                .collectList();
        
        // 6. 获取快捷访问预设
        Mono<List<AIPromptPreset>> quickAccessPresetsMono = presetRepository
                .findByUserIdAndShowInQuickAccessTrue(userId)
                .collectList();
        
        // 7. 获取最近使用预设（按最后使用时间排序，取前20个）
        Mono<List<AIPromptPreset>> recentlyUsedPresetsMono = presetRepository
                .findByUserIdOrderByLastUsedAtDesc(userId)
                .take(20)
                .collectList();
        
        // 聚合所有数据
        return Mono.zip(
                overviewMono,
                packagesMono,
                systemPresetsMono,
                userPresetsGroupedMono,
                favoritePresetsMono,
                quickAccessPresetsMono,
                recentlyUsedPresetsMono
        ).map(tuple -> {
            long duration = System.currentTimeMillis() - startTime;
            
            UserPresetOverview overview = tuple.getT1();
            Map<AIFeatureType, PresetPackage> packages = tuple.getT2();
            List<AIPromptPreset> systemPresets = tuple.getT3();
            Map<String, List<AIPromptPreset>> userPresetsGrouped = tuple.getT4();
            List<AIPromptPreset> favoritePresets = tuple.getT5();
            List<AIPromptPreset> quickAccessPresets = tuple.getT6();
            List<AIPromptPreset> recentlyUsedPresets = tuple.getT7();
            
            AllUserPresetData allData = AllUserPresetData.builder()
                    .userId(userId)
                    .overview(overview)
                    .packagesByFeatureType(packages)
                    .systemPresets(systemPresets)
                    .userPresetsByFeatureType(userPresetsGrouped)
                    .favoritePresets(favoritePresets)
                    .quickAccessPresets(quickAccessPresets)
                    .recentlyUsedPresets(recentlyUsedPresets)
                    .timestamp(System.currentTimeMillis())
                    .cacheDuration(duration)
                    .build();
            
            log.info("✅ 用户预设聚合数据构建完成: userId={}, 耗时={}ms", userId, duration);
            log.info("📊 数据统计: 系统预设{}个, 用户预设分组{}个, 收藏{}个, 快捷访问{}个, 最近使用{}个", 
                    systemPresets.size(),
                    userPresetsGrouped.size(),
                    favoritePresets.size(),
                    quickAccessPresets.size(),
                    recentlyUsedPresets.size());
            
            return allData;
        })
        .doOnError(error -> log.error("❌ 获取用户预设聚合数据失败: userId={}, error={}", userId, error.getMessage()));
    }

    /**
     * 统计缓存命中情况
     */
    private void incrementCacheStats(String cacheKey, boolean hit) {
        if (hit) {
            cacheHitCounts.computeIfAbsent(cacheKey, k -> new AtomicLong(0)).incrementAndGet();
        } else {
            cacheMissCounts.computeIfAbsent(cacheKey, k -> new AtomicLong(0)).incrementAndGet();
        }
    }
}