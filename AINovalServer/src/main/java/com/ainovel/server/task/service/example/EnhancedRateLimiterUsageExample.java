package com.ainovel.server.task.service.example;

import com.ainovel.server.task.service.EnhancedRateLimiterService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

/**
 * 增强限流器使用示例
 * 展示如何在实际任务中使用新的限流重试系统
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EnhancedRateLimiterUsageExample {
    
    private final EnhancedRateLimiterService rateLimiterService;
    
    /**
     * 调用AI服务的标准流程
     * 1. 获取限流许可
     * 2. 调用AI服务  
     * 3. 处理结果或错误
     * 4. 记录成功/失败
     */
    public Mono<String> callAIServiceWithRateLimit(String providerCode, String userId, String modelName, String prompt) {
        String requestId = generateRequestId();
        
        log.info("开始AI服务调用: provider={}, user={}, model={}, requestId={}", 
                providerCode, userId, modelName, requestId);
        
        return rateLimiterService.tryAcquirePermit(providerCode, userId, modelName, requestId)
                .flatMap(permitResult -> {
                    if (permitResult.isSuccess()) {
                        // 获取到许可，调用AI服务
                        return callActualAIService(providerCode, modelName, prompt, requestId)
                                .flatMap(result -> {
                                    // 记录成功
                                    return rateLimiterService.recordSuccess(providerCode, userId, modelName, requestId)
                                            .then(Mono.just(result));
                                })
                                .onErrorResume(ex -> {
                                    // 记录错误并处理重试
                                    String errorType = extractErrorType(ex);
                                    return rateLimiterService.recordErrorAndRetry(
                                            providerCode, userId, modelName, requestId, errorType, prompt)
                                            .flatMap(retryResult -> {
                                                if (retryResult.isScheduled()) {
                                                    return Mono.error(new RuntimeException(
                                                            String.format("请求失败，已安排重试 (第%d次，下次重试时间: %d)", 
                                                                    retryResult.getAttemptNumber(), 
                                                                    retryResult.getNextRetryTime())));
                                                } else {
                                                    return Mono.error(new RuntimeException(
                                                            "请求失败且重试已耗尽: " + retryResult.getMessage()));
                                                }
                                            });
                                });
                    } else {
                        // 未获取到许可
                        return Mono.error(new RuntimeException("限流器拒绝请求: " + permitResult.getMessage()));
                    }
                });
    }
    
    /**
     * 模拟实际AI服务调用
     */
    private Mono<String> callActualAIService(String providerCode, String modelName, String prompt, String requestId) {
        // 这里是实际的AI服务调用逻辑
        return Mono.fromCallable(() -> {
            // 模拟不同的错误情况
            if (providerCode.equals("gemini") && Math.random() < 0.3) {
                throw new RuntimeException("HTTP error (429): quota exceeded");
            }
            if (Math.random() < 0.1) {
                throw new RuntimeException("Network timeout");
            }
            
            // 模拟成功响应
            return String.format("AI响应: 对于提示 '%s' 的回复 [请求ID: %s]", prompt, requestId);
        });
    }
    
    /**
     * 提取错误类型
     */
    private String extractErrorType(Throwable ex) {
        String message = ex.getMessage();
        if (message.contains("429") || message.contains("quota")) {
            return "quota_exceeded";
        } else if (message.contains("timeout")) {
            return "timeout";
        } else if (message.contains("502") || message.contains("503")) {
            return "server_error";
        } else {
            return "unknown_error";
        }
    }
    
    /**
     * 生成请求ID
     */
    private String generateRequestId() {
        return "req_" + System.currentTimeMillis() + "_" + (int)(Math.random() * 1000);
    }
    
    /**
     * 获取限流器状态示例
     */
    public Mono<String> getRateLimiterStatusExample() {
        return rateLimiterService.getStatus("gemini", "user123", "gemini-2.0-flash")
                .map(status -> String.format(
                        "限流器状态: provider=%s, strategy=%s, rate=%.2f, available=%d, retryCount=%d",
                        status.getProvider() != null ? status.getProvider().getCode() : "unknown",
                        status.getStrategyName(),
                        status.getEffectiveRate(),
                        status.getAvailablePermits(),
                        status.getRetryCount()
                ));
    }
    
    /**
     * 重置限流器示例
     */
    public Mono<String> resetRateLimiterExample() {
        return rateLimiterService.resetRateLimiter("gemini", "user123", "gemini-2.0-flash")
                .then(Mono.just("限流器已重置"));
    }
    
    /**
     * 批量测试不同供应商的限流效果
     */
    public Mono<String> batchTestRateLimiting() {
        String[] providers = {"gemini", "openai", "anthropic"};
        String userId = "test_user";
        String modelName = "default";
        
        return Mono.fromCallable(() -> {
            StringBuilder result = new StringBuilder("批量限流测试结果:\n");
            
            for (String provider : providers) {
                for (int i = 0; i < 10; i++) {
                    final int requestNumber = i + 1; // 创建final变量
                    String requestId = generateRequestId();
                    
                    rateLimiterService.tryAcquirePermit(provider, userId, modelName, requestId)
                            .subscribe(permitResult -> {
                                result.append(String.format("Provider: %s, Request: %d, Success: %b\n",
                                        provider, requestNumber, permitResult.isSuccess()));
                            });
                }
            }
            
            return result.toString();
        });
    }
} 