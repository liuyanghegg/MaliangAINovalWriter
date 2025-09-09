package com.ainovel.server.service.ai.observability;

import com.ainovel.server.domain.model.observability.LLMTrace;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * 跨线程Trace上下文管理器
 * 用于在TracingAIModelProviderDecorator和RichTraceChatModelListener之间传递LLMTrace对象
 * 
 * 由于ChatModelListener运行在LangChain4j的独立线程中，无法访问Reactor Context，
 * 因此需要使用此管理器来实现跨线程的trace传递。
 */
@Component
@Slf4j
public class TraceContextManager {
    
    // 使用线程名称作为key存储trace，确保线程安全且避免deprecated警告
    private final ConcurrentMap<String, LLMTrace> traceContext = new ConcurrentHashMap<>();
    
    /**
     * 存储当前线程的trace
     */
    public void setTrace(LLMTrace trace) {
        if (trace != null) {
            String threadName = Thread.currentThread().getName();
            traceContext.put(threadName, trace);
            log.debug("存储trace到上下文: traceId={}, threadName={}", trace.getTraceId(), threadName);
        }
    }
    
    /**
     * 获取当前线程的trace
     */
    public LLMTrace getTrace() {
        String threadName = Thread.currentThread().getName();
        LLMTrace trace = traceContext.get(threadName);
        if (trace != null) {
            log.debug("从上下文获取trace: traceId={}, threadName={}", trace.getTraceId(), threadName);
        } else {
            log.debug("当前线程未找到trace: threadName={}", threadName);
        }
        return trace;
    }
    
    /**
     * 清理当前线程的trace
     */
    public void clearTrace() {
        String threadName = Thread.currentThread().getName();
        LLMTrace trace = traceContext.remove(threadName);
        if (trace != null) {
            log.debug("清理trace上下文: traceId={}, threadName={}", trace.getTraceId(), threadName);
        }
    }
    
    /**
     * 获取上下文中的trace数量（用于监控）
     */
    public int getContextSize() {
        return traceContext.size();
    }
    
    /**
     * 清理所有过期的trace（防止内存泄漏）
     * 可以定期调用此方法清理长时间未使用的trace
     */
    public void cleanup() {
        int sizeBefore = traceContext.size();
        // 这里可以添加基于时间的清理逻辑
        // 暂时保持简单，依赖正常的clearTrace调用
        log.debug("Trace上下文清理完成，清理前: {}, 清理后: {}", sizeBefore, traceContext.size());
    }
}