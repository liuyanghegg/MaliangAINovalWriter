package com.ainovel.server.web.dto;

import com.ainovel.server.domain.model.ChatMemoryConfig;
import com.ainovel.server.domain.model.ChatMemoryMode;

import lombok.Data;

/**
 * 聊天记忆配置DTO
 */
@Data
public class ChatMemoryConfigDto {
    
    private String mode;
    private Integer maxMessages;
    private Integer maxTokens;
    private Boolean preserveSystemMessages;
    private Integer summaryThreshold;
    private Integer summaryRetainCount;
    private Boolean enablePersistence;
    
    /**
     * 转换为领域模型
     */
    public ChatMemoryConfig toModel() {
        return ChatMemoryConfig.builder()
                .mode(ChatMemoryMode.fromCode(mode))
                .maxMessages(maxMessages)
                .maxTokens(maxTokens)
                .preserveSystemMessages(preserveSystemMessages)
                .summaryThreshold(summaryThreshold)
                .summaryRetainCount(summaryRetainCount)
                .enablePersistence(enablePersistence)
                .build();
    }
    
    /**
     * 从领域模型创建DTO
     */
    public static ChatMemoryConfigDto fromModel(ChatMemoryConfig config) {
        ChatMemoryConfigDto dto = new ChatMemoryConfigDto();
        dto.setMode(config.getMode().getCode());
        dto.setMaxMessages(config.getMaxMessages());
        dto.setMaxTokens(config.getMaxTokens());
        dto.setPreserveSystemMessages(config.getPreserveSystemMessages());
        dto.setSummaryThreshold(config.getSummaryThreshold());
        dto.setSummaryRetainCount(config.getSummaryRetainCount());
        dto.setEnablePersistence(config.getEnablePersistence());
        return dto;
    }
} 