package com.ainovel.server.service.ai.pricing;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

import reactor.core.publisher.Mono;

/**
 * Token使用追踪服务接口
 * 用于追踪和记录AI模型的token使用情况和成本
 */
public interface TokenUsageTrackingService {
    
    /**
     * 记录token使用情况
     * 
     * @param usage token使用记录
     * @return 保存结果
     */
    Mono<TokenUsageRecord> recordUsage(TokenUsageRecord usage);
    
    /**
     * 记录token使用情况（简化版本）
     * 
     * @param userId 用户ID
     * @param provider 提供商
     * @param modelId 模型ID
     * @param inputTokens 输入token数
     * @param outputTokens 输出token数
     * @param cost 成本
     * @return 保存结果
     */
    Mono<TokenUsageRecord> recordUsage(String userId, String provider, String modelId, 
                                     int inputTokens, int outputTokens, BigDecimal cost);
    
    /**
     * 获取用户的token使用统计
     * 
     * @param userId 用户ID
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 使用统计
     */
    Mono<TokenUsageStatistics> getUserUsageStatistics(String userId, 
                                                      LocalDateTime startTime, 
                                                      LocalDateTime endTime);
    
    /**
     * 获取提供商的token使用统计
     * 
     * @param provider 提供商
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 使用统计
     */
    Mono<TokenUsageStatistics> getProviderUsageStatistics(String provider, 
                                                          LocalDateTime startTime, 
                                                          LocalDateTime endTime);
    
    /**
     * Token使用记录
     */
    record TokenUsageRecord(
            String id,
            String userId,
            String provider,
            String modelId,
            int inputTokens,
            int outputTokens,
            int totalTokens,
            BigDecimal inputCost,
            BigDecimal outputCost,
            BigDecimal totalCost,
            LocalDateTime timestamp,
            String requestId,
            String sessionId,
            TokenUsageContext context
    ) {
        
        public TokenUsageRecord {
            if (totalTokens <= 0) {
                totalTokens = inputTokens + outputTokens;
            }
            if (totalCost == null && inputCost != null && outputCost != null) {
                totalCost = inputCost.add(outputCost);
            }
            if (timestamp == null) {
                timestamp = LocalDateTime.now();
            }
        }
        
        public static Builder builder() {
            return new Builder();
        }
        
        public static class Builder {
            private String id;
            private String userId;
            private String provider;
            private String modelId;
            private int inputTokens;
            private int outputTokens;
            private int totalTokens;
            private BigDecimal inputCost;
            private BigDecimal outputCost;
            private BigDecimal totalCost;
            private LocalDateTime timestamp;
            private String requestId;
            private String sessionId;
            private TokenUsageContext context;
            
            public Builder id(String id) { this.id = id; return this; }
            public Builder userId(String userId) { this.userId = userId; return this; }
            public Builder provider(String provider) { this.provider = provider; return this; }
            public Builder modelId(String modelId) { this.modelId = modelId; return this; }
            public Builder inputTokens(int inputTokens) { this.inputTokens = inputTokens; return this; }
            public Builder outputTokens(int outputTokens) { this.outputTokens = outputTokens; return this; }
            public Builder totalTokens(int totalTokens) { this.totalTokens = totalTokens; return this; }
            public Builder inputCost(BigDecimal inputCost) { this.inputCost = inputCost; return this; }
            public Builder outputCost(BigDecimal outputCost) { this.outputCost = outputCost; return this; }
            public Builder totalCost(BigDecimal totalCost) { this.totalCost = totalCost; return this; }
            public Builder timestamp(LocalDateTime timestamp) { this.timestamp = timestamp; return this; }
            public Builder requestId(String requestId) { this.requestId = requestId; return this; }
            public Builder sessionId(String sessionId) { this.sessionId = sessionId; return this; }
            public Builder context(TokenUsageContext context) { this.context = context; return this; }
            
            public TokenUsageRecord build() {
                return new TokenUsageRecord(id, userId, provider, modelId, inputTokens, outputTokens,
                        totalTokens, inputCost, outputCost, totalCost, timestamp, requestId, sessionId, context);
            }
        }
    }
    
    /**
     * Token使用上下文
     */
    record TokenUsageContext(
            String feature,      // 功能名称（如：chat, generation, summarization）
            String novelId,      // 小说ID
            String chapterId,    // 章节ID
            String sceneId,      // 场景ID
            String operation     // 操作类型（如：create, edit, continue, summarize）
    ) {
        
        public static TokenUsageContext of(String feature) {
            return new TokenUsageContext(feature, null, null, null, null);
        }
        
        public static TokenUsageContext novel(String feature, String novelId) {
            return new TokenUsageContext(feature, novelId, null, null, null);
        }
        
        public static TokenUsageContext scene(String feature, String novelId, String chapterId, String sceneId) {
            return new TokenUsageContext(feature, novelId, chapterId, sceneId, null);
        }
        
        public TokenUsageContext withOperation(String operation) {
            return new TokenUsageContext(this.feature, this.novelId, this.chapterId, this.sceneId, operation);
        }
    }
    
    /**
     * Token使用统计
     */
    record TokenUsageStatistics(
            String scope,                    // 统计范围（user, provider, global）
            String scopeId,                  // 范围ID
            LocalDateTime startTime,         // 开始时间
            LocalDateTime endTime,           // 结束时间
            long totalRequests,              // 总请求数
            long totalInputTokens,           // 总输入token数
            long totalOutputTokens,          // 总输出token数
            long totalTokens,                // 总token数
            BigDecimal totalCost,            // 总成本
            BigDecimal averageCostPerRequest, // 平均每请求成本
            BigDecimal averageCostPerToken,   // 平均每token成本
            Map<String, ProviderUsage> providerBreakdown,  // 按提供商分解
            Map<String, FeatureUsage> featureBreakdown     // 按功能分解
    ) {
        
        public TokenUsageStatistics {
            if (totalTokens <= 0 && totalInputTokens > 0 && totalOutputTokens > 0) {
                totalTokens = totalInputTokens + totalOutputTokens;
            }
            if (averageCostPerRequest == null && totalCost != null && totalRequests > 0) {
                averageCostPerRequest = totalCost.divide(BigDecimal.valueOf(totalRequests), 6, BigDecimal.ROUND_HALF_UP);
            }
            if (averageCostPerToken == null && totalCost != null && totalTokens > 0) {
                averageCostPerToken = totalCost.divide(BigDecimal.valueOf(totalTokens), 6, BigDecimal.ROUND_HALF_UP);
            }
        }
        
        /**
         * 提供商使用统计
         */
        public record ProviderUsage(
                String provider,
                long requests,
                long inputTokens,
                long outputTokens,
                long totalTokens,
                BigDecimal cost
        ) {}
        
        /**
         * 功能使用统计
         */
        public record FeatureUsage(
                String feature,
                long requests,
                long inputTokens,
                long outputTokens,
                long totalTokens,
                BigDecimal cost
        ) {}
    }
}