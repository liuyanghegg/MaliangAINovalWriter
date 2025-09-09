package com.ainovel.server.service.ai.capability;

import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.chat.StreamingChatLanguageModel;

/**
 * 标记接口：表示AI模型提供者支持工具调用功能
 * 
 * 使用策略模式解决装饰器模式中的类型检查问题：
 * - 避免直接依赖具体的LangChain4jModelProvider类型
 * - 通过能力接口而不是具体实现来判断功能支持
 * - 装饰器可以透明地代理此能力
 */
public interface ToolCallCapable {
    
    /**
     * 检查是否支持工具调用
     * @return 是否支持工具调用
     */
    default boolean supportsToolCalling() {
        return true;
    }
    
    /**
     * 获取支持工具调用的聊天模型
     * @return 聊天模型实例
     */
    ChatLanguageModel getToolCallableChatModel();
    
    /**
     * 获取支持工具调用的流式聊天模型（可选）
     * @return 流式聊天模型实例，如果不支持返回null
     */
    default StreamingChatLanguageModel getToolCallableStreamingChatModel() {
        return null;
    }
}