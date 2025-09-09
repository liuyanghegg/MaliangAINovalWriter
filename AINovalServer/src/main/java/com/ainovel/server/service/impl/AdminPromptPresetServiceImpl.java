package com.ainovel.server.service.impl;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.AIPromptPreset;
import com.ainovel.server.repository.AIPromptPresetRepository;
import com.ainovel.server.repository.EnhancedUserPromptTemplateRepository;
import com.ainovel.server.service.AdminPromptPresetService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 管理员预设管理服务实现
 */
@Slf4j
@Service
public class AdminPromptPresetServiceImpl implements AdminPromptPresetService {
    
    @Autowired
    private AIPromptPresetRepository presetRepository;
    @Autowired
    private EnhancedUserPromptTemplateRepository templateRepository;
    
    @Override
    public Flux<AIPromptPreset> findAllSystemPresets() {
        return presetRepository.findByIsSystemTrue()
                .doOnNext(preset -> log.debug("找到系统预设: {}", preset.getPresetName()));
    }
    
    @Override
    public Flux<AIPromptPreset> findSystemPresetsByFeatureType(AIFeatureType featureType) {
        return presetRepository.findByIsSystemTrueAndAiFeatureType(featureType.name())
                .doOnNext(preset -> log.debug("找到功能类型 {} 的系统预设: {}", featureType, preset.getPresetName()));
    }
    
    @Override
    public Mono<AIPromptPreset> createSystemPreset(AIPromptPreset preset, String adminId) {
        log.info("管理员 {} 创建系统预设: {}", adminId, preset.getPresetName());
        
        // 设置系统预设标识
        preset.setIsSystem(true);
        preset.setUserId(adminId); // 记录创建者
        preset.setCreatedAt(LocalDateTime.now());
        preset.setUpdatedAt(LocalDateTime.now());
        
        // 生成唯一的presetId
        if (preset.getPresetId() == null) {
            preset.setPresetId(UUID.randomUUID().toString());
        }
        
        return presetRepository.save(preset)
                .doOnSuccess(savedPreset -> log.info("系统预设创建成功: {} (ID: {})", 
                    savedPreset.getPresetName(), savedPreset.getPresetId()));
    }
    
    @Override
    public Mono<AIPromptPreset> updateSystemPreset(String presetId, AIPromptPreset preset, String adminId) {
        log.info("管理员 {} 更新系统预设: {}", adminId, presetId);
        
        return presetRepository.findByPresetId(presetId)
                .switchIfEmpty(Mono.error(new RuntimeException("系统预设不存在: " + presetId)))
                .filter(existing -> existing.getIsSystem())
                .switchIfEmpty(Mono.error(new RuntimeException("只能更新系统预设")))
                .flatMap(existing -> {
                    // 保留系统预设属性
                    preset.setId(existing.getId());
                    preset.setPresetId(existing.getPresetId());
                    preset.setIsSystem(true);
                    preset.setCreatedAt(existing.getCreatedAt());
                    preset.setUpdatedAt(LocalDateTime.now());
                    // 如果有关联模板，做约束校验：系统预设只能关联同管理员的私有模板，功能类型一致，禁止公共模板
                    String tplId = preset.getTemplateId();
                    if (tplId != null && !tplId.isEmpty()) {
                        return templateRepository.findById(tplId)
                                .switchIfEmpty(Mono.error(new RuntimeException("模板不存在: " + tplId)))
                                .flatMap(tpl -> {
                                    // 功能类型一致
                                    try {
                                        AIFeatureType ft = AIFeatureType.valueOf(preset.getAiFeatureType());
                                        if (tpl.getFeatureType() != null && !tpl.getFeatureType().equals(ft)) {
                                            return Mono.error(new RuntimeException("模板功能类型与预设不一致"));
                                        }
                                    } catch (IllegalArgumentException ex) {
                                        return Mono.error(new RuntimeException("预设功能类型无效: " + preset.getAiFeatureType())) ;
                                    }
                                    // 不能是公共模板
                                    if (Boolean.TRUE.equals(tpl.getIsPublic())) {
                                        return Mono.error(new RuntimeException("系统预设不能关联公共模板"));
                                    }
                                    // 仅允许关联同管理员创建的模板
                                    if (tpl.getUserId() == null || !tpl.getUserId().equals(adminId)) {
                                        return Mono.error(new RuntimeException("系统预设只能关联由同管理员创建的私有模板"));
                                    }
                                    return presetRepository.save(preset);
                                });
                    }
                    return presetRepository.save(preset);
                })
                .doOnSuccess(savedPreset -> log.info("系统预设更新成功: {}", savedPreset.getPresetName()));
    }
    
    @Override
    public Mono<Void> deleteSystemPreset(String presetId) {
        log.info("删除系统预设: {}", presetId);
        
        return presetRepository.findByPresetId(presetId)
                .switchIfEmpty(Mono.error(new RuntimeException("系统预设不存在: " + presetId)))
                .filter(preset -> preset.getIsSystem())
                .switchIfEmpty(Mono.error(new RuntimeException("只能删除系统预设")))
                .flatMap(preset -> presetRepository.delete(preset))
                .doOnSuccess(v -> log.info("系统预设删除成功: {}", presetId));
    }
    
    @Override
    public Mono<AIPromptPreset> toggleSystemPresetQuickAccess(String presetId) {
        log.info("切换系统预设快捷访问状态: {}", presetId);
        
        return presetRepository.findByPresetId(presetId)
                .switchIfEmpty(Mono.error(new RuntimeException("系统预设不存在: " + presetId)))
                .filter(preset -> preset.getIsSystem())
                .switchIfEmpty(Mono.error(new RuntimeException("只能操作系统预设")))
                .flatMap(preset -> {
                    preset.setShowInQuickAccess(!preset.getShowInQuickAccess());
                    preset.setUpdatedAt(LocalDateTime.now());
                    return presetRepository.save(preset);
                })
                .doOnSuccess(preset -> log.info("系统预设快捷访问状态已更新: {} -> {}", 
                    presetId, preset.getShowInQuickAccess()));
    }
    
    @Override
    public Mono<List<AIPromptPreset>> batchUpdateVisibility(List<String> presetIds, boolean showInQuickAccess) {
        log.info("批量更新 {} 个系统预设的可见性为: {}", presetIds.size(), showInQuickAccess);
        
        return presetRepository.findByPresetIdIn(presetIds)
                .filter(preset -> preset.getIsSystem())
                .map(preset -> {
                    preset.setShowInQuickAccess(showInQuickAccess);
                    preset.setUpdatedAt(LocalDateTime.now());
                    return preset;
                })
                .flatMap(preset -> presetRepository.save(preset))
                .collectList()
                .doOnSuccess(presets -> log.info("批量更新完成，影响 {} 个预设", presets.size()));
    }
    
    @Override
    public Mono<Map<String, Object>> getPresetUsageStatistics(String presetId) {
        return presetRepository.findByPresetId(presetId)
                .switchIfEmpty(Mono.error(new RuntimeException("预设不存在: " + presetId)))
                .map(preset -> {
                    Map<String, Object> stats = new HashMap<>();
                    stats.put("presetId", preset.getPresetId());
                    stats.put("presetName", preset.getPresetName());
                    stats.put("useCount", preset.getUseCount() != null ? preset.getUseCount() : 0);
                    stats.put("lastUsedAt", preset.getLastUsedAt());
                    stats.put("createdAt", preset.getCreatedAt());
                    stats.put("isSystem", preset.getIsSystem());
                    stats.put("showInQuickAccess", preset.getShowInQuickAccess());
                    stats.put("featureType", preset.getAiFeatureType());
                    return stats;
                });
    }
    
    @Override
    public Mono<Map<String, Object>> getSystemPresetsStatistics() {
        return presetRepository.findByIsSystemTrue()
                .collectList()
                .map(presets -> {
                    Map<String, Object> stats = new HashMap<>();
                    stats.put("totalSystemPresets", presets.size());
                    
                    // 按功能类型分组统计
                    Map<String, Long> byFeatureType = presets.stream()
                            .collect(Collectors.groupingBy(
                                preset -> preset.getAiFeatureType() != null ? preset.getAiFeatureType() : "UNKNOWN",
                                Collectors.counting()));
                    stats.put("byFeatureType", byFeatureType);
                    
                    // 快捷访问预设数量
                    long quickAccessCount = presets.stream()
                            .mapToInt(preset -> preset.getShowInQuickAccess() ? 1 : 0)
                            .sum();
                    stats.put("quickAccessCount", quickAccessCount);
                    
                    // 总使用次数
                    int totalUsage = presets.stream()
                            .mapToInt(preset -> preset.getUseCount() != null ? preset.getUseCount() : 0)
                            .sum();
                    stats.put("totalUsage", totalUsage);
                    
                    // 最近创建的预设
                    Optional<AIPromptPreset> latest = presets.stream()
                            .filter(preset -> preset.getCreatedAt() != null)
                            .max(Comparator.comparing(AIPromptPreset::getCreatedAt));
                    stats.put("latestPreset", latest.map(preset -> {
                        Map<String, Object> presetInfo = new HashMap<>();
                        presetInfo.put("name", preset.getPresetName());
                        presetInfo.put("createdAt", preset.getCreatedAt());
                        return presetInfo;
                    }).orElse(null));
                    
                    return stats;
                });
    }
    
    @Override
    public Mono<List<AIPromptPreset>> exportSystemPresets(List<String> presetIds) {
        log.info("导出 {} 个系统预设", presetIds.size());
        
        Flux<AIPromptPreset> presetsFlux = presetIds.isEmpty() 
                ? presetRepository.findByIsSystemTrue()
                : presetRepository.findByPresetIdIn(presetIds).filter(preset -> preset.getIsSystem());
                
        return presetsFlux.collectList()
                .doOnSuccess(presets -> log.info("成功导出 {} 个系统预设", presets.size()));
    }
    
    @Override
    public Mono<List<AIPromptPreset>> importSystemPresets(List<AIPromptPreset> presets, String adminId) {
        log.info("管理员 {} 导入 {} 个系统预设", adminId, presets.size());
        
        return Flux.fromIterable(presets)
                .map(preset -> {
                    // 重置ID和标识
                    preset.setId(null);
                    preset.setPresetId(UUID.randomUUID().toString());
                    preset.setIsSystem(true);
                    preset.setUserId(adminId);
                    preset.setCreatedAt(LocalDateTime.now());
                    preset.setUpdatedAt(LocalDateTime.now());
                    preset.setUseCount(0);
                    preset.setLastUsedAt(null);
                    return preset;
                })
                .flatMap(preset -> presetRepository.save(preset))
                .collectList()
                .doOnSuccess(savedPresets -> log.info("成功导入 {} 个系统预设", savedPresets.size()));
    }
    
    @Override
    public Mono<AIPromptPreset> promoteUserPresetToSystem(String userPresetId, String adminId) {
        log.info("管理员 {} 将用户预设 {} 提升为系统预设", adminId, userPresetId);
        
        return presetRepository.findByPresetId(userPresetId)
                .switchIfEmpty(Mono.error(new RuntimeException("用户预设不存在: " + userPresetId)))
                .filter(preset -> !preset.getIsSystem())
                .switchIfEmpty(Mono.error(new RuntimeException("预设已经是系统预设")))
                .flatMap(userPreset -> {
                    // 创建系统预设副本
                    AIPromptPreset systemPreset = AIPromptPreset.builder()
                            .presetId(UUID.randomUUID().toString())
                            .presetName("[系统] " + userPreset.getPresetName())
                            .presetDescription(userPreset.getPresetDescription())
                            .presetTags(userPreset.getPresetTags())
                            .requestData(userPreset.getRequestData())
                            .systemPrompt(userPreset.getSystemPrompt())
                            .userPrompt(userPreset.getUserPrompt())
                            .aiFeatureType(userPreset.getAiFeatureType())
                            .customSystemPrompt(userPreset.getCustomSystemPrompt())
                            .customUserPrompt(userPreset.getCustomUserPrompt())
                            .promptCustomized(userPreset.getPromptCustomized())
                            .templateId(userPreset.getTemplateId())
                            .isSystem(true)
                            .showInQuickAccess(false)
                            .isFavorite(false)
                            .isPublic(false)
                            .useCount(0)
                            .userId(adminId)
                            .createdAt(LocalDateTime.now())
                            .updatedAt(LocalDateTime.now())
                            .build();
                            
                    return presetRepository.save(systemPreset);
                })
                .doOnSuccess(systemPreset -> log.info("用户预设已成功提升为系统预设: {}", 
                    systemPreset.getPresetId()));
    }
    
    @Override
    public Mono<Map<String, Object>> getPresetDetailsWithStats(String presetId) {
        return presetRepository.findByPresetId(presetId)
                .switchIfEmpty(Mono.error(new RuntimeException("预设不存在: " + presetId)))
                .map(preset -> {
                    Map<String, Object> details = new HashMap<>();
                    details.put("preset", preset);
                    
                    // 添加统计信息
                    Map<String, Object> statistics = new HashMap<>();
                    statistics.put("useCount", preset.getUseCount() != null ? preset.getUseCount() : 0);
                    statistics.put("lastUsedAt", preset.getLastUsedAt());
                    statistics.put("daysSinceCreated", preset.getCreatedAt() != null 
                        ? java.time.temporal.ChronoUnit.DAYS.between(preset.getCreatedAt().toLocalDate(), LocalDateTime.now().toLocalDate())
                        : 0);
                    statistics.put("daysSinceLastUsed", preset.getLastUsedAt() != null
                        ? java.time.temporal.ChronoUnit.DAYS.between(preset.getLastUsedAt().toLocalDate(), LocalDateTime.now().toLocalDate())
                        : null);
                    
                    details.put("statistics", statistics);
                    return details;
                });
    }
}