package com.ainovel.server.service;

import com.ainovel.server.domain.model.AIRequest;
import com.ainovel.server.domain.model.AIResponse;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 公共AI应用服务接口
 * 负责处理使用公共模型池的AI请求业务逻辑
 */
public interface PublicAIApplicationService {
    
    /**
     * 使用公共模型生成内容 (非流式)
     * 自动从公共模型池中获取可用的API Key
     *
     * @param request 包含提示、消息、模型名、参数等的请求对象
     * @return AI响应
     */
    Mono<AIResponse> generateContentWithPublicModel(AIRequest request);
    
    /**
     * 使用公共模型生成内容 (流式)
     * 自动从公共模型池中获取可用的API Key
     *
     * @param request 包含提示、消息、模型名、参数等的请求对象
     * @return 响应内容流
     */
    Flux<String> generateContentStreamWithPublicModel(AIRequest request);
} 