package com.ainovel.server.web.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 获取当前章节后面章节的请求数据传输对象
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChaptersAfterRequestDto {

    /**
     * 小说ID
     */
    private String novelId;

    /**
     * 当前章节ID，从这个章节之后开始加载
     */
    private String currentChapterId;

    /**
     * 要加载的章节数量限制
     * 例如：值为3时，则加载当前章节之后的3章
     */
    private int chaptersLimit;
    
    /**
     * 是否包含当前章节的场景内容
     * true: 返回当前章节及其后续章节的内容
     * false: 只返回当前章节之后的章节内容
     */
    private boolean includeCurrentChapter;
} 