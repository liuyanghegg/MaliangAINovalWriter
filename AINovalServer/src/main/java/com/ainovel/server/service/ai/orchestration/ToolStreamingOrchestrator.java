package com.ainovel.server.service.ai.orchestration;
import com.ainovel.server.service.AIService;
import com.ainovel.server.service.ai.tools.ToolDefinition;
import com.ainovel.server.service.ai.tools.ToolExecutionService;
import com.ainovel.server.service.ai.tools.events.ToolEvent;
import dev.langchain4j.data.message.ChatMessage;
import dev.langchain4j.data.message.SystemMessage;
import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.agent.tool.ToolSpecification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 通用工具编排（流式直通）：注册指定工具，执行工具调用循环，
 * 将每次工具调用的原始结果以 ToolEvent 流式返回；不进行任何类型映射或业务落地。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ToolStreamingOrchestrator {

    private final ToolExecutionService toolExecutionService;
    private final AIService aiService;

    public record StartOptions(
            String contextId,
            String provider,
            String modelName,
            String apiKey,
            String apiEndpoint,
            Map<String, String> config,
            List<ToolDefinition> tools,
            String systemPrompt,
            String userPrompt,
            int maxIterations,
            boolean endWhenNoToolCalls
    ) {}

    public Flux<ToolEvent> startStreaming(StartOptions options) {
        String contextId = options.contextId() != null ? options.contextId() : ("orchestrate-" + UUID.randomUUID());

        // 0) 打印工具清单与模型信息，便于排错
        List<String> toolNames = new ArrayList<>();
        if (options.tools() != null) {
            for (ToolDefinition t : options.tools()) {
                try { toolNames.add(t.getName()); } catch (Exception ignore) {}
            }
        }
        log.info("工具编排开始: 上下文ID={} 提供商={} 模型={} 工具={}",
                contextId, options.provider(), options.modelName(), toolNames);

        // 1) 注册上下文工具
        ToolExecutionService.ToolCallContext context = toolExecutionService.createContext(contextId);
        for (ToolDefinition tool : options.tools()) {
            context.registerTool(tool);
        }

        // 2) 事件流订阅
        Flux<ToolEvent> eventFlux = toolExecutionService.subscribeToContext(contextId);

        // 3) 构建消息
        List<ChatMessage> messages = new ArrayList<>();
        if (options.systemPrompt() != null && !options.systemPrompt().isBlank()) {
            messages.add(new SystemMessage(options.systemPrompt()));
        }
        if (options.userPrompt() != null && !options.userPrompt().isBlank()) {
            messages.add(new UserMessage(options.userPrompt()));
        }

        // 4) 工具规范
        List<ToolSpecification> specs = new ArrayList<>();
        for (ToolDefinition t : options.tools()) {
            specs.add(t.getSpecification());
        }

        // 5) 透传上下文ID
        Map<String, String> config = options.config() != null ? new HashMap<>(options.config()) : new HashMap<>();
        if (options.provider() != null && !options.provider().isBlank()) {
            config.put("provider", options.provider());
        }
        config.put("toolContextId", contextId);
        config.putIfAbsent("requestType", "TOOL_ORCHESTRATION");

        // 工具编排阶段：不做扣费标记注入（仅透传公共模型ID用于日志观测，真正扣费在文本流阶段完成）
        try {
            String publicCfgId = config.get("publicModelConfigId");
            if (publicCfgId != null && !publicCfgId.isBlank()) {
                config.putIfAbsent(com.ainovel.server.service.billing.BillingKeys.PUBLIC_MODEL_CONFIG_ID, publicCfgId);
            }
        } catch (Exception ignore) {}

        // 6) 启动循环（后台执行），结束后发 COMPLETE
        Mono<List<ChatMessage>> loop = aiService.executeToolCallLoop(
                messages,
                specs,
                options.modelName(),
                options.apiKey(),
                options.apiEndpoint(),
                config,
                options.maxIterations() > 0 ? options.maxIterations() : 20
        )
        // 对瞬时LLM错误进行有限次数重试（例如429/上游忙/网络抖动）
        .retryWhen(reactor.util.retry.Retry.backoff(2, java.time.Duration.ofSeconds(2))
            .maxBackoff(java.time.Duration.ofSeconds(8))
            .jitter(0.3)
            .filter(err -> {
                String cls = err.getClass().getName().toLowerCase();
                String msg = err.getMessage() != null ? err.getMessage().toLowerCase() : "";
                boolean isNetwork = err instanceof java.net.SocketException
                    || err instanceof java.io.IOException
                    || err instanceof java.util.concurrent.TimeoutException;
                boolean isRateLimited = msg.contains("429")
                    || msg.contains("rate limit")
                    || msg.contains("quota")
                    || msg.contains("temporarily")
                    || msg.contains("retry shortly")
                    || msg.contains("upstream")
                    || msg.contains("resource_exhausted");
                boolean isHttp = cls.contains("httpexception") || cls.contains("httpclient");
                return isNetwork || isRateLimited || isHttp;
            })
        )
        .subscribeOn(Schedulers.boundedElastic())
         .doOnError(err -> {
            log.error("工具循环出错: 上下文={} 错误={}", contextId, err.getMessage(), err);
            // 显式发出错误事件，便于前端结束等待并展示错误
            try {
                SinksFieldHolder.emit(toolExecutionService, contextId, ToolEvent.builder()
                    .contextId(contextId)
                    .eventType("CALL_ERROR")
                    .errorMessage(err.getMessage())
                    .timestamp(LocalDateTime.now())
                    .sequence(-1L)
                    .success(false)
                    .build());
            } catch (Exception ignore) {}
            toolExecutionService.closeContext(contextId);
        }).doOnSuccess(v -> {
            emitComplete(contextId);
            toolExecutionService.closeContext(contextId);
            try { context.close(); } catch (Exception ignore) {}
        });

        // 7) 返回事件流，追加心跳与最终 complete 合并（complete 在 closeContext 时触发）
        return eventFlux
            .mergeWith(Flux.interval(Duration.ofSeconds(15)).map(i -> ToolEvent.builder()
                .contextId(contextId)
                .eventType("HEARTBEAT")
                .sequence(-1L)
                .timestamp(LocalDateTime.now())
                .build()))
            .takeUntilOther(loop.thenMany(Flux.empty()));
    }

    private void emitComplete(String contextId) {
        try {
            SinksFieldHolder.emit(toolExecutionService, contextId, ToolEvent.builder()
                .contextId(contextId)
                .eventType("COMPLETE")
                .timestamp(LocalDateTime.now())
                .sequence(-1L)
                .success(true)
                .build());
        } catch (Exception ignore) {}
    }

    /** 简单的反射助手：复用 ToolExecutionService 的 emitEvent */
    static class SinksFieldHolder {
        static void emit(ToolExecutionService svc, String ctx, ToolEvent evt) {
            try {
                var m = ToolExecutionService.class.getDeclaredMethod("emitEvent", String.class, ToolEvent.class);
                m.setAccessible(true);
                m.invoke(svc, ctx, evt);
            } catch (Exception ignored) {}
        }
    }
}


