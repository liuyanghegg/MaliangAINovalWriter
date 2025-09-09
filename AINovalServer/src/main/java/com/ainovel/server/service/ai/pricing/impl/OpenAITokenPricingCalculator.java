package com.ainovel.server.service.ai.pricing.impl;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import com.ainovel.server.domain.model.ModelPricing;
import com.ainovel.server.service.ai.pricing.AbstractTokenPricingCalculator;
import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * OpenAI Token定价计算器
 * 支持从OpenAI官方API获取最新定价信息
 */
@Slf4j
@Component
public class OpenAITokenPricingCalculator extends AbstractTokenPricingCalculator {
    
    private static final String PROVIDER_NAME = "openai";
    private static final String OPENAI_API_BASE = "https://api.openai.com/v1";
    private static final String PRICING_INFO_URL = OPENAI_API_BASE + "/models";
    
    @Override
    public String getProviderName() {
        return PROVIDER_NAME;
    }
    
    /**
     * 从OpenAI API同步定价信息
     * 
     * @param apiKey OpenAI API密钥
     * @return 同步结果
     */
    public Mono<List<ModelPricing>> syncPricingFromAPI(String apiKey) {
        if (apiKey == null || apiKey.trim().isEmpty()) {
            log.warn("OpenAI API key is not provided, using default pricing");
            return getDefaultOpenAIPricing();
        }
        
        WebClient webClient = WebClient.builder()
                .baseUrl(OPENAI_API_BASE)
                .build();
        
        return webClient.get()
                .uri("/models")
                .header("Authorization", "Bearer " + apiKey)
                .accept(MediaType.APPLICATION_JSON)
                .retrieve()
                .bodyToMono(OpenAIModelsResponse.class)
                .map(response -> response.getData().stream()
                        .filter(model -> isMainModel(model.getId()))
                        .map(this::convertToModelPricing)
                        .toList())
                .doOnSuccess(pricingList -> log.info("Successfully fetched {} OpenAI models", pricingList.size()))
                .onErrorResume(error -> {
                    log.error("Failed to fetch OpenAI models from API: {}", error.getMessage());
                    return getDefaultOpenAIPricing();
                });
    }
    
    /**
     * 检查是否为主要模型（过滤掉已废弃或特殊用途模型）
     * 
     * @param modelId 模型ID
     * @return 是否为主要模型
     */
    private boolean isMainModel(String modelId) {
        return modelId.startsWith("gpt-3.5") || 
               modelId.startsWith("gpt-4") || 
               modelId.contains("turbo") ||
               modelId.contains("davinci") ||
               modelId.contains("curie") ||
               modelId.contains("babbage") ||
               modelId.contains("ada");
    }
    
    /**
     * 转换OpenAI模型信息为定价信息
     * 
     * @param model OpenAI模型信息
     * @return 定价信息
     */
    private ModelPricing convertToModelPricing(OpenAIModel model) {
        // 根据模型ID获取对应的定价信息
        Map<String, Double> pricing = getKnownModelPricing(model.getId());
        
        return ModelPricing.builder()
                .provider(PROVIDER_NAME)
                .modelId(model.getId())
                .modelName(model.getId()) // OpenAI使用ID作为名称
                .inputPricePerThousandTokens(pricing.get("input"))
                .outputPricePerThousandTokens(pricing.get("output"))
                .maxContextTokens(getKnownModelContextLength(model.getId()))
                .supportsStreaming(true)
                .description("OpenAI " + model.getId() + " model")
                .source(ModelPricing.PricingSource.OFFICIAL_API)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .version(1)
                .active(true)
                .build();
    }
    
    /**
     * 获取已知模型的定价信息
     * 
     * @param modelId 模型ID
     * @return 定价信息Map (input, output)
     */
    private Map<String, Double> getKnownModelPricing(String modelId) {
        return switch (modelId) {
            case "gpt-3.5-turbo", "gpt-3.5-turbo-0125" -> Map.of("input", 0.0005, "output", 0.0015);
            case "gpt-3.5-turbo-instruct" -> Map.of("input", 0.0015, "output", 0.002);
            case "gpt-4", "gpt-4-0613" -> Map.of("input", 0.03, "output", 0.06);
            case "gpt-4-32k", "gpt-4-32k-0613" -> Map.of("input", 0.06, "output", 0.12);
            case "gpt-4-turbo", "gpt-4-turbo-2024-04-09" -> Map.of("input", 0.01, "output", 0.03);
            case "gpt-4o", "gpt-4o-2024-05-13" -> Map.of("input", 0.005, "output", 0.015);
            case "gpt-4o-mini", "gpt-4o-mini-2024-07-18" -> Map.of("input", 0.00015, "output", 0.0006);
            case "gpt-4-vision-preview" -> Map.of("input", 0.01, "output", 0.03);
            default -> Map.of("input", 0.002, "output", 0.002); // 默认价格
        };
    }
    
    /**
     * 获取已知模型的上下文长度
     * 
     * @param modelId 模型ID
     * @return 上下文长度
     */
    private Integer getKnownModelContextLength(String modelId) {
        return switch (modelId) {
            case "gpt-3.5-turbo", "gpt-3.5-turbo-0125" -> 16385;
            case "gpt-3.5-turbo-instruct" -> 4096;
            case "gpt-4", "gpt-4-0613" -> 8192;
            case "gpt-4-32k", "gpt-4-32k-0613" -> 32768;
            case "gpt-4-turbo", "gpt-4-turbo-2024-04-09" -> 128000;
            case "gpt-4o", "gpt-4o-2024-05-13", "gpt-4o-mini", "gpt-4o-mini-2024-07-18" -> 128000;
            case "gpt-4-vision-preview" -> 128000;
            default -> 4096; // 默认上下文长度
        };
    }
    
    /**
     * 获取默认OpenAI定价信息
     * 
     * @return 默认定价信息列表
     */
    public Mono<List<ModelPricing>> getDefaultOpenAIPricing() {
        List<ModelPricing> defaultPricing = List.of(
                createDefaultPricing("gpt-3.5-turbo", "GPT-3.5 Turbo", 0.0005, 0.0015, 16385),
                createDefaultPricing("gpt-3.5-turbo-instruct", "GPT-3.5 Turbo Instruct", 0.0015, 0.002, 4096),
                createDefaultPricing("gpt-4", "GPT-4", 0.03, 0.06, 8192),
                createDefaultPricing("gpt-4-32k", "GPT-4 32K", 0.06, 0.12, 32768),
                createDefaultPricing("gpt-4-turbo", "GPT-4 Turbo", 0.01, 0.03, 128000),
                createDefaultPricing("gpt-4o", "GPT-4o", 0.005, 0.015, 128000),
                createDefaultPricing("gpt-4o-mini", "GPT-4o Mini", 0.00015, 0.0006, 128000)
        );
        
        return Mono.just(defaultPricing);
    }
    
    /**
     * 创建默认定价信息
     * 
     * @param modelId 模型ID
     * @param modelName 模型名称
     * @param inputPrice 输入价格
     * @param outputPrice 输出价格
     * @param maxTokens 最大token数
     * @return 定价信息
     */
    private ModelPricing createDefaultPricing(String modelId, String modelName, 
                                            double inputPrice, double outputPrice, int maxTokens) {
        return ModelPricing.builder()
                .provider(PROVIDER_NAME)
                .modelId(modelId)
                .modelName(modelName)
                .inputPricePerThousandTokens(inputPrice)
                .outputPricePerThousandTokens(outputPrice)
                .maxContextTokens(maxTokens)
                .supportsStreaming(true)
                .description("OpenAI " + modelName + " model")
                .source(ModelPricing.PricingSource.DEFAULT)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .version(1)
                .active(true)
                .build();
    }
    
    /**
     * OpenAI API响应结构
     */
    @Data
    private static class OpenAIModelsResponse {
        private String object;
        private List<OpenAIModel> data;
    }
    
    /**
     * OpenAI模型信息结构
     */
    @Data
    private static class OpenAIModel {
        private String id;
        private String object;
        private Long created;
        @JsonProperty("owned_by")
        private String ownedBy;
        private List<Permission> permission;
        private String root;
        private String parent;
    }
    
    /**
     * OpenAI模型权限结构
     */
    @Data
    private static class Permission {
        private String id;
        private String object;
        private Long created;
        @JsonProperty("allow_create_engine")
        private Boolean allowCreateEngine;
        @JsonProperty("allow_sampling")
        private Boolean allowSampling;
        @JsonProperty("allow_logprobs")
        private Boolean allowLogprobs;
        @JsonProperty("allow_search_indices")
        private Boolean allowSearchIndices;
        @JsonProperty("allow_view")
        private Boolean allowView;
        @JsonProperty("allow_fine_tuning")
        private Boolean allowFineTuning;
        private String organization;
        private String group;
        @JsonProperty("is_blocking")
        private Boolean isBlocking;
    }
}