package com.ainovel.server.task.executor;

import com.ainovel.server.domain.model.UserAIModelConfig;
import com.ainovel.server.service.UserAIModelConfigService;
import com.ainovel.server.task.service.EnhancedRateLimiterService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * AI任务执行器基类
 * 提供公共的限流和AI配置管理功能
 */
@Slf4j
@RequiredArgsConstructor
public abstract class BaseAITaskExecutor {

    protected final UserAIModelConfigService userAIModelConfigService;
    protected final EnhancedRateLimiterService rateLimiterService;

    /**
     * 获取提供商和模型信息
     * 
     * @param userId 用户ID
     * @param useAIEnhancement 是否使用AI增强
     * @param aiConfigId AI配置ID（可为空）
     * @return [providerCode, modelName]
     */
    protected Mono<String[]> getProviderAndModel(String userId, boolean useAIEnhancement, String aiConfigId) {
        if (useAIEnhancement) {
            Mono<UserAIModelConfig> configMono;
            if (aiConfigId != null && !aiConfigId.isBlank()) {
                configMono = userAIModelConfigService.getConfigurationById(userId, aiConfigId);
            } else {
                configMono = userAIModelConfigService.getFirstValidatedConfiguration(userId);
            }
        
            return configMono
                .map(config -> {
                    String providerCode = config.getProvider(); 
                    String modelName = config.getModelName();
                    return new String[]{providerCode, modelName};
                })
                .defaultIfEmpty(new String[]{"openai", "gpt-3.5-turbo"});
        } else {
            return Mono.just(new String[]{"openai", "gpt-3.5-turbo"});
        }
    }

    /**
     * 执行带限流的AI操作
     * 
     * @param userId 用户ID
     * @param useAIEnhancement 是否使用AI增强
     * @param aiConfigId AI配置ID
     * @param requestId 请求ID
     * @param aiOperation AI操作（将在获得限流许可后执行）
     * @param parameters 用于重试的原始参数
     * @return AI操作结果
     */
    protected <T, R> Mono<R> executeWithRateLimit(String userId, boolean useAIEnhancement, 
                                                  String aiConfigId, String requestId, 
                                                  Mono<R> aiOperation, T parameters) {
        return getProviderAndModel(userId, useAIEnhancement, aiConfigId)
            .flatMap(providerModel -> {
                String providerCode = providerModel[0];
                String modelName = providerModel[1];
                
                log.info("[任务:{}] 为AI服务调用申请限流许可: provider={}, model={}", 
                        requestId, providerCode, modelName);
                
                return reactor.core.publisher.Mono.defer(() ->
                        rateLimiterService.tryAcquirePermit(providerCode, userId, modelName, requestId)
                )
                    .doOnError(ex ->
                        log.error("[任务:{}] 限流检查异常: {}", requestId, ex.toString(), ex)
                    )
                    .flatMap(permitResult -> {
                        if (!permitResult.isSuccess()) {
                            log.error("[任务:{}] 获取限流许可失败: {}", requestId, permitResult.getMessage());
                            return Mono.error(new RuntimeException("获取AI服务限流许可失败: " + permitResult.getMessage()));
                        }

                        log.info("[任务:{}] 执行AI操作", requestId);
                        
                        return aiOperation
                            .doOnSuccess(result -> {
                                // 记录成功
                                rateLimiterService.recordSuccess(providerCode, userId, modelName, requestId)
                                    .subscribe();
                            })
                            .onErrorResume(ex -> {
                                // 记录错误
                                log.error("[任务:{}] AI调用出错: {}", requestId, ex.getMessage(), ex);
                                return rateLimiterService.recordErrorAndRetry(providerCode, userId, modelName, 
                                        requestId, ex.getMessage(), parameters)
                                        .then(Mono.error(ex));
                            });
                    });
            });
    }

    /**
     * 执行简单的带限流AI操作（不需要重试参数）
     */
    protected <R> Mono<R> executeWithRateLimit(String userId, boolean useAIEnhancement, 
                                               String aiConfigId, String requestId, 
                                               Mono<R> aiOperation) {
        return executeWithRateLimit(userId, useAIEnhancement, aiConfigId, requestId, aiOperation, null);
    }
} 