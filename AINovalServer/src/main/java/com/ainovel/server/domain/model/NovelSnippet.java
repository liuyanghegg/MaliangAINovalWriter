package com.ainovel.server.domain.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.index.TextIndexed;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 小说片段领域模型
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "novel_snippets")
@CompoundIndexes({
    @CompoundIndex(name = "user_novel_idx", def = "{'userId': 1, 'novelId': 1}"),
    @CompoundIndex(name = "user_favorite_idx", def = "{'userId': 1, 'isFavorite': 1}"),
    @CompoundIndex(name = "novel_creation_idx", def = "{'novelId': 1, 'createdAt': -1}")
})
public class NovelSnippet {

    @Id
    private String id;

    /**
     * 用户ID
     */
    @Indexed
    private String userId;

    /**
     * 小说ID
     */
    @Indexed
    private String novelId;

    /**
     * 片段标题（用户自定义或自动生成）
     */
    @TextIndexed
    private String title;

    /**
     * 片段内容
     */
    @TextIndexed
    private String content;

    /**
     * 初始生成信息
     */
    private InitialGenerationInfo initialGenerationInfo;

    /**
     * 片段元数据
     */
    @Builder.Default
    private SnippetMetadata metadata = new SnippetMetadata();

    /**
     * 是否收藏
     */
    @Builder.Default
    private Boolean isFavorite = false;

    /**
     * 片段标签
     */
    @Builder.Default
    private List<String> tags = new ArrayList<>();

    /**
     * 片段分类（如：灵感、参考、重要情节等）
     */
    private String category;

    /**
     * 用户备注
     */
    private String notes;

    /**
     * 片段状态（ACTIVE, ARCHIVED, DELETED）
     */
    @Builder.Default
    private String status = "ACTIVE";

    /**
     * 版本号
     */
    @Builder.Default
    private Integer version = 1;

    /**
     * 创建时间
     */
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    private LocalDateTime updatedAt;

    /**
     * 初始生成信息
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class InitialGenerationInfo {
        
        /**
         * 源章节ID
         */
        private String sourceChapterId;
        
        /**
         * 源场景ID（可选）
         */
        private String sourceSceneId;
    }

    /**
     * 片段元数据
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SnippetMetadata {
        
        /**
         * 字数
         */
        private Integer wordCount;
        
        /**
         * 字符数
         */
        private Integer characterCount;
        
        /**
         * 访问次数
         */
        @Builder.Default
        private Integer viewCount = 0;
        
        /**
         * 最后访问时间
         */
        private LocalDateTime lastViewedAt;
        
        /**
         * 排序权重（用于用户自定义排序）
         */
        @Builder.Default
        private Integer sortWeight = 0;
        
        /**
         * 其他扩展元数据
         */
        @Builder.Default
        private Map<String, Object> extensions = new HashMap<>();
    }
}