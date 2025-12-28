package com.ainovel.server.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 聊天记忆配置
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatMemoryConfig {
    
    /**
     * 记忆模式
     */
    @Builder.Default
    private ChatMemoryMode mode = ChatMemoryMode.HISTORY;
    
    /**
     * 消息窗口大小（仅在MESSAGE_WINDOW模式下有效）
     */
    @Builder.Default
    private Integer maxMessages = 50;
    
    /**
     * 令牌窗口大小（仅在TOKEN_WINDOW模式下有效）
     */
    @Builder.Default
    private Integer maxTokens = 4000;
    
    /**
     * 是否保留系统消息
     */
    @Builder.Default
    private Boolean preserveSystemMessages = true;
    
    /**
     * 总结阈值（仅在SUMMARY模式下有效）
     * 当消息数量超过此阈值时触发总结
     */
    @Builder.Default
    private Integer summaryThreshold = 20;
    
    /**
     * 总结后保留的消息数量（仅在SUMMARY模式下有效）
     */
    @Builder.Default
    private Integer summaryRetainCount = 5;
    
    /**
     * 是否启用记忆持久化
     */
    @Builder.Default
    private Boolean enablePersistence = false;
    
    /**
     * 获取默认配置
     */
    public static ChatMemoryConfig getDefault() {
        return ChatMemoryConfig.builder()
                .mode(ChatMemoryMode.HISTORY)
                .maxMessages(50)
                .maxTokens(4000)
                .preserveSystemMessages(true)
                .summaryThreshold(20)
                .summaryRetainCount(5)
                .enablePersistence(false)
                .build();
    }
    
    /**
     * 创建消息窗口配置
     */
    public static ChatMemoryConfig messageWindow(int maxMessages) {
        return ChatMemoryConfig.builder()
                .mode(ChatMemoryMode.MESSAGE_WINDOW)
                .maxMessages(maxMessages)
                .preserveSystemMessages(true)
                .enablePersistence(false)
                .build();
    }
    
    /**
     * 创建令牌窗口配置
     */
    public static ChatMemoryConfig tokenWindow(int maxTokens) {
        return ChatMemoryConfig.builder()
                .mode(ChatMemoryMode.TOKEN_WINDOW)
                .maxTokens(maxTokens)
                .preserveSystemMessages(true)
                .enablePersistence(false)
                .build();
    }
    
    /**
     * 创建总结模式配置
     */
    public static ChatMemoryConfig summary(int threshold, int retainCount) {
        return ChatMemoryConfig.builder()
                .mode(ChatMemoryMode.SUMMARY)
                .summaryThreshold(threshold)
                .summaryRetainCount(retainCount)
                .preserveSystemMessages(true)
                .enablePersistence(false)
                .build();
    }
} 