package com.ainovel.server.service.ai.pricing.impl;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.ModelPricing;
import com.ainovel.server.service.ai.pricing.AbstractTokenPricingCalculator;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * Anthropic Token定价计算器
 * 目前使用静态定价数据，因为Anthropic没有公开的定价API
 */
@Slf4j
@Component
public class AnthropicTokenPricingCalculator extends AbstractTokenPricingCalculator {
    
    private static final String PROVIDER_NAME = "anthropic";
    
    @Override
    public String getProviderName() {
        return PROVIDER_NAME;
    }
    
    /**
     * 获取Anthropic模型的默认定价信息
     * 基于官网公布的价格信息
     * 
     * @return 默认定价信息列表
     */
    public Mono<List<ModelPricing>> getDefaultAnthropicPricing() {
        List<ModelPricing> defaultPricing = List.of(
                createDefaultPricing("claude-3-haiku-20240307", "Claude 3 Haiku", 
                        0.00025, 0.00125, 200000, "最快且最经济的Claude 3模型"),
                
                createDefaultPricing("claude-3-sonnet-20240229", "Claude 3 Sonnet", 
                        0.003, 0.015, 200000, "智能与速度的平衡，适合企业工作负载"),
                
                createDefaultPricing("claude-3-opus-20240229", "Claude 3 Opus", 
                        0.015, 0.075, 200000, "最强大的Claude 3模型，适合复杂任务"),
                
                createDefaultPricing("claude-3-5-sonnet-20241022", "Claude 3.5 Sonnet", 
                        0.003, 0.015, 200000, "升级版Sonnet，提供更强的性能"),
                
                createDefaultPricing("claude-2.1", "Claude 2.1", 
                        0.008, 0.024, 200000, "Claude 2.1模型"),
                
                createDefaultPricing("claude-2.0", "Claude 2.0", 
                        0.008, 0.024, 100000, "Claude 2.0模型"),
                
                createDefaultPricing("claude-instant-1.2", "Claude Instant 1.2", 
                        0.0008, 0.0024, 100000, "快速响应的Claude Instant模型")
        );
        
        return Mono.just(defaultPricing);
    }
    
    /**
     * 创建默认定价信息
     * 
     * @param modelId 模型ID
     * @param modelName 模型名称
     * @param inputPrice 输入价格（每1000个token）
     * @param outputPrice 输出价格（每1000个token）
     * @param maxTokens 最大token数
     * @param description 描述
     * @return 定价信息
     */
    private ModelPricing createDefaultPricing(String modelId, String modelName, 
                                            double inputPrice, double outputPrice, 
                                            int maxTokens, String description) {
        return ModelPricing.builder()
                .provider(PROVIDER_NAME)
                .modelId(modelId)
                .modelName(modelName)
                .inputPricePerThousandTokens(inputPrice)
                .outputPricePerThousandTokens(outputPrice)
                .maxContextTokens(maxTokens)
                .supportsStreaming(true)
                .description(description)
                .source(ModelPricing.PricingSource.DEFAULT)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .version(1)
                .active(true)
                .build();
    }
    
    /**
     * 根据模型ID获取特定的定价信息
     * 
     * @param modelId 模型ID
     * @return 定价信息
     */
    @Override
    protected Mono<ModelPricing> getDefaultPricing(String modelId) {
        return getDefaultAnthropicPricing()
                .flatMapMany(reactor.core.publisher.Flux::fromIterable)
                .filter(pricing -> pricing.getModelId().equals(modelId))
                .next();
    }
    
    /**
     * 批量更新Anthropic定价信息
     * 
     * @return 更新结果
     */
    public Mono<Void> updateAllPricing() {
        log.info("Updating Anthropic pricing information...");
        
        return getDefaultAnthropicPricing()
                .flatMap(super::batchSavePricing)
                .doOnSuccess(unused -> log.info("Successfully updated Anthropic pricing"))
                .doOnError(error -> log.error("Failed to update Anthropic pricing", error));
    }
    
    /**
     * 检查模型是否为Claude模型
     * 
     * @param modelId 模型ID
     * @return 是否为Claude模型
     */
    public boolean isClaudeModel(String modelId) {
        return modelId != null && 
               (modelId.startsWith("claude-") || 
                modelId.contains("claude") || 
                modelId.startsWith("anthropic"));
    }
    
    /**
     * 获取模型类型（Haiku, Sonnet, Opus等）
     * 
     * @param modelId 模型ID
     * @return 模型类型
     */
    public String getModelType(String modelId) {
        if (modelId.contains("haiku")) {
            return "haiku";
        } else if (modelId.contains("sonnet")) {
            return "sonnet";
        } else if (modelId.contains("opus")) {
            return "opus";
        } else if (modelId.contains("instant")) {
            return "instant";
        } else if (modelId.contains("claude-2")) {
            return "claude-2";
        } else {
            return "unknown";
        }
    }
    
    /**
     * 获取模型的建议用途
     * 
     * @param modelId 模型ID
     * @return 建议用途
     */
    public String getModelRecommendation(String modelId) {
        String type = getModelType(modelId);
        return switch (type) {
            case "haiku" -> "适合快速响应和大批量处理任务";
            case "sonnet" -> "适合平衡性能和成本的日常工作";
            case "opus" -> "适合需要最高质量输出的复杂任务";
            case "instant" -> "适合需要快速响应的简单任务";
            case "claude-2" -> "通用型模型，适合各种文本任务";
            default -> "通用AI助手模型";
        };
    }
}