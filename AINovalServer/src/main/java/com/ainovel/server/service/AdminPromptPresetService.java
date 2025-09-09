package com.ainovel.server.service;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.AIPromptPreset;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

/**
 * 管理员预设管理服务接口
 */
public interface AdminPromptPresetService {
    
    /**
     * 获取所有系统预设
     */
    Flux<AIPromptPreset> findAllSystemPresets();
    
    /**
     * 根据功能类型获取系统预设
     */
    Flux<AIPromptPreset> findSystemPresetsByFeatureType(AIFeatureType featureType);
    
    /**
     * 创建系统预设
     */
    Mono<AIPromptPreset> createSystemPreset(AIPromptPreset preset, String adminId);
    
    /**
     * 更新系统预设
     */
    Mono<AIPromptPreset> updateSystemPreset(String presetId, AIPromptPreset preset, String adminId);
    
    /**
     * 删除系统预设
     */
    Mono<Void> deleteSystemPreset(String presetId);
    
    /**
     * 切换系统预设的快捷访问状态
     */
    Mono<AIPromptPreset> toggleSystemPresetQuickAccess(String presetId);
    
    /**
     * 批量设置系统预设可见性
     */
    Mono<List<AIPromptPreset>> batchUpdateVisibility(List<String> presetIds, boolean showInQuickAccess);
    
    /**
     * 获取预设使用统计
     */
    Mono<Map<String, Object>> getPresetUsageStatistics(String presetId);
    
    /**
     * 获取系统预设总体统计
     */
    Mono<Map<String, Object>> getSystemPresetsStatistics();
    
    /**
     * 导出系统预设
     */
    Mono<List<AIPromptPreset>> exportSystemPresets(List<String> presetIds);
    
    /**
     * 导入系统预设
     */
    Mono<List<AIPromptPreset>> importSystemPresets(List<AIPromptPreset> presets, String adminId);
    
    /**
     * 复制用户预设为系统预设
     */
    Mono<AIPromptPreset> promoteUserPresetToSystem(String userPresetId, String adminId);
    
    /**
     * 获取预设详情（包含使用统计）
     */
    Mono<Map<String, Object>> getPresetDetailsWithStats(String presetId);
}