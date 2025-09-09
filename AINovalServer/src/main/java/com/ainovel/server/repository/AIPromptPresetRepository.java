package com.ainovel.server.repository;

import com.ainovel.server.domain.model.AIPromptPreset;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.List;

/**
 * AI提示词预设数据访问接口
 */
@Repository
public interface AIPromptPresetRepository extends ReactiveMongoRepository<AIPromptPreset, String> {

    /**
     * 根据预设ID查找
     */
    Mono<AIPromptPreset> findByPresetId(String presetId);

    /**
     * 根据用户ID和哈希查找（用于查重）
     */
    Mono<AIPromptPreset> findByUserIdAndPresetHash(String userId, String presetHash);

    /**
     * 根据用户ID查找所有预设
     */
    Flux<AIPromptPreset> findByUserId(String userId);

    /**
     * 根据用户ID和功能类型查找
     */
    Flux<AIPromptPreset> findByUserIdAndAiFeatureType(String userId, String aiFeatureType);

    /**
     * 删除用户的所有预设
     */
    Mono<Void> deleteByUserId(String userId);

    /**
     * 根据预设ID删除
     */
    Mono<Void> deleteByPresetId(String presetId);

    /**
     * 根据用户ID查找所有预设，按最后使用时间倒序
     */
    Flux<AIPromptPreset> findByUserIdOrderByLastUsedAtDesc(String userId);

    /**
     * 根据用户ID查找所有预设，按创建时间倒序
     */
    Flux<AIPromptPreset> findByUserIdOrderByCreatedAtDesc(String userId);

    /**
     * 根据用户ID查找收藏的预设
     */
    Flux<AIPromptPreset> findByUserIdAndIsFavoriteTrue(String userId);

    /**
     * 根据用户ID和小说ID查找所有预设，按最后使用时间倒序
     * 包含全局预设（novelId为null）
     */
    @Query("{ 'userId': ?0, $or: [ { 'novelId': ?1 }, { 'novelId': null } ] }")
    Flux<AIPromptPreset> findByUserIdAndNovelIdOrderByLastUsedAtDesc(String userId, String novelId);

    /**
     * 根据用户ID、小说ID和功能类型查找预设
     * 包含全局预设（novelId为null）
     */
    @Query("{ 'userId': ?0, 'aiFeatureType': ?1, $or: [ { 'novelId': ?2 }, { 'novelId': null } ] }")
    Flux<AIPromptPreset> findByUserIdAndAiFeatureTypeAndNovelId(String userId, String aiFeatureType, String novelId);

    /**
     * 根据用户ID和小说ID查找收藏的预设
     * 包含全局预设（novelId为null）
     */
    @Query("{ 'userId': ?0, 'isFavorite': true, $or: [ { 'novelId': ?1 }, { 'novelId': null } ] }")
    Flux<AIPromptPreset> findByUserIdAndIsFavoriteTrueAndNovelId(String userId, String novelId);

    /**
     * 根据用户ID和预设名称查找（模糊搜索）
     */
    @Query("{ 'userId': ?0, 'presetName': { $regex: ?1, $options: 'i' } }")
    Flux<AIPromptPreset> findByUserIdAndPresetNameContainingIgnoreCase(String userId, String presetName);

    /**
     * 根据用户ID和标签查找
     */
    Flux<AIPromptPreset> findByUserIdAndPresetTagsIn(String userId, List<String> tags);

    /**
     * 复合搜索：根据用户ID、关键词（名称或描述）、标签、功能类型查找
     */
    @Query("{ " +
           "'userId': ?0, " +
           "$and: [" +
           "  { $or: [ " +
           "    { 'presetName': { $regex: ?1, $options: 'i' } }, " +
           "    { 'presetDescription': { $regex: ?1, $options: 'i' } } " +
           "  ] }, " +
           "  { $or: [ " +
           "    { $expr: { $eq: [?2, null] } }, " +
           "    { 'presetTags': { $in: ?2 } } " +
           "  ] }, " +
           "  { $or: [ " +
           "    { $expr: { $eq: [?3, null] } }, " +
           "    { 'aiFeatureType': ?3 } " +
           "  ] } " +
           "] " +
           "}")
    Flux<AIPromptPreset> searchPresets(String userId, String keyword, List<String> tags, String featureType);

    /**
     * 根据小说ID复合搜索：根据用户ID、关键词（名称或描述）、标签、功能类型、小说ID查找
     * 包含全局预设（novelId为null）
     */
    @Query("{ " +
           "'userId': ?0, " +
           "$and: [" +
           "  { $or: [ " +
           "    { 'presetName': { $regex: ?1, $options: 'i' } }, " +
           "    { 'presetDescription': { $regex: ?1, $options: 'i' } } " +
           "  ] }, " +
           "  { $or: [ " +
           "    { $expr: { $eq: [?2, null] } }, " +
           "    { 'presetTags': { $in: ?2 } } " +
           "  ] }, " +
           "  { $or: [ " +
           "    { $expr: { $eq: [?3, null] } }, " +
           "    { 'aiFeatureType': ?3 } " +
           "  ] }, " +
           "  { $or: [ " +
           "    { 'novelId': ?4 }, " +
           "    { 'novelId': null } " +
           "  ] } " +
           "] " +
           "}")
    Flux<AIPromptPreset> searchPresetsByNovelId(String userId, String keyword, List<String> tags, String featureType, String novelId);

    /**
     * 获取用户最近使用的预设（最近30天）
     */
    @Query("{ 'userId': ?0, 'lastUsedAt': { $gte: ?1 } }")
    Flux<AIPromptPreset> findRecentlyUsedPresets(String userId, LocalDateTime since);

    /**
     * 统计用户预设数量
     */
    Mono<Long> countByUserId(String userId);

    /**
     * 统计用户收藏预设数量
     */
    Mono<Long> countByUserIdAndIsFavoriteTrue(String userId);

    /**
     * 根据小说ID统计用户预设数量（包含全局预设）
     */
    @Query(value = "{ 'userId': ?0, $or: [ { 'novelId': ?1 }, { 'novelId': null } ] }", count = true)
    Mono<Long> countByUserIdAndNovelId(String userId, String novelId);

    /**
     * 根据小说ID统计用户收藏预设数量（包含全局预设）
     */
    @Query(value = "{ 'userId': ?0, 'isFavorite': true, $or: [ { 'novelId': ?1 }, { 'novelId': null } ] }", count = true)
    Mono<Long> countByUserIdAndIsFavoriteTrueAndNovelId(String userId, String novelId);

    /**
     * 统计用户各功能类型的预设数量
     */
    @Query(value = "{ 'userId': ?0 }", count = true)
    Flux<Object> countByUserIdGroupByAiFeatureType(String userId);

    /**
     * 获取用户所有预设的标签（去重）
     */
    @Query("{ 'userId': ?0 }")
    Flux<String> findDistinctTagsByUserId(String userId);

    /**
     * 检查预设名称是否已存在（同一用户）
     */
    Mono<Boolean> existsByUserIdAndPresetName(String userId, String presetName);

    // ==================== 🚀 新增：系统预设和快捷访问相关查询 ====================

    /**
     * 获取所有系统预设
     */
    Flux<AIPromptPreset> findByIsSystemTrue();

    /**
     * 根据功能类型获取系统预设
     */
    Flux<AIPromptPreset> findByIsSystemTrueAndAiFeatureType(String aiFeatureType);

    /**
     * 获取所有快捷访问预设（包括用户和系统）
     */
    Flux<AIPromptPreset> findByShowInQuickAccessTrue();

    /**
     * 根据功能类型获取快捷访问预设
     */
    Flux<AIPromptPreset> findByShowInQuickAccessTrueAndAiFeatureType(String aiFeatureType);

    /**
     * 获取系统预设中显示在快捷访问的预设
     */
    Flux<AIPromptPreset> findByIsSystemTrueAndShowInQuickAccessTrue();

    /**
     * 获取用户的快捷访问预设
     */
    Flux<AIPromptPreset> findByUserIdAndShowInQuickAccessTrue(String userId);

    /**
     * 根据用户ID和功能类型获取快捷访问预设
     */
    Flux<AIPromptPreset> findByUserIdAndShowInQuickAccessTrueAndAiFeatureType(String userId, String aiFeatureType);

    /**
     * 联合查询：获取用户预设 + 系统预设（按功能类型）
     * 用于获取用户可见的所有预设
     */
    @Query("{ $or: [ { 'userId': ?0 }, { 'isSystem': true } ], 'aiFeatureType': ?1 }")
    Flux<AIPromptPreset> findUserAndSystemPresetsByFeatureType(String userId, String aiFeatureType);

    /**
     * 联合查询：获取用户快捷访问预设 + 系统快捷访问预设（按功能类型）
     */
    @Query("{ $or: [ { 'userId': ?0, 'showInQuickAccess': true }, { 'isSystem': true, 'showInQuickAccess': true } ], 'aiFeatureType': ?1 }")
    Flux<AIPromptPreset> findQuickAccessPresetsByUserAndFeatureType(String userId, String aiFeatureType);

    /**
     * 根据模板ID查找使用该模板的预设
     */
    Flux<AIPromptPreset> findByTemplateId(String templateId);

    /**
     * 检查系统预设是否已存在（通过预设ID）
     */
    Mono<Boolean> existsByPresetIdAndIsSystemTrue(String presetId);

    /**
     * 批量获取多个功能类型的用户和系统预设
     */
    @Query("{ $or: [ { 'userId': ?0 }, { 'isSystem': true } ], 'aiFeatureType': { $in: ?1 } }")
    Flux<AIPromptPreset> findUserAndSystemPresetsByFeatureTypes(String userId, List<String> aiFeatureTypes);

    /**
     * 批量获取多个功能类型的快捷访问预设
     */
    @Query("{ $or: [ { 'userId': ?0, 'showInQuickAccess': true }, { 'isSystem': true, 'showInQuickAccess': true } ], 'aiFeatureType': { $in: ?1 } }")
    Flux<AIPromptPreset> findQuickAccessPresetsByUserAndFeatureTypes(String userId, List<String> aiFeatureTypes);
    
    /**
     * 根据预设ID列表查找预设
     * 
     * @param presetIds 预设ID列表
     * @return 预设列表
     */
    Flux<AIPromptPreset> findByPresetIdIn(List<String> presetIds);
} 