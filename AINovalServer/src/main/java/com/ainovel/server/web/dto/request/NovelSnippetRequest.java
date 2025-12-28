package com.ainovel.server.web.dto.request;

import java.util.List;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 小说片段请求DTO
 */
public class NovelSnippetRequest {

    /**
     * 创建片段请求
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Create {

        @NotBlank(message = "小说ID不能为空")
        private String novelId;

        @NotBlank(message = "片段标题不能为空")
        @Size(max = 200, message = "标题长度不能超过200字符")
        private String title;

        @NotBlank(message = "片段内容不能为空")
        @Size(max = 10000, message = "内容长度不能超过10000字符")
        private String content;

        private String sourceChapterId;

        private String sourceSceneId;

        private List<String> tags;

        private String category;

        private String notes;
    }

    /**
     * 更新片段内容请求
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateContent {

        @NotBlank(message = "片段ID不能为空")
        private String snippetId;

        @NotBlank(message = "片段内容不能为空")
        @Size(max = 10000, message = "内容长度不能超过10000字符")
        private String content;

        private String changeDescription;
    }

    /**
     * 更新片段标题请求
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateTitle {

        @NotBlank(message = "片段ID不能为空")
        private String snippetId;

        @NotBlank(message = "片段标题不能为空")
        @Size(max = 200, message = "标题长度不能超过200字符")
        private String title;

        private String changeDescription;
    }

    /**
     * 收藏/取消收藏请求
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateFavorite {

        @NotBlank(message = "片段ID不能为空")
        private String snippetId;

        @NotNull(message = "收藏状态不能为空")
        private Boolean isFavorite;
    }

    /**
     * 回退版本请求
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RevertToVersion {

        @NotBlank(message = "片段ID不能为空")
        private String snippetId;

        @NotNull(message = "版本号不能为空")
        private Integer version;

        private String changeDescription;
    }
} 