package com.ainovel.server.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import lombok.Data;

/**
 * 定价系统配置
 */
@Configuration
@EnableConfigurationProperties(PricingConfig.PricingProperties.class)
public class PricingConfig {
    
    /**
     * 定价系统配置属性
     */
    @Data
    @ConfigurationProperties(prefix = "pricing")
    public static class PricingProperties {
        
        /**
         * 是否在启动时自动同步定价
         */
        private boolean autoSyncOnStartup = true;
        
        /**
         * 定价同步间隔（小时）
         */
        private int syncIntervalHours = 24;
        
        /**
         * 是否启用定价缓存
         */
        private boolean enableCache = true;
        
        /**
         * 缓存TTL（分钟）
         */
        private int cacheTtlMinutes = 60;
        
        /**
         * 默认精度（小数位数）
         */
        private int defaultPrecision = 6;
        
        /**
         * 是否启用成本跟踪
         */
        private boolean enableCostTracking = false;
        
        /**
         * OpenAI配置
         */
        private OpenAIConfig openai = new OpenAIConfig();
        
        /**
         * Anthropic配置
         */
        private AnthropicConfig anthropic = new AnthropicConfig();
        
        /**
         * Gemini配置
         */
        private GeminiConfig gemini = new GeminiConfig();
        
        @Data
        public static class OpenAIConfig {
            /**
             * 是否启用API定价同步
             */
            private boolean enableApiSync = false;
            
            /**
             * API密钥（用于获取模型列表和定价）
             */
            private String apiKey;
            
            /**
             * API端点
             */
            private String apiEndpoint = "https://api.openai.com/v1";
        }
        
        @Data
        public static class AnthropicConfig {
            /**
             * 是否启用API定价同步
             */
            private boolean enableApiSync = false;
            
            /**
             * API密钥
             */
            private String apiKey;
            
            /**
             * API端点
             */
            private String apiEndpoint = "https://api.anthropic.com/v1";
        }
        
        @Data
        public static class GeminiConfig {
            /**
             * 是否启用API定价同步
             */
            private boolean enableApiSync = false;
            
            /**
             * API密钥
             */
            private String apiKey;
            
            /**
             * API端点
             */
            private String apiEndpoint = "https://generativelanguage.googleapis.com/v1";
        }
    }
    
    @Bean
    public PricingProperties pricingProperties() {
        return new PricingProperties();
    }
}