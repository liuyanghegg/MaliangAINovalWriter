package com.ainovel.server.web.dto.response;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import com.ainovel.server.domain.model.NovelSnippet;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 小说片段响应DTO
 */
public class NovelSnippetResponse {

    /**
     * 片段基本信息
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Basic {

        private String id;
        private String userId;
        private String novelId;
        private String title;
        private String content;
        private Boolean isFavorite;
        private List<String> tags;
        private String category;
        private String notes;
        private String status;
        private Integer version;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;
        private InitialGenerationInfo initialGenerationInfo;
        private SnippetMetadata metadata;

        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class InitialGenerationInfo {
            private String sourceChapterId;
            private String sourceSceneId;
        }

        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class SnippetMetadata {
            private Integer wordCount;
            private Integer characterCount;
            private Integer viewCount;
            private LocalDateTime lastViewedAt;
            private Integer sortWeight;
            private Map<String, Object> extensions;
        }

        public static Basic from(NovelSnippet snippet) {
            return Basic.builder()
                    .id(snippet.getId())
                    .userId(snippet.getUserId())
                    .novelId(snippet.getNovelId())
                    .title(snippet.getTitle())
                    .content(snippet.getContent())
                    .isFavorite(snippet.getIsFavorite())
                    .tags(snippet.getTags())
                    .category(snippet.getCategory())
                    .notes(snippet.getNotes())
                    .status(snippet.getStatus())
                    .version(snippet.getVersion())
                    .createdAt(snippet.getCreatedAt())
                    .updatedAt(snippet.getUpdatedAt())
                    .initialGenerationInfo(snippet.getInitialGenerationInfo() != null 
                            ? InitialGenerationInfo.builder()
                                .sourceChapterId(snippet.getInitialGenerationInfo().getSourceChapterId())
                                .sourceSceneId(snippet.getInitialGenerationInfo().getSourceSceneId())
                                .build()
                            : null)
                    .metadata(snippet.getMetadata() != null 
                            ? SnippetMetadata.builder()
                                .wordCount(snippet.getMetadata().getWordCount())
                                .characterCount(snippet.getMetadata().getCharacterCount())
                                .viewCount(snippet.getMetadata().getViewCount())
                                .lastViewedAt(snippet.getMetadata().getLastViewedAt())
                                .sortWeight(snippet.getMetadata().getSortWeight())
                                .extensions(snippet.getMetadata().getExtensions())
                                .build()
                            : null)
                    .build();
        }
    }

    /**
     * 片段简要信息（用于列表显示）
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Summary {

        private String id;
        private String title;
        private String contentPreview; // 内容预览（前100字符）
        private Boolean isFavorite;
        private List<String> tags;
        private String category;
        private Integer version;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;

        public static Summary from(NovelSnippet snippet) {
            String contentPreview = snippet.getContent() != null && snippet.getContent().length() > 100
                    ? snippet.getContent().substring(0, 100) + "..."
                    : snippet.getContent();

            return Summary.builder()
                    .id(snippet.getId())
                    .title(snippet.getTitle())
                    .contentPreview(contentPreview)
                    .isFavorite(snippet.getIsFavorite())
                    .tags(snippet.getTags())
                    .category(snippet.getCategory())
                    .version(snippet.getVersion())
                    .createdAt(snippet.getCreatedAt())
                    .updatedAt(snippet.getUpdatedAt())
                    .build();
        }
    }

    /**
     * 历史记录信息
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class History {

        private String id;
        private String snippetId;
        private String operationType;
        private Integer version;
        private String beforeTitle;
        private String afterTitle;
        private String beforeContent;
        private String afterContent;
        private String changeDescription;
        private LocalDateTime createdAt;
    }

    /**
     * 分页响应
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PageResult<T> {

        private List<T> content;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;
        private boolean hasNext;
        private boolean hasPrevious;
    }
} 