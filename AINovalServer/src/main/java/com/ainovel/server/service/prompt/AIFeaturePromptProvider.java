package com.ainovel.server.service.prompt;

import java.util.Map;
import java.util.Set;

import com.ainovel.server.domain.model.AIFeatureType;

import reactor.core.publisher.Mono;

/**
 * AI功能提示词提供器接口
 * 每个AI功能类型都应该实现此接口
 */
public interface AIFeaturePromptProvider {

    /**
     * 获取功能类型
     * @return AI功能类型
     */
    AIFeatureType getFeatureType();

    /**
     * 获取系统提示词
     * @param userId 用户ID
     * @param parameters 参数映射
     * @return 系统提示词
     */
    Mono<String> getSystemPrompt(String userId, Map<String, Object> parameters);

    /**
     * 获取用户提示词
     * @param userId 用户ID  
     * @param templateId 模板ID（可选）
     * @param parameters 参数映射
     * @return 用户提示词
     */
    Mono<String> getUserPrompt(String userId, String templateId, Map<String, Object> parameters);

    /**
     * 获取支持的占位符
     * @return 支持的占位符集合
     */
    Set<String> getSupportedPlaceholders();

    /**
     * 获取占位符描述信息
     * @return 占位符及其描述的映射
     */
    Map<String, String> getPlaceholderDescriptions();

    /**
     * 验证占位符
     * @param content 内容
     * @return 验证结果
     */
    ValidationResult validatePlaceholders(String content);

    /**
     * 渲染提示词模板
     * @param template 模板内容
     * @param context 上下文数据
     * @return 渲染后的内容
     */
    Mono<String> renderPrompt(String template, Map<String, Object> context);

    /**
     * 获取默认系统提示词
     * @return 默认系统提示词
     */
    String getDefaultSystemPrompt();

    /**
     * 获取默认用户提示词
     * @return 默认用户提示词
     */
    String getDefaultUserPrompt();

    // ==================== 🚀 新增：模板初始化相关方法 ====================

    /**
     * 初始化系统模板
     * 检查数据库中是否存在系统模板，不存在则创建
     * @return 模板ID
     */
    Mono<String> initializeSystemTemplate();

    /**
     * 获取系统模板ID（缓存的）
     * @return 模板ID，如果未初始化则返回null
     */
    String getSystemTemplateId();

    /**
     * 获取模板名称
     * @return 模板名称
     */
    String getTemplateName();

    /**
     * 获取模板描述
     * @return 模板描述
     */
    String getTemplateDescription();

    /**
     * 获取模板唯一标识符
     * 格式：功能类型_序号，如 "TEXT_EXPANSION_1"
     * @return 模板唯一标识符
     */
    String getTemplateIdentifier();

    /**
     * 验证结果类
     */
    class ValidationResult {
        private final boolean valid;
        private final String message;
        private final Set<String> missingPlaceholders;
        private final Set<String> unsupportedPlaceholders;

        public ValidationResult(boolean valid, String message, 
                               Set<String> missingPlaceholders, 
                               Set<String> unsupportedPlaceholders) {
            this.valid = valid;
            this.message = message;
            this.missingPlaceholders = missingPlaceholders;
            this.unsupportedPlaceholders = unsupportedPlaceholders;
        }

        // Getters
        public boolean isValid() { return valid; }
        public String getMessage() { return message; }
        public Set<String> getMissingPlaceholders() { return missingPlaceholders; }
        public Set<String> getUnsupportedPlaceholders() { return unsupportedPlaceholders; }
    }
} 