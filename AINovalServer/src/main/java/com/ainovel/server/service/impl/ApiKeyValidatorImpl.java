package com.ainovel.server.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.ainovel.server.service.ApiKeyValidator;
import com.ainovel.server.service.ai.AIModelProvider;
import com.ainovel.server.service.ai.factory.AIModelProviderFactory;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * API Key验证器实现
 * 负责验证各种AI提供商的API Key有效性
 */
@Slf4j
@Service
public class ApiKeyValidatorImpl implements ApiKeyValidator {
    
    private final AIModelProviderFactory providerFactory;
    
    @Autowired
    public ApiKeyValidatorImpl(AIModelProviderFactory providerFactory) {
        this.providerFactory = providerFactory;
    }
    
    @Override
    public Mono<Boolean> validate(String provider, String apiKey, String apiEndpoint) {
        return validate(null, provider, "default", apiKey, apiEndpoint);
    }
    
    @Override
    public Mono<Boolean> validate(String userId, String provider, String modelName, String apiKey, String apiEndpoint) {
        log.debug("验证API Key: provider={}, modelName={}, userId={}", provider, modelName, userId);
        
        try {
            // 创建临时的AI模型提供商实例用于验证（禁用可观测性，避免监听器与追踪日志）
            AIModelProvider modelProvider = providerFactory.createProvider(provider, modelName, apiKey, apiEndpoint, false);
            
            if (modelProvider == null) {
                log.warn("无法创建提供商实例: provider={}, modelName={}", provider, modelName);
                return Mono.just(false);
            }
            
            // 调用提供商的验证方法
            return modelProvider.validateApiKey()
                    .doOnNext(isValid -> {
                        if (isValid) {
                            log.debug("API Key验证成功: provider={}, modelName={}", provider, modelName);
                        } else {
                            log.warn("API Key验证失败: provider={}, modelName={}", provider, modelName);
                        }
                    })
                    .onErrorResume(error -> {
                        log.error("API Key验证过程中发生错误: provider={}, modelName={}, error={}", 
                                 provider, modelName, error.getMessage(), error);
                        return Mono.just(false);
                    });
        } catch (Exception e) {
            log.error("创建提供商实例时发生错误: provider={}, modelName={}, error={}", 
                     provider, modelName, e.getMessage(), e);
            return Mono.just(false);
        }
    }
} 