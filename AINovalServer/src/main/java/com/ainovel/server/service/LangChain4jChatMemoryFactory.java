package com.ainovel.server.service;

import org.springframework.stereotype.Service;

import com.ainovel.server.domain.model.ChatMemoryConfig;
import com.ainovel.server.domain.model.ChatMemoryMode;
import com.ainovel.server.service.impl.MongoChatMemoryStore;

import dev.langchain4j.memory.ChatMemory;
import dev.langchain4j.memory.chat.MessageWindowChatMemory;
import dev.langchain4j.memory.chat.TokenWindowChatMemory;
import dev.langchain4j.model.Tokenizer;
import dev.langchain4j.model.openai.OpenAiTokenizer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * LangChain4j ChatMemory工厂类
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class LangChain4jChatMemoryFactory {

    private final MongoChatMemoryStore chatMemoryStore;

    /**
     * 创建ChatMemory实例
     *
     * @param sessionId 会话ID
     * @param config 记忆配置
     * @param modelName 模型名称（用于选择合适的分词器）
     * @return ChatMemory实例
     */
    public ChatMemory createChatMemory(String sessionId, ChatMemoryConfig config, String modelName) {
        log.debug("创建ChatMemory: sessionId={}, mode={}, model={}", sessionId, config.getMode(), modelName);
        
        switch (config.getMode()) {
            case MESSAGE_WINDOW:
                return createMessageWindowMemory(sessionId, config);
            case TOKEN_WINDOW:
                return createTokenWindowMemory(sessionId, config, modelName);
            case SUMMARY:
                // TODO: 实现SummarizingChatMemory
                log.warn("总结模式暂未实现，使用消息窗口模式代替");
                return createMessageWindowMemory(sessionId, config);
            case HISTORY:
            default:
                // 历史模式使用超大窗口的消息记忆
                return createHistoryMemory(sessionId, config);
        }
    }

    /**
     * 创建消息窗口记忆
     */
    private ChatMemory createMessageWindowMemory(String sessionId, ChatMemoryConfig config) {
        MessageWindowChatMemory.Builder builder = MessageWindowChatMemory.builder()
                .id(sessionId)
                .maxMessages(config.getMaxMessages());
        
        if (config.getEnablePersistence()) {
            builder.chatMemoryStore(chatMemoryStore);
        }
        
        log.debug("创建消息窗口记忆: sessionId={}, maxMessages={}, persistent={}", 
                sessionId, config.getMaxMessages(), config.getEnablePersistence());
        
        return builder.build();
    }

    /**
     * 创建令牌窗口记忆
     */
    private ChatMemory createTokenWindowMemory(String sessionId, ChatMemoryConfig config, String modelName) {
        Tokenizer tokenizer = getTokenizerForModel(modelName);
        
        TokenWindowChatMemory.Builder builder = TokenWindowChatMemory.builder()
                .id(sessionId)
                .maxTokens(config.getMaxTokens(), tokenizer);
        
        if (config.getEnablePersistence()) {
            builder.chatMemoryStore(chatMemoryStore);
        }
        
        log.debug("创建令牌窗口记忆: sessionId={}, maxTokens={}, model={}, persistent={}", 
                sessionId, config.getMaxTokens(), modelName, config.getEnablePersistence());
        
        return builder.build();
    }

    /**
     * 创建历史记忆（使用超大窗口）
     */
    private ChatMemory createHistoryMemory(String sessionId, ChatMemoryConfig config) {
        MessageWindowChatMemory.Builder builder = MessageWindowChatMemory.builder()
                .id(sessionId)
                .maxMessages(10000); // 使用超大窗口模拟历史模式
        
        if (config.getEnablePersistence()) {
            builder.chatMemoryStore(chatMemoryStore);
        }
        
        log.debug("创建历史记忆: sessionId={}, persistent={}", sessionId, config.getEnablePersistence());
        
        return builder.build();
    }

    /**
     * 根据模型名称获取合适的分词器
     */
    private Tokenizer getTokenizerForModel(String modelName) {
        if (modelName == null) {
            return new OpenAiTokenizer("gpt-3.5-turbo"); // 默认分词器
        }
        
        String lowerModelName = modelName.toLowerCase();
        
        if (lowerModelName.contains("gpt-3.5")) {
            return new OpenAiTokenizer("gpt-3.5-turbo");
        } else if (lowerModelName.contains("gpt-4")) {
            return new OpenAiTokenizer("gpt-4");
        } else if (lowerModelName.contains("gpt") || lowerModelName.contains("openai")) {
            return new OpenAiTokenizer("gpt-3.5-turbo");
        } else {
            // 其他模型使用默认分词器
            return new OpenAiTokenizer("gpt-3.5-turbo");
        }
    }

    /**
     * 检查配置是否支持LangChain4j原生实现
     */
    public boolean isLangChain4jSupported(ChatMemoryConfig config) {
        // 总结模式暂未实现
        return config.getMode() != ChatMemoryMode.SUMMARY;
    }
} 