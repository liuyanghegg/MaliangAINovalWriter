package com.ainovel.server.domain.model;

/**
 * 聊天记忆模式枚举
 * 
 * 基于LangChain4j的Chat Memory概念
 */
public enum ChatMemoryMode {
    
    /**
     * 历史模式 - 保留完整的对话历史，不进行任何修改或删除
     */
    HISTORY("history", "历史模式", "保留完整的对话历史记录"),
    
    /**
     * 消息窗口记忆模式 - 保留最近的N条消息
     */
    MESSAGE_WINDOW("message_window", "消息窗口记忆", "保留最近的N条消息，淘汰旧消息"),
    
    /**
     * 令牌窗口记忆模式 - 保留最近的N个令牌
     */
    TOKEN_WINDOW("token_window", "令牌窗口记忆", "保留最近的N个令牌，按令牌数量淘汰"),
    
    /**
     * 总结记忆模式 - 对历史消息进行总结压缩
     */
    SUMMARY("summary", "总结记忆", "对历史消息进行总结压缩，保留关键信息");
    
    private final String code;
    private final String displayName;
    private final String description;
    
    ChatMemoryMode(String code, String displayName, String description) {
        this.code = code;
        this.displayName = displayName;
        this.description = description;
    }
    
    public String getCode() {
        return code;
    }
    
    public String getDisplayName() {
        return displayName;
    }
    
    public String getDescription() {
        return description;
    }
    
    /**
     * 根据代码获取枚举值
     */
    public static ChatMemoryMode fromCode(String code) {
        for (ChatMemoryMode mode : values()) {
            if (mode.code.equals(code)) {
                return mode;
            }
        }
        return HISTORY; // 默认返回历史模式
    }
} 