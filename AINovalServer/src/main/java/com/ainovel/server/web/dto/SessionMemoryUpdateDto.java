package com.ainovel.server.web.dto;

import lombok.Data;

/**
 * 会话记忆更新DTO
 */
@Data
public class SessionMemoryUpdateDto {
    private String userId;
    private String novelId;
    private String sessionId;
    private ChatMemoryConfigDto memoryConfig;
} 