package com.ainovel.server.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.mongodb.ReactiveMongoDatabaseFactory;
import org.springframework.data.mongodb.core.convert.MongoCustomConversions;
import org.springframework.data.mongodb.core.convert.MappingMongoConverter;
import org.springframework.data.mongodb.core.convert.NoOpDbRefResolver;
import org.springframework.data.mongodb.core.mapping.MongoMappingContext;

@Configuration
public class ReactiveMongoConfig {

    private static final Logger logger = LoggerFactory.getLogger(ReactiveMongoConfig.class);
    private static final String DOT_REPLACEMENT = "#DOT#";

    @Bean
    @Primary  // 确保这个Bean优先级最高
    public MappingMongoConverter mappingMongoConverter(ReactiveMongoDatabaseFactory factory,
                                                       MongoMappingContext context,
                                                       MongoCustomConversions conversions) {
        logger.info("🔧 创建 MappingMongoConverter Bean...");
        
        NoOpDbRefResolver dbRefResolver = NoOpDbRefResolver.INSTANCE;
        MappingMongoConverter converter = new MappingMongoConverter(dbRefResolver, context);
        converter.setCustomConversions(conversions);
        converter.setCodecRegistryProvider(factory);
        
        // 强制设置点号替换，解决 "ai.daily.calls"、"import.daily.limit" 等带点号的Map key问题
        converter.setMapKeyDotReplacement(DOT_REPLACEMENT);
        
        logger.info("✅ MongoDB MappingMongoConverter 配置完成:");
        logger.info("   - 点号替换字符: '{}'", DOT_REPLACEMENT);
        logger.info("   - Bean优先级: @Primary");
        logger.info("   - 解决Map key包含点号的问题: ai.daily.calls, import.daily.limit 等");
        
        return converter;
    }
}


