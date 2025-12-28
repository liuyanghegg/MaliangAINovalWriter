package com.ainovel.server.service.setting.generation;

import com.ainovel.server.domain.model.setting.generation.SettingGenerationSession;
import com.ainovel.server.domain.model.setting.generation.SettingNode;
import com.ainovel.server.domain.model.settinggeneration.SettingGenerationConfig;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;

/**
 * 配置化策略适配器
 * 将用户自定义的配置与基础策略结合，提供个性化的策略行为
 */
public class ConfigurableStrategyAdapter implements SettingGenerationStrategy {
    
    private final SettingGenerationStrategy baseStrategy;
    private final SettingGenerationConfig customConfig;
    
    public ConfigurableStrategyAdapter(SettingGenerationStrategy baseStrategy, SettingGenerationConfig customConfig) {
        this.baseStrategy = baseStrategy;
        this.customConfig = customConfig;
    }
    
    @Override
    public String getStrategyId() {
        return customConfig.getStrategyName() != null ? 
            customConfig.getStrategyName().toLowerCase().replaceAll("\\s+", "-") : 
            baseStrategy.getStrategyId() + "-custom";
    }
    
    @Override
    public String getStrategyName() {
        return customConfig.getStrategyName() != null ? 
            customConfig.getStrategyName() : 
            baseStrategy.getStrategyName();
    }
    
    @Override
    public String getDescription() {
        return customConfig.getDescription() != null ? 
            customConfig.getDescription() : 
            baseStrategy.getDescription();
    }
    
    @Override
    public SettingGenerationConfig createDefaultConfig() {
        // 返回自定义配置
        return customConfig;
    }
    
    @Override
    public ValidationResult validateConfig(SettingGenerationConfig config) {
        // 使用基础策略的验证逻辑，但允许一定的灵活性
        return baseStrategy.validateConfig(config);
    }
    
    @Override
    public ValidationResult validateNode(SettingNode node, SettingGenerationConfig config, SettingGenerationSession session) {
        // 使用自定义配置进行验证
        return baseStrategy.validateNode(node, customConfig, session);
    }
    
    @Override
    public Flux<SettingNode> postProcessNodes(Flux<SettingNode> nodes, SettingGenerationConfig config, SettingGenerationSession session) {
        // 使用自定义配置进行后处理
        return baseStrategy.postProcessNodes(nodes, customConfig, session);
    }
    
    @Override
    public List<String> getSupportedNodeTypes() {
        // 可以基于自定义配置的节点模板来确定支持的类型
        if (customConfig.getNodeTemplates() != null && !customConfig.getNodeTemplates().isEmpty()) {
            return customConfig.getNodeTemplates().stream()
                .map(template -> template.getType().toString())
                .distinct()
                .toList();
        }
        return baseStrategy.getSupportedNodeTypes();
    }
    
    @Override
    public boolean supportsInheritance() {
        return baseStrategy.supportsInheritance();
    }
    
    @Override
    public SettingGenerationConfig createInheritedConfig(SettingGenerationConfig baseConfig, Map<String, Object> modifications) {
        return baseStrategy.createInheritedConfig(customConfig, modifications);
    }
    
    /**
     * 获取基础策略
     */
    public SettingGenerationStrategy getBaseStrategy() {
        return baseStrategy;
    }
    
    /**
     * 获取自定义配置
     */
    public SettingGenerationConfig getCustomConfig() {
        return customConfig;
    }
}