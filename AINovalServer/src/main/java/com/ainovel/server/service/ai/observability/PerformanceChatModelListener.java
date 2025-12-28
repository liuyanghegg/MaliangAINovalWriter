package com.ainovel.server.service.ai.observability;

import dev.langchain4j.model.chat.listener.ChatModelListener;
import dev.langchain4j.model.chat.listener.ChatModelRequestContext;
import dev.langchain4j.model.chat.listener.ChatModelResponseContext;
import dev.langchain4j.model.chat.listener.ChatModelErrorContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 性能监控监听器示例
 * 展示如何轻松扩展新的监听器功能
 * 
 * 这个监听器专门用于性能监控：
 * 1. 记录请求响应时间
 * 2. 统计Token使用效率
 * 3. 监控错误率
 * 4. 生成性能报告
 */
@Slf4j
@Component  // 标记为Spring Bean，会被自动注入到ChatModelListenerManager中
public class PerformanceChatModelListener implements ChatModelListener {

    private static final String PERFORMANCE_ATTR_KEY = "performance.start_time";

    @Override
    public void onRequest(ChatModelRequestContext context) {
        try {
            // 记录请求开始时间
            long startTime = System.currentTimeMillis();
            context.attributes().put(PERFORMANCE_ATTR_KEY, startTime);
            
            log.debug("⏱️ 性能监控：请求开始 - {}", startTime);
        } catch (Exception e) {
            log.warn("性能监控：记录请求开始时间失败", e);
        }
    }

    @Override
    public void onResponse(ChatModelResponseContext context) {
        try {
            Object startTimeObj = context.attributes().get(PERFORMANCE_ATTR_KEY);
            if (startTimeObj instanceof Long startTime) {
                long endTime = System.currentTimeMillis();
                long duration = endTime - startTime;
                
                // 获取Token使用信息
                int inputTokens = 0;
                int outputTokens = 0;
                if (context.chatResponse().metadata().tokenUsage() != null) {
                    inputTokens = context.chatResponse().metadata().tokenUsage().inputTokenCount();
                    outputTokens = context.chatResponse().metadata().tokenUsage().outputTokenCount();
                }
                
                // 计算性能指标
                double tokensPerSecond = outputTokens > 0 ? (outputTokens * 1000.0) / duration : 0;
                String tps = String.format("%.2f", tokensPerSecond);

                log.info("📊 性能监控报告：");
                log.info("  ⏱️ 响应时间: {}ms", duration);
                log.info("  📥 输入Token: {}", inputTokens);
                log.info("  📤 输出Token: {}", outputTokens);
                log.info("  🚀 生成速度: {} tokens/秒", tps);
                
                // 性能警告
                if (duration > 20000) { // 放宽为20秒，减少无意义告警
                    log.warn("⚠️ 响应时间过长: {}ms，建议检查网络或模型配置", duration);
                }
                
                if (tokensPerSecond < 1.0 && outputTokens > 10) {
                    log.warn("⚠️ Token生成速度较慢: {} tokens/秒", tps);
                }
                
            } else {
                log.warn("性能监控：未找到请求开始时间");
            }
        } catch (Exception e) {
            log.warn("性能监控：处理响应时间失败", e);
        }
    }

    @Override
    public void onError(ChatModelErrorContext context) {
        try {
            Object startTimeObj = context.attributes().get(PERFORMANCE_ATTR_KEY);
            if (startTimeObj instanceof Long startTime) {
                long endTime = System.currentTimeMillis();
                long duration = endTime - startTime;
                
                log.error("❌ 性能监控：请求失败");
                log.error("  ⏱️ 失败时间: {}ms", duration);
                log.error("  🔍 错误类型: {}", context.error().getClass().getSimpleName());
                log.error("  📝 错误信息: {}", context.error().getMessage());
            }
        } catch (Exception e) {
            log.warn("性能监控：处理错误信息失败", e);
        }
    }
}