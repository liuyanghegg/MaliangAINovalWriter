package com.ainovel.server.service.cache;

import com.ainovel.server.domain.model.Scene;
import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.time.Duration;
import java.util.*;
import java.util.function.Supplier;

/**
 * 缓存每本小说的结构索引（章节/场景包含关系）。
 * 通过 ContainIndex 可以快速判断某节点包含哪些下级节点，供去重算法使用。
 */
@Component
public class NovelStructureCache {

    /** key=novelId -> 索引 */
    private final Cache<String, ContainIndex> cache = Caffeine.newBuilder()
            .maximumSize(500)
            .expireAfterWrite(Duration.ofMinutes(30))
            .build();

    /**
     * 获取索引；不存在时调用 loader 构建并放入缓存。
     */
    public Mono<ContainIndex> getIndex(String novelId, Supplier<Mono<ContainIndex>> loader) {
        ContainIndex existing = cache.getIfPresent(novelId);
        if (existing != null) {
            return Mono.just(existing);
        }
        // 弹性线程构建
        return loader.get()
                .subscribeOn(Schedulers.boundedElastic())
                .doOnNext(idx -> cache.put(novelId, idx));
    }

    /**
     * 在小说结构发生变更时显式失效。
     */
    public void evict(String novelId) {
        cache.invalidate(novelId);
    }

    /**
     * 索引结构：normalizedId -> 其包含的所有子节点 normalizedId 集合。
     */
    public static class ContainIndex {
        private final Map<String, Set<String>> containMap;

        public ContainIndex(Map<String, Set<String>> containMap) {
            this.containMap = containMap;
        }

        public Set<String> getContained(String key) {
            return containMap.getOrDefault(key, Collections.emptySet());
        }
    }

    /**
     * 构建索引的简单工具方法，供 NovelService 使用。
     */
    public static ContainIndex buildIndex(List<Scene> orderedScenes) {
        Map<String, Set<String>> map = new HashMap<>();
        // 对于全文文本节点，包含所有 scene_*
        Set<String> allScenes = new HashSet<>();
        for (Scene s : orderedScenes) {
            allScenes.add("scene_" + s.getId());
            // chapter contains scenes
            map.computeIfAbsent("chapter_" + s.getChapterId(), k -> new HashSet<>()).add("scene_" + s.getId());
        }
        map.put("full_novel_text", allScenes);
        // 章节包含关系已填；若有卷/Act，可在 NovelService 里补充
        return new ContainIndex(map);
    }
} 