package com.ainovel.server.web.dto;

import com.ainovel.server.domain.model.Novel.Chapter;
import com.ainovel.server.domain.model.Scene;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * 预加载章节数据传输对象
 * 专门用于阅读器预加载功能，包含章节列表和对应的场景内容
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChaptersForPreloadDto {
    
    /**
     * 章节列表，按顺序排列
     */
    private List<Chapter> chapters;
    
    /**
     * 按章节ID分组的场景列表
     * Key: 章节ID
     * Value: 该章节的场景列表（按sequence排序）
     */
    private Map<String, List<Scene>> scenesByChapter;
    
    /**
     * 获取章节总数
     * @return 章节数量
     */
    public int getChapterCount() {
        return chapters != null ? chapters.size() : 0;
    }
    
    /**
     * 获取场景总数
     * @return 所有章节的场景数量总和
     */
    public int getTotalSceneCount() {
        if (scenesByChapter == null) {
            return 0;
        }
        return scenesByChapter.values().stream()
                .mapToInt(List::size)
                .sum();
    }
    
    /**
     * 检查是否包含指定章节的数据
     * @param chapterId 章节ID
     * @return 是否包含该章节
     */
    public boolean containsChapter(String chapterId) {
        if (chapters == null) {
            return false;
        }
        return chapters.stream().anyMatch(chapter -> chapter.getId().equals(chapterId));
    }
} 