package com.ainovel.server.common.util;

import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlElementWrapper;
import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlProperty;
import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlRootElement;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * 提示词模板数据模型
 * 用于Jackson XML序列化和反序列化
 */
public class PromptTemplateModel {

    /**
     * 系统提示词模板
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JacksonXmlRootElement(localName = "system")
    public static class SystemPrompt {
        
        @JacksonXmlProperty(localName = "role")
        private String role;
        
        @JacksonXmlProperty(localName = "instructions")
        private String instructions;
        
        @JacksonXmlProperty(localName = "context")
        private String context;
        
        @JacksonXmlProperty(localName = "length")
        private String length;
        
        @JacksonXmlProperty(localName = "style")
        private String style;
        
        @JacksonXmlProperty(localName = "parameters")
        private Parameters parameters;
        
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class Parameters {
            @JacksonXmlProperty(localName = "temperature")
            private Double temperature;
            
            @JacksonXmlProperty(localName = "max_tokens")
            private Integer maxTokens;
            
            @JacksonXmlProperty(localName = "top_p")
            private Double topP;
        }
    }

    /**
     * 用户提示词模板
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JacksonXmlRootElement(localName = "task")
    public static class UserPrompt {
        
        @JacksonXmlProperty(localName = "action")
        private String action;
        
        @JacksonXmlProperty(localName = "input")
        private String input;
        
        @JacksonXmlProperty(localName = "message")
        private String message;
        
        @JacksonXmlProperty(localName = "context")
        private String context;
        
        @JacksonXmlProperty(localName = "requirements")
        private Requirements requirements;
        
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class Requirements {
            @JacksonXmlProperty(localName = "length")
            private String length;
            
            @JacksonXmlProperty(localName = "style")
            private String style;
            
            @JacksonXmlProperty(localName = "tone")
            private String tone;
        }
    }

    /**
     * 聊天消息模板
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JacksonXmlRootElement(localName = "message")
    public static class ChatMessage {
        
        @JacksonXmlProperty(localName = "content")
        private String content;
        
        @JacksonXmlProperty(localName = "context")
        private String context;
    }

    /**
     * 小说内容结构
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JacksonXmlRootElement(localName = "outline")
    public static class NovelOutline {
        
        @JacksonXmlProperty(localName = "title")
        private String title;
        
        @JacksonXmlProperty(localName = "description")
        private String description;
        
        @JacksonXmlElementWrapper(useWrapping = false)
        @JacksonXmlProperty(localName = "act")
        private List<Act> acts;
        
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class Act {
            @JacksonXmlProperty(isAttribute = true, localName = "number")
            private Integer number;
            
            @JacksonXmlProperty(localName = "title")
            private String title;
            
            @JacksonXmlProperty(localName = "description")
            private String description;
            
            @JacksonXmlElementWrapper(useWrapping = false)
            @JacksonXmlProperty(localName = "chapter")
            private List<Chapter> chapters;
        }
        
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class Chapter {
            @JacksonXmlProperty(isAttribute = true, localName = "number")
            private Integer number;
            
            @JacksonXmlProperty(isAttribute = true, localName = "id")
            private String id;
            
            @JacksonXmlProperty(localName = "title")
            private String title;
            
            @JacksonXmlProperty(localName = "summary")
            private String summary;
            
            @JacksonXmlElementWrapper(useWrapping = false)
            @JacksonXmlProperty(localName = "scene")
            private List<Scene> scenes;
        }
        
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class Scene {
            @JacksonXmlProperty(isAttribute = true, localName = "title")
            private String title;
            
            @JacksonXmlProperty(isAttribute = true, localName = "number")
            private Integer number;
            
            @JacksonXmlProperty(isAttribute = true, localName = "id")
            private String id;
            
            @JacksonXmlProperty(localName = "summary")
            private String summary;
            
            @JacksonXmlProperty(localName = "content")
            private String content;
        }
    }

    /**
     * 上下文数据结构
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JacksonXmlRootElement(localName = "selected_context")
    public static class SelectedContext {
        
        @JacksonXmlProperty(localName = "full_novel_text")
        private NovelOutline fullNovelText;
        
        @JacksonXmlProperty(localName = "full_novel_summary")
        private NovelSummary fullNovelSummary;
        
        @JacksonXmlElementWrapper(useWrapping = false)
        @JacksonXmlProperty(localName = "act")
        private List<NovelOutline.Act> acts;
        
        @JacksonXmlElementWrapper(useWrapping = false)
        @JacksonXmlProperty(localName = "chapter")
        private List<NovelOutline.Chapter> chapters;
        
        @JacksonXmlElementWrapper(useWrapping = false)
        @JacksonXmlProperty(localName = "scene")
        private List<NovelOutline.Scene> scenes;
        
        @JacksonXmlElementWrapper(useWrapping = false)
        @JacksonXmlProperty(localName = "setting")
        private List<Setting> settings;
        
        @JacksonXmlElementWrapper(useWrapping = false)
        @JacksonXmlProperty(localName = "snippet")
        private List<Snippet> snippets;
        
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class Setting {
            @JacksonXmlProperty(isAttribute = true, localName = "type")
            private String type;
            
            @JacksonXmlProperty(isAttribute = true, localName = "id")
            private String id;
            
            @JacksonXmlProperty(localName = "name")
            private String name;
            
            @JacksonXmlProperty(localName = "description")
            private String description;
            
            @JacksonXmlProperty(localName = "attributes")
            private String attributes;
            
            @JacksonXmlProperty(localName = "tags")
            private String tags;
        }
        
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class Snippet {
            @JacksonXmlProperty(isAttribute = true, localName = "id")
            private String id;
            
            @JacksonXmlProperty(localName = "title")
            private String title;
            
            @JacksonXmlProperty(localName = "content")
            private String content;
        }
    }

    /**
     * 小说摘要结构
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JacksonXmlRootElement(localName = "full_novel_summary")
    public static class NovelSummary {
        
        @JacksonXmlProperty(localName = "title")
        private String title;
        
        @JacksonXmlProperty(localName = "description")
        private String description;
        
        @JacksonXmlElementWrapper(localName = "summary_content")
        @JacksonXmlProperty(localName = "chapter")
        private List<ChapterSummary> chapters;
        
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class ChapterSummary {
            @JacksonXmlProperty(isAttribute = true, localName = "id")
            private String id;
            
            @JacksonXmlProperty(isAttribute = true, localName = "number")
            private Integer number;
            
            @JacksonXmlElementWrapper(useWrapping = false)
            @JacksonXmlProperty(localName = "scene_summary")
            private List<SceneSummary> scenes;
        }
        
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class SceneSummary {
            @JacksonXmlProperty(isAttribute = true, localName = "title")
            private String title;
            
            @JacksonXmlProperty(isAttribute = true, localName = "number")
            private Integer number;
            
            @JacksonXmlProperty(isAttribute = true, localName = "id")
            private String id;
            
            @JacksonXmlProperty(localName = "content")
            private String content;
        }
    }

    /**
     * 片段数据结构
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JacksonXmlRootElement(localName = "snippet")
    public static class Snippet {
        
        @JacksonXmlProperty(isAttribute = true, localName = "id")
        private String id;
        
        @JacksonXmlProperty(isAttribute = true, localName = "title")
        private String title;
        
        @JacksonXmlProperty(localName = "notes")
        private String notes;
        
        @JacksonXmlProperty(localName = "content")
        private String content;
        
        @JacksonXmlProperty(localName = "category")
        private String category;
        
        @JacksonXmlProperty(localName = "tags")
        private String tags;
    }

    /**
     * 🚀 新增：完整小说文本结构（包含所有场景的实际内容）
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JacksonXmlRootElement(localName = "full_novel_text")
    public static class FullNovelText {
        
        @JacksonXmlProperty(localName = "title")
        private String title;
        
        @JacksonXmlProperty(localName = "description")
        private String description;
        
        @JacksonXmlElementWrapper(useWrapping = false)
        @JacksonXmlProperty(localName = "act")
        private List<ActContent> acts;
        
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class ActContent {
            @JacksonXmlProperty(isAttribute = true, localName = "number")
            private Integer number;
            
            @JacksonXmlProperty(localName = "title")
            private String title;
            
            @JacksonXmlProperty(localName = "description")
            private String description;
            
            @JacksonXmlElementWrapper(useWrapping = false)
            @JacksonXmlProperty(localName = "chapter")
            private List<ChapterContent> chapters;
        }
        
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class ChapterContent {
            @JacksonXmlProperty(isAttribute = true, localName = "number")
            private Integer number;
            
            @JacksonXmlProperty(isAttribute = true, localName = "id")
            private String id;
            
            @JacksonXmlProperty(localName = "title")
            private String title;
            
            @JacksonXmlElementWrapper(useWrapping = false)
            @JacksonXmlProperty(localName = "scene")
            private List<SceneContent> scenes;
        }
        
        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class SceneContent {
            @JacksonXmlProperty(isAttribute = true, localName = "title")
            private String title;
            
            @JacksonXmlProperty(isAttribute = true, localName = "number")
            private Integer number;
            
            @JacksonXmlProperty(isAttribute = true, localName = "id")
            private String id;
            
            @JacksonXmlProperty(localName = "content")
            private String content;
        }
    }

    /**
     * 🚀 新增：Act内容结构
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JacksonXmlRootElement(localName = "act")
    public static class ActStructure {
        @JacksonXmlProperty(isAttribute = true, localName = "number")
        private Integer number;
        
        @JacksonXmlProperty(localName = "title")
        private String title;
        
        @JacksonXmlProperty(localName = "description")
        private String description;
        
        @JacksonXmlElementWrapper(useWrapping = false)
        @JacksonXmlProperty(localName = "chapter")
        private List<FullNovelText.ChapterContent> chapters;
    }
} 