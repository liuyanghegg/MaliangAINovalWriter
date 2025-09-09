package com.ainovel.server.repository;

import java.util.List;

import org.springframework.data.mongodb.repository.Query;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.EnhancedUserPromptTemplate;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 增强用户提示词模板Repository
 */
@Repository
public interface EnhancedUserPromptTemplateRepository extends ReactiveMongoRepository<EnhancedUserPromptTemplate, String> {

    /**
     * 根据用户ID查找模板
     */
    Flux<EnhancedUserPromptTemplate> findByUserId(String userId);

    /**
     * 根据用户ID和功能类型查找模板
     */
    Flux<EnhancedUserPromptTemplate> findByUserIdAndFeatureType(String userId, AIFeatureType featureType);

    /**
     * 根据用户ID和功能类型查找默认模板
     */
    Mono<EnhancedUserPromptTemplate> findByUserIdAndFeatureTypeAndIsDefaultTrue(String userId, AIFeatureType featureType);

    /**
     * 根据用户ID和功能类型查找所有默认模板（用于清除默认状态）
     */
    Flux<EnhancedUserPromptTemplate> findAllByUserIdAndFeatureTypeAndIsDefaultTrue(String userId, AIFeatureType featureType);

    /**
     * 根据用户ID查找收藏的模板
     */
    Flux<EnhancedUserPromptTemplate> findByUserIdAndIsFavoriteTrue(String userId);

    /**
     * 根据分享码查找模板
     */
    Mono<EnhancedUserPromptTemplate> findByShareCode(String shareCode);

    /**
     * 查找公开模板
     */
    @Query("{ 'isPublic': true, 'featureType': ?0 }")
    Flux<EnhancedUserPromptTemplate> findPublicTemplatesByFeatureType(AIFeatureType featureType);

    /**
     * 查找所有公开模板
     */
    Flux<EnhancedUserPromptTemplate> findByIsPublicTrue();

    /**
     * 根据标签搜索用户模板
     */
    @Query("{ 'userId': ?0, 'tags': { '$in': ?1 } }")
    Flux<EnhancedUserPromptTemplate> findByUserIdAndTagsIn(String userId, List<String> tags);

    /**
     * 根据关键词搜索用户模板（名称和描述）
     */
    @Query("{ 'userId': ?0, '$or': [ " +
           "{ 'name': { '$regex': ?1, '$options': 'i' } }, " +
           "{ 'description': { '$regex': ?1, '$options': 'i' } } ] }")
    Flux<EnhancedUserPromptTemplate> findByUserIdAndKeyword(String userId, String keyword);

    /**
     * 获取最近使用的模板
     */
    @Query("{ 'userId': ?0, 'lastUsedAt': { '$ne': null } }")
    Flux<EnhancedUserPromptTemplate> findByUserIdOrderByLastUsedAtDesc(String userId);

    /**
     * 获取热门公开模板（按使用次数和评分排序）
     */
    @Query("{ 'isPublic': true, 'featureType': ?0 }")
    Flux<EnhancedUserPromptTemplate> findPopularPublicTemplatesByFeatureType(AIFeatureType featureType);

    /**
     * 删除用户的模板
     */
    Mono<Void> deleteByUserIdAndId(String userId, String id);

    /**
     * 统计用户模板数量
     */
    Mono<Long> countByUserId(String userId);

    /**
     * 统计用户指定功能类型的模板数量
     */
    Mono<Long> countByUserIdAndFeatureType(String userId, AIFeatureType featureType);

    /**
     * 统计用户公开模板数量
     */
    Mono<Long> countByUserIdAndIsPublicTrue(String userId);

    /**
     * 统计用户收藏模板数量
     */
    Mono<Long> countByUserIdAndIsFavoriteTrue(String userId);

    /**
     * 获取用户所有标签
     */
    @Query(value = "{ 'userId': ?0 }", fields = "{ 'tags': 1 }")
    Flux<EnhancedUserPromptTemplate> findTagsByUserId(String userId);

    /**
     * 根据名称或描述搜索所有模板（管理员用）
     */
    @Query("{ '$or': [ " +
           "{ 'name': { '$regex': ?0, '$options': 'i' } }, " +
           "{ 'description': { '$regex': ?1, '$options': 'i' } } ] }")
    Flux<EnhancedUserPromptTemplate> findByNameContainingIgnoreCaseOrDescriptionContainingIgnoreCase(String name, String description);

    /**
     * 根据ID和用户ID查找模板
     */
    Mono<EnhancedUserPromptTemplate> findByIdAndUserId(String id, String userId);

    /**
     * 根据功能类型查找公开模板
     */
    Flux<EnhancedUserPromptTemplate> findByFeatureTypeAndIsPublicTrue(AIFeatureType featureType);

    /**
     * 根据功能类型查找所有模板
     */
    Flux<EnhancedUserPromptTemplate> findByFeatureType(AIFeatureType featureType);
} 