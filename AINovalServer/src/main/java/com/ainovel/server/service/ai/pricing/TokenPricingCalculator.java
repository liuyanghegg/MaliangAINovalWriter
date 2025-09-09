package com.ainovel.server.service.ai.pricing;

import java.math.BigDecimal;

import reactor.core.publisher.Mono;

/**
 * Token定价计算器接口
 * 定义了计算AI模型token成本的标准方法
 */
public interface TokenPricingCalculator {
    
    /**
     * 计算输入token成本
     * 
     * @param modelId 模型ID
     * @param tokenCount token数量
     * @return 成本（美元）
     */
    Mono<BigDecimal> calculateInputCost(String modelId, int tokenCount);
    
    /**
     * 计算输出token成本
     * 
     * @param modelId 模型ID
     * @param tokenCount token数量
     * @return 成本（美元）
     */
    Mono<BigDecimal> calculateOutputCost(String modelId, int tokenCount);
    
    /**
     * 计算总成本
     * 
     * @param modelId 模型ID
     * @param inputTokens 输入token数量
     * @param outputTokens 输出token数量
     * @return 总成本（美元）
     */
    Mono<BigDecimal> calculateTotalCost(String modelId, int inputTokens, int outputTokens);
    
    /**
     * 获取模型的输入token单价（每1000个token）
     * 
     * @param modelId 模型ID
     * @return 单价（美元）
     */
    Mono<BigDecimal> getInputPricePerThousandTokens(String modelId);
    
    /**
     * 获取模型的输出token单价（每1000个token）
     * 
     * @param modelId 模型ID
     * @return 单价（美元）
     */
    Mono<BigDecimal> getOutputPricePerThousandTokens(String modelId);
    
    /**
     * 检查模型是否有定价信息
     * 
     * @param modelId 模型ID
     * @return 是否有定价信息
     */
    Mono<Boolean> hasPricingInfo(String modelId);
    
    /**
     * 获取提供商名称
     * 
     * @return 提供商名称
     */
    String getProviderName();
}