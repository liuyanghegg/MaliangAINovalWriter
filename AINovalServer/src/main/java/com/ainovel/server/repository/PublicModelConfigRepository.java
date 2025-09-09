package com.ainovel.server.repository;

import java.util.List;

import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.PublicModelConfig;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 公共模型配置数据访问层
 */
@Repository
public interface PublicModelConfigRepository extends ReactiveMongoRepository<PublicModelConfig, String> {
    
    /**
     * 根据提供商和模型ID查找配置
     * 
     * @param provider 提供商名称
     * @param modelId 模型ID
     * @return 公共模型配置
     */
    Mono<PublicModelConfig> findByProviderAndModelId(String provider, String modelId);
    
    /**
     * 查找所有启用的公共模型配置
     * 
     * @return 启用的公共模型配置列表
     */
    Flux<PublicModelConfig> findByEnabledTrue();
    
    /**
     * 根据提供商查找启用的公共模型配置
     * 
     * @param provider 提供商名称
     * @return 启用的公共模型配置列表
     */
    Flux<PublicModelConfig> findByProviderAndEnabledTrue(String provider);
    
    /**
     * 根据AI功能类型查找支持的公共模型配置
     * 
     * @param featureType AI功能类型
     * @return 支持该功能的公共模型配置列表
     */
    Flux<PublicModelConfig> findByEnabledTrueAndEnabledForFeaturesContaining(AIFeatureType featureType);
    
    /**
     * 根据提供商和AI功能类型查找支持的公共模型配置
     * 
     * @param provider 提供商名称
     * @param featureType AI功能类型
     * @return 支持该功能的公共模型配置列表
     */
    Flux<PublicModelConfig> findByProviderAndEnabledTrueAndEnabledForFeaturesContaining(String provider, AIFeatureType featureType);
    
    /**
     * 查找所有启用的公共模型配置，按优先级降序排列
     * 
     * @return 按优先级排序的启用公共模型配置列表
     */
    Flux<PublicModelConfig> findByEnabledTrueOrderByPriorityDesc();
    
    /**
     * 根据标签查找公共模型配置
     * 
     * @param tag 标签
     * @return 包含该标签的公共模型配置列表
     */
    Flux<PublicModelConfig> findByEnabledTrueAndTagsContaining(String tag);
    
    /**
     * 检查指定提供商和模型ID的配置是否存在
     * 
     * @param provider 提供商名称
     * @param modelId 模型ID
     * @return 是否存在
     */
    Mono<Boolean> existsByProviderAndModelId(String provider, String modelId);
    
    /**
     * 根据提供商列表查找启用的公共模型配置
     * 
     * @param providers 提供商名称列表
     * @return 启用的公共模型配置列表
     */
    Flux<PublicModelConfig> findByProviderInAndEnabledTrue(List<String> providers);
}