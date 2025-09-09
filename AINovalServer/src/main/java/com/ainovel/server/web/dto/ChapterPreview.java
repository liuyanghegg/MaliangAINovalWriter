package com.ainovel.server.web.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 章节预览DTO
 * 包含章节的基本信息和内容预览
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChapterPreview {

    /**
     * 章节索引
     */
    private Integer chapterIndex;

    /**
     * 章节标题
     */
    private String title;

    /**
     * 内容预览（前200个字符）
     */
    private String contentPreview;

    /**
     * 完整内容长度
     */
    private Integer fullContentLength;

    /**
     * 估算字数
     */
    private Integer wordCount;

    /**
     * 是否被选中导入
     */
    private Boolean selected = true;
} 