package com.ainovel.server.service;

import com.ainovel.server.domain.model.AIPromptPreset;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;

/**
 * AI预设服务接口
 * 专门处理预设的CRUD操作和管理功能
 */
public interface AIPresetService {

    /**
     * 创建用户预设（新逻辑：直接存储原始请求数据）
     * @param request AI请求配置
     * @param presetName 预设名称
     * @param presetDescription 预设描述
     * @param presetTags 预设标签
     * @return 创建的预设
     */
    Mono<AIPromptPreset> createPreset(UniversalAIRequestDto request, String presetName, 
                                     String presetDescription, List<String> presetTags);

    /**
     * 覆盖更新预设（完整对象）
     * @param presetId 预设ID
     * @param newPreset 新的预设对象
     * @return 更新后的预设
     */
    Mono<AIPromptPreset> overwritePreset(String presetId, AIPromptPreset newPreset);

    /**
     * 更新预设基本信息
     * @param presetId 预设ID
     * @param presetName 预设名称
     * @param presetDescription 预设描述
     * @param presetTags 预设标签
     * @return 更新后的预设
     */
    Mono<AIPromptPreset> updatePresetInfo(String presetId, String presetName, 
                                         String presetDescription, List<String> presetTags);

    /**
     * 更新预设的提示词
     * @param presetId 预设ID
     * @param customSystemPrompt 自定义系统提示词
     * @param customUserPrompt 自定义用户提示词
     * @return 更新后的预设
     */
    Mono<AIPromptPreset> updatePresetPrompts(String presetId, String customSystemPrompt, String customUserPrompt);

    /**
     * 更新预设关联的模板ID
     * @param presetId 预设ID
     * @param templateId 模板ID
     * @return 更新后的预设
     */
    Mono<AIPromptPreset> updatePresetTemplate(String presetId, String templateId);

    /**
     * 删除预设
     * @param presetId 预设ID
     * @return 删除结果
     */
    Mono<Void> deletePreset(String presetId);

    /**
     * 复制预设
     * @param presetId 源预设ID
     * @param newPresetName 新预设名称
     * @return 复制的预设
     */
    Mono<AIPromptPreset> duplicatePreset(String presetId, String newPresetName);

    /**
     * 切换预设的快捷访问状态
     * @param presetId 预设ID
     * @return 更新后的预设
     */
    Mono<AIPromptPreset> toggleQuickAccess(String presetId);

    /**
     * 设置预设为收藏/取消收藏
     * @param presetId 预设ID
     * @return 更新后的预设
     */
    Mono<AIPromptPreset> toggleFavorite(String presetId);

    /**
     * 记录预设使用
     * @param presetId 预设ID
     * @return 操作结果
     */
    Mono<Void> recordUsage(String presetId);

    /**
     * 根据预设ID获取预设详情
     * @param presetId 预设ID
     * @return 预设详情
     */
    Mono<AIPromptPreset> getPresetById(String presetId);

    /**
     * 获取用户的所有预设
     * @param userId 用户ID
     * @return 预设列表
     */
    Flux<AIPromptPreset> getUserPresets(String userId);

    /**
     * 根据小说ID获取用户预设（包含全局预设）
     * @param userId 用户ID
     * @param novelId 小说ID
     * @return 预设列表
     */
    Flux<AIPromptPreset> getUserPresetsByNovelId(String userId, String novelId);

    /**
     * 根据功能类型获取用户预设
     * @param userId 用户ID
     * @param featureType 功能类型
     * @return 预设列表
     */
    Flux<AIPromptPreset> getUserPresetsByFeatureType(String userId, String featureType);

    /**
     * 根据功能类型和小说ID获取用户预设（包含全局预设）
     * @param userId 用户ID
     * @param featureType 功能类型
     * @param novelId 小说ID
     * @return 预设列表
     */
    Flux<AIPromptPreset> getUserPresetsByFeatureTypeAndNovelId(String userId, String featureType, String novelId);

    /**
     * 获取系统预设
     * @param featureType 功能类型（可选）
     * @return 系统预设列表
     */
    Flux<AIPromptPreset> getSystemPresets(String featureType);

    /**
     * 获取快捷访问预设
     * @param userId 用户ID
     * @param featureType 功能类型（可选）
     * @return 快捷访问预设列表
     */
    Flux<AIPromptPreset> getQuickAccessPresets(String userId, String featureType);

    /**
     * 获取收藏预设
     * @param userId 用户ID
     * @param featureType 功能类型（可选）
     * @param novelId 小说ID（可选）
     * @return 收藏预设列表
     */
    Flux<AIPromptPreset> getFavoritePresets(String userId, String featureType, String novelId);

    /**
     * 获取最近使用的预设
     * @param userId 用户ID
     * @param limit 限制数量
     * @param featureType 功能类型（可选）
     * @param novelId 小说ID（可选）
     * @return 最近使用的预设列表
     */
    Flux<AIPromptPreset> getRecentPresets(String userId, int limit, String featureType, String novelId);

    /**
     * 按功能类型分组获取用户预设
     * @param userId 用户ID
     * @return 分组的预设Map
     */
    Mono<Map<String, List<AIPromptPreset>>> getUserPresetsGrouped(String userId);

    /**
     * 批量获取预设
     * @param presetIds 预设ID列表
     * @return 预设列表
     */
    Flux<AIPromptPreset> getPresetsBatch(List<String> presetIds);

    /**
     * 获取功能预设列表（收藏、最近使用、推荐）
     * @param userId 用户ID
     * @param featureType 功能类型
     * @param novelId 小说ID（可选）
     * @return 功能预设列表响应
     */
    Mono<com.ainovel.server.dto.response.PresetListResponse> getFeaturePresetList(String userId, String featureType, String novelId);

    /**
     * 搜索用户预设
     * @param userId 用户ID
     * @param keyword 关键词（名称/描述）
     * @param tags 标签列表（可选）
     * @param featureType 功能类型（可选）
     */
    Flux<AIPromptPreset> searchUserPresets(String userId, String keyword, java.util.List<String> tags, String featureType);

    /**
     * 根据小说ID搜索用户预设（包含全局）
     */
    Flux<AIPromptPreset> searchUserPresetsByNovelId(String userId, String keyword, java.util.List<String> tags, String featureType, String novelId);
} 