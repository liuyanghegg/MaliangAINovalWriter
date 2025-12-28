package com.ainovel.server.service;

import com.ainovel.server.domain.model.AIFeatureType;

import reactor.core.publisher.Mono;

/**
 * AI功能授权服务接口
 * 负责检查用户是否有权限使用特定的AI功能
 */
public interface AIFeatureAuthorizationService {
    
    /**
     * 检查用户是否有权限使用指定的AI功能
     * 
     * @param userId 用户ID
     * @param featureType AI功能类型
     * @return 是否有权限
     */
    Mono<Boolean> hasFeaturePermission(String userId, AIFeatureType featureType);
    
    /**
     * 检查用户是否可以使用指定的AI功能（包括权限和积分检查）
     * 
     * @param userId 用户ID
     * @param provider 提供商
     * @param modelId 模型ID
     * @param featureType AI功能类型
     * @param estimatedInputTokens 预估输入token数量
     * @param estimatedOutputTokens 预估输出token数量
     * @return 授权结果
     */
    Mono<AIFeatureAuthorizationResult> authorizeFeatureUsage(String userId, String provider, String modelId, 
                                                             AIFeatureType featureType, int estimatedInputTokens, int estimatedOutputTokens);
    
    /**
     * 执行AI功能调用的完整授权和积分扣减流程
     * 
     * @param userId 用户ID
     * @param provider 提供商
     * @param modelId 模型ID
     * @param featureType AI功能类型
     * @param inputTokens 实际输入token数量
     * @param outputTokens 实际输出token数量
     * @return 执行结果
     */
    Mono<AIFeatureExecutionResult> executeFeatureWithCredits(String userId, String provider, String modelId, 
                                                             AIFeatureType featureType, int inputTokens, int outputTokens);
    
    /**
     * AI功能授权结果
     */
    class AIFeatureAuthorizationResult {
        private final boolean authorized;
        private final String message;
        private final long estimatedCreditCost;
        
        public AIFeatureAuthorizationResult(boolean authorized, String message, long estimatedCreditCost) {
            this.authorized = authorized;
            this.message = message;
            this.estimatedCreditCost = estimatedCreditCost;
        }
        
        public boolean isAuthorized() {
            return authorized;
        }
        
        public String getMessage() {
            return message;
        }
        
        public long getEstimatedCreditCost() {
            return estimatedCreditCost;
        }
        
        public static AIFeatureAuthorizationResult authorized(long estimatedCreditCost) {
            return new AIFeatureAuthorizationResult(true, "授权成功", estimatedCreditCost);
        }
        
        public static AIFeatureAuthorizationResult denied(String message) {
            return new AIFeatureAuthorizationResult(false, message, 0);
        }
    }
    
    /**
     * AI功能执行结果
     */
    class AIFeatureExecutionResult {
        private final boolean success;
        private final String message;
        private final long creditsDeducted;
        
        public AIFeatureExecutionResult(boolean success, String message, long creditsDeducted) {
            this.success = success;
            this.message = message;
            this.creditsDeducted = creditsDeducted;
        }
        
        public boolean isSuccess() {
            return success;
        }
        
        public String getMessage() {
            return message;
        }
        
        public long getCreditsDeducted() {
            return creditsDeducted;
        }
        
        public static AIFeatureExecutionResult success(long creditsDeducted) {
            return new AIFeatureExecutionResult(true, "执行成功", creditsDeducted);
        }
        
        public static AIFeatureExecutionResult failure(String message) {
            return new AIFeatureExecutionResult(false, message, 0);
        }
    }
}