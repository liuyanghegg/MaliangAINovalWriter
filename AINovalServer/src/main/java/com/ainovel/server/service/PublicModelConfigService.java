package com.ainovel.server.service;

import java.util.List;

import com.ainovel.server.controller.AdminModelConfigController.CreditRateUpdate;
import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.PublicModelConfig;
import com.ainovel.server.dto.PublicModelConfigDetailsDTO;
import com.ainovel.server.web.dto.response.PublicModelResponseDto;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 公共模型配置服务接口
 */
public interface PublicModelConfigService {
    
    /**
     * 创建公共模型配置
     * 
     * @param config 配置信息
     * @return 创建的配置
     */
    Mono<PublicModelConfig> createConfig(PublicModelConfig config);
    
    /**
     * 更新公共模型配置
     * 
     * @param id 配置ID
     * @param config 配置信息
     * @return 更新的配置
     */
    Mono<PublicModelConfig> updateConfig(String id, PublicModelConfig config);
    
    /**
     * 删除公共模型配置
     * 
     * @param id 配置ID
     * @return 删除结果
     */
    Mono<Void> deleteConfig(String id);
    
    /**
     * 根据ID查找配置
     * 
     * @param id 配置ID
     * @return 配置信息
     */
    Mono<PublicModelConfig> findById(String id);
    
    /**
     * 查找所有配置
     * 
     * @return 配置列表
     */
    Flux<PublicModelConfig> findAll();
    
    /**
     * 查找所有启用的配置
     * 
     * @return 启用的配置列表
     */
    Flux<PublicModelConfig> findAllEnabled();

    /**
     * [新增] 获取公共模型列表 (前端安全接口)
     * 只包含向前端暴露的安全信息，不含API Keys等敏感数据
     * 
     * @return 公共模型响应DTO列表
     */
    Flux<PublicModelResponseDto> getPublicModels();
    
    /**
     * 根据提供商和模型ID查找配置
     * 
     * @param provider 提供商
     * @param modelId 模型ID
     * @return 配置信息
     */
    Mono<PublicModelConfig> findByProviderAndModelId(String provider, String modelId);
    
    /**
     * 根据AI功能类型查找支持的配置
     * 
     * @param featureType AI功能类型
     * @return 支持的配置列表
     */
    Flux<PublicModelConfig> findByFeatureType(AIFeatureType featureType);
    
    /**
     * 切换配置状态
     * 
     * @param id 配置ID
     * @param enabled 是否启用
     * @return 更新的配置
     */
    Mono<PublicModelConfig> toggleStatus(String id, boolean enabled);
    
    /**
     * 为配置添加支持的功能
     * 
     * @param id 配置ID
     * @param featureType 功能类型
     * @return 更新的配置
     */
    Mono<PublicModelConfig> addEnabledFeature(String id, AIFeatureType featureType);
    
    /**
     * 从配置移除支持的功能
     * 
     * @param id 配置ID
     * @param featureType 功能类型
     * @return 更新的配置
     */
    Mono<PublicModelConfig> removeEnabledFeature(String id, AIFeatureType featureType);
    
    /**
     * 批量更新积分汇率
     * 
     * @param updates 更新列表
     * @return 更新的配置列表
     */
    Flux<PublicModelConfig> batchUpdateCreditRates(List<CreditRateUpdate> updates);
    
    /**
     * 检查配置是否存在
     * 
     * @param provider 提供商
     * @param modelId 模型ID
     * @return 是否存在
     */
    Mono<Boolean> existsByProviderAndModelId(String provider, String modelId);
    
    /**
     * 验证指定配置的所有API Key
     * 
     * @param configId 配置ID
     * @return 验证后的配置
     */
    Mono<PublicModelConfig> validateConfig(String configId);
    
    /**
     * 获取一个可用的解密后的API Key
     * 
     * @param provider 提供商
     * @param modelId 模型ID
     * @return 解密后的API Key
     */
    Mono<String> getActiveDecryptedApiKey(String provider, String modelId);
    
    /**
     * 为配置添加API Key
     * 
     * @param configId 配置ID
     * @param apiKey API Key
     * @param note 备注
     * @return 更新后的配置
     */
    Mono<PublicModelConfig> addApiKey(String configId, String apiKey, String note);
    
    /**
     * 从配置移除API Key
     * 
     * @param configId 配置ID
     * @param apiKeyId API Key ID
     * @return 更新后的配置
     */
    Mono<PublicModelConfig> removeApiKey(String configId, String apiKeyId);
    
    /**
     * 获取配置详细信息
     * 
     * @param configId 配置ID
     * @return 配置详细信息
     */
    Mono<PublicModelConfigDetailsDTO> getConfigDetails(String configId);

    /**
     * 获取所有配置的详细信息
     * 
     * @return 配置详细信息列表
     */
    Flux<PublicModelConfigDetailsDTO> findAllWithDetails();
}