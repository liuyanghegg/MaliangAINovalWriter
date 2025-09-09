package com.ainovel.server.service;

import com.ainovel.server.domain.model.AIFeatureType;

import reactor.core.publisher.Mono;

/**
 * 积分管理服务接口
 */
public interface CreditService {
    
    /**
     * 扣减用户积分
     * 
     * @param userId 用户ID
     * @param amount 扣减数量
     * @return 扣减结果（true表示成功，false表示余额不足）
     */
    Mono<Boolean> deductCredits(String userId, long amount);
    
    /**
     * 增加用户积分
     * 
     * @param userId 用户ID
     * @param amount 增加数量
     * @param reason 增加原因
     * @return 增加结果
     */
    Mono<Boolean> addCredits(String userId, long amount, String reason);
    
    /**
     * 获取用户当前积分余额
     * 
     * @param userId 用户ID
     * @return 积分余额
     */
    Mono<Long> getUserCredits(String userId);
    
    /**
     * 计算AI功能调用的积分成本
     * 
     * @param provider 提供商
     * @param modelId 模型ID
     * @param featureType AI功能类型
     * @param inputTokens 输入token数量
     * @param outputTokens 输出token数量
     * @return 积分成本
     */
    Mono<Long> calculateCreditCost(String provider, String modelId, AIFeatureType featureType, int inputTokens, int outputTokens);
    
    /**
     * 检查用户是否有足够积分使用指定功能
     * 
     * @param userId 用户ID
     * @param provider 提供商
     * @param modelId 模型ID
     * @param featureType AI功能类型
     * @param estimatedInputTokens 预估输入token数量
     * @param estimatedOutputTokens 预估输出token数量
     * @return 是否有足够积分
     */
    Mono<Boolean> hasEnoughCredits(String userId, String provider, String modelId, AIFeatureType featureType, int estimatedInputTokens, int estimatedOutputTokens);
    
    /**
     * 执行AI功能调用的积分扣减
     * 
     * @param userId 用户ID
     * @param provider 提供商
     * @param modelId 模型ID
     * @param featureType AI功能类型
     * @param inputTokens 实际输入token数量
     * @param outputTokens 实际输出token数量
     * @return 扣减结果和消费的积分数量
     */
    Mono<CreditDeductionResult> deductCreditsForAI(String userId, String provider, String modelId, AIFeatureType featureType, int inputTokens, int outputTokens);
    
    /**
     * 获取积分与美元的汇率
     * 
     * @return 汇率（1美元等于多少积分）
     */
    Mono<Double> getCreditToUsdRate();
    
    /**
     * 设置积分与美元的汇率
     * 
     * @param rate 新汇率
     * @return 设置结果
     */
    Mono<Boolean> setCreditToUsdRate(double rate);
    
    /**
     * 为新用户赠送初始积分
     * 
     * @param userId 用户ID
     * @return 赠送结果
     */
    Mono<Boolean> grantNewUserCredits(String userId);
    
    /**
     * 积分扣减结果
     */
    class CreditDeductionResult {
        private final boolean success;
        private final long creditsDeducted;
        private final String message;
        
        public CreditDeductionResult(boolean success, long creditsDeducted, String message) {
            this.success = success;
            this.creditsDeducted = creditsDeducted;
            this.message = message;
        }
        
        public boolean isSuccess() {
            return success;
        }
        
        public long getCreditsDeducted() {
            return creditsDeducted;
        }
        
        public String getMessage() {
            return message;
        }
        
        public static CreditDeductionResult success(long creditsDeducted) {
            return new CreditDeductionResult(true, creditsDeducted, "积分扣减成功");
        }
        
        public static CreditDeductionResult failure(String message) {
            return new CreditDeductionResult(false, 0, message);
        }
    }
}