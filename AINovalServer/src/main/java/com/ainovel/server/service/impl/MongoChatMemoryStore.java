package com.ainovel.server.service.impl;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.AIChatMessage;
import com.ainovel.server.repository.AIChatMessageRepository;

import dev.langchain4j.data.message.AiMessage;
import dev.langchain4j.data.message.ChatMessage;
import dev.langchain4j.data.message.SystemMessage;
import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.store.memory.chat.ChatMemoryStore;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * 基于MongoDB的LangChain4j ChatMemoryStore实现
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MongoChatMemoryStore implements ChatMemoryStore {

    private final AIChatMessageRepository messageRepository;

    @Override
    public List<ChatMessage> getMessages(Object memoryId) {
        String sessionId = memoryId.toString();
        log.debug("从持久化存储获取消息: sessionId={}", sessionId);
        
        List<AIChatMessage> dbMessages = messageRepository.findBySessionIdOrderByCreatedAtDesc(sessionId, 1000)
                .collectList()
                .block();
        
        if (dbMessages == null) {
            return List.of();
        }
        
        // 转换为LangChain4j ChatMessage
        List<ChatMessage> langchainMessages = dbMessages.stream()
                .sorted((m1, m2) -> m1.getCreatedAt().compareTo(m2.getCreatedAt())) // 按时间正序
                .map(this::convertToLangChain4jMessage)
                .collect(Collectors.toList());
        
        log.debug("成功获取{}条消息", langchainMessages.size());
        return langchainMessages;
    }

    @Override
    public void updateMessages(Object memoryId, List<ChatMessage> messages) {
        String sessionId = memoryId.toString();
        log.debug("更新持久化存储消息: sessionId={}, messages={}", sessionId, messages.size());
        
        // 先删除现有消息
        messageRepository.deleteBySessionId(sessionId).block();
        
        // 保存新消息
        List<AIChatMessage> dbMessages = messages.stream()
                .map(msg -> convertToDbMessage(msg, sessionId))
                .collect(Collectors.toList());
        
        for (AIChatMessage dbMessage : dbMessages) {
            messageRepository.save(dbMessage).block();
        }
        
        log.debug("成功更新{}条消息到持久化存储", dbMessages.size());
    }

    @Override
    public void deleteMessages(Object memoryId) {
        String sessionId = memoryId.toString();
        log.info("删除持久化存储中的所有消息: sessionId={}", sessionId);
        
        messageRepository.deleteBySessionId(sessionId).block();
    }

    /**
     * 将数据库消息转换为LangChain4j消息
     */
    private ChatMessage convertToLangChain4jMessage(AIChatMessage dbMessage) {
        String role = dbMessage.getRole().toLowerCase();
        String content = dbMessage.getContent();
        
        switch (role) {
            case "user":
                return new UserMessage(content);
            case "assistant":
                return new AiMessage(content);
            case "system":
                return new SystemMessage(content);
            default:
                log.warn("未知的消息角色: {}, 转换为UserMessage", role);
                return new UserMessage(content);
        }
    }

    /**
     * 将LangChain4j消息转换为数据库消息
     */
    private AIChatMessage convertToDbMessage(ChatMessage langchainMessage, String sessionId) {
        String role;
        String content;
        
        if (langchainMessage instanceof UserMessage) {
            role = "user";
            content = ((UserMessage) langchainMessage).singleText();
        } else if (langchainMessage instanceof AiMessage) {
            role = "assistant";
            content = ((AiMessage) langchainMessage).text();
        } else if (langchainMessage instanceof SystemMessage) {
            role = "system";
            content = ((SystemMessage) langchainMessage).text();
        } else {
            role = "unknown";
            content = langchainMessage.toString();
            log.warn("未知的LangChain4j消息类型: {}", langchainMessage.getClass().getSimpleName());
        }
        
        return AIChatMessage.builder()
                .sessionId(sessionId)
                .role(role)
                .content(content)
                .status("DELIVERED")
                .messageType("TEXT")
                .createdAt(LocalDateTime.now())
                .build();
    }
} 