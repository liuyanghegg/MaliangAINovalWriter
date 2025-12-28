package com.ainovel.server.web.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.util.Map;

/**
 * 会话AI配置DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionAIConfigDto {
    
    /**
     * 用户ID
     */
    private String userId;
    
    /**
     * 小说ID
     */
    private String novelId;
    
    /**
     * 会话ID
     */
    private String sessionId;
    
    /**
     * AI配置数据
     */
    private Map<String, Object> config;
} 