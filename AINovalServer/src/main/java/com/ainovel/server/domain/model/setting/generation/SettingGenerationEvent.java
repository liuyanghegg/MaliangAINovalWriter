package com.ainovel.server.domain.model.setting.generation;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonSubTypes;
import com.fasterxml.jackson.annotation.JsonTypeInfo;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 设定生成事件基类
 * 用于SSE流式推送
 */
@lombok.EqualsAndHashCode(callSuper = false)
@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, property = "eventType")
@JsonSubTypes({
    @JsonSubTypes.Type(value = SettingGenerationEvent.SessionStartedEvent.class, name = "SESSION_STARTED"),
    @JsonSubTypes.Type(value = SettingGenerationEvent.NodeCreatedEvent.class, name = "NODE_CREATED"),
    @JsonSubTypes.Type(value = SettingGenerationEvent.NodeUpdatedEvent.class, name = "NODE_UPDATED"),
    @JsonSubTypes.Type(value = SettingGenerationEvent.NodeDeletedEvent.class, name = "NODE_DELETED"),
    @JsonSubTypes.Type(value = SettingGenerationEvent.GenerationProgressEvent.class, name = "GENERATION_PROGRESS"),
    @JsonSubTypes.Type(value = SettingGenerationEvent.GenerationCompletedEvent.class, name = "GENERATION_COMPLETED"),
    @JsonSubTypes.Type(value = SettingGenerationEvent.GenerationErrorEvent.class, name = "GENERATION_ERROR")
})
public abstract class SettingGenerationEvent {
    /**
     * 会话ID
     */
    private String sessionId;
    
    /**
     * 事件时间戳
     */
    private LocalDateTime timestamp;
    
    /**
     * 会话开始事件
     */
    @lombok.EqualsAndHashCode(callSuper = false)
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SessionStartedEvent extends SettingGenerationEvent {
        private String initialPrompt;
        private String strategy;
    }
    
    /**
     * 节点创建事件
     */
    @lombok.EqualsAndHashCode(callSuper = false)
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class NodeCreatedEvent extends SettingGenerationEvent {
        private SettingNode node;
        private String parentPath; // 从根节点到父节点的路径
    }
    
    /**
     * 节点更新事件
     */
    @lombok.EqualsAndHashCode(callSuper = false)
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class NodeUpdatedEvent extends SettingGenerationEvent {
        private SettingNode node;
        private SettingNode previousVersion;
    }
    
    /**
     * 节点删除事件
     */
    @lombok.EqualsAndHashCode(callSuper = false)
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class NodeDeletedEvent extends SettingGenerationEvent {
        private List<String> deletedNodeIds;
        private String reason;
    }
    
    /**
     * 生成进度事件
     */
    @lombok.EqualsAndHashCode(callSuper = false)
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GenerationProgressEvent extends SettingGenerationEvent {
        private String message;
        private Integer totalNodes;
        private Integer completedNodes;
        private Double progress; // 0.0 to 1.0

        /**
         * 为前端兼容提供的字段：阶段名
         * 旧前端期望存在非空的 stage 字段
         */
        public String getStage() {
            return "progress";
        }

        /**
         * 为前端兼容提供的字段：当前步骤
         */
        public Integer getCurrentStep() {
            return null;
        }

        /**
         * 为前端兼容提供的字段：总步骤
         */
        public Integer getTotalSteps() {
            return null;
        }

        /**
         * 为前端兼容提供的字段：关联节点ID
         */
        public String getNodeId() {
            return null;
        }
    }
    
    /**
     * 生成完成事件
     */
    @lombok.EqualsAndHashCode(callSuper = false)
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GenerationCompletedEvent extends SettingGenerationEvent {
        private Integer totalNodesGenerated;
        private Long generationTimeMs;
        private String status;
    }
    
    /**
     * 生成错误事件
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GenerationErrorEvent extends SettingGenerationEvent {
        private String errorCode;
        private String errorMessage;
        private String nodeId; // 如果错误与特定节点相关
        private Boolean recoverable;
    }

}