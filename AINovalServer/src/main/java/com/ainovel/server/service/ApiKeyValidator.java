package com.ainovel.server.service;

import reactor.core.publisher.Mono;

/**
 * API Key验证器接口
 * 负责验证各种AI提供商的API Key有效性
 */
public interface ApiKeyValidator {
    
    /**
     * 验证API Key是否有效
     * 
     * @param provider 提供商名称
     * @param apiKey API密钥
     * @param apiEndpoint API端点（可选）
     * @return 是否有效
     */
    Mono<Boolean> validate(String provider, String apiKey, String apiEndpoint);
    
    /**
     * 验证API Key是否有效（带用户ID和模型名称）
     * 
     * @param userId 用户ID
     * @param provider 提供商名称
     * @param modelName 模型名称
     * @param apiKey API密钥
     * @param apiEndpoint API端点（可选）
     * @return 是否有效
     */
    Mono<Boolean> validate(String userId, String provider, String modelName, String apiKey, String apiEndpoint);
} 