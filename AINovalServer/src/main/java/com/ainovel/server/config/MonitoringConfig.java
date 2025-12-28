package com.ainovel.server.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.EnableAspectJAutoProxy;

import io.micrometer.core.aop.TimedAspect;
import io.micrometer.core.instrument.MeterRegistry;
// JVM指标的 Binder 在 MetricsConfiguration 中集中提供，这里不再导入

/**
 * 监控配置类
 * 配置Micrometer和Prometheus指标收集
 */
@Configuration
@EnableAspectJAutoProxy
public class MonitoringConfig {

    // 为避免与 MetricsConfiguration 重复注册，同类 JVM 指标 Binder 改由 MetricsConfiguration 提供。
    // 本配置仅保留 @Timed 切面（若需要），并不再重复绑定 JVM 指标。

    @Bean
    public TimedAspect timedAspect(MeterRegistry registry) {
        return new TimedAspect(registry);
    }
}