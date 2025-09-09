package com.ainovel.server.service.impl.content;

import org.springframework.stereotype.Component;
import lombok.extern.slf4j.Slf4j;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * 内容提供器工厂
 * 管理所有内容提供器的注册和获取
 */
@Slf4j
@Component
public class ContentProviderFactory {
    
    private final Map<String, ContentProvider> contentProviders = new ConcurrentHashMap<>();
    
    /**
     * 注册内容提供器
     */
    public void registerProvider(String type, ContentProvider provider) {
        contentProviders.put(type.toLowerCase(), provider);
        log.info("注册内容提供器: {}", type);
    }
    
    /**
     * 获取内容提供器
     */
    public Optional<ContentProvider> getProvider(String type) {
        return Optional.ofNullable(contentProviders.get(type.toLowerCase()));
    }
    
    /**
     * 获取所有注册的提供器类型
     */
    public Set<String> getAvailableTypes() {
        return contentProviders.keySet();
    }
    
    /**
     * 检查是否存在指定类型的提供器
     */
    public boolean hasProvider(String type) {
        return contentProviders.containsKey(type.toLowerCase());
    }

    /**
     * 批量检查多个提供器类型是否存在
     */
    public Map<String, Boolean> checkProviders(Set<String> types) {
        Map<String, Boolean> result = new java.util.HashMap<>();
        for (String type : types) {
            result.put(type, hasProvider(type));
        }
        return result;
    }

    /**
     * 获取已实现的提供器类型（过滤掉未注册的）
     */
    public Set<String> getImplementedTypes(Set<String> requestedTypes) {
        return requestedTypes.stream()
                .filter(this::hasProvider)
                .collect(Collectors.toSet());
    }

    /**
     * 获取未实现的提供器类型
     */
    public Set<String> getMissingTypes(Set<String> requestedTypes) {
        return requestedTypes.stream()
                .filter(type -> !hasProvider(type))
                .collect(Collectors.toSet());
    }

    /**
     * [新增] 获取所有提供器的语义标签映射
     * @return 类型 -> 语义标签集合的映射
     */
    public Map<String, Set<String>> getSemanticTagsMapping() {
        Map<String, Set<String>> mapping = new java.util.HashMap<>();
        for (Map.Entry<String, ContentProvider> entry : contentProviders.entrySet()) {
            mapping.put(entry.getKey(), entry.getValue().getSemanticTags());
        }
        return mapping;
    }

    /**
     * [新增] 检测内容类型之间的重叠关系
     * @param types 要检测的内容类型集合
     * @return 重叠关系映射：类型 -> 与其重叠的其他类型集合
     */
    public Map<String, Set<String>> detectOverlaps(Set<String> types) {
        Map<String, Set<String>> overlaps = new java.util.HashMap<>();
        
        for (String type : types) {
            Optional<ContentProvider> providerOpt = getProvider(type);
            if (providerOpt.isPresent()) {
                ContentProvider provider = providerOpt.get();
                Set<String> otherTypes = types.stream()
                    .filter(t -> !t.equals(type))
                    .collect(Collectors.toSet());
                
                Set<String> overlappingTypes = new java.util.HashSet<>();
                for (String otherType : otherTypes) {
                    Optional<ContentProvider> otherProviderOpt = getProvider(otherType);
                    if (otherProviderOpt.isPresent()) {
                        ContentProvider otherProvider = otherProviderOpt.get();
                        if (provider.hasOverlapWith(otherProvider.getSemanticTags())) {
                            overlappingTypes.add(otherType);
                        }
                    }
                }
                
                if (!overlappingTypes.isEmpty()) {
                    overlaps.put(type, overlappingTypes);
                }
            }
        }
        
        return overlaps;
    }

    /**
     * [新增] 根据优先级排序提供器类型
     * @param types 要排序的类型集合
     * @return 按优先级排序的类型列表（优先级高的在前）
     */
    public List<String> sortByPriority(Set<String> types) {
        return types.stream()
                .map(type -> {
                    Optional<ContentProvider> providerOpt = getProvider(type);
                    int priority = providerOpt.map(ContentProvider::getPriority).orElse(Integer.MAX_VALUE);
                    return Map.entry(type, priority);
                })
                .sorted(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .collect(Collectors.toList());
    }

    /**
     * [新增] 获取与指定内容类型不重叠的提供器
     * @param excludedTypes 要排除的内容类型
     * @return 不与排除类型重叠的提供器类型集合
     */
    public Set<String> getNonOverlappingTypes(Set<String> excludedTypes) {
        // 获取排除类型的所有语义标签
        Set<String> excludedTags = excludedTypes.stream()
                .map(this::getProvider)
                .filter(Optional::isPresent)
                .map(Optional::get)
                .flatMap(provider -> provider.getSemanticTags().stream())
                .collect(Collectors.toSet());

        // 找出不与排除标签重叠的提供器
        return contentProviders.entrySet().stream()
                .filter(entry -> {
                    ContentProvider provider = entry.getValue();
                    return !provider.hasOverlapWith(excludedTags);
                })
                .map(Map.Entry::getKey)
                .collect(Collectors.toSet());
    }

    /**
     * [新增] 智能去重：移除冲突的内容类型，保留优先级高的
     * @param types 原始类型集合
     * @return 去重后的类型集合
     */
    public Set<String> deduplicateByPriority(Set<String> types) {
        Map<String, Set<String>> overlaps = detectOverlaps(types);
        if (overlaps.isEmpty()) {
            return new java.util.HashSet<>(types);
        }

        Set<String> result = new java.util.HashSet<>(types);
        log.info("检测到内容重叠，开始智能去重: {}", overlaps);

        // 对于每个有重叠的类型，只保留优先级最高的
        for (Map.Entry<String, Set<String>> overlap : overlaps.entrySet()) {
            String type = overlap.getKey();
            Set<String> conflictTypes = overlap.getValue();
            
            // 将当前类型也加入比较
            Set<String> allConflictTypes = new java.util.HashSet<>(conflictTypes);
            allConflictTypes.add(type);
            
            // 找出优先级最高的类型
            String highestPriorityType = allConflictTypes.stream()
                    .min((t1, t2) -> {
                        int p1 = getProvider(t1).map(ContentProvider::getPriority).orElse(Integer.MAX_VALUE);
                        int p2 = getProvider(t2).map(ContentProvider::getPriority).orElse(Integer.MAX_VALUE);
                        return Integer.compare(p1, p2);
                    })
                    .orElse(type);
            
            // 移除其他冲突的类型
            for (String conflictType : conflictTypes) {
                if (!conflictType.equals(highestPriorityType)) {
                    result.remove(conflictType);
                    log.info("去重：移除低优先级类型 {} (保留 {})", conflictType, highestPriorityType);
                }
            }
        }

        return result;
    }
} 