package com.ainovel.server.service;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.dto.PresetPackage;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

/**
 * 统一预设聚合服务接口
 * 提供高效的预设数据聚合和缓存功能
 */
public interface UnifiedPresetAggregationService {

    /**
     * 获取完整的预设包（包含系统预设和用户预设）
     *
     * @param featureType AI功能类型
     * @param userId 用户ID
     * @param novelId 小说ID（可选）
     * @return 预设包
     */
    Mono<PresetPackage> getCompletePresetPackage(AIFeatureType featureType, String userId, String novelId);

    /**
     * 批量获取多个功能类型的预设包
     *
     * @param featureTypes 功能类型列表
     * @param userId 用户ID
     * @param novelId 小说ID（可选）
     * @return 功能类型到预设包的映射
     */
    Mono<Map<AIFeatureType, PresetPackage>> getBatchPresetPackages(List<AIFeatureType> featureTypes, String userId, String novelId);

    /**
     * 获取用户的预设概览统计
     *
     * @param userId 用户ID
     * @return 预设概览
     */
    Mono<UserPresetOverview> getUserPresetOverview(String userId);

    /**
     * 预热用户缓存
     *
     * @param userId 用户ID
     * @return 缓存预热结果
     */
    Mono<CacheWarmupResult> warmupCache(String userId);

    /**
     * 获取缓存统计信息
     *
     * @return 缓存统计
     */
    Mono<AggregationCacheStats> getCacheStats();

    /**
     * 清除所有缓存
     *
     * @return 清除结果
     */
    Mono<String> clearAllCaches();

    /**
     * 🚀 获取用户的所有预设聚合数据
     * 一次性返回用户的所有预设数据，包括系统预设和按功能分组的预设
     *
     * @param userId 用户ID
     * @param novelId 小说ID（可选）
     * @return 完整的用户预设聚合数据
     */
    Mono<AllUserPresetData> getAllUserPresetData(String userId, String novelId);

    /**
     * 用户预设概览DTO
     */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    class UserPresetOverview {
        private String userId;
        private long totalPresetCount;
        private long favoritePresetCount;
        private long quickAccessPresetCount;
        private long totalUsageCount;
        private Map<String, Long> presetCountsByFeature;
        private List<String> availableFeatures;
        private long lastActiveTime;
    }

    /**
     * 缓存预热结果DTO
     */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    class CacheWarmupResult {
        private boolean success;
        private long duration;
        private int warmedFeatures;
        private String message;
    }

    /**
     * 聚合缓存统计DTO
     */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    class AggregationCacheStats {
        private long totalCacheSize;
        private Map<String, Long> cacheHitCounts;
        private Map<String, Long> cacheMissCounts;
        private long totalRequests;
        private double hitRate;
    }

    /**
     * 用户所有预设聚合数据DTO
     * 🚀 一次性返回用户的所有预设相关数据，避免多次API调用
     */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    class AllUserPresetData {
        /** 用户ID */
        private String userId;
        
        /** 用户预设概览统计 */
        private UserPresetOverview overview;
        
        /** 按功能类型分组的预设包 */
        private Map<AIFeatureType, PresetPackage> packagesByFeatureType;
        
        /** 系统预设列表（所有功能类型） */
        private List<com.ainovel.server.domain.model.AIPromptPreset> systemPresets;
        
        /** 用户预设按功能类型分组 */
        private Map<String, List<com.ainovel.server.domain.model.AIPromptPreset>> userPresetsByFeatureType;
        
        /** 收藏预设列表 */
        private List<com.ainovel.server.domain.model.AIPromptPreset> favoritePresets;
        
        /** 快捷访问预设列表 */
        private List<com.ainovel.server.domain.model.AIPromptPreset> quickAccessPresets;
        
        /** 最近使用预设列表 */
        private List<com.ainovel.server.domain.model.AIPromptPreset> recentlyUsedPresets;
        
        /** 数据生成时间戳 */
        private long timestamp;
        
        /** 缓存时长（毫秒） */
        private long cacheDuration;
    }
}