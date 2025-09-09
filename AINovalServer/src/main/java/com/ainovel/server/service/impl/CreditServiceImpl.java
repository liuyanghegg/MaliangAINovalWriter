package com.ainovel.server.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.data.mongodb.core.ReactiveMongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import com.mongodb.client.result.UpdateResult;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.ModelPricing;
import com.ainovel.server.domain.model.PublicModelConfig;
import com.ainovel.server.domain.model.SystemConfig;
import com.ainovel.server.domain.model.User;
import com.ainovel.server.repository.PublicModelConfigRepository;
import com.ainovel.server.repository.SystemConfigRepository;
import com.ainovel.server.repository.UserRepository;
import com.ainovel.server.service.CreditService;
import com.ainovel.server.repository.ModelPricingRepository;

import reactor.core.publisher.Mono;

/**
 * 积分管理服务实现
 */
@Service
public class CreditServiceImpl implements CreditService {
    
    private final UserRepository userRepository;
    private final SystemConfigRepository systemConfigRepository;
    private final PublicModelConfigRepository publicModelConfigRepository;
    private final ModelPricingRepository modelPricingRepository;
    private final ReactiveMongoTemplate mongoTemplate;
    
    // 默认配置常量
    private static final double DEFAULT_CREDIT_TO_USD_RATE = 200.0; // 1美元 = 200积分 (即1积分 = 0.005美元)
    private static final long DEFAULT_NEW_USER_CREDITS = 200L; // 新用户赠送200积分
    
    @Autowired
    public CreditServiceImpl(UserRepository userRepository, 
                           SystemConfigRepository systemConfigRepository,
                           PublicModelConfigRepository publicModelConfigRepository,
                           ModelPricingRepository modelPricingRepository,
                           ReactiveMongoTemplate mongoTemplate) {
        this.userRepository = userRepository;
        this.systemConfigRepository = systemConfigRepository;
        this.publicModelConfigRepository = publicModelConfigRepository;
        this.modelPricingRepository = modelPricingRepository;
        this.mongoTemplate = mongoTemplate;
    }
    
    @Override
    @Transactional(propagation = Propagation.SUPPORTS)
    public Mono<Boolean> deductCredits(String userId, long amount) {
        if (amount <= 0L) {
            return Mono.just(true);
        }
        Query query = new Query(Criteria.where("_id").is(userId).and("credits").gte(amount));
        Update update = new Update()
                .inc("credits", -amount)
                .inc("totalCreditsUsed", amount);
        return mongoTemplate.updateFirst(query, update, User.class)
                .map(UpdateResult::getModifiedCount)
                .map(modified -> modified != null && modified > 0);
    }
    
    @Override
    @Transactional(propagation = Propagation.SUPPORTS)
    public Mono<Boolean> addCredits(String userId, long amount, String reason) {
        if (amount == 0L) {
            return Mono.just(true);
        }
        Query query = new Query(Criteria.where("_id").is(userId));
        Update update = new Update().inc("credits", amount);
        return mongoTemplate.updateFirst(query, update, User.class)
                .map(UpdateResult::getModifiedCount)
                .map(modified -> modified != null && modified > 0);
    }
    
    @Override
    public Mono<Long> getUserCredits(String userId) {
        return userRepository.findById(userId)
                .map(user -> user.getCredits() != null ? user.getCredits() : 0L)
                .defaultIfEmpty(0L);
    }
    
    @Override
    public Mono<Long> calculateCreditCost(String provider, String modelId, AIFeatureType featureType, int inputTokens, int outputTokens) {
        return Mono.zip(
                getModelPricing(provider, modelId),
                getPublicModelConfig(provider, modelId),
                getCreditToUsdRate()
        ).map(tuple -> {
            ModelPricing modelPricing = tuple.getT1();
            PublicModelConfig config = tuple.getT2();
            double creditRate = tuple.getT3();
            
            // 验证模型是否支持该功能
            if (!config.isEnabledForFeature(featureType)) {
                throw new IllegalArgumentException("模型 " + provider + ":" + modelId + " 不支持功能: " + featureType);
            }
            
            // 计算美元成本
            double usdCost = modelPricing.calculateTotalCost(inputTokens, outputTokens);
            
            // 应用积分汇率乘数
            double multiplier = config.getCreditRateMultiplier() != null ? config.getCreditRateMultiplier() : 1.0;
            
            // 转换为积分并向上取整
            long creditCost = Math.round(Math.ceil(usdCost * creditRate * multiplier));
            
            return Math.max(1L, creditCost); // 最小消费1积分
        });
    }
    
    @Override
    public Mono<Boolean> hasEnoughCredits(String userId, String provider, String modelId, AIFeatureType featureType, int estimatedInputTokens, int estimatedOutputTokens) {
        return Mono.zip(
                getUserCredits(userId),
                calculateCreditCost(provider, modelId, featureType, estimatedInputTokens, estimatedOutputTokens)
        ).map(tuple -> tuple.getT1() >= tuple.getT2());
    }
    
    @Override
    @Transactional(propagation = Propagation.SUPPORTS)
    public Mono<CreditDeductionResult> deductCreditsForAI(String userId, String provider, String modelId, AIFeatureType featureType, int inputTokens, int outputTokens) {
        return calculateCreditCost(provider, modelId, featureType, inputTokens, outputTokens)
                .flatMap(creditCost -> 
                    deductCredits(userId, creditCost)
                            .map(success -> {
                                if (success) {
                                    return CreditDeductionResult.success(creditCost);
                                } else {
                                    return CreditDeductionResult.failure("积分余额不足，需要 " + creditCost + " 积分");
                                }
                            })
                )
                .onErrorResume(throwable -> 
                    Mono.just(CreditDeductionResult.failure("积分扣减失败: " + throwable.getMessage()))
                );
    }
    
    @Override
    public Mono<Double> getCreditToUsdRate() {
        return systemConfigRepository.findByConfigKey(SystemConfig.Keys.CREDIT_TO_USD_RATE)
                .map(config -> {
                    Double rate = config.getNumericValue();
                    return rate != null ? rate : DEFAULT_CREDIT_TO_USD_RATE;
                })
                .defaultIfEmpty(DEFAULT_CREDIT_TO_USD_RATE);
    }
    
    @Override
    @Transactional
    public Mono<Boolean> setCreditToUsdRate(double rate) {
        return systemConfigRepository.findByConfigKey(SystemConfig.Keys.CREDIT_TO_USD_RATE)
                .switchIfEmpty(createDefaultCreditRateConfig())
                .flatMap(config -> {
                    config.setConfigValue(String.valueOf(rate));
                    config.setUpdatedAt(java.time.LocalDateTime.now());
                    return systemConfigRepository.save(config);
                })
                .thenReturn(true)
                .onErrorReturn(false);
    }
    
    @Override
    @Transactional
    public Mono<Boolean> grantNewUserCredits(String userId) {
        return systemConfigRepository.findByConfigKey(SystemConfig.Keys.NEW_USER_CREDITS)
                .map(config -> {
                    Long credits = config.getLongValue();
                    return credits != null ? credits : DEFAULT_NEW_USER_CREDITS;
                })
                .defaultIfEmpty(DEFAULT_NEW_USER_CREDITS)
                .flatMap(credits -> addCredits(userId, credits, "新用户注册赠送"));
    }
    
    private Mono<ModelPricing> getModelPricing(String provider, String modelId) {
        return modelPricingRepository.findByProviderAndModelId(provider, modelId)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("模型定价信息不存在: " + provider + ":" + modelId)));
    }
    
    private Mono<PublicModelConfig> getPublicModelConfig(String provider, String modelId) {
        return publicModelConfigRepository.findByProviderAndModelId(provider, modelId)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("模型配置不存在或未开放: " + provider + ":" + modelId)));
    }
    
    private Mono<SystemConfig> createDefaultCreditRateConfig() {
        SystemConfig config = SystemConfig.builder()
                .configKey(SystemConfig.Keys.CREDIT_TO_USD_RATE)
                .configValue(String.valueOf(DEFAULT_CREDIT_TO_USD_RATE))
                .description("积分与美元的汇率（1美元等于多少积分）")
                .configType(SystemConfig.ConfigType.NUMBER)
                .configGroup("credit")
                .enabled(true)
                .createdAt(java.time.LocalDateTime.now())
                .updatedAt(java.time.LocalDateTime.now())
                .build();
        
        return systemConfigRepository.save(config);
    }
}