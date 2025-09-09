package com.ainovel.server.controller;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.domain.model.ModelPricing;
import com.ainovel.server.repository.ModelPricingRepository;
import com.ainovel.server.service.ai.pricing.PricingDataSyncService;
import com.ainovel.server.service.ai.pricing.TokenPricingCalculator;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 模型定价管理控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/pricing")
@Tag(name = "ModelPricing", description = "模型定价管理API")
public class ModelPricingController {
    
    @Autowired
    private ModelPricingRepository modelPricingRepository;
    
    @Autowired
    private PricingDataSyncService pricingDataSyncService;
    
    @Autowired
    private List<TokenPricingCalculator> pricingCalculators;
    
    /**
     * 获取所有模型定价信息
     */
    @GetMapping
    @Operation(summary = "获取所有模型定价信息")
    public Mono<ResponseEntity<ApiResponse<List<ModelPricing>>>> getAllPricing() {
        return modelPricingRepository.findByActiveTrue()
                .collectList()
                .map(pricingList -> ResponseEntity.ok(ApiResponse.success(pricingList)))
                .doOnSuccess(response -> log.info("Retrieved {} pricing records", 
                        response.getBody().getData().size()));
    }
    
    /**
     * 根据提供商获取定价信息
     */
    @GetMapping("/provider/{provider}")
    @Operation(summary = "根据提供商获取定价信息")
    public Mono<ResponseEntity<ApiResponse<List<ModelPricing>>>> getPricingByProvider(
            @Parameter(description = "提供商名称") @PathVariable String provider) {
        return modelPricingRepository.findByProviderAndActiveTrue(provider)
                .collectList()
                .map(pricingList -> ResponseEntity.ok(ApiResponse.success(pricingList)))
                .doOnSuccess(response -> log.info("Retrieved {} pricing records for provider {}", 
                        response.getBody().getData().size(), provider));
    }
    
    /**
     * 获取特定模型的定价信息
     */
    @GetMapping("/provider/{provider}/model/{modelId}")
    @Operation(summary = "获取特定模型的定价信息")
    public Mono<ResponseEntity<ApiResponse<ModelPricing>>> getModelPricing(
            @Parameter(description = "提供商名称") @PathVariable String provider,
            @Parameter(description = "模型ID") @PathVariable String modelId) {
        return modelPricingRepository.findByProviderAndModelIdAndActiveTrue(provider, modelId)
                .map(pricing -> ResponseEntity.ok(ApiResponse.success(pricing)))
                .switchIfEmpty(Mono.just(ResponseEntity.notFound().build()));
    }
    
    /**
     * 计算Token成本
     */
    @PostMapping("/calculate")
    @Operation(summary = "计算Token成本")
    public Mono<ResponseEntity<ApiResponse<CostCalculationResult>>> calculateCost(
            @RequestBody CostCalculationRequest request) {
        
        // 查找对应的计算器
        TokenPricingCalculator calculator = pricingCalculators.stream()
                .filter(calc -> calc.getProviderName().equals(request.getProvider()))
                .findFirst()
                .orElse(null);
        
        if (calculator == null) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("不支持的提供商: " + request.getProvider())));
        }
        
        return calculator.calculateInputCost(request.getModelId(), request.getInputTokens())
                .zipWith(calculator.calculateOutputCost(request.getModelId(), request.getOutputTokens()))
                .zipWith(calculator.calculateTotalCost(request.getModelId(), 
                        request.getInputTokens(), request.getOutputTokens()))
                .map(tuple -> {
                    BigDecimal inputCost = tuple.getT1().getT1();
                    BigDecimal outputCost = tuple.getT1().getT2();
                    BigDecimal totalCost = tuple.getT2();
                    
                    CostCalculationResult result = new CostCalculationResult();
                    result.setProvider(request.getProvider());
                    result.setModelId(request.getModelId());
                    result.setInputTokens(request.getInputTokens());
                    result.setOutputTokens(request.getOutputTokens());
                    result.setInputCost(inputCost);
                    result.setOutputCost(outputCost);
                    result.setTotalCost(totalCost);
                    
                    return ResponseEntity.ok(ApiResponse.success(result));
                });
    }
    
    /**
     * 同步提供商定价信息
     */
    @PostMapping("/sync/{provider}")
    @Operation(summary = "同步提供商定价信息")
    @PreAuthorize("hasRole('ADMIN')")
    public Mono<ResponseEntity<ApiResponse<PricingDataSyncService.PricingSyncResult>>> syncProviderPricing(
            @Parameter(description = "提供商名称") @PathVariable String provider) {
        return pricingDataSyncService.syncProviderPricing(provider)
                .map(result -> ResponseEntity.ok(ApiResponse.success(result)))
                .doOnSuccess(response -> log.info("Sync completed for provider {}: {}", 
                        provider, response.getBody().getData()));
    }
    
    /**
     * 同步所有提供商定价信息
     */
    @PostMapping("/sync-all")
    @Operation(summary = "同步所有提供商定价信息")
    @PreAuthorize("hasRole('ADMIN')")
    public Mono<ResponseEntity<ApiResponse<List<PricingDataSyncService.PricingSyncResult>>>> syncAllPricing() {
        return pricingDataSyncService.syncAllProvidersPricing()
                .collectList()
                .map(results -> ResponseEntity.ok(ApiResponse.success(results)))
                .doOnSuccess(response -> log.info("Sync completed for all providers: {} results", 
                        response.getBody().getData().size()));
    }
    
    /**
     * 创建或更新模型定价
     */
    @PutMapping
    @Operation(summary = "创建或更新模型定价")
    @PreAuthorize("hasRole('ADMIN')")
    public Mono<ResponseEntity<ApiResponse<ModelPricing>>> upsertPricing(
            @RequestBody ModelPricing pricing) {
        return pricingDataSyncService.updateModelPricing(pricing)
                .map(savedPricing -> ResponseEntity.ok(ApiResponse.success(savedPricing)))
                .doOnSuccess(response -> log.info("Updated pricing for {}:{}", 
                        pricing.getProvider(), pricing.getModelId()));
    }
    
    /**
     * 批量更新模型定价
     */
    @PutMapping("/batch")
    @Operation(summary = "批量更新模型定价")
    @PreAuthorize("hasRole('ADMIN')")
    public Mono<ResponseEntity<ApiResponse<PricingDataSyncService.PricingSyncResult>>> batchUpdatePricing(
            @RequestBody List<ModelPricing> pricingList) {
        return pricingDataSyncService.batchUpdatePricing(pricingList)
                .map(result -> ResponseEntity.ok(ApiResponse.success(result)))
                .doOnSuccess(response -> log.info("Batch update completed: {}", 
                        response.getBody().getData()));
    }
    
    /**
     * 删除模型定价（软删除）
     */
    @DeleteMapping("/provider/{provider}/model/{modelId}")
    @Operation(summary = "删除模型定价")
    @PreAuthorize("hasRole('ADMIN')")
    public Mono<ResponseEntity<ApiResponse<Void>>> deletePricing(
            @Parameter(description = "提供商名称") @PathVariable String provider,
            @Parameter(description = "模型ID") @PathVariable String modelId) {
        return modelPricingRepository.findByProviderAndModelIdAndActiveTrue(provider, modelId)
                .flatMap(pricing -> {
                    pricing.setActive(false);
                    pricing.setUpdatedAt(java.time.LocalDateTime.now());
                    return modelPricingRepository.save(pricing);
                })
                .then(Mono.just(ResponseEntity.ok(ApiResponse.<Void>success())))
                .switchIfEmpty(Mono.just(ResponseEntity.notFound().build()))
                .doOnSuccess(response -> log.info("Deleted pricing for {}:{}", provider, modelId));
    }
    
    /**
     * 搜索模型定价
     */
    @GetMapping("/search")
    @Operation(summary = "搜索模型定价")
    public Flux<ModelPricing> searchPricing(
            @Parameter(description = "最小价格") @RequestParam(required = false) Double minPrice,
            @Parameter(description = "最大价格") @RequestParam(required = false) Double maxPrice,
            @Parameter(description = "最小Token数") @RequestParam(required = false) Integer minTokens,
            @Parameter(description = "最大Token数") @RequestParam(required = false) Integer maxTokens,
            @Parameter(description = "提供商") @RequestParam(required = false) String provider) {
        
        Flux<ModelPricing> query = modelPricingRepository.findByActiveTrue();
        
        if (provider != null && !provider.trim().isEmpty()) {
            query = modelPricingRepository.findByProviderAndActiveTrue(provider);
        }
        
        if (minPrice != null && maxPrice != null) {
            query = modelPricingRepository.findByPriceRange(minPrice, maxPrice);
        }
        
        if (minTokens != null && maxTokens != null) {
            query = modelPricingRepository.findByTokenRange(minTokens, maxTokens);
        }
        
        return query.doOnNext(pricing -> log.debug("Found pricing: {}:{}", 
                pricing.getProvider(), pricing.getModelId()));
    }
    
    /**
     * 获取支持的提供商列表
     */
    @GetMapping("/providers")
    @Operation(summary = "获取支持的提供商列表")
    public Flux<String> getSupportedProviders() {
        return pricingDataSyncService.getSupportedProviders()
                .doOnNext(provider -> log.debug("Supported provider: {}", provider));
    }
    
    /**
     * 成本计算请求
     */
    @Data
    public static class CostCalculationRequest {
        private String provider;
        private String modelId;
        private int inputTokens;
        private int outputTokens;
    }
    
    /**
     * 成本计算结果
     */
    @Data
    public static class CostCalculationResult {
        private String provider;
        private String modelId;
        private int inputTokens;
        private int outputTokens;
        private BigDecimal inputCost;
        private BigDecimal outputCost;
        private BigDecimal totalCost;
        
        public String getFormattedTotalCost() {
            return String.format("$%.6f", totalCost);
        }
        
        public String getFormattedInputCost() {
            return String.format("$%.6f", inputCost);
        }
        
        public String getFormattedOutputCost() {
            return String.format("$%.6f", outputCost);
        }
    }
}