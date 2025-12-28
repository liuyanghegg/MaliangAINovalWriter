package com.ainovel.server.domain.model;

import java.time.LocalDateTime;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 小说片段历史记录
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "novel_snippet_histories")
@CompoundIndexes({
    @CompoundIndex(name = "snippet_version_idx", def = "{'snippetId': 1, 'version': 1}"),
    @CompoundIndex(name = "snippet_time_idx", def = "{'snippetId': 1, 'createdAt': -1}")
})
public class NovelSnippetHistory {

    @Id
    private String id;

    /**
     * 片段ID
     */
    @Indexed
    private String snippetId;

    /**
     * 用户ID
     */
    @Indexed
    private String userId;

    /**
     * 操作类型（CREATE, UPDATE, DELETE, FAVORITE, UNFAVORITE, TAG_ADD, TAG_REMOVE）
     */
    private String operationType;

    /**
     * 版本号
     */
    private Integer version;

    /**
     * 变更前的标题
     */
    private String beforeTitle;

    /**
     * 变更后的标题
     */
    private String afterTitle;

    /**
     * 变更前的内容
     */
    private String beforeContent;

    /**
     * 变更后的内容
     */
    private String afterContent;

    /**
     * 变更描述
     */
    private String changeDescription;

    /**
     * 操作时间
     */
    private LocalDateTime createdAt;
} 