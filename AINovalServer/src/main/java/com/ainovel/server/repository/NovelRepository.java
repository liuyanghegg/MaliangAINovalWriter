package com.ainovel.server.repository;

import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.Novel;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;

/**
 * 小说仓库接口
 */
@Repository
public interface NovelRepository extends ReactiveMongoRepository<Novel, String> {
    
    /**
     * 根据作者ID查找小说
     * @param authorId 作者ID
     * @return 小说列表
     */
    Flux<Novel> findByAuthorId(String authorId);

    /**
     * 根据作者ID查找已就绪的小说
     */
    Flux<Novel> findByAuthorIdAndIsReadyTrue(String authorId);
    
    /**
     * 根据标题模糊查询小说
     * @param title 标题关键词
     * @return 小说列表
     */
    Flux<Novel> findByTitleContaining(String title);
    
    /**
     * 统计指定时间范围内创建的小说数量
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 小说数量
     */
    Mono<Long> countByCreatedAtBetween(LocalDateTime startTime, LocalDateTime endTime);
    
    /**
     * 统计指定时间之后创建的小说数量
     * @param createdAfter 创建时间之后
     * @return 小说数量
     */
    Mono<Long> countByCreatedAtAfter(LocalDateTime createdAfter);
    
    /**
     * 查找最近创建的小说
     * @return 小说列表
     */
    Flux<Novel> findTop10ByOrderByCreatedAtDesc();

    /**
     * 统计作者的小说数量
     */
    Mono<Long> countByAuthorId(String authorId);
} 