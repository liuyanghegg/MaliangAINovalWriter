package com.ainovel.server.service.ai.pricing;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import lombok.extern.slf4j.Slf4j;

/**
 * Token定价计算器工厂
 * 负责根据提供商名称获取对应的定价计算器
 */
@Slf4j
@Component
public class TokenPricingCalculatorFactory {
    
    private final Map<String, TokenPricingCalculator> calculatorMap;
    
    @Autowired
    public TokenPricingCalculatorFactory(List<TokenPricingCalculator> calculators) {
        this.calculatorMap = calculators.stream()
                .collect(Collectors.toMap(
                        TokenPricingCalculator::getProviderName,
                        calculator -> calculator,
                        (existing, replacement) -> {
                            log.warn("Duplicate calculator for provider {}, using existing", 
                                    existing.getProviderName());
                            return existing;
                        }
                ));
        
        log.info("Initialized pricing calculators for providers: {}", 
                calculatorMap.keySet());
    }
    
    /**
     * 根据提供商名称获取定价计算器
     * 
     * @param provider 提供商名称
     * @return 定价计算器（可能为空）
     */
    public Optional<TokenPricingCalculator> getCalculator(String provider) {
        if (provider == null || provider.trim().isEmpty()) {
            return Optional.empty();
        }
        
        TokenPricingCalculator calculator = calculatorMap.get(provider.toLowerCase());
        if (calculator == null) {
            log.debug("No pricing calculator found for provider: {}", provider);
        }
        return Optional.ofNullable(calculator);
    }
    
    /**
     * 获取所有支持的提供商
     * 
     * @return 提供商名称列表
     */
    public List<String> getSupportedProviders() {
        return List.copyOf(calculatorMap.keySet());
    }
    
    /**
     * 检查是否支持指定提供商
     * 
     * @param provider 提供商名称
     * @return 是否支持
     */
    public boolean isSupported(String provider) {
        return provider != null && calculatorMap.containsKey(provider.toLowerCase());
    }
    
    /**
     * 获取所有计算器
     * 
     * @return 计算器列表
     */
    public List<TokenPricingCalculator> getAllCalculators() {
        return List.copyOf(calculatorMap.values());
    }
}