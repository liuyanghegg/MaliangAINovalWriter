package com.ainovel.server.service.setting.generation;

import com.ainovel.server.domain.model.setting.generation.SettingGenerationSession;
import com.ainovel.server.domain.model.setting.generation.SettingNode;
import com.ainovel.server.domain.model.settinggeneration.SettingGenerationConfig;
import reactor.core.publisher.Flux;

/**
 * 设定生成策略接口
 * 解耦后的策略接口，专注于核心策略逻辑，提示词生成交给 PromptProvider 处理
 */
public interface SettingGenerationStrategy {
    
    /**
     * 获取策略标识符（用于注册和查找）
     */
    String getStrategyId();
    
    /**
     * 获取策略名称
     */
    String getStrategyName();
    
    /**
     * 获取策略描述
     */
    String getDescription();
    
    /**
     * 创建默认的策略配置
     * @return 默认配置
     */
    SettingGenerationConfig createDefaultConfig();
    
    /**
     * 验证策略配置是否有效
     * @param config 策略配置
     * @return 验证结果
     */
    ValidationResult validateConfig(SettingGenerationConfig config);
    
    /**
     * 验证生成的节点是否符合策略要求
     * @param node 生成的节点
     * @param config 策略配置
     * @param session 当前会话
     * @return 验证结果
     */
    ValidationResult validateNode(SettingNode node, SettingGenerationConfig config, SettingGenerationSession session);
    
    /**
     * 后处理生成的节点
     * 可以用于添加策略特定的元数据或调整节点结构
     * @param nodes 生成的节点流
     * @param config 策略配置
     * @param session 当前会话
     * @return 处理后的节点流
     */
    Flux<SettingNode> postProcessNodes(Flux<SettingNode> nodes, SettingGenerationConfig config, SettingGenerationSession session);
    
    /**
     * 获取策略支持的节点类型
     * @return 支持的节点类型列表
     */
    java.util.List<String> getSupportedNodeTypes();
    
    /**
     * 检查策略是否支持基于其他策略创建
     * @return 是否支持继承
     */
    boolean supportsInheritance();
    
    /**
     * 基于现有配置创建新配置（用于策略继承）
     * @param baseConfig 基础配置
     * @param modifications 修改内容
     * @return 新配置
     */
    default SettingGenerationConfig createInheritedConfig(SettingGenerationConfig baseConfig, 
                                                         java.util.Map<String, Object> modifications) {
        throw new UnsupportedOperationException("This strategy does not support inheritance");
    }
    
    /**
     * 验证结果
     */
    record ValidationResult(boolean valid, String errorMessage) {
        public static ValidationResult success() {
            return new ValidationResult(true, null);
        }
        
        public static ValidationResult failure(String errorMessage) {
            return new ValidationResult(false, errorMessage);
        }
    }
}