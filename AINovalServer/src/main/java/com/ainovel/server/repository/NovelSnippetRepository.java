package com.ainovel.server.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.NovelSnippet;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 小说片段仓库接口
 */
@Repository
public interface NovelSnippetRepository extends ReactiveMongoRepository<NovelSnippet, String> {

    /**
     * 根据用户ID和小说ID查找片段（支持分页）
     */
    @Query("{ 'userId': ?0, 'novelId': ?1, 'status': 'ACTIVE' }")
    Flux<NovelSnippet> findByUserIdAndNovelIdAndStatusActive(String userId, String novelId, Pageable pageable);

    /**
     * 根据ID和用户ID查找片段（权限验证）
     */
    Mono<NovelSnippet> findByIdAndUserId(String id, String userId);

    /**
     * 根据用户ID查找收藏的片段
     */
    @Query("{ 'userId': ?0, 'isFavorite': true, 'status': 'ACTIVE' }")
    Flux<NovelSnippet> findFavoritesByUserId(String userId, Pageable pageable);

    /**
     * 根据用户ID和分类查找片段
     */
    @Query("{ 'userId': ?0, 'category': ?1, 'status': 'ACTIVE' }")
    Flux<NovelSnippet> findByUserIdAndCategory(String userId, String category, Pageable pageable);

    /**
     * 根据用户ID和标签查找片段
     */
    @Query("{ 'userId': ?0, 'tags': { $in: ?1 }, 'status': 'ACTIVE' }")
    Flux<NovelSnippet> findByUserIdAndTagsIn(String userId, List<String> tags, Pageable pageable);

    /**
     * 全文搜索片段
     */
    @Query("{ 'userId': ?0, 'novelId': ?1, '$text': { '$search': ?2 }, 'status': 'ACTIVE' }")
    Flux<NovelSnippet> findByUserIdAndNovelIdAndFullTextSearch(String userId, String novelId, String searchText, Pageable pageable);

    /**
     * 根据时间范围查找片段
     */
    @Query("{ 'userId': ?0, 'novelId': ?1, 'createdAt': { '$gte': ?2, '$lte': ?3 }, 'status': 'ACTIVE' }")
    Flux<NovelSnippet> findByUserIdAndNovelIdAndCreatedAtBetween(String userId, String novelId, LocalDateTime startTime, LocalDateTime endTime, Pageable pageable);

    /**
     * 统计用户在特定小说中的片段数量
     */
    @Query(value = "{ 'userId': ?0, 'novelId': ?1, 'status': 'ACTIVE' }", count = true)
    Mono<Long> countByUserIdAndNovelIdAndStatusActive(String userId, String novelId);

    /**
     * 统计用户收藏片段数量
     */
    @Query(value = "{ 'userId': ?0, 'isFavorite': true, 'status': 'ACTIVE' }", count = true)
    Mono<Long> countFavoritesByUserId(String userId);

    /**
     * 删除用户在特定小说中的所有片段
     */
    @Query("{ 'userId': ?0, 'novelId': ?1 }")
    Mono<Void> deleteByUserIdAndNovelId(String userId, String novelId);

    /**
     * 根据小说ID删除所有相关片段
     */
    Mono<Void> deleteByNovelId(String novelId);

    /**
     * 查找用户的最新片段
     */
    @Query("{ 'userId': ?0, 'novelId': ?1, 'status': 'ACTIVE' }")
    Flux<NovelSnippet> findLatestByUserIdAndNovelId(String userId, String novelId, Pageable pageable);
} 