package com.ainovel.server.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;

import com.ainovel.server.service.TokenEstimationService;
import com.ainovel.server.service.UserAIModelConfigService;
import com.ainovel.server.service.AIService;
import com.ainovel.server.web.dto.TokenEstimationRequest;
import com.ainovel.server.web.dto.TokenEstimationResponse;
import com.ainovel.server.domain.model.UserAIModelConfig;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * Token估算服务实现类
 */
@Slf4j
@Service
public class TokenEstimationServiceImpl implements TokenEstimationService {

    private final UserAIModelConfigService userAIModelConfigService;
    private final AIService aiService;

    // Token估算常量 - 基于经验值
    private static final Map<String, Double> TOKEN_RATIO_MAP = new HashMap<>();
    
    static {
        // 不同模型的大概Token比率 (字数 -> Token数量)
        TOKEN_RATIO_MAP.put("gpt-3.5-turbo", 1.3);
        TOKEN_RATIO_MAP.put("gpt-4", 1.3);
        TOKEN_RATIO_MAP.put("gpt-4-turbo", 1.3);
        TOKEN_RATIO_MAP.put("claude-3", 1.2);
        TOKEN_RATIO_MAP.put("claude-3-sonnet", 1.2);
        TOKEN_RATIO_MAP.put("claude-3-haiku", 1.2);
        // 默认比率
        TOKEN_RATIO_MAP.put("default", 1.3);
    }

    // 成本估算 (每1000 Token的美元价格)
    private static final Map<String, Double> COST_PER_1K_TOKENS = new HashMap<>();
    
    static {
        COST_PER_1K_TOKENS.put("gpt-3.5-turbo", 0.002);
        COST_PER_1K_TOKENS.put("gpt-4", 0.03);
        COST_PER_1K_TOKENS.put("gpt-4-turbo", 0.01);
        COST_PER_1K_TOKENS.put("claude-3-sonnet", 0.015);
        COST_PER_1K_TOKENS.put("claude-3-haiku", 0.0025);
        // 默认成本
        COST_PER_1K_TOKENS.put("default", 0.01);
    }

    @Autowired
    public TokenEstimationServiceImpl(
            UserAIModelConfigService userAIModelConfigService,
            AIService aiService) {
        this.userAIModelConfigService = userAIModelConfigService;
        this.aiService = aiService;
    }

    @Override
    public Mono<TokenEstimationResponse> estimateTokens(TokenEstimationRequest request) {
        log.info("开始估算Token: 用户={}, AI配置={}, 估算类型={}", 
                request.getUserId(), request.getAiConfigId(), request.getEstimationType());

        if (request.getContent() == null || request.getContent().trim().isEmpty()) {
            return Mono.just(TokenEstimationResponse.builder()
                    .success(false)
                    .errorMessage("文本内容不能为空")
                    .build());
        }

        return userAIModelConfigService.getConfigurationById(request.getUserId(), request.getAiConfigId())
                .filter(UserAIModelConfig::getIsValidated)
                .switchIfEmpty(Mono.error(new RuntimeException("指定的AI配置不存在或未验证")))
                .flatMap(config -> {
                    String modelName = config.getModelName();

                    // 估算输入Token
                    long inputTokens = estimateTokensForText(request.getContent(), modelName);

                    // 根据估算类型估算输出Token
                    long outputTokens = estimateOutputTokens(inputTokens, request.getEstimationType());

                    long totalTokens = inputTokens + outputTokens;

                    // 估算成本
                    double cost = estimateCost(totalTokens, modelName);

                    return Mono.just(TokenEstimationResponse.builder()
                            .inputTokens(inputTokens)
                            .outputTokens(outputTokens)
                            .totalTokens(totalTokens)
                            .estimatedCost(cost)
                            .modelName(modelName)
                            .success(true)
                            .build());
                })
                .onErrorResume(e -> {
                    log.error("Token估算失败", e);
                    return Mono.just(TokenEstimationResponse.builder()
                            .success(false)
                            .errorMessage("Token估算失败: " + e.getMessage())
                            .build());
                });
    }

    @Override
    public Mono<TokenEstimationResponse> estimateBatchTokens(
            List<String> texts, 
            String aiConfigId, 
            String userId, 
            String estimationType) {
        
        if (texts == null || texts.isEmpty()) {
            return Mono.just(TokenEstimationResponse.builder()
                    .success(false)
                    .errorMessage("文本列表不能为空")
                    .build());
        }

        return userAIModelConfigService.getConfigurationById(userId, aiConfigId)
                .filter(UserAIModelConfig::getIsValidated)
                .switchIfEmpty(Mono.error(new RuntimeException("指定的AI配置不存在或未验证")))
                .flatMap(config -> {
                    String modelName = config.getModelName();
                    
                    // 合并所有文本进行估算
                    String combinedText = String.join("\n", texts);
                    long inputTokens = estimateTokensForText(combinedText, modelName);
                    
                    // 批量处理输出Token估算
                    long outputTokens = estimateOutputTokens(inputTokens, estimationType) * texts.size();
                    
                    long totalTokens = inputTokens + outputTokens;
                    double cost = estimateCost(totalTokens, modelName);
                    
                    return Mono.just(TokenEstimationResponse.builder()
                            .inputTokens(inputTokens)
                            .outputTokens(outputTokens)
                            .totalTokens(totalTokens)
                            .estimatedCost(cost)
                            .modelName(modelName)
                            .success(true)
                            .warnings("这是批量估算，实际Token消耗可能因章节而异")
                            .build());
                })
                .onErrorResume(e -> {
                    log.error("批量Token估算失败", e);
                    return Mono.just(TokenEstimationResponse.builder()
                            .success(false)
                            .errorMessage("批量Token估算失败: " + e.getMessage())
                            .build());
                });
    }

    @Override
    public Mono<Long> estimateTokensByWordCount(Integer wordCount, String modelName) {
        if (wordCount == null || wordCount <= 0) {
            return Mono.just(0L);
        }
        
        double ratio = TOKEN_RATIO_MAP.getOrDefault(modelName, TOKEN_RATIO_MAP.get("default"));
        long tokens = Math.round(wordCount * ratio);
        
        log.debug("根据字数估算Token: 字数={}, 模型={}, 比率={}, Token={}", 
                wordCount, modelName, ratio, tokens);
        
        return Mono.just(tokens);
    }

    /**
     * 估算文本的Token数量
     */
    private long estimateTokensForText(String text, String modelName) {
        if (text == null || text.isEmpty()) {
            return 0;
        }
        
        // 简单的字数统计作为估算基础
        int wordCount = text.length(); // 对中文而言，字符数近似等于字数
        
        double ratio = TOKEN_RATIO_MAP.getOrDefault(modelName, TOKEN_RATIO_MAP.get("default"));
        return Math.round(wordCount * ratio);
    }

    /**
     * 根据估算类型估算输出Token数量
     */
    private long estimateOutputTokens(long inputTokens, String estimationType) {
        switch (estimationType.toUpperCase()) {
            case "SUMMARY_GENERATION":
                // 摘要生成通常输出是输入的10-20%
                return Math.round(inputTokens * 0.15);
            case "CONTENT_ANALYSIS":
                // 内容分析输出较少
                return Math.round(inputTokens * 0.1);
            case "TRANSLATION":
                // 翻译输出接近输入
                return Math.round(inputTokens * 0.9);
            case "EXPANSION":
                // 内容扩展输出更多
                return Math.round(inputTokens * 1.5);
            default:
                // 默认估算
                return Math.round(inputTokens * 0.2);
        }
    }

    /**
     * 估算成本
     */
    private double estimateCost(long totalTokens, String modelName) {
        double costPer1K = COST_PER_1K_TOKENS.getOrDefault(modelName, COST_PER_1K_TOKENS.get("default"));
        return (totalTokens / 1000.0) * costPer1K;
    }
} 