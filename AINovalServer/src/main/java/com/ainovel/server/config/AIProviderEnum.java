package com.ainovel.server.config;

import lombok.Getter;

/**
 * AI供应商枚举
 * 定义支持的AI供应商及其基础特征
 */
@Getter
public enum AIProviderEnum {
    
    OPENAI("openai", "OpenAI", true, false, 8000),
    ANTHROPIC("anthropic", "Anthropic", true, false, 100000),
    GEMINI("gemini", "Google Gemini", false, true, 1000000),
    OPENROUTER("openrouter", "OpenRouter", true, false, 32000),
    SILICONFLOW("siliconflow", "SiliconFlow", true, false, 32000),
    TOGETHERAI("togetherai", "TogetherAI", true, false, 32000),
    DOUBAO("doubao", "Doubao (Bytedance Ark)", true, false, 128000),
    ZHIPU("zhipu", "Zhipu GLM", true, false, 128000),
    QWEN("qwen", "Qwen (DashScope)", true, false, 128000),
    X_AI("x-ai", "xAI", true, false, 128000),
    GROK("grok", "Grok", true, false, 128000);
    
    private final String code;
    private final String displayName;
    private final boolean supportsPaidTier;
    private final boolean hasFreeTierQuota;
    private final int defaultContextLength;
    
    AIProviderEnum(String code, String displayName, boolean supportsPaidTier, 
                  boolean hasFreeTierQuota, int defaultContextLength) {
        this.code = code;
        this.displayName = displayName;
        this.supportsPaidTier = supportsPaidTier;
        this.hasFreeTierQuota = hasFreeTierQuota;
        this.defaultContextLength = defaultContextLength;
    }
    
    /**
     * 根据字符串代码获取供应商枚举
     */
    public static AIProviderEnum fromCode(String code) {
        for (AIProviderEnum provider : values()) {
            if (provider.code.equalsIgnoreCase(code)) {
                return provider;
            }
        }
        throw new IllegalArgumentException("不支持的AI供应商: " + code);
    }
    
    /**
     * 获取默认限流策略
     */
    public RateLimitStrategyEnum getDefaultRateLimitStrategy() {
        return hasFreeTierQuota ? RateLimitStrategyEnum.CONSERVATIVE : RateLimitStrategyEnum.STANDARD;
    }
    
    /**
     * 获取默认重试策略
     */
    public RetryStrategyEnum getDefaultRetryStrategy() {
        return hasFreeTierQuota ? RetryStrategyEnum.EXPONENTIAL_BACKOFF : RetryStrategyEnum.LINEAR_BACKOFF;
    }
} 