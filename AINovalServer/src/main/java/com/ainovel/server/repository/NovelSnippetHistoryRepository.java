package com.ainovel.server.repository;

import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.NovelSnippetHistory;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 小说片段历史记录仓库接口
 */
@Repository
public interface NovelSnippetHistoryRepository extends ReactiveMongoRepository<NovelSnippetHistory, String> {

    /**
     * 根据片段ID查找历史记录（按时间倒序）
     */
    @Query("{ 'snippetId': ?0 }")
    Flux<NovelSnippetHistory> findBySnippetIdOrderByCreatedAtDesc(String snippetId, Pageable pageable);

    /**
     * 根据片段ID和版本号查找历史记录
     */
    Mono<NovelSnippetHistory> findBySnippetIdAndVersion(String snippetId, Integer version);

    /**
     * 根据片段ID和用户ID查找历史记录（权限验证）
     */
    @Query("{ 'snippetId': ?0, 'userId': ?1 }")
    Flux<NovelSnippetHistory> findBySnippetIdAndUserId(String snippetId, String userId, Pageable pageable);

    /**
     * 统计片段的历史记录数量
     */
    @Query(value = "{ 'snippetId': ?0 }", count = true)
    Mono<Long> countBySnippetId(String snippetId);

    /**
     * 删除片段的所有历史记录
     */
    Mono<Void> deleteBySnippetId(String snippetId);

    /**
     * 根据用户ID删除所有历史记录
     */
    Mono<Void> deleteByUserId(String userId);
} 