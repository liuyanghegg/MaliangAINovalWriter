package com.ainovel.server.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import lombok.Getter;
import lombok.extern.slf4j.Slf4j;

/**
 * AI模型提供商服务配置类
 */
@Configuration
@Slf4j
@Getter
public class ProviderServiceConfig {

    @Value("${ai.use-langchain4j:true}")
    private boolean useLangChain4j;
    
    @Value("${ai.enable-provider-auto-detection:false}")
    private boolean enableProviderAutoDetection;
    
    @Value("${ai.default-provider:openai}")
    private String defaultProvider;
    
    @Value("${ai.default-model:gpt-3.5-turbo}")
    private String defaultModel;
    
    @Value("${ai.connect-timeout:30}")
    private int connectTimeoutSeconds;
    
    @Value("${ai.read-timeout:60}")
    private int readTimeoutSeconds;
    
    /**
     * 获取代理配置
     * 
     * @return 代理配置
     */
    @Bean
    @Primary
    public ProxyConfig proxyConfig(
            @Value("${proxy.enabled:false}") boolean proxyEnabled,
            @Value("${proxy.host:}") String proxyHost,
            @Value("${proxy.port:0}") int proxyPort,
            @Value("${proxy.username:}") String proxyUsername,
            @Value("${proxy.password:}") String proxyPassword,
            @Value("${proxy.applySystemProperties:true}") boolean applySystemProperties,
            @Value("${proxy.applyProxySelector:false}") boolean applyProxySelector,
            @Value("${proxy.type:http}") String proxyType,
            @Value("${proxy.trustAllCerts:false}") boolean trustAllCerts) {
        
        ProxyConfig config = ProxyConfig.builder()
                .enabled(proxyEnabled)
                .host(proxyHost)
                .port(proxyPort)
                .username(proxyUsername)
                .password(proxyPassword)
                .build();
        // 使用 setter 避免个别构建方法名冲突（如 type/trustAllCerts ）
        config.setApplySystemProperties(applySystemProperties);
        config.setApplyProxySelector(applyProxySelector);
        config.setType(proxyType);
        config.setTrustAllCerts(trustAllCerts);
        
        log.info("代理配置: enabled={}, host={}, port={}, type={}, applySysProps={}, applySelector={}", 
                proxyEnabled, proxyHost, proxyPort, proxyType, applySystemProperties, applyProxySelector);
        return config;
    }
} 