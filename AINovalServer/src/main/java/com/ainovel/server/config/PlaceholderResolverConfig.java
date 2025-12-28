package com.ainovel.server.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import com.ainovel.server.service.prompt.ContentPlaceholderResolver;
import com.ainovel.server.service.prompt.impl.ContextualPlaceholderResolver;

/**
 * 占位符解析器配置类
 * 确保ContextualPlaceholderResolver作为主要的占位符解析器被注入
 */
@Configuration
public class PlaceholderResolverConfig {

    /**
     * 配置ContextualPlaceholderResolver为主要的占位符解析器
     * 它会自动委托给ContentProviderPlaceholderResolver处理具体的占位符解析
     */
    @Bean
    @Primary
    @Qualifier("primaryPlaceholderResolver")
    public ContentPlaceholderResolver primaryPlaceholderResolver(
        ContextualPlaceholderResolver contextualResolver) {
        return contextualResolver;
    }
}