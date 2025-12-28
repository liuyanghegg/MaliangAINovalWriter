package com.ainovel.server.service.impl;

import org.springframework.stereotype.Service;

import com.ainovel.server.domain.model.AIRequest;
import com.ainovel.server.domain.model.AIResponse;
import com.ainovel.server.service.AIService;
import com.ainovel.server.service.PublicAIApplicationService;
import com.ainovel.server.service.PublicModelConfigService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 公共AI应用服务实现
 * 负责处理使用公共模型池的AI请求业务逻辑
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PublicAIApplicationServiceImpl implements PublicAIApplicationService {
    
    private final PublicModelConfigService configService;
    private final AIService aiService;
    
    @Override
    public Mono<AIResponse> generateContentWithPublicModel(AIRequest request) {
        String provider = getProviderForModel(request.getModel());
        String modelId = request.getModel();
        
        return configService.getActiveDecryptedApiKey(provider, modelId)
                .flatMap(apiKey -> {
                    // 获取对应的公共模型配置来获取API endpoint
                    return configService.findByProviderAndModelId(provider, modelId)
                            .flatMap(config -> aiService.generateContent(request, apiKey, config.getApiEndpoint()))
                            .switchIfEmpty(aiService.generateContent(request, apiKey, null));
                })
                .doOnError(e -> log.error("使用公共模型生成内容失败: provider={}, modelId={}, error={}", 
                           provider, modelId, e.getMessage()));
    }
    
    @Override
    public Flux<String> generateContentStreamWithPublicModel(AIRequest request) {
        String provider = getProviderForModel(request.getModel());
        String modelId = request.getModel();
        
        return configService.getActiveDecryptedApiKey(provider, modelId)
                .flatMapMany(apiKey -> {
                    // 获取对应的公共模型配置来获取API endpoint
                    Flux<String> upstream = configService.findByProviderAndModelId(provider, modelId)
                            .flatMapMany(config -> aiService.generateContentStream(request, apiKey, config.getApiEndpoint()))
                            .switchIfEmpty(aiService.generateContentStream(request, apiKey, null));
                    // 共享上游，避免多订阅触发重复请求
                    return upstream.publish().refCount(1);
                })
                .doOnError(e -> log.error("使用公共模型生成流式内容失败: provider={}, modelId={}, error={}", 
                           provider, modelId, e.getMessage()));
    }
    
    /**
     * 根据模型名称获取提供商名称
     * 这个方法从AIService中移动过来，因为它是业务逻辑
     */
    private String getProviderForModel(String modelName) {
        if (modelName == null) {
            return "openai"; // 默认提供商
        }
        
        // 根据模型名称前缀或特征判断提供商
        String lowerModelName = modelName.toLowerCase();
        
        if (lowerModelName.startsWith("gpt-") || lowerModelName.startsWith("o1-")) {
            return "openai";
        } else if (lowerModelName.startsWith("claude-")) {
            return "anthropic";
        } else if (lowerModelName.startsWith("gemini-")) {
            return "gemini";
        } else if (lowerModelName.startsWith("grok-")) {
            return "grok";
        } else if (lowerModelName.contains("silicon")) {
            return "siliconflow";
        } else {
            // 默认返回openai
            return "openai";
        }
    }
} 