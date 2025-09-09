package com.ainovel.server;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import io.micrometer.core.instrument.Meter;
import io.micrometer.core.instrument.config.MeterFilter;
import io.micrometer.core.instrument.config.MeterFilterReply;

/**
 * AI小说助手系统后端服务主应用类
 */
@SpringBootApplication
public class AiNovelServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(AiNovelServerApplication.class, args);
    }

    /**
     * In production, only allow memory-related meters to be exported to minimize overhead.
     * This filters out all meters except those whose names start with known memory prefixes.
     */
    @Bean
    public MeterFilter memoryOnlyMetersFilter() {
        return new MeterFilter() {
            @Override
            public MeterFilterReply accept(Meter.Id id) {
                String name = id.getName();
                if (name == null) {
                    return MeterFilterReply.DENY;
                }

                // JVM memory (existing)
                if (name.startsWith("jvm.memory.")
                    || name.startsWith("process.runtime.jvm.memory.")
                    || name.startsWith("system.memory.")
                    || name.startsWith("process.memory.")) {
                    return MeterFilterReply.ACCEPT;
                }

                // JVM GC / threads / classes / JIT compilation
                if (name.startsWith("jvm.gc.")
                    || name.startsWith("jvm.threads.")
                    || name.startsWith("jvm.classes.")
                    || name.startsWith("jvm.compilation.")) {
                    return MeterFilterReply.ACCEPT;
                }

                // CPU / Load / Uptime
                if (name.startsWith("process.cpu.")
                    || name.startsWith("system.cpu.")
                    || name.startsWith("system.load.")
                    || name.startsWith("process.uptime")) {
                    return MeterFilterReply.ACCEPT;
                }

                // Application level throughput/latency
                if (name.startsWith("http.server.requests")) {
                    return MeterFilterReply.ACCEPT;
                }

                // Logging throughput
                if (name.startsWith("logback.events")) {
                    return MeterFilterReply.ACCEPT;
                }

                // Cache metrics (Caffeine)
                if (name.startsWith("cache.")) {
                    return MeterFilterReply.ACCEPT;
                }

                // Reactor Netty (connections/throughput/timeout)
                if (name.startsWith("reactor.netty.")) {
                    return MeterFilterReply.ACCEPT;
                }

                // Optional: RabbitMQ & MongoDB metrics
                if (name.startsWith("rabbitmq.") || name.startsWith("mongodb.")) {
                    return MeterFilterReply.ACCEPT;
                }

                return MeterFilterReply.DENY;
            }
        };
    }

    @Bean
    public org.springframework.boot.CommandLineRunner startupWarnings(
            org.springframework.core.env.Environment env) {
        return args -> {
            org.slf4j.Logger logger = org.slf4j.LoggerFactory.getLogger(AiNovelServerApplication.class);
            try {
                boolean rabbitEnabled = env.getProperty("spring.rabbitmq.enabled", Boolean.class, false);
                if (!rabbitEnabled) {
                    logger.warn("RabbitMQ disabled by configuration (spring.rabbitmq.enabled=false). Background task queue will not start.");
                }
            } catch (Exception ignored) { }

            try {
                boolean chromaEnabled = env.getProperty("vectorstore.chroma.enabled", Boolean.class, false);
                if (!chromaEnabled) {
                    logger.warn("Chroma vectorstore disabled by configuration (vectorstore.chroma.enabled=false). RAG features will be limited.");
                }
            } catch (Exception ignored) { }
        };
    }
} 