package com.ainovel.server.config;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.convert.converter.Converter;
import org.springframework.data.convert.ReadingConverter;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

/**
 * 安全的Map转换器，处理可能的类型不匹配问题
 * 特别是当数据库中存储的是JSON字符串，但需要映射为Map<String, Object>时
 */
@Component
@ReadingConverter
public class SafeMapConverter implements Converter<Object, Map<String, Object>> {
    
    private static final Logger logger = LoggerFactory.getLogger(SafeMapConverter.class);
    private final ObjectMapper objectMapper;
    
    public SafeMapConverter(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }
    
    @Override
    public Map<String, Object> convert(Object source) {
        if (source == null) {
            return new HashMap<>();
        }
        
        // 如果已经是Map，直接返回
        if (source instanceof Map) {
            try {
                @SuppressWarnings("unchecked")
                Map<String, Object> result = (Map<String, Object>) source;
                return result;
            } catch (ClassCastException e) {
                logger.warn("Map类型转换失败，尝试重新构建: {}", e.getMessage());
                // 如果类型转换失败，尝试重新构建
                try {
                    Map<?, ?> rawMap = (Map<?, ?>) source;
                    Map<String, Object> result = new HashMap<>();
                    rawMap.forEach((key, value) -> {
                        String stringKey = key != null ? key.toString() : null;
                        result.put(stringKey, value);
                    });
                    return result;
                } catch (Exception ex) {
                    logger.error("Map重构失败: {}", ex.getMessage());
                    return new HashMap<>();
                }
            }
        }
        
        // 如果是字符串，尝试解析为JSON
        if (source instanceof String) {
            String jsonString = (String) source;
            if (jsonString.trim().isEmpty()) {
                return new HashMap<>();
            }
            
            try {
                // 尝试解析为Map
                TypeReference<Map<String, Object>> typeRef = new TypeReference<Map<String, Object>>() {};
                return objectMapper.readValue(jsonString, typeRef);
            } catch (Exception e) {
                logger.warn("无法将字符串解析为Map，返回包含原字符串的Map: {}", e.getMessage());
                // 如果解析失败，将字符串作为值存储
                Map<String, Object> result = new HashMap<>();
                result.put("value", jsonString);
                return result;
            }
        }
        
        // 对于其他类型，尝试使用ObjectMapper转换
        try {
            TypeReference<Map<String, Object>> typeRef = new TypeReference<Map<String, Object>>() {};
            return objectMapper.convertValue(source, typeRef);
        } catch (Exception e) {
            logger.warn("无法转换对象为Map: {} -> {}", source.getClass().getSimpleName(), e.getMessage());
            // 如果所有转换都失败，返回一个包含原始值的Map
            Map<String, Object> result = new HashMap<>();
            result.put("originalValue", source);
            result.put("originalType", source.getClass().getSimpleName());
            return result;
        }
    }
}