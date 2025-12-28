package com.ainovel.server.service.ai.tools.events;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 通用工具编排流式事件（纯数据，解耦业务/会话）
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ToolEvent {
    /** 上下文ID（用于多路复用） */
    private String contextId;
    /** 事件类型：CALL_RECEIVED/CALL_RESULT/CALL_ERROR/COMPLETE */
    private String eventType;
    /** 工具名（COMPLETE 时可能为空） */
    private String toolName;
    /** 工具参数原始JSON（CALL_RECEIVED时可带） */
    private String argumentsJson;
    /** 工具结果原始JSON（CALL_RESULT时可带） */
    private String resultJson;
    /** 是否成功（仅对结果事件有意义） */
    private Boolean success;
    /** 错误信息（仅错误事件） */
    private String errorMessage;
    /** 同一上下文内的自增序号，保证事件有序 */
    private Long sequence;
    /** 工具循环迭代序号（可选） */
    private Integer iteration;
    /** 时间戳 */
    private LocalDateTime timestamp;
}


