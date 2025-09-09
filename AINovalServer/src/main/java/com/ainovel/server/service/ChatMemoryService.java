package com.ainovel.server.service;

import java.util.List;

import com.ainovel.server.domain.model.AIChatMessage;
import com.ainovel.server.domain.model.ChatMemoryConfig;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 聊天记忆服务接口
 * 
 * 基于LangChain4j的ChatMemory概念，提供不同的记忆策略
 */
public interface ChatMemoryService {
    
    /**
     * 获取经过记忆处理的消息列表
     * 
     * @param sessionId 会话ID
     * @param config 记忆配置
     * @param limit 原始消息限制（用于历史模式）
     * @return 处理后的消息列表
     */
    Flux<AIChatMessage> getMemoryMessages(String sessionId, ChatMemoryConfig config, int limit);
    
    /**
     * 添加新消息并应用记忆策略
     * 
     * @param sessionId 会话ID
     * @param message 新消息
     * @param config 记忆配置
     * @return 处理结果
     */
    Mono<Void> addMessage(String sessionId, AIChatMessage message, ChatMemoryConfig config);
    
    /**
     * 清除会话记忆
     * 
     * @param sessionId 会话ID
     * @return 操作结果
     */
    Mono<Void> clearMemory(String sessionId);
    
    /**
     * 计算消息的令牌数量
     * 
     * @param messages 消息列表
     * @param modelName 模型名称（用于选择合适的分词器）
     * @return 总令牌数
     */
    Mono<Integer> calculateTokens(List<AIChatMessage> messages, String modelName);
    
    /**
     * 获取支持的记忆模式列表
     * 
     * @return 记忆模式列表
     */
    Flux<String> getSupportedMemoryModes();
    
    /**
     * 验证记忆配置是否有效
     * 
     * @param config 记忆配置
     * @return 验证结果
     */
    Mono<Boolean> validateMemoryConfig(ChatMemoryConfig config);
    
    /**
     * 应用消息窗口策略
     * 
     * @param messages 原始消息列表
     * @param maxMessages 最大消息数
     * @param preserveSystemMessages 是否保留系统消息
     * @return 处理后的消息列表
     */
    List<AIChatMessage> applyMessageWindowStrategy(List<AIChatMessage> messages, int maxMessages, boolean preserveSystemMessages);
    
    /**
     * 应用令牌窗口策略
     * 
     * @param messages 原始消息列表
     * @param maxTokens 最大令牌数
     * @param preserveSystemMessages 是否保留系统消息
     * @param modelName 模型名称
     * @return 处理后的消息列表
     */
    Mono<List<AIChatMessage>> applyTokenWindowStrategy(List<AIChatMessage> messages, int maxTokens, boolean preserveSystemMessages, String modelName);
    
    /**
     * 应用总结策略
     * 
     * @param messages 原始消息列表
     * @param threshold 总结阈值
     * @param retainCount 保留消息数
     * @param modelName 模型名称（用于生成总结）
     * @return 处理后的消息列表（包含总结）
     */
    Mono<List<AIChatMessage>> applySummaryStrategy(List<AIChatMessage> messages, int threshold, int retainCount, String modelName);
} 