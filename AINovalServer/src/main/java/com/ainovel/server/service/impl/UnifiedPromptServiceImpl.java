package com.ainovel.server.service.impl;

import java.util.Map;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.EnhancedUserPromptService;
import com.ainovel.server.service.UnifiedPromptService;
import com.ainovel.server.service.prompt.AIFeaturePromptProvider;
import com.ainovel.server.service.prompt.PromptProviderFactory;
import com.ainovel.server.service.prompt.impl.ContentProviderPlaceholderResolver;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * 统一提示词服务实现类
 * 整合所有提示词相关功能的具体实现
 */
@Slf4j
@Service
public class UnifiedPromptServiceImpl implements UnifiedPromptService {

    @Autowired
    private PromptProviderFactory promptProviderFactory;

    @Autowired
    private EnhancedUserPromptService enhancedUserPromptService;

    @Autowired
    private ContentProviderPlaceholderResolver contentProviderPlaceholderResolver;

    @Override
    public Mono<String> getSystemPrompt(AIFeatureType featureType, String userId, Map<String, Object> parameters) {
        log.debug("获取系统提示词: featureType={}, userId={}", featureType, userId);

        AIFeaturePromptProvider provider = promptProviderFactory.getProvider(featureType);
        if (provider == null) {
            log.error("未找到功能类型 {} 的提示词提供器", featureType);
            return Mono.error(new IllegalArgumentException("不支持的功能类型: " + featureType));
        }

        return provider.getSystemPrompt(userId, parameters)
                .doOnNext(prompt -> log.debug("成功获取系统提示词，长度: {}", prompt.length()))
                .onErrorResume(error -> {
                    log.error("获取系统提示词失败: featureType={}, userId={}, error={}", 
                             featureType, userId, error.getMessage(), error);
                    // 回退到默认系统提示词
                    return Mono.just(provider.getDefaultSystemPrompt())
                            .flatMap(template -> provider.renderPrompt(template, parameters));
                });
    }

    @Override
    public Mono<String> getUserPrompt(AIFeatureType featureType, String userId, String templateId, Map<String, Object> parameters) {
        log.debug("获取用户提示词: featureType={}, userId={}, templateId={}", featureType, userId, templateId);

        AIFeaturePromptProvider provider = promptProviderFactory.getProvider(featureType);
        if (provider == null) {
            log.error("未找到功能类型 {} 的提示词提供器", featureType);
            return Mono.error(new IllegalArgumentException("不支持的功能类型: " + featureType));
        }

        return provider.getUserPrompt(userId, templateId, parameters)
                .doOnNext(prompt -> {
                    log.debug("成功获取用户提示词，长度: {}", prompt.length());
                    // 记录模板使用（如果有templateId的话）
                    if (templateId != null && !templateId.isEmpty()) {
                        enhancedUserPromptService.recordTemplateUsage(userId, templateId)
                                .subscribe();
                    }
                })
                .onErrorResume(error -> {
                    log.error("获取用户提示词失败: featureType={}, userId={}, templateId={}, error={}", 
                             featureType, userId, templateId, error.getMessage(), error);
                    // 回退到默认用户提示词
                    return Mono.just(provider.getDefaultUserPrompt())
                            .flatMap(template -> provider.renderPrompt(template, parameters));
                });
    }

    @Override
    public Mono<PromptConversation> getCompletePromptConversation(AIFeatureType featureType, String userId, 
                                                                  String templateId, Map<String, Object> parameters) {
        log.debug("获取完整提示词对话: featureType={}, userId={}, templateId={}", featureType, userId, templateId);

        return Mono.zip(
                getSystemPrompt(featureType, userId, parameters),
                getUserPrompt(featureType, userId, templateId, parameters)
        ).map(tuple -> {
            String systemMessage = tuple.getT1();
            String userMessage = tuple.getT2();
            
            log.debug("成功构建完整提示词对话: 系统消息长度={}, 用户消息长度={}", 
                     systemMessage.length(), userMessage.length());
            
            return new PromptConversation(systemMessage, userMessage, featureType, parameters);
        });
    }

    @Override
    public Set<String> getSupportedPlaceholders(AIFeatureType featureType) {
        AIFeaturePromptProvider provider = promptProviderFactory.getProvider(featureType);
        if (provider == null) {
            return Set.of();
        }
        
        // 获取功能提供器支持的所有占位符
        Set<String> allSupportedPlaceholders = provider.getSupportedPlaceholders();
        
        // 获取实际可用的占位符（过滤掉未实现的内容提供器）
        Set<String> availablePlaceholders = contentProviderPlaceholderResolver.getAvailablePlaceholders();
        
        // 取交集，只返回既被功能支持又实际可用的占位符
        Set<String> filteredPlaceholders = new java.util.HashSet<>(allSupportedPlaceholders);
        filteredPlaceholders.retainAll(availablePlaceholders);
        
        log.debug("功能 {} 占位符过滤结果: 原始={}, 过滤后={}", 
                 featureType, allSupportedPlaceholders.size(), filteredPlaceholders.size());
        
        return filteredPlaceholders;
    }

    @Override
    public AIFeaturePromptProvider.ValidationResult validatePlaceholders(AIFeatureType featureType, String content) {
        AIFeaturePromptProvider provider = promptProviderFactory.getProvider(featureType);
        if (provider == null) {
            return new AIFeaturePromptProvider.ValidationResult(
                false, 
                "不支持的功能类型: " + featureType, 
                Set.of(), 
                Set.of()
            );
        }
        
        return provider.validatePlaceholders(content);
    }

    @Override
    public AIFeaturePromptProvider getPromptProvider(AIFeatureType featureType) {
        return promptProviderFactory.getProvider(featureType);
    }

    @Override
    public boolean hasPromptProvider(AIFeatureType featureType) {
        return promptProviderFactory.hasProvider(featureType);
    }

    @Override
    public Set<AIFeatureType> getSupportedFeatureTypes() {
        return promptProviderFactory.getSupportedFeatureTypes();
    }
} 