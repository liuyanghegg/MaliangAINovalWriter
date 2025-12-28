package com.ainovel.server.repository;

import com.ainovel.server.domain.model.NovelSettingGenerationHistory;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 设定生成历史记录仓库接口
 */
@Repository
public interface NovelSettingGenerationHistoryRepository extends ReactiveMongoRepository<NovelSettingGenerationHistory, String> {

    /**
     * 根据小说ID和用户ID查找历史记录（按创建时间倒序）
     */
    Flux<NovelSettingGenerationHistory> findByNovelIdAndUserIdOrderByCreatedAtDesc(String novelId, String userId);

    /**
     * 根据小说ID和用户ID查找历史记录（支持分页）
     */
    Flux<NovelSettingGenerationHistory> findByNovelIdAndUserIdOrderByCreatedAtDesc(String novelId, String userId, Pageable pageable);

    /**
     * 根据用户ID查找所有历史记录（按创建时间倒序）
     */
    Flux<NovelSettingGenerationHistory> findByUserIdOrderByCreatedAtDesc(String userId);

    /**
     * 根据用户ID查找所有历史记录（支持分页，按创建时间倒序）
     */
    Flux<NovelSettingGenerationHistory> findByUserIdOrderByCreatedAtDesc(String userId, Pageable pageable);

    /**
     * 根据用户ID和小说ID查找历史记录（按创建时间倒序）
     * 参数顺序：用户ID在前，小说ID在后
     */
    Flux<NovelSettingGenerationHistory> findByUserIdAndNovelIdOrderByCreatedAtDesc(String userId, String novelId);

    /**
     * 根据用户ID和小说ID查找历史记录（支持分页，按创建时间倒序）
     * 参数顺序：用户ID在前，小说ID在后
     */
    Flux<NovelSettingGenerationHistory> findByUserIdAndNovelIdOrderByCreatedAtDesc(String userId, String novelId, Pageable pageable);

    /**
     * 根据原始会话ID查找历史记录
     */
    Mono<NovelSettingGenerationHistory> findByOriginalSessionId(String originalSessionId);

    /**
     * 根据源历史记录ID查找衍生的历史记录
     */
    Flux<NovelSettingGenerationHistory> findBySourceHistoryId(String sourceHistoryId);

    /**
     * 统计用户在指定小说下的历史记录数量
     */
    @Query(value = "{ 'novelId': ?0, 'userId': ?1 }", count = true)
    Mono<Long> countByNovelIdAndUserId(String novelId, String userId);

    /**
     * 统计用户和小说的历史记录数量
     * 参数顺序：用户ID在前，小说ID在后
     */
    @Query(value = "{ 'userId': ?0, 'novelId': ?1 }", count = true)
    Mono<Long> countByUserIdAndNovelId(String userId, String novelId);

    /**
     * 统计用户的历史记录数量
     */
    @Query(value = "{ 'userId': ?0 }", count = true)
    Mono<Long> countByUserId(String userId);

    /**
     * 删除指定小说的所有历史记录
     */
    Mono<Void> deleteByNovelIdAndUserId(String novelId, String userId);
} 