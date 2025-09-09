package com.ainovel.server.service.prompt;

import java.util.Map;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.ainovel.server.service.prompt.impl.ContentProviderPlaceholderResolver;

import lombok.extern.slf4j.Slf4j;

/**
 * 占位符描述服务
 * 提供统一的占位符描述和过滤功能
 */
@Slf4j
@Service
public class PlaceholderDescriptionService {

    @Autowired
    private ContentProviderPlaceholderResolver contentProviderPlaceholderResolver;

    /**
     * 获取占位符描述映射
     */
    public Map<String, String> getPlaceholderDescriptions(Set<String> placeholders) {
        Map<String, String> descriptions = new java.util.HashMap<>();
        
        for (String placeholder : placeholders) {
            String description = contentProviderPlaceholderResolver.getPlaceholderDescription(placeholder);
            descriptions.put(placeholder, description);
        }
        
        return descriptions;
    }

    /**
     * 获取实际可用的占位符集合
     */
    public Set<String> getAvailablePlaceholders() {
        return contentProviderPlaceholderResolver.getAvailablePlaceholders();
    }

    /**
     * 过滤占位符集合，只保留实际可用的
     */
    public Set<String> filterAvailablePlaceholders(Set<String> requestedPlaceholders) {
        Set<String> availablePlaceholders = getAvailablePlaceholders();
        Set<String> filteredPlaceholders = new java.util.HashSet<>(requestedPlaceholders);
        filteredPlaceholders.retainAll(availablePlaceholders);
        
        log.debug("占位符过滤结果: 请求={}, 可用={}, 过滤后={}", 
                 requestedPlaceholders.size(), availablePlaceholders.size(), filteredPlaceholders.size());
        
        return filteredPlaceholders;
    }
} 