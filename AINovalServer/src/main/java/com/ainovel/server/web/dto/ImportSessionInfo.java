package com.ainovel.server.web.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 导入会话信息DTO
 * 用于跟踪导入预览会话状态
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ImportSessionInfo {

    /**
     * 会话ID
     */
    private String sessionId;

    /**
     * 用户ID
     */
    private String userId;

    /**
     * 原始文件名
     */
    private String originalFileName;

    /**
     * 临时文件路径
     */
    private String tempFilePath;

    /**
     * 文件大小（字节）
     */
    private Long fileSize;

    /**
     * 会话创建时间
     */
    private LocalDateTime createdAt;

    /**
     * 会话过期时间
     */
    private LocalDateTime expiresAt;

    /**
     * 解析状态
     */
    private String parseStatus;

    /**
     * 解析出的章节数量
     */
    private Integer totalChapters;

    /**
     * 解析错误信息
     */
    private List<String> parseErrors;

    /**
     * 是否已清理
     */
    private Boolean cleaned = false;
} 