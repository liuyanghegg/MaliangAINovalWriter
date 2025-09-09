package com.ainovel.server.repository;

import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;

import com.ainovel.server.domain.model.AIChatSession;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface AIChatSessionRepository extends ReactiveMongoRepository<AIChatSession, String> {

    Mono<AIChatSession> findByUserIdAndSessionId(String userId, String sessionId);

    Flux<AIChatSession> findByUserId(String userId, Pageable pageable);

    Mono<Void> deleteByUserIdAndSessionId(String userId, String sessionId);

    Mono<Long> countByUserId(String userId);

    /**
     * 根据用户ID、小说ID和会话ID查找会话
     */
    Mono<AIChatSession> findByUserIdAndNovelIdAndSessionId(String userId, String novelId, String sessionId);

    /**
     * 根据用户ID和小说ID查找会话列表
     */
    Flux<AIChatSession> findByUserIdAndNovelId(String userId, String novelId, Pageable pageable);

    /**
     * 根据用户ID、小说ID删除会话
     */
    Mono<Void> deleteByUserIdAndNovelIdAndSessionId(String userId, String novelId, String sessionId);

    /**
     * 根据用户ID和小说ID统计会话数量
     */
    Mono<Long> countByUserIdAndNovelId(String userId, String novelId);
}
