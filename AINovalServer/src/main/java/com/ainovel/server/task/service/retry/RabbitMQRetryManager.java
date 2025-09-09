package com.ainovel.server.task.service.retry;

import com.ainovel.server.config.ProviderRateLimitConfig;
import com.ainovel.server.config.RetryStrategyEnum;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.core.MessageBuilder;
import org.springframework.amqp.core.MessageProperties;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * RabbitMQ重试管理器
 * 实现基于RabbitMQ延迟队列的重试机制
 * 
 * 特点:
 * 1. 4倍指数退避重试
 * 2. 智能重试策略选择
 * 3. 并发安全的重试计数
 * 4. 基于错误类型的策略调整
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RabbitMQRetryManager {
    
    private final RabbitTemplate rabbitTemplate;
    
    // 重试计数器 - 按请求ID分组
    private final ConcurrentHashMap<String, AtomicInteger> retryCounters = new ConcurrentHashMap<>();
    
    // 延迟队列配置
    private static final String RETRY_EXCHANGE = "ai.retry.exchange";
    private static final String DLX_SUFFIX = ".dlx";
    private static final String RETRY_HEADER = "x-retry-count";
    private static final String ERROR_TYPE_HEADER = "x-error-type";
    private static final String ORIGINAL_QUEUE_HEADER = "x-original-queue";
    
    /**
     * 发送重试任务到延迟队列
     * 
     * @param config 供应商配置
     * @param originalPayload 原始任务载荷
     * @param errorType 错误类型
     * @param requestId 请求ID
     */
    public Mono<Boolean> scheduleRetry(ProviderRateLimitConfig config, 
                                     Object originalPayload, 
                                     String errorType, 
                                     String requestId) {
        
        AtomicInteger counter = retryCounters.computeIfAbsent(requestId, k -> new AtomicInteger(0));
        int currentAttempt = counter.incrementAndGet();
        
        RetryStrategyEnum strategy = config.getRetryStrategy().adjustForErrorType(errorType);
        int maxAttempts = strategy.getMaxRetryAttempts();
        
        if (currentAttempt > maxAttempts) {
            log.error("重试次数已达上限: requestId={}, attempts={}, max={}", 
                    requestId, currentAttempt, maxAttempts);
            retryCounters.remove(requestId);
            return Mono.just(false);
        }
        
        // 计算延迟时间
        long delayMillis = strategy.calculateDelay(currentAttempt);
        
        return Mono.fromCallable(() -> {
            try {
                // 构建重试消息
                Message retryMessage = createRetryMessage(config, originalPayload, errorType, requestId, currentAttempt);
                
                // 发送到延迟队列
                String routingKey = config.getRetryQueueName();
                
                                 if (strategy.isUseRabbitMQDelay()) {
                     // 使用RabbitMQ延迟插件
                     rabbitTemplate.convertAndSend(RETRY_EXCHANGE, routingKey, retryMessage, message -> {
                         // 使用自定义头部设置延迟
                         message.getMessageProperties().setHeader("x-delay", delayMillis);
                         return message;
                     });
                 } else {
                     // 使用TTL + DLX方式
                     sendToTtlQueue(routingKey, retryMessage, delayMillis);
                 }
                
                log.info("任务已加入重试队列: requestId={}, attempt={}/{}, delay={}ms, strategy={}", 
                        requestId, currentAttempt, maxAttempts, delayMillis, strategy.name());
                
                return true;
            } catch (Exception e) {
                log.error("发送重试任务失败: requestId={}, error={}", requestId, e.getMessage(), e);
                return false;
            }
        });
    }
    
    /**
     * 创建重试消息
     */
    private Message createRetryMessage(ProviderRateLimitConfig config, 
                                     Object payload, 
                                     String errorType, 
                                     String requestId, 
                                     int attemptNumber) {
        
        MessageProperties properties = new MessageProperties();
        properties.setHeader(RETRY_HEADER, attemptNumber);
        properties.setHeader(ERROR_TYPE_HEADER, errorType);
        properties.setHeader(ORIGINAL_QUEUE_HEADER, config.getRateLimiterKey());
        properties.setHeader("x-provider", config.getProvider().getCode());
        properties.setHeader("x-user-id", config.getUserId());
        properties.setHeader("x-model-name", config.getModelName());
        properties.setHeader("x-request-id", requestId);
        properties.setHeader("x-retry-strategy", config.getRetryStrategy().name());
        properties.setHeader("x-scheduled-time", System.currentTimeMillis());
        
        // 设置持久化
        properties.setDeliveryMode(MessageProperties.DEFAULT_DELIVERY_MODE);
        
        return MessageBuilder.withBody(serializePayload(payload))
                .andProperties(properties)
                .build();
    }
    
    /**
     * 发送到TTL队列（备用方案）
     */
    private void sendToTtlQueue(String routingKey, Message message, long delayMillis) {
        String ttlQueueName = routingKey + ".ttl";
        
        // 设置TTL
        message.getMessageProperties().setExpiration(String.valueOf(delayMillis));
        
        // 发送到TTL队列，过期后会自动转发到目标队列
        rabbitTemplate.send(ttlQueueName, message);
    }
    
    /**
     * 序列化载荷
     */
    private byte[] serializePayload(Object payload) {
        try {
            // 这里可以使用Jackson或其他序列化方式
            if (payload instanceof String) {
                return ((String) payload).getBytes();
            } else if (payload instanceof byte[]) {
                return (byte[]) payload;
            } else {
                // 简单的toString序列化，实际应用中应使用JSON
                return payload.toString().getBytes();
            }
        } catch (Exception e) {
            log.error("序列化载荷失败: {}", e.getMessage());
            return new byte[0];
        }
    }
    
    /**
     * 清除重试计数器
     */
    public Mono<Void> clearRetryCount(String requestId) {
        retryCounters.remove(requestId);
        log.debug("清除重试计数器: requestId={}", requestId);
        return Mono.empty();
    }
    
    /**
     * 获取当前重试次数
     */
    public int getCurrentRetryCount(String requestId) {
        AtomicInteger counter = retryCounters.get(requestId);
        return counter != null ? counter.get() : 0;
    }
    
    /**
     * 计算下次重试时间
     */
    public long calculateNextRetryTime(ProviderRateLimitConfig config, String errorType, int currentAttempt) {
        RetryStrategyEnum strategy = config.getRetryStrategy().adjustForErrorType(errorType);
        long delay = strategy.calculateDelay(currentAttempt + 1);
        return System.currentTimeMillis() + delay;
    }
    
    /**
     * 检查是否应该重试
     */
    public boolean shouldRetry(ProviderRateLimitConfig config, String errorType, String requestId) {
        int currentAttempt = getCurrentRetryCount(requestId);
        RetryStrategyEnum strategy = config.getRetryStrategy().adjustForErrorType(errorType);
        
        boolean shouldRetry = currentAttempt < strategy.getMaxRetryAttempts();
        
        log.debug("重试检查: requestId={}, attempt={}, max={}, errorType={}, shouldRetry={}", 
                requestId, currentAttempt, strategy.getMaxRetryAttempts(), errorType, shouldRetry);
        
        return shouldRetry;
    }
    
    /**
     * 获取重试统计信息
     */
    public RetryStatistics getRetryStatistics() {
        int totalRetryTasks = retryCounters.size();
        int totalRetryAttempts = retryCounters.values().stream()
                .mapToInt(AtomicInteger::get)
                .sum();
        
        return RetryStatistics.builder()
                .totalRetryTasks(totalRetryTasks)
                .totalRetryAttempts(totalRetryAttempts)
                .averageRetriesPerTask(totalRetryTasks > 0 ? (double) totalRetryAttempts / totalRetryTasks : 0)
                .build();
    }
    
    /**
     * 重试统计信息
     */
    @lombok.Builder
    @lombok.Data
    public static class RetryStatistics {
        private final int totalRetryTasks;
        private final int totalRetryAttempts;
        private final double averageRetriesPerTask;
    }
} 