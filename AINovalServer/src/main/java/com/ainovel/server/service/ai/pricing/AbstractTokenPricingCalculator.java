package com.ainovel.server.service.ai.pricing;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;

import com.ainovel.server.domain.model.ModelPricing;
import com.ainovel.server.repository.ModelPricingRepository;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * Token定价计算器抽象基类
 * 提供通用的定价计算逻辑和数据库访问
 */
@Slf4j
public abstract class AbstractTokenPricingCalculator implements TokenPricingCalculator {
    
    @Autowired
    protected ModelPricingRepository modelPricingRepository;
    
    /**
     * 精度控制：保留6位小数
     */
    protected static final int PRECISION = 6;
    protected static final RoundingMode ROUNDING_MODE = RoundingMode.HALF_UP;
    
    @Override
    public Mono<BigDecimal> calculateInputCost(String modelId, int tokenCount) {
        return getModelPricing(modelId)
                .map(pricing -> {
                    double cost = pricing.calculateInputCost(tokenCount);
                    return BigDecimal.valueOf(cost).setScale(PRECISION, ROUNDING_MODE);
                })
                .switchIfEmpty(Mono.just(BigDecimal.ZERO));
    }
    
    @Override
    public Mono<BigDecimal> calculateOutputCost(String modelId, int tokenCount) {
        return getModelPricing(modelId)
                .map(pricing -> {
                    double cost = pricing.calculateOutputCost(tokenCount);
                    return BigDecimal.valueOf(cost).setScale(PRECISION, ROUNDING_MODE);
                })
                .switchIfEmpty(Mono.just(BigDecimal.ZERO));
    }
    
    @Override
    public Mono<BigDecimal> calculateTotalCost(String modelId, int inputTokens, int outputTokens) {
        return getModelPricing(modelId)
                .map(pricing -> {
                    double cost = pricing.calculateTotalCost(inputTokens, outputTokens);
                    return BigDecimal.valueOf(cost).setScale(PRECISION, ROUNDING_MODE);
                })
                .switchIfEmpty(Mono.just(BigDecimal.ZERO));
    }
    
    @Override
    public Mono<BigDecimal> getInputPricePerThousandTokens(String modelId) {
        return getModelPricing(modelId)
                .map(pricing -> {
                    if (pricing.getUnifiedPricePerThousandTokens() != null) {
                        return BigDecimal.valueOf(pricing.getUnifiedPricePerThousandTokens())
                                .setScale(PRECISION, ROUNDING_MODE);
                    }
                    if (pricing.getInputPricePerThousandTokens() != null) {
                        return BigDecimal.valueOf(pricing.getInputPricePerThousandTokens())
                                .setScale(PRECISION, ROUNDING_MODE);
                    }
                    return BigDecimal.ZERO;
                })
                .switchIfEmpty(Mono.just(BigDecimal.ZERO));
    }
    
    @Override
    public Mono<BigDecimal> getOutputPricePerThousandTokens(String modelId) {
        return getModelPricing(modelId)
                .map(pricing -> {
                    if (pricing.getUnifiedPricePerThousandTokens() != null) {
                        return BigDecimal.valueOf(pricing.getUnifiedPricePerThousandTokens())
                                .setScale(PRECISION, ROUNDING_MODE);
                    }
                    if (pricing.getOutputPricePerThousandTokens() != null) {
                        return BigDecimal.valueOf(pricing.getOutputPricePerThousandTokens())
                                .setScale(PRECISION, ROUNDING_MODE);
                    }
                    return BigDecimal.ZERO;
                })
                .switchIfEmpty(Mono.just(BigDecimal.ZERO));
    }
    
    @Override
    public Mono<Boolean> hasPricingInfo(String modelId) {
        return modelPricingRepository.existsByProviderAndModelIdAndActiveTrue(getProviderName(), modelId);
    }
    
    /**
     * 获取模型定价信息
     * 
     * @param modelId 模型ID
     * @return 定价信息
     */
    protected Mono<ModelPricing> getModelPricing(String modelId) {
        return modelPricingRepository.findByProviderAndModelIdAndActiveTrue(getProviderName(), modelId)
                .doOnNext(pricing -> log.debug("Found pricing for model {}: {}", modelId, pricing))
                .doOnError(error -> log.error("Error getting pricing for model {}: {}", modelId, error.getMessage()));
    }
    
    /**
     * 创建或更新模型定价信息
     * 
     * @param pricing 定价信息
     * @return 保存后的定价信息
     */
    protected Mono<ModelPricing> saveOrUpdatePricing(ModelPricing pricing) {
        return modelPricingRepository.findByProviderAndModelIdAndActiveTrue(
                pricing.getProvider(), pricing.getModelId())
                .flatMap(existing -> {
                    // 更新现有记录
                    existing.setInputPricePerThousandTokens(pricing.getInputPricePerThousandTokens());
                    existing.setOutputPricePerThousandTokens(pricing.getOutputPricePerThousandTokens());
                    existing.setUnifiedPricePerThousandTokens(pricing.getUnifiedPricePerThousandTokens());
                    existing.setMaxContextTokens(pricing.getMaxContextTokens());
                    existing.setSupportsStreaming(pricing.getSupportsStreaming());
                    existing.setDescription(pricing.getDescription());
                    existing.setAdditionalPricing(pricing.getAdditionalPricing());
                    existing.setSource(pricing.getSource());
                    existing.setUpdatedAt(java.time.LocalDateTime.now());
                    existing.setVersion(existing.getVersion() + 1);
                    return modelPricingRepository.save(existing);
                })
                .switchIfEmpty(
                    // 创建新记录
                    Mono.defer(() -> {
                        pricing.setCreatedAt(java.time.LocalDateTime.now());
                        pricing.setUpdatedAt(java.time.LocalDateTime.now());
                        pricing.setVersion(1);
                        pricing.setActive(true);
                        return modelPricingRepository.save(pricing);
                    })
                );
    }
    
    /**
     * 批量保存定价信息
     * 
     * @param pricingList 定价信息列表
     * @return 保存结果
     */
    protected Mono<Void> batchSavePricing(List<ModelPricing> pricingList) {
        return reactor.core.publisher.Flux.fromIterable(pricingList)
                .flatMap(this::saveOrUpdatePricing)
                .then()
                .doOnSuccess(unused -> log.info("Successfully saved {} pricing records for provider {}", 
                        pricingList.size(), getProviderName()))
                .doOnError(error -> log.error("Error saving pricing records for provider {}: {}", 
                        getProviderName(), error.getMessage()));
    }
    
    /**
     * 使用模型的默认定价信息（用于回退）
     * 子类可以重写此方法提供默认定价
     * 
     * @param modelId 模型ID
     * @return 默认定价信息
     */
    protected Mono<ModelPricing> getDefaultPricing(String modelId) {
        return Mono.empty();
    }
}