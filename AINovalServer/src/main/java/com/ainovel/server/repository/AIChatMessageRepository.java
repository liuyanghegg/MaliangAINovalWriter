package com.ainovel.server.repository;

import org.springframework.data.mongodb.repository.ReactiveMongoRepository;

import com.ainovel.server.domain.model.AIChatMessage;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;

public interface AIChatMessageRepository extends ReactiveMongoRepository<AIChatMessage, String> {

    Flux<AIChatMessage> findBySessionIdOrderByCreatedAtDesc(String sessionId, int limit);

    Mono<AIChatMessage> findByIdAndUserId(String id, String userId);

    Mono<Void> deleteByIdAndUserId(String id, String userId);

    Mono<Long> countBySessionId(String sessionId);

    Mono<Void> deleteBySessionId(String sessionId);

    /**
     * 统计指定时间范围内的消息数量
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 消息数量
     */
    Mono<Long> countByCreatedAtBetween(LocalDateTime startTime, LocalDateTime endTime);

    /**
     * 统计指定时间之后的消息数量
     * @param createdAfter 创建时间之后
     * @return 消息数量
     */
    Mono<Long> countByCreatedAtAfter(LocalDateTime createdAfter);

    /**
     * 查找最近的消息用于活动统计
     * @param limit 数量限制
     * @return 消息列表
     */
    Flux<AIChatMessage> findTop20ByOrderByCreatedAtDesc();
}
