package com.ainovel.server.service.ai.pricing.impl;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.ModelPricing;
import com.ainovel.server.service.ai.pricing.AbstractTokenPricingCalculator;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * Google Gemini Token定价计算器
 * 支持Gemini系列模型的定价计算
 */
@Slf4j
@Component
public class GeminiTokenPricingCalculator extends AbstractTokenPricingCalculator {
    
    private static final String PROVIDER_NAME = "gemini";
    
    @Override
    public String getProviderName() {
        return PROVIDER_NAME;
    }
    
    /**
     * 获取Gemini模型的默认定价信息
     * 基于Google AI官网公布的价格信息
     * 
     * @return 默认定价信息列表
     */
    public Mono<List<ModelPricing>> getDefaultGeminiPricing() {
        List<ModelPricing> defaultPricing = List.of(
                // Gemini 1.5 Flash - 最经济的模型
                createDefaultPricing("gemini-1.5-flash", "Gemini 1.5 Flash", 
                        0.00015, 0.0006, 1000000, "快速高效的多模态模型"),
                
                createDefaultPricing("gemini-1.5-flash-001", "Gemini 1.5 Flash 001", 
                        0.00015, 0.0006, 1000000, "Gemini 1.5 Flash稳定版本"),
                
                createDefaultPricing("gemini-1.5-flash-002", "Gemini 1.5 Flash 002", 
                        0.00015, 0.0006, 1000000, "Gemini 1.5 Flash最新版本"),
                
                // Gemini 1.5 Pro - 性能最强的模型
                createDefaultPricing("gemini-1.5-pro", "Gemini 1.5 Pro", 
                        0.00125, 0.005, 2000000, "最强大的Gemini模型，支持超长上下文"),
                
                createDefaultPricing("gemini-1.5-pro-001", "Gemini 1.5 Pro 001", 
                        0.00125, 0.005, 2000000, "Gemini 1.5 Pro稳定版本"),
                
                createDefaultPricing("gemini-1.5-pro-002", "Gemini 1.5 Pro 002", 
                        0.00125, 0.005, 2000000, "Gemini 1.5 Pro最新版本"),
                
                // Gemini 1.0 Pro - 第一代模型
                createDefaultPricing("gemini-1.0-pro", "Gemini 1.0 Pro", 
                        0.0005, 0.0015, 32760, "第一代Gemini Pro模型"),
                
                createDefaultPricing("gemini-1.0-pro-001", "Gemini 1.0 Pro 001", 
                        0.0005, 0.0015, 32760, "Gemini 1.0 Pro稳定版本"),
                
                createDefaultPricing("gemini-1.0-pro-vision", "Gemini 1.0 Pro Vision", 
                        0.00025, 0.0005, 16384, "支持视觉输入的Gemini模型"),
                
                // Gemini Pro实验版本
                createDefaultPricing("gemini-pro", "Gemini Pro", 
                        0.0005, 0.0015, 32760, "Gemini Pro通用版本"),
                
                createDefaultPricing("gemini-pro-vision", "Gemini Pro Vision", 
                        0.00025, 0.0005, 16384, "Gemini Pro视觉版本")
        );
        
        // 添加免费额度信息
        addFreeTierInfo(defaultPricing);
        
        return Mono.just(defaultPricing);
    }
    
    /**
     * 添加免费额度信息到定价数据
     * 
     * @param pricingList 定价列表
     */
    private void addFreeTierInfo(List<ModelPricing> pricingList) {
        pricingList.forEach(pricing -> {
            Map<String, Double> additionalPricing = new HashMap<>();
            
            // Gemini API 免费额度
            if (pricing.getModelId().contains("1.5-flash")) {
                additionalPricing.put("free_tier_requests_per_minute", 15.0);
                additionalPricing.put("free_tier_requests_per_day", 1500.0);
                additionalPricing.put("free_tier_tokens_per_minute", 1000000.0);
            } else if (pricing.getModelId().contains("1.5-pro")) {
                additionalPricing.put("free_tier_requests_per_minute", 2.0);
                additionalPricing.put("free_tier_requests_per_day", 50.0);
                additionalPricing.put("free_tier_tokens_per_minute", 32000.0);
            } else if (pricing.getModelId().contains("1.0-pro")) {
                additionalPricing.put("free_tier_requests_per_minute", 60.0);
                additionalPricing.put("free_tier_requests_per_day", 1440.0);
                additionalPricing.put("free_tier_tokens_per_minute", 120000.0);
            }
            
            pricing.setAdditionalPricing(additionalPricing);
        });
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
        return getDefaultGeminiPricing()
                .flatMapMany(reactor.core.publisher.Flux::fromIterable)
                .filter(pricing -> pricing.getModelId().equals(modelId))
                .next();
    }
    
    /**
     * 批量更新Gemini定价信息
     * 
     * @return 更新结果
     */
    public Mono<Void> updateAllPricing() {
        log.info("Updating Gemini pricing information...");
        
        return getDefaultGeminiPricing()
                .flatMap(super::batchSavePricing)
                .doOnSuccess(unused -> log.info("Successfully updated Gemini pricing"))
                .doOnError(error -> log.error("Failed to update Gemini pricing", error));
    }
    
    /**
     * 检查模型是否为Gemini模型
     * 
     * @param modelId 模型ID
     * @return 是否为Gemini模型
     */
    public boolean isGeminiModel(String modelId) {
        return modelId != null && 
               (modelId.startsWith("gemini-") || 
                modelId.equals("gemini-pro") || 
                modelId.equals("gemini-pro-vision"));
    }
    
    /**
     * 获取模型类型（Flash, Pro等）
     * 
     * @param modelId 模型ID
     * @return 模型类型
     */
    public String getModelType(String modelId) {
        if (modelId.contains("flash")) {
            return "flash";
        } else if (modelId.contains("pro")) {
            return "pro";
        } else if (modelId.contains("vision")) {
            return "vision";
        } else {
            return "standard";
        }
    }
    
    /**
     * 获取模型版本
     * 
     * @param modelId 模型ID
     * @return 模型版本
     */
    public String getModelVersion(String modelId) {
        if (modelId.contains("1.5")) {
            return "1.5";
        } else if (modelId.contains("1.0")) {
            return "1.0";
        } else {
            return "latest";
        }
    }
    
    /**
     * 检查模型是否在免费额度内
     * 
     * @param modelId 模型ID
     * @param requestsPerMinute 每分钟请求数
     * @param requestsPerDay 每天请求数
     * @return 是否在免费额度内
     */
    public boolean isWithinFreeTier(String modelId, int requestsPerMinute, int requestsPerDay) {
        // 改为返回Mono而不是阻塞调用
        return getDefaultPricing(modelId)
                .map(pricing -> {
                    Map<String, Double> additional = pricing.getAdditionalPricing();
                    if (additional == null) return false;
                    
                    Double freeReqPerMin = additional.get("free_tier_requests_per_minute");
                    Double freeReqPerDay = additional.get("free_tier_requests_per_day");
                    
                    return (freeReqPerMin == null || requestsPerMinute <= freeReqPerMin) &&
                           (freeReqPerDay == null || requestsPerDay <= freeReqPerDay);
                })
                .defaultIfEmpty(false)
                .block(); // 临时使用block，实际应该返回Mono<Boolean>
    }
    
    /**
     * 获取模型的建议用途
     * 
     * @param modelId 模型ID
     * @return 建议用途
     */
    public String getModelRecommendation(String modelId) {
        String type = getModelType(modelId);
        String version = getModelVersion(modelId);
        
        return switch (type) {
            case "flash" -> "适合快速响应和高频调用，成本最低";
            case "pro" -> version.equals("1.5") ? 
                    "最强性能，支持200万token超长上下文" : 
                    "平衡性能与成本的通用模型";
            case "vision" -> "支持图像和文本多模态输入";
            default -> "通用文本生成模型";
        };
    }
}