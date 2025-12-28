package com.ainovel.server.service;

import com.ainovel.server.web.dto.TokenEstimationRequest;
import com.ainovel.server.web.dto.TokenEstimationResponse;

import reactor.core.publisher.Mono;

/**
 * Token估算服务接口
 * 用于估算AI操作的成本和Token消耗
 */
public interface TokenEstimationService {

    /**
     * 估算单个文本的Token和成本
     *
     * @param request 估算请求
     * @return 估算结果
     */
    Mono<TokenEstimationResponse> estimateTokens(TokenEstimationRequest request);

    /**
     * 估算批量文本的Token和成本
     *
     * @param texts 文本列表
     * @param aiConfigId AI配置ID
     * @param userId 用户ID
     * @param estimationType 估算类型
     * @return 估算结果
     */
    Mono<TokenEstimationResponse> estimateBatchTokens(
            java.util.List<String> texts, 
            String aiConfigId, 
            String userId, 
            String estimationType);

    /**
     * 根据字数估算Token数量（快速估算）
     *
     * @param wordCount 字数
     * @param modelName 模型名称
     * @return 估算的Token数量
     */
    Mono<Long> estimateTokensByWordCount(Integer wordCount, String modelName);
} 