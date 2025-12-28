package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.NovelService;
import com.ainovel.server.service.SceneService;
import com.ainovel.server.domain.model.Scene;
import com.ainovel.server.domain.model.Novel;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

import java.util.Map;
import java.util.List;
 
import com.ainovel.server.common.util.ChapterOrderUtil;

/**
 * 前五章摘要提供器
 * 提供当前章节前五章的场景摘要信息
 */
@Slf4j
@Component
public class RecentChaptersSummaryProvider implements ContentProvider {

    private static final String TYPE_RECENT_CHAPTERS_SUMMARY = "recent_chapters_summary";
    private static final int DEFAULT_CHAPTER_COUNT = 5;

    @Autowired
    private NovelService novelService;

    @Autowired
    private SceneService sceneService;

    

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        String novelId = request.getNovelId();
        String currentChapterId = request.getChapterId(); // 可能为null
        
        return getRecentChaptersSummary(novelId, currentChapterId, DEFAULT_CHAPTER_COUNT)
                .map(content -> new ContentResult(content, TYPE_RECENT_CHAPTERS_SUMMARY, id))
                .onErrorReturn(new ContentResult("", TYPE_RECENT_CHAPTERS_SUMMARY, id));
    }

    @Override
    public String getType() { 
        return TYPE_RECENT_CHAPTERS_SUMMARY; 
    }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, 
                                                 Map<String, Object> parameters) {
        log.debug("获取前五章摘要用于占位符: userId={}, novelId={}, contentId={}", userId, novelId, contentId);
        
        // 从参数中获取当前章节ID
        String currentChapterId = (String) parameters.get("currentChapterId");
        
        return getRecentChaptersSummary(novelId, currentChapterId, DEFAULT_CHAPTER_COUNT)
                .onErrorReturn("[前五章摘要获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(Map<String, Object> contextParameters) {
        String novelId = (String) contextParameters.get("novelId");
        String currentChapterId = (String) contextParameters.get("currentChapterId");
        
        if (novelId == null || novelId.isBlank()) {
            return Mono.just(0);
        }
        
        log.debug("估算前五章摘要长度: novelId={}, currentChapterId={}", novelId, currentChapterId);
        
        return getRecentChaptersSummaryLength(novelId, currentChapterId, DEFAULT_CHAPTER_COUNT)
                .defaultIfEmpty(0)
                .doOnNext(length -> log.debug("前五章摘要长度: novelId={}, length={}", novelId, length))
                .onErrorResume(error -> {
                    log.error("估算前五章摘要长度失败: novelId={}, error={}", novelId, error.getMessage());
                    return Mono.just(0);
                });
    }

    /**
     * 获取前五章的摘要
     */
    private Mono<String> getRecentChaptersSummary(String novelId, String currentChapterId, int chapterCount) {
        return novelService.findNovelById(novelId)
                .flatMap(novel -> {
                    List<String> recentChapterIds = getRecentChapterIds(novel, currentChapterId, chapterCount);
                    
                    if (recentChapterIds.isEmpty()) {
                        return Mono.just("");
                    }
                    
                    // 为每个章节获取摘要信息
                    return getChaptersWithSceneSummaries(novel, recentChapterIds);
                });
    }

    /**
     * 获取前五章的摘要长度估算
     */
    private Mono<Integer> getRecentChaptersSummaryLength(String novelId, String currentChapterId, int chapterCount) {
        return novelService.findNovelById(novelId)
                .flatMap(novel -> {
                    List<String> recentChapterIds = getRecentChapterIds(novel, currentChapterId, chapterCount);
                    
                    if (recentChapterIds.isEmpty()) {
                        return Mono.just(0);
                    }
                    
                    // 估算每个章节的摘要长度
                    return estimateChaptersSummaryLength(recentChapterIds);
                });
    }

    /**
     * 获取前N章的章节ID列表
     */
    private List<String> getRecentChapterIds(Novel novel, String currentChapterId, int chapterCount) {
        List<String> allChapterIds = getAllChapterIdsInOrder(novel);
        
        if (currentChapterId == null || currentChapterId.isEmpty()) {
            // 如果没有当前章节ID，返回前N章
            return allChapterIds.stream()
                    .limit(chapterCount)
                    .toList();
        }
        
        // 找到当前章节的位置
        int currentIndex = allChapterIds.indexOf(currentChapterId);
        if (currentIndex == -1) {
            // 如果找不到当前章节，返回前N章
            return allChapterIds.stream()
                    .limit(chapterCount)
                    .toList();
        }
        
        // 计算起始位置（当前章节前4章 + 当前章节 = 5章）
        int startIndex = Math.max(0, currentIndex - (chapterCount - 1));
        int endIndex = Math.min(allChapterIds.size() - 1, currentIndex);
        
        return allChapterIds.subList(startIndex, endIndex + 1);
    }

    /**
     * 获取所有章节ID的有序列表
     */
    private List<String> getAllChapterIdsInOrder(Novel novel) {
        return novel.getStructure().getActs().stream()
                .flatMap(act -> act.getChapters().stream())
                .sorted((c1, c2) -> Integer.compare(c1.getOrder(), c2.getOrder()))
                .map(Novel.Chapter::getId)
                .toList();
    }

    /**
     * 获取多个章节的场景摘要
     */
    private Mono<String> getChaptersWithSceneSummaries(Novel novel, List<String> chapterIds) {
        StringBuilder contentBuilder = new StringBuilder();
        contentBuilder.append("<recent_chapters_summary>\n");
        contentBuilder.append("  <novel_title>").append(novel.getTitle()).append("</novel_title>\n");
        contentBuilder.append("  <chapters_count>").append(chapterIds.size()).append("</chapters_count>\n");
        
        // 准备章节顺序映射
        Map<String, Integer> chapterOrderMap = ChapterOrderUtil.buildChapterOrderMap(novel);

        // 获取每个章节的摘要
        return getChapterSummaries(chapterIds, chapterOrderMap)
                .collectList()
                .map(chapterSummaries -> {
                    for (int i = 0; i < chapterIds.size(); i++) {
                        String chapterId = chapterIds.get(i);
                        int chapterOrder = ChapterOrderUtil.getChapterOrder(chapterOrderMap, chapterId);
                        String chapterSummary = i < chapterSummaries.size() ? chapterSummaries.get(i) : "";
                        
                        if (!chapterSummary.isEmpty()) {
                            contentBuilder.append("  <chapter order=\"").append(chapterOrder).append("\">\n");
                            contentBuilder.append("    ").append(chapterSummary.replace("\n", "\n    ")).append("\n");
                            contentBuilder.append("  </chapter>\n");
                        }
                    }
                    
                    contentBuilder.append("</recent_chapters_summary>");
                    return contentBuilder.toString();
                });
    }

    /**
     * 获取多个章节的摘要
     */
    private reactor.core.publisher.Flux<String> getChapterSummaries(List<String> chapterIds, Map<String, Integer> chapterOrderMap) {
        return reactor.core.publisher.Flux.fromIterable(chapterIds)
                .flatMap(chapterId -> 
                    sceneService.findSceneByChapterIdOrdered(chapterId)
                            .collectList()
                            .map(scenes -> formatChapterSceneSummaries(chapterId, scenes, chapterOrderMap))
                            .onErrorReturn("")
                );
    }

    /**
     * 格式化章节的场景摘要
     */
    private String formatChapterSceneSummaries(String chapterId, List<Scene> scenes, Map<String, Integer> chapterOrderMap) {
        if (scenes.isEmpty()) {
            return "";
        }
        
        StringBuilder chapterBuilder = new StringBuilder();
        int chapterOrder = ChapterOrderUtil.getChapterOrder(chapterOrderMap, chapterId);
        chapterBuilder.append("<chapter_summary chapter_order=\"").append(chapterOrder).append("\">\n");
        chapterBuilder.append("  <scenes_count>").append(scenes.size()).append("</scenes_count>\n");
        
        int sceneIndex = 0;
        for (Scene scene : ChapterOrderUtil.sortScenesBySequence(scenes)) {
            String sceneSummary = extractSceneSummary(scene);
            if (!sceneSummary.isEmpty()) {
                sceneIndex++;
                chapterBuilder.append("  <scene_summary order=\"")
                        .append(ChapterOrderUtil.buildSceneOrderTag(chapterOrder, sceneIndex))
                        .append("\">\n");
                chapterBuilder.append("    <title>").append(scene.getTitle() != null ? scene.getTitle() : "").append("</title>\n");
                chapterBuilder.append("    <summary>").append(sceneSummary).append("</summary>\n");
                chapterBuilder.append("  </scene_summary>\n");
            }
        }
        
        chapterBuilder.append("</chapter_summary>");
        return chapterBuilder.toString();
    }

    /**
     * 提取场景摘要
     */
    private String extractSceneSummary(Scene scene) {
        if (scene.getSummary() != null && !scene.getSummary().isEmpty()) {
            return com.ainovel.server.common.util.RichTextUtil.deltaJsonToPlainText(scene.getSummary());
        }
        String content = scene.getContent();
        if (content == null || content.isEmpty()) {
            return "";
        }
        String plain = com.ainovel.server.common.util.RichTextUtil.deltaJsonToPlainText(content);
        if (plain.length() > 150) {
            return plain.substring(0, 150) + "...";
        }
        return plain;
    }

    /**
     * 估算多个章节的摘要长度
     */
    private Mono<Integer> estimateChaptersSummaryLength(List<String> chapterIds) {
        return reactor.core.publisher.Flux.fromIterable(chapterIds)
                .flatMap(chapterId -> 
                    sceneService.findSceneByChapterIdOrdered(chapterId)
                            .map(scene -> estimateSceneSummaryLength(scene))
                            .reduce(0, Integer::sum)
                            .onErrorReturn(0)
                )
                .reduce(0, Integer::sum);
    }

    /**
     * 估算单个场景摘要的长度
     */
    private int estimateSceneSummaryLength(Scene scene) {
        // 摘要长度大约为150-200字符
        if (scene.getSummary() != null && !scene.getSummary().isEmpty()) {
            return scene.getSummary().length();
        }
        
        // 如果没有摘要，估算为150字符
        return 150;
    }
} 