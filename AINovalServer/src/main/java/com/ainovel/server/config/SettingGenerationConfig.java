package com.ainovel.server.config;

import com.ainovel.server.service.setting.generation.SettingGenerationStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 设定生成配置
 * 配置策略Bean和相关组件
 */
@Configuration
public class SettingGenerationConfig {
    
    /**
     * 注册所有策略为Map
     * key为策略名称，value为策略实现
     */
    @Bean
    public Map<String, SettingGenerationStrategy> settingGenerationStrategies(
            List<SettingGenerationStrategy> strategies) {
        return strategies.stream()
            .collect(Collectors.toMap(
                strategy -> strategy.getStrategyName().toLowerCase().replace(" ", "-"),
                Function.identity()
            ));
    }
}