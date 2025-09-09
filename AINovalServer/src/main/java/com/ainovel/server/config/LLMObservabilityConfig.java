package com.ainovel.server.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.EnableAspectJAutoProxy;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

/**
 * LLM可观测性配置
 * 配置AOP、异步执行器等
 */
@Configuration
// @EnableAspectJAutoProxy  // 可以移除这行，因为不再使用AOP
@EnableAsync
public class LLMObservabilityConfig {

    /**
     * LLM追踪专用线程池
     * 使用虚拟线程提高并发性能
     */
    @Bean("llmTraceExecutor")
    public Executor llmTraceExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(4);
        executor.setMaxPoolSize(16);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("llm-trace-");
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(30);
        
        // 使用虚拟线程（Java 21+）
        executor.setVirtualThreads(true);
        
        executor.initialize();
        return executor;
    }
} 