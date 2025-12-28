package com.ainovel.server.service.setting.generation;

import com.ainovel.server.domain.model.EnhancedUserPromptTemplate;
import com.ainovel.server.domain.model.settinggeneration.SettingGenerationConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Optional;

/**
 * 设定生成策略工厂
 * 负责根据配置创建和管理策略实例
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SettingGenerationStrategyFactory {
    
    private final Map<String, SettingGenerationStrategy> strategies;
    
    /**
     * 根据策略ID获取策略实例
     * @param strategyId 策略ID
     * @return 策略实例
     */
    public Optional<SettingGenerationStrategy> getStrategy(String strategyId) {
        return Optional.ofNullable(strategies.get(strategyId));
    }
    
    /**
     * 从模板中提取策略信息
     * @param template 提示词模板
     * @return 策略实例（如果模板包含策略配置）
     */
    public Optional<SettingGenerationStrategy> getStrategyFromTemplate(EnhancedUserPromptTemplate template) {
        if (!template.isSettingGenerationTemplate()) {
            return Optional.empty();
        }
        
        SettingGenerationConfig config = template.getSettingGenerationConfig();
        if (config == null) {
            log.warn("设定生成模板 {} 缺少策略配置", template.getId());
            return Optional.empty();
        }
        
        // 根据配置中的策略名称或其他标识来查找对应的策略
        String strategyId = determineStrategyId(config);
        return getStrategy(strategyId);
    }
    
    /**
     * 创建基于配置的策略适配器
     * @param template 提示词模板
     * @return 配置化的策略适配器
     */
    public Optional<ConfigurableStrategyAdapter> createConfigurableStrategy(EnhancedUserPromptTemplate template) {
        if (!template.isSettingGenerationTemplate()) {
            return Optional.empty();
        }
        
        SettingGenerationConfig config = template.getSettingGenerationConfig();
        if (config == null) {
            return Optional.empty();
        }
        
        // 查找基础策略
        String baseStrategyId = determineStrategyId(config);
        SettingGenerationStrategy baseStrategy = strategies.get(baseStrategyId);
        
        if (baseStrategy == null) {
            log.warn("找不到基础策略: {}", baseStrategyId);
            return Optional.empty();
        }
        
        return Optional.of(new ConfigurableStrategyAdapter(baseStrategy, config));
    }
    
    /**
     * 获取所有可用的策略
     * @return 策略映射
     */
    public Map<String, SettingGenerationStrategy> getAllStrategies() {
        return Map.copyOf(strategies);
    }
    
    /**
     * 检查策略是否存在
     * @param strategyId 策略ID
     * @return 是否存在
     */
    public boolean hasStrategy(String strategyId) {
        return strategies.containsKey(strategyId);
    }
    
    /**
     * 根据配置确定策略ID
     */
    private String determineStrategyId(SettingGenerationConfig config) {
        // 如果配置中指定了基础策略ID，使用它
        if (config.getBaseStrategyId() != null) {
            return config.getBaseStrategyId();
        }
        
        // 根据策略名称推断策略类型
        String strategyName = config.getStrategyName();
        if (strategyName != null) {
            if (strategyName.contains("九线法")) {
                return "nine-line-method";
            } else if (strategyName.contains("三幕剧")) {
                return "three-act-structure";
            } else if (strategyName.contains("番茄") || strategyName.contains("网文")) {
                return "tomato-web-novel";
            } else if (strategyName.contains("知乎") || strategyName.contains("短文")) {
                return "zhihu-article";
            } else if (strategyName.contains("视频") || strategyName.contains("短剧")) {
                return "short-video-script";
            }
        }
        
        // 根据节点模板数量和其他特征推断策略类型
        int rootNodeCount = config.getExpectedRootNodes();
        switch (rootNodeCount) {
            case 8 -> {
                // 三幕剧策略有8个根节点
                return "three-act-structure";
            }
            case 9 -> {
                // 网文策略或九线法都有9个根节点，需要进一步判断
                if (hasWebNovelElements(config)) {
                    return "tomato-web-novel";
                }
                return "nine-line-method";
            }
            case 10 -> {
                // 视频短剧策略有10个根节点
                return "short-video-script";
            }
            default -> {
                // 知乎短文策略有9个根节点，但如果不是网文元素，可能是知乎策略
                if (rootNodeCount == 9 && hasArticleElements(config)) {
                    return "zhihu-article";
                }
            }
        }
        
        // 默认策略
        return "nine-line-method";
    }
    
    /**
     * 检查配置是否包含网文相关元素
     */
    private boolean hasWebNovelElements(SettingGenerationConfig config) {
        return config.getNodeTemplates().stream()
            .anyMatch(template -> 
                template.getName().contains("主角设定") || 
                template.getName().contains("金手指") ||
                template.getName().contains("爽点"));
    }
    
    /**
     * 检查配置是否包含文章创作相关元素
     */
    private boolean hasArticleElements(SettingGenerationConfig config) {
        return config.getNodeTemplates().stream()
            .anyMatch(template -> 
                template.getName().contains("引人开头") || 
                template.getName().contains("干货内容") ||
                template.getName().contains("互动设计"));
    }
}