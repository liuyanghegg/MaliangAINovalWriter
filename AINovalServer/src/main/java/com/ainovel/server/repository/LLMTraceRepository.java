package com.ainovel.server.repository;

import com.ainovel.server.domain.model.observability.LLMTrace;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Instant;

/**
 * LLM链路追踪数据访问层
 */
@Repository
public interface LLMTraceRepository extends ReactiveMongoRepository<LLMTrace, String> {

    /**
     * 根据用户ID查找追踪记录
     */
    Flux<LLMTrace> findByUserIdOrderByCreatedAtDesc(String userId, Pageable pageable);

    /**
     * 根据会话ID查找追踪记录
     */
    Flux<LLMTrace> findBySessionIdOrderByCreatedAtDesc(String sessionId);

    /**
     * 根据提供商和模型查找追踪记录
     */
    Flux<LLMTrace> findByProviderAndModelOrderByCreatedAtDesc(String provider, String model, Pageable pageable);

    /**
     * 查找指定时间范围内的追踪记录
     */
    @Query("{'createdAt': {$gte: ?0, $lte: ?1}}")
    Flux<LLMTrace> findByCreatedAtBetweenOrderByCreatedAtDesc(Instant start, Instant end, Pageable pageable);

    /**
     * 统计用户的调用次数
     */
    Mono<Long> countByUserId(String userId);

    /**
     * 统计错误调用次数
     */
    @Query(value = "{'error': {$ne: null}}", count = true)
    Mono<Long> countErrorTraces();

    /**
     * 根据完成原因统计
     */
    @Query(value = "{'response.metadata.finishReason': ?0}", count = true)
    Mono<Long> countByFinishReason(String finishReason);

    /**
     * 查找性能较差的调用（耗时超过阈值）
     */
    @Query("{'performance.totalDurationMs': {$gt: ?0}}")
    Flux<LLMTrace> findSlowTraces(Long thresholdMs, Pageable pageable);

    /**
     * 根据关联ID查找相关的所有调用
     */
    Flux<LLMTrace> findByCorrelationIdOrderByCreatedAtAsc(String correlationId);

    /**
     * 查找所有追踪记录（分页，按创建时间倒序）
     */
    Flux<LLMTrace> findAllByOrderByCreatedAtDesc(Pageable pageable);

    /**
     * 根据提供商查找追踪记录（分页，按创建时间倒序）
     */
    Flux<LLMTrace> findByProviderOrderByCreatedAtDesc(String provider, Pageable pageable);

    /**
     * 根据模型查找追踪记录（分页，按创建时间倒序）
     */
    Flux<LLMTrace> findByModelOrderByCreatedAtDesc(String model, Pageable pageable);

    /**
     * 根据traceId查找追踪记录
     */
    Mono<LLMTrace> findByTraceId(String traceId);

    /**
     * 幂等支持：根据 traceId 查找第一条记录
     */
    Mono<LLMTrace> findFirstByTraceId(String traceId);

    /**
     * 删除指定时间之前的记录
     */
    @Query(value = "{'createdAt': {$lt: ?0}}", delete = true)
    Mono<Long> deleteByCreatedAtBefore(Instant before);
    
    // ==================== 管理后台分页支持方法 ====================
    
    /**
     * 统计根据提供商的记录数
     */
    Mono<Long> countByProvider(String provider);
    
    /**
     * 统计根据模型的记录数
     */
    Mono<Long> countByModel(String model);
    
    /**
     * 统计时间范围内的记录数
     */
    @Query(value = "{'createdAt': {$gte: ?0, $lte: ?1}}", count = true)
    Mono<Long> countByCreatedAtBetween(Instant start, Instant end);
    
    /**
     * 统计会话ID的记录数
     */
    Mono<Long> countBySessionId(String sessionId);
    
    /**
     * 统计有错误的记录数（根据用户ID）
     */
    @Query(value = "{'userId': ?0, 'error': {$ne: null}}", count = true)
    Mono<Long> countByUserIdAndErrorIsNotNull(String userId);
    
    /**
     * 统计无错误的记录数（根据用户ID）
     */
    @Query(value = "{'userId': ?0, 'error': {$eq: null}}", count = true)
    Mono<Long> countByUserIdAndErrorIsNull(String userId);
} 