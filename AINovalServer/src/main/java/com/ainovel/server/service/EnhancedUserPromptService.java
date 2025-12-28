package com.ainovel.server.service;

import java.util.List;
import java.util.Map;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.EnhancedUserPromptTemplate;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 增强的用户提示词服务接口
 * 支持标签、评分、分享、收藏等功能
 */
public interface EnhancedUserPromptService {

    // ==================== 基础CRUD操作 ====================

    /**
     * 创建用户提示词模板
     */
    Mono<EnhancedUserPromptTemplate> createPromptTemplate(
            String userId, 
            String name, 
            String description,
            AIFeatureType featureType,
            String systemPrompt,
            String userPrompt,
            List<String> tags,
            List<String> categories);

    /**
     * 更新用户提示词模板
     */
    Mono<EnhancedUserPromptTemplate> updatePromptTemplate(
            String userId,
            String templateId,
            String name,
            String description,
            String systemPrompt,
            String userPrompt,
            List<String> tags,
            List<String> categories);

    /**
     * 删除用户提示词模板
     */
    Mono<Void> deletePromptTemplate(String userId, String templateId);

    /**
     * 根据ID获取模板
     */
    Mono<EnhancedUserPromptTemplate> getPromptTemplateById(String userId, String templateId);

    // ==================== 查询操作 ====================

    /**
     * 获取用户的所有模板
     */
    Flux<EnhancedUserPromptTemplate> getUserPromptTemplates(String userId);

    /**
     * 按功能类型获取用户模板
     */
    Flux<EnhancedUserPromptTemplate> getUserPromptTemplatesByFeatureType(String userId, AIFeatureType featureType);

    /**
     * 获取用户收藏的模板
     */
    Flux<EnhancedUserPromptTemplate> getUserFavoriteTemplates(String userId);

    /**
     * 获取最近使用的模板
     */
    Flux<EnhancedUserPromptTemplate> getRecentlyUsedTemplates(String userId, int limit);

    // ==================== 分享和公开功能 ====================

    /**
     * 发布模板为公开
     */
    Mono<EnhancedUserPromptTemplate> publishTemplate(String userId, String templateId, String shareCode);

    /**
     * 通过分享码获取模板
     */
    Mono<EnhancedUserPromptTemplate> getTemplateByShareCode(String shareCode);

    /**
     * 复制公开模板到用户账户
     */
    Mono<EnhancedUserPromptTemplate> copyPublicTemplate(String userId, String templateId);

    /**
     * 获取公开模板列表
     */
    Flux<EnhancedUserPromptTemplate> getPublicTemplates(AIFeatureType featureType, int page, int size);

    // ==================== 收藏功能 ====================

    /**
     * 收藏模板
     */
    Mono<Void> favoriteTemplate(String userId, String templateId);

    /**
     * 取消收藏模板
     */
    Mono<Void> unfavoriteTemplate(String userId, String templateId);

    // ==================== 默认模板功能 ====================

    /**
     * 设置默认模板
     */
    Mono<EnhancedUserPromptTemplate> setDefaultTemplate(String userId, String templateId);

    /**
     * 获取默认模板
     */
    Mono<EnhancedUserPromptTemplate> getDefaultTemplate(String userId, AIFeatureType featureType);

    // ==================== 评分功能 ====================

    /**
     * 对模板评分
     */
    Mono<EnhancedUserPromptTemplate> rateTemplate(String userId, String templateId, int rating);

    // ==================== 统计功能 ====================

    /**
     * 记录模板使用
     */
    Mono<Void> recordTemplateUsage(String userId, String templateId);

    /**
     * 获取用户的所有标签
     */
    Flux<String> getUserTags(String userId);
    
    // ==================== 提示词模板功能 ====================
    
    /**
     * 获取指定类型的建议提示词
     */
    Mono<String> getSuggestionPrompt(String suggestionType);
    
    /**
     * 获取修改提示词
     */
    Mono<String> getRevisionPrompt();
    
    /**
     * 获取角色生成提示词
     */
    Mono<String> getCharacterGenerationPrompt();
    
    /**
     * 获取情节生成提示词
     */
    Mono<String> getPlotGenerationPrompt();
    
    /**
     * 获取设定生成提示词
     */
    Mono<String> getSettingGenerationPrompt();
    
    /**
     * 获取下一个剧情大纲生成提示词
     */
    Mono<String> getNextOutlinesGenerationPrompt();
    
    /**
     * 获取单个剧情大纲生成提示词
     */
    Mono<String> getSingleOutlineGenerationPrompt();
    
    /**
     * 获取用于单轮剧情推演的提示词模板
     */
    Mono<String> getNextChapterOutlineGenerationPrompt();
    
    /**
     * 获取结构化的设定生成提示词，用于支持JSON Schema的模型
     */
    Mono<Map<String, String>> getStructuredSettingPrompt(String settingTypes, int maxSettingsPerType, String additionalInstructions);
    
    /**
     * 获取常规的设定生成提示词，用于不支持JSON Schema的模型
     */
    Mono<String> getGeneralSettingPrompt(String contextText, String settingTypes, int maxSettingsPerType, String additionalInstructions);
    
    /**
     * 获取特定功能的系统消息提示词
     */
    Mono<String> getSystemMessageForFeature(AIFeatureType featureType);
    
    /**
     * 获取所有提示词类型
     */
    Mono<List<String>> getAllPromptTypes();
} 