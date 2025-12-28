package com.ainovel.server.service;

import java.util.Map;

import com.ainovel.server.domain.model.SystemConfig;
import com.ainovel.server.domain.model.SystemConfig.ConfigType;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 系统配置服务接口
 */
public interface SystemConfigService {
    
    /**
     * 创建系统配置
     * 
     * @param config 配置信息
     * @return 创建的配置
     */
    Mono<SystemConfig> createConfig(SystemConfig config);
    
    /**
     * 更新系统配置
     * 
     * @param id 配置ID
     * @param config 配置信息
     * @return 更新的配置
     */
    Mono<SystemConfig> updateConfig(String id, SystemConfig config);
    
    /**
     * 删除系统配置
     * 
     * @param id 配置ID
     * @return 删除结果
     */
    Mono<Void> deleteConfig(String id);
    
    /**
     * 根据配置键获取配置
     * 
     * @param configKey 配置键
     * @return 配置信息
     */
    Mono<SystemConfig> getConfig(String configKey);
    
    /**
     * 根据配置键获取配置值
     * 
     * @param configKey 配置键
     * @return 配置值
     */
    Mono<String> getConfigValue(String configKey);
    
    /**
     * 根据配置键获取字符串值
     * 
     * @param configKey 配置键
     * @param defaultValue 默认值
     * @return 字符串值
     */
    Mono<String> getStringValue(String configKey, String defaultValue);
    
    /**
     * 根据配置键获取数值
     * 
     * @param configKey 配置键
     * @param defaultValue 默认值
     * @return 数值
     */
    Mono<Double> getNumericValue(String configKey, Double defaultValue);
    
    /**
     * 根据配置键获取整数值
     * 
     * @param configKey 配置键
     * @param defaultValue 默认值
     * @return 整数值
     */
    Mono<Integer> getIntegerValue(String configKey, Integer defaultValue);
    
    /**
     * 根据配置键获取长整数值
     * 
     * @param configKey 配置键
     * @param defaultValue 默认值
     * @return 长整数值
     */
    Mono<Long> getLongValue(String configKey, Long defaultValue);
    
    /**
     * 根据配置键获取布尔值
     * 
     * @param configKey 配置键
     * @param defaultValue 默认值
     * @return 布尔值
     */
    Mono<Boolean> getBooleanValue(String configKey, Boolean defaultValue);
    
    /**
     * 设置配置值
     * 
     * @param configKey 配置键
     * @param value 配置值
     * @return 设置结果
     */
    Mono<Boolean> setConfigValue(String configKey, String value);
    
    /**
     * 批量设置配置值
     * 
     * @param configs 配置键值对
     * @return 设置结果
     */
    Mono<Boolean> setConfigValues(Map<String, String> configs);
    
    /**
     * 查找所有配置
     * 
     * @return 配置列表
     */
    Flux<SystemConfig> findAll();
    
    /**
     * 根据配置分组查找配置
     * 
     * @param configGroup 配置分组
     * @return 配置列表
     */
    Flux<SystemConfig> findByGroup(String configGroup);
    
    /**
     * 根据配置类型查找配置
     * 
     * @param configType 配置类型
     * @return 配置列表
     */
    Flux<SystemConfig> findByType(ConfigType configType);
    
    /**
     * 查找所有启用的配置
     * 
     * @return 启用的配置列表
     */
    Flux<SystemConfig> findAllEnabled();
    
    /**
     * 查找所有非只读的配置
     * 
     * @return 非只读配置列表
     */
    Flux<SystemConfig> findAllNonReadOnly();
    
    /**
     * 初始化默认配置
     * 
     * @return 初始化结果
     */
    Mono<Boolean> initializeDefaultConfigs();
    
    /**
     * 检查配置键是否存在
     * 
     * @param configKey 配置键
     * @return 是否存在
     */
    Mono<Boolean> existsByConfigKey(String configKey);
    
    /**
     * 验证配置值是否有效
     * 
     * @param configKey 配置键
     * @param value 配置值
     * @return 是否有效
     */
    Mono<Boolean> validateConfigValue(String configKey, String value);
}