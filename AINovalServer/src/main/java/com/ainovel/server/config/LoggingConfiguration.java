package com.ainovel.server.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.TaskDecorator;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.web.server.WebFilter;
import reactor.core.publisher.Hooks;

import jakarta.annotation.PostConstruct;
import java.util.Map;
import java.util.UUID;

/**
 * 日志配置，包括MDC跟踪信息和日志格式设置
 */
@Configuration
public class LoggingConfiguration {

    private static final Logger logger = LoggerFactory.getLogger(LoggingConfiguration.class);
    
    /**
     * 设置Reactor上下文传播MDC
     */
    @PostConstruct
    public void init() {
        logger.info("配置Reactor上下文传播MDC");
        // 启用自动上下文传播 (需要 io.micrometer:context-propagation 依赖)
        Hooks.enableAutomaticContextPropagation();
        logger.info("已启用Reactor自动MDC传播");

        // 全局错误 Hook，确保丢弃/运算符错误也能被规范记录
        Hooks.onErrorDropped(e -> logger.error("Reactor onErrorDropped 错误: {}", e.toString(), e));

    }
    
    /**
     * WebFlux请求过滤器，用于设置MDC上下文
     */
    @Bean
    public WebFilter mdcAndLoggingFilter() {
        return (exchange, chain) -> {
            long startTime = System.currentTimeMillis();
            ServerHttpRequest request = exchange.getRequest();

            // --- MDC 设置 开始 ---
            String originalTraceId = request.getHeaders().getFirst("X-Trace-ID");
            final String traceId = (originalTraceId == null)
                    ? UUID.randomUUID().toString().replace("-", "")
                    : originalTraceId;
            MDC.put("traceId", traceId);

            String userId = request.getHeaders().getFirst("X-User-Id");
            if (userId != null) {
                MDC.put("userId", userId);
            }

            final String path = request.getPath().value();
            MDC.put("path", path);
            // --- MDC 设置 结束 ---

            // 对健康检查与监控采集等低价值请求不打印日志
            if (path != null && path.startsWith("/actuator/prometheus")) {
                return chain.filter(exchange)
                        .doFinally(signalType -> MDC.clear());
            }

            // --- 请求日志 开始 ---
            final String finalUserId = userId; // effectively final for lambda
            logger.info("请求开始: 方法={} URI={} 追踪ID={} 用户ID={}",
                    request.getMethod(),
                    request.getURI(),
                    traceId,
                    finalUserId != null ? finalUserId : "N/A");
            // --- 请求日志 结束 ---

            // 附加响应日志和MDC清理
            return chain.filter(exchange)
                    .doOnSuccess(aVoid -> {
                        long duration = System.currentTimeMillis() - startTime;
                        int statusCode = exchange.getResponse().getStatusCode() != null ? exchange.getResponse().getStatusCode().value() : 0;
                        logger.info("请求结束: 状态={} 耗时={}ms 追踪ID={} 路径={}",
                                statusCode, duration, traceId, path);
                    })
                    .doOnError(throwable -> {
                        long duration = System.currentTimeMillis() - startTime;
                        logger.error("请求错误: {} 耗时={}ms 追踪ID={} 路径={}",
                                throwable.getMessage(), duration, traceId, path, throwable);
                    })
                    .doFinally(signalType -> MDC.clear()); // 清理MDC
        };
    }
    
    /**
     * 任务装饰器，用于异步任务间传递MDC
     */
    @Bean
    public TaskDecorator mdcTaskDecorator() {
        return task -> {
            Map<String, String> contextMap = MDC.getCopyOfContextMap();
            return () -> {
                try {
                    if (contextMap != null) {
                        MDC.setContextMap(contextMap);
                    }
                    task.run();
                } finally {
                    MDC.clear();
                }
            };
        };
    }
    
    /**
     * 请求日志过滤器
     */
    /* @Bean
    @ConditionalOnProperty(name = "logging.request", havingValue = "true")
    public CommonsRequestLoggingFilter requestLoggingFilter() {
        CommonsRequestLoggingFilter filter = new CommonsRequestLoggingFilter();
        filter.setIncludeQueryString(true);
        filter.setIncludePayload(true);
        filter.setMaxPayloadLength(10000);
        filter.setIncludeHeaders(false);
        filter.setAfterMessagePrefix("Request data: ");
        return filter;
    } */
} 