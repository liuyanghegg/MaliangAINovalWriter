package com.ainovel.server.service;

import java.util.Map;

import com.ainovel.server.domain.model.AIChatMessage;
import com.ainovel.server.domain.model.AIChatSession;
import com.ainovel.server.domain.model.ChatMemoryConfig;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface AIChatService {

    // ==================== 会话管理 ====================
    
    // 创建会话（已经支持novelId）
    Mono<AIChatSession> createSession(String userId, String novelId, String modelName, Map<String, Object> metadata);

    // 🚀 新增：支持novelId的会话管理方法
    /**
     * 获取会话详情（支持novelId隔离）
     */
    Mono<AIChatSession> getSession(String userId, String novelId, String sessionId);

    /**
     * 获取指定小说的用户会话列表
     */
    Flux<AIChatSession> listUserSessions(String userId, String novelId, int page, int size);

    /**
     * 更新会话（支持novelId隔离）
     */
    Mono<AIChatSession> updateSession(String userId, String novelId, String sessionId, Map<String, Object> updates);

    /**
     * 删除会话（支持novelId隔离）
     */
    Mono<Void> deleteSession(String userId, String novelId, String sessionId);

    /**
     * 统计指定小说的用户会话数量
     */
    Mono<Long> countUserSessions(String userId, String novelId);

    // 🚀 保留原有方法以确保向后兼容
    /**
     * @deprecated 使用 getSession(String, String, String) 替代以支持novelId隔离
     */
    @Deprecated
    Mono<AIChatSession> getSession(String userId, String sessionId);

    /**
     * @deprecated 使用 listUserSessions(String, String, int, int) 替代以支持novelId隔离
     */
    @Deprecated
    Flux<AIChatSession> listUserSessions(String userId, int page, int size);

    /**
     * @deprecated 使用 updateSession(String, String, String, Map) 替代以支持novelId隔离
     */
    @Deprecated
    Mono<AIChatSession> updateSession(String userId, String sessionId, Map<String, Object> updates);

    /**
     * @deprecated 使用 deleteSession(String, String, String) 替代以支持novelId隔离
     */
    @Deprecated
    Mono<Void> deleteSession(String userId, String sessionId);

    /**
     * @deprecated 使用 countUserSessions(String, String) 替代以支持novelId隔离
     */
    @Deprecated
    Mono<Long> countUserSessions(String userId);

    // ==================== 消息管理 ====================

    // 🚀 新增：支持novelId的消息管理方法
    /**
     * 发送消息并获取响应（支持novelId隔离）
     */
    Mono<AIChatMessage> sendMessage(String userId, String novelId, String sessionId, String content, UniversalAIRequestDto aiRequest);

    /**
     * 流式发送消息并获取响应（支持novelId隔离）
     */
    Flux<AIChatMessage> streamMessage(String userId, String novelId, String sessionId, String content, UniversalAIRequestDto aiRequest);

    /**
     * 获取会话消息历史（支持novelId隔离）
     */
    Flux<AIChatMessage> getSessionMessages(String userId, String novelId, String sessionId, int limit);

    // 🚀 原有消息方法保持不变（通过userId验证权限）
    /**
     * 发送消息并获取响应
     */
    Mono<AIChatMessage> sendMessage(String userId, String sessionId, String content, UniversalAIRequestDto aiRequest);

    /**
     * 流式发送消息并获取响应
     */
    Flux<AIChatMessage> streamMessage(String userId, String sessionId, String content, UniversalAIRequestDto aiRequest);

    // 保留原有方法以支持向后兼容
    /**
     * @deprecated 使用 sendMessage(String, String, String, UniversalAIRequestDto) 替代
     */
    @Deprecated
    Mono<AIChatMessage> sendMessage(String userId, String sessionId, String content, Map<String, Object> metadata);

    /**
     * @deprecated 使用 streamMessage(String, String, String, UniversalAIRequestDto) 替代
     */
    @Deprecated
    Flux<AIChatMessage> streamMessage(String userId, String sessionId, String content, Map<String, Object> metadata);

    Flux<AIChatMessage> getSessionMessages(String userId, String sessionId, int limit);

    Mono<AIChatMessage> getMessage(String userId, String messageId);

    Mono<Void> deleteMessage(String userId, String messageId);

    // ==================== 记忆模式支持方法 ====================

    // 🚀 新增：支持novelId的记忆模式方法
    /**
     * 发送消息并获取响应（支持记忆模式和novelId隔离）
     */
    Mono<AIChatMessage> sendMessageWithMemory(String userId, String novelId, String sessionId, String content, Map<String, Object> metadata, ChatMemoryConfig memoryConfig);

    /**
     * 流式发送消息并获取响应（支持记忆模式和novelId隔离）
     */
    Flux<AIChatMessage> streamMessageWithMemory(String userId, String novelId, String sessionId, String content, Map<String, Object> metadata, ChatMemoryConfig memoryConfig);

    /**
     * 获取会话的记忆消息（支持novelId隔离）
     */
    Flux<AIChatMessage> getSessionMemoryMessages(String userId, String novelId, String sessionId, ChatMemoryConfig memoryConfig, int limit);

    /**
     * 更新会话的记忆配置（支持novelId隔离）
     */
    Mono<AIChatSession> updateSessionMemoryConfig(String userId, String novelId, String sessionId, ChatMemoryConfig memoryConfig);

    /**
     * 清除会话记忆（支持novelId隔离）
     */
    Mono<Void> clearSessionMemory(String userId, String novelId, String sessionId);

    // 🚀 原有记忆模式方法保持不变
    /**
     * 发送消息并获取响应（支持记忆模式）
     */
    Mono<AIChatMessage> sendMessageWithMemory(String userId, String sessionId, String content, Map<String, Object> metadata, ChatMemoryConfig memoryConfig);

    /**
     * 流式发送消息并获取响应（支持记忆模式）
     */
    Flux<AIChatMessage> streamMessageWithMemory(String userId, String sessionId, String content, Map<String, Object> metadata, ChatMemoryConfig memoryConfig);

    /**
     * 获取会话的记忆消息（按照记忆策略过滤）
     */
    Flux<AIChatMessage> getSessionMemoryMessages(String userId, String sessionId, ChatMemoryConfig memoryConfig, int limit);

    /**
     * 更新会话的记忆配置
     */
    Mono<AIChatSession> updateSessionMemoryConfig(String userId, String sessionId, ChatMemoryConfig memoryConfig);

    /**
     * 清除会话记忆
     */
    Mono<Void> clearSessionMemory(String userId, String sessionId);

    /**
     * 获取支持的记忆模式列表
     */
    Flux<String> getSupportedMemoryModes();

    // ==================== 统计 ====================
    
    Mono<Long> countSessionMessages(String sessionId);
}
