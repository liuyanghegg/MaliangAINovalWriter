package com.ainovel.server.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.core.mapping.MongoMappingContext;
import org.springframework.data.mapping.model.PropertyNameFieldNamingStrategy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * MongoDB映射配置类
 * 专门处理复杂嵌套对象的映射问题，特别是LLMTrace类
 */
@Configuration
public class MongoMappingConfig {
    
    private static final Logger logger = LoggerFactory.getLogger(MongoMappingConfig.class);
    
    /**
     * 自定义MongoDB映射上下文
     * 解决复杂嵌套对象的构造函数参数名称问题
     */
    @Bean
    public MongoMappingContext mongoMappingContext() {
        MongoMappingContext mappingContext = new MongoMappingContext();
        
        // 设置字段命名策略
        mappingContext.setFieldNamingStrategy(PropertyNameFieldNamingStrategy.INSTANCE);
        
        // 启用自动索引创建
        mappingContext.setAutoIndexCreation(true);
        
        logger.info("MongoDB映射上下文配置完成，支持复杂嵌套对象映射");
        
        return mappingContext;
    }
    

}