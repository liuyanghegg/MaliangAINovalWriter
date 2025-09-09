package com.ainovel.server.service.ai.observability.events;

import org.springframework.context.ApplicationEvent;

import com.ainovel.server.domain.model.observability.LLMTrace;

import lombok.Getter;

@Getter
public class BillingRequestedEvent extends ApplicationEvent {
    private final LLMTrace trace;
    public BillingRequestedEvent(Object source, LLMTrace trace) {
        super(source);
        this.trace = trace;
    }
}


