package com.ainovel.server.common.util;

import com.ainovel.server.domain.model.Novel;
import com.ainovel.server.domain.model.Scene;

import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 章节与场景顺序工具：
 * - 提供章节顺序映射（chapterId -> order）
 * - 提供场景排序（按 sequence 升序，null 最后）
 * - 提供统一的场景顺序标签生成（"chapterOrder-sceneIndex"）
 */
public final class ChapterOrderUtil {

    private ChapterOrderUtil() {}

    /**
     * 根据小说结构构建章节顺序映射。
     */
    public static Map<String, Integer> buildChapterOrderMap(Novel novel) {
        if (novel == null || novel.getStructure() == null || novel.getStructure().getActs() == null) {
            return Map.of();
        }
        // 先按原始顺序构建映射
        Map<String, Integer> rawOrderMap = novel.getStructure().getActs().stream()
                .filter(Objects::nonNull)
                .flatMap(a -> a.getChapters().stream())
                .filter(Objects::nonNull)
                .collect(Collectors.toMap(Novel.Chapter::getId, Novel.Chapter::getOrder, (a, b) -> a, LinkedHashMap::new));

        // 将章节序号统一转换为从1开始：
        // 若最小序号为0，则整体偏移+1；若更小（<0），则偏移到最小为1。
        int minOrder = rawOrderMap.values().stream()
                .filter(Objects::nonNull)
                .min(Integer::compareTo)
                .orElse(1);
        int offset = 0;
        if (minOrder <= 0) {
            offset = 1 - minOrder;
        }

        if (offset == 0) {
            return rawOrderMap;
        }

        Map<String, Integer> adjusted = new LinkedHashMap<>();
        for (Map.Entry<String, Integer> entry : rawOrderMap.entrySet()) {
            Integer value = entry.getValue();
            // 避免出现null，确保后续取值不会发生空指针
            int normalized = (value == null ? 1 : value + offset);
            adjusted.put(entry.getKey(), normalized);
        }
        return adjusted;
    }

    /**
     * 安全获取章节顺序号，若不存在则返回 -1。
     */
    public static int getChapterOrder(Map<String, Integer> chapterOrderMap, String chapterId) {
        if (chapterOrderMap == null || chapterId == null) {
            return -1;
        }
        return chapterOrderMap.getOrDefault(chapterId, -1);
    }

    /**
     * 将场景按 sequence 升序排列，null sequence 排在最后。
     */
    public static List<Scene> sortScenesBySequence(List<Scene> scenes) {
        if (scenes == null) return List.of();
        return scenes.stream()
                .filter(Objects::nonNull)
                .sorted(Comparator.comparing(Scene::getSequence, Comparator.nullsLast(Integer::compareTo)))
                .collect(Collectors.toList());
    }

    /**
     * 统一的场景顺序标签（示例：5-2）。
     */
    public static String buildSceneOrderTag(int chapterOrder, int sceneIndex) {
        return chapterOrder + "-" + sceneIndex;
    }
}


