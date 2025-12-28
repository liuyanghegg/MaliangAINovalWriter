package com.ainovel.server.service.ai.observability.events;

import com.ainovel.server.domain.model.observability.LLMTrace;
import lombok.Getter;
import org.springframework.context.ApplicationEvent;

/**
 * LLM链路追踪事件
 * 用于在AOP切面和事件监听器之间传递追踪数据
 */
@Getter
public class LLMTraceEvent extends ApplicationEvent {
    
    private final LLMTrace trace;
    
    public LLMTraceEvent(Object source, LLMTrace trace) {
        super(source);
        this.trace = trace;
    }
} 