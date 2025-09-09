package com.ainovel.server.service;

import java.util.Map;
import java.util.Set;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.prompt.AIFeaturePromptProvider;

import reactor.core.publisher.Mono;

/**
 * 统一的提示词管理服务接口
 * 整合所有提示词相关功能，作为外部调用的统一入口
 */
public interface UnifiedPromptService {

    // ==================== 提示词获取 ====================

    /**
     * 获取指定功能的系统提示词
     * @param featureType 功能类型
     * @param userId 用户ID
     * @param parameters 参数映射
     * @return 渲染后的系统提示词
     */
    Mono<String> getSystemPrompt(AIFeatureType featureType, String userId, Map<String, Object> parameters);

    /**
     * 获取指定功能的用户提示词
     * @param featureType 功能类型
     * @param userId 用户ID
     * @param templateId 模板ID（可选，用于指定特定的用户模板）
     * @param parameters 参数映射
     * @return 渲染后的用户提示词
     */
    Mono<String> getUserPrompt(AIFeatureType featureType, String userId, String templateId, Map<String, Object> parameters);

    /**
     * 获取完整的提示词对话
     * @param featureType 功能类型
     * @param userId 用户ID
     * @param templateId 模板ID（可选）
     * @param parameters 参数映射
     * @return 包含系统消息和用户消息的完整对话
     */
    Mono<PromptConversation> getCompletePromptConversation(AIFeatureType featureType, String userId, String templateId, Map<String, Object> parameters);

    // ==================== 占位符管理 ====================

    /**
     * 获取指定功能支持的占位符
     * @param featureType 功能类型
     * @return 支持的占位符集合
     */
    Set<String> getSupportedPlaceholders(AIFeatureType featureType);

    /**
     * 验证提示词中的占位符
     * @param featureType 功能类型
     * @param content 提示词内容
     * @return 验证结果
     */
    AIFeaturePromptProvider.ValidationResult validatePlaceholders(AIFeatureType featureType, String content);

    // ==================== 提示词提供器管理 ====================

    /**
     * 获取指定功能的提示词提供器
     * @param featureType 功能类型
     * @return 提示词提供器
     */
    AIFeaturePromptProvider getPromptProvider(AIFeatureType featureType);

    /**
     * 检查是否存在指定功能的提示词提供器
     * @param featureType 功能类型
     * @return 是否存在
     */
    boolean hasPromptProvider(AIFeatureType featureType);

    /**
     * 获取所有支持的功能类型
     * @return 支持的功能类型集合
     */
    Set<AIFeatureType> getSupportedFeatureTypes();

    // ==================== 数据传输对象 ====================

    /**
     * 提示词对话对象
     * 包含系统消息和用户消息
     */
    class PromptConversation {
        private final String systemMessage;
        private final String userMessage;
        private final AIFeatureType featureType;
        private final Map<String, Object> usedParameters;

        public PromptConversation(String systemMessage, String userMessage, AIFeatureType featureType, Map<String, Object> usedParameters) {
            this.systemMessage = systemMessage;
            this.userMessage = userMessage;
            this.featureType = featureType;
            this.usedParameters = usedParameters;
        }

        public String getSystemMessage() { return systemMessage; }
        public String getUserMessage() { return userMessage; }
        public AIFeatureType getFeatureType() { return featureType; }
        public Map<String, Object> getUsedParameters() { return usedParameters; }
    }
} 