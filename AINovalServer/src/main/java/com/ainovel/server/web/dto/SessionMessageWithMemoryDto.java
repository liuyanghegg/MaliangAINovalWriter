package com.ainovel.server.web.dto;

import java.util.Map;

import lombok.Data;

/**
 * 支持记忆模式的会话消息DTO
 */
@Data
public class SessionMessageWithMemoryDto {
    private String userId;
    private String novelId;
    private String sessionId;
    private String messageId;
    private String content;
    private Map<String, Object> metadata;
    private ChatMemoryConfigDto memoryConfig;
} 