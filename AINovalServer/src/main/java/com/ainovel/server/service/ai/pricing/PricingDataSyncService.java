package com.ainovel.server.service.ai.pricing;

import java.util.List;

import com.ainovel.server.domain.model.ModelPricing;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 定价数据同步服务接口
 * 用于从官方API或其他来源同步模型定价信息
 */
public interface PricingDataSyncService {
    
    /**
     * 同步指定提供商的定价信息
     * 
     * @param provider 提供商名称
     * @return 同步结果
     */
    Mono<PricingSyncResult> syncProviderPricing(String provider);
    
    /**
     * 同步所有支持的提供商定价信息
     * 
     * @return 同步结果列表
     */
    Flux<PricingSyncResult> syncAllProvidersPricing();
    
    /**
     * 检查提供商是否支持自动价格同步
     * 
     * @param provider 提供商名称
     * @return 是否支持
     */
    Mono<Boolean> isAutoSyncSupported(String provider);
    
    /**
     * 获取支持自动同步的提供商列表
     * 
     * @return 提供商列表
     */
    Flux<String> getSupportedProviders();
    
    /**
     * 手动更新模型定价
     * 
     * @param pricing 定价信息
     * @return 更新结果
     */
    Mono<ModelPricing> updateModelPricing(ModelPricing pricing);
    
    /**
     * 批量更新模型定价
     * 
     * @param pricingList 定价信息列表
     * @return 更新结果
     */
    Mono<PricingSyncResult> batchUpdatePricing(List<ModelPricing> pricingList);
    
    /**
     * 定价同步结果
     */
    record PricingSyncResult(
            String provider,
            int totalModels,
            int successCount,
            int failureCount,
            List<String> errors,
            long duration
    ) {
        
        public static PricingSyncResult success(String provider, int count, long duration) {
            return new PricingSyncResult(provider, count, count, 0, List.of(), duration);
        }
        
        public static PricingSyncResult failure(String provider, List<String> errors, long duration) {
            return new PricingSyncResult(provider, 0, 0, errors.size(), errors, duration);
        }
        
        public static PricingSyncResult partial(String provider, int total, int success, 
                                              List<String> errors, long duration) {
            return new PricingSyncResult(provider, total, success, total - success, errors, duration);
        }
        
        public boolean isSuccess() {
            return failureCount == 0 && successCount > 0;
        }
        
        public boolean isPartialSuccess() {
            return successCount > 0 && failureCount > 0;
        }
        
        public boolean isFailure() {
            return successCount == 0 && failureCount > 0;
        }
    }
}