package com.ainovel.server.repository;

import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.SystemConfig;
import com.ainovel.server.domain.model.SystemConfig.ConfigType;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 系统配置数据访问层
 */
@Repository
public interface SystemConfigRepository extends ReactiveMongoRepository<SystemConfig, String> {
    
    /**
     * 根据配置键查找配置
     * 
     * @param configKey 配置键
     * @return 系统配置
     */
    Mono<SystemConfig> findByConfigKey(String configKey);
    
    /**
     * 查找所有启用的配置
     * 
     * @return 启用的配置列表
     */
    Flux<SystemConfig> findByEnabledTrue();
    
    /**
     * 根据配置分组查找配置
     * 
     * @param configGroup 配置分组
     * @return 配置列表
     */
    Flux<SystemConfig> findByConfigGroup(String configGroup);
    
    /**
     * 根据配置类型查找配置
     * 
     * @param configType 配置类型
     * @return 配置列表
     */
    Flux<SystemConfig> findByConfigType(ConfigType configType);
    
    /**
     * 查找所有非只读的配置
     * 
     * @return 非只读配置列表
     */
    Flux<SystemConfig> findByReadOnlyFalse();
    
    /**
     * 根据配置分组查找启用的配置
     * 
     * @param configGroup 配置分组
     * @return 启用的配置列表
     */
    Flux<SystemConfig> findByConfigGroupAndEnabledTrue(String configGroup);
    
    /**
     * 检查配置键是否存在
     * 
     * @param configKey 配置键
     * @return 是否存在
     */
    Mono<Boolean> existsByConfigKey(String configKey);
    
    /**
     * 根据配置键删除配置
     * 
     * @param configKey 配置键
     * @return 删除结果
     */
    Mono<Void> deleteByConfigKey(String configKey);
}