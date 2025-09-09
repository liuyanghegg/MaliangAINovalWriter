package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.NovelService;
import com.ainovel.server.service.SceneService;
import com.ainovel.server.domain.model.Scene;
import com.ainovel.server.domain.model.Novel;
import com.ainovel.server.common.util.PromptXmlFormatter;
import com.ainovel.server.common.util.ChapterOrderUtil;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

import java.util.Map;
import java.util.List;

/**
 * 前五章内容提供器
 * 提供当前章节前五章的场景内容（包括当前章节）
 */
@Slf4j
@Component
public class RecentChaptersProvider implements ContentProvider {

    private static final String TYPE_RECENT_CHAPTERS = "recent_chapters_content";
    private static final int DEFAULT_CHAPTER_COUNT = 5;

    @Autowired
    private NovelService novelService;

    @Autowired
    private SceneService sceneService;

    @Autowired
    private PromptXmlFormatter promptXmlFormatter;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        String novelId = request.getNovelId();
        String currentChapterId = request.getChapterId(); // 可能为null
        
        return getRecentChaptersContent(novelId, currentChapterId, DEFAULT_CHAPTER_COUNT)
                .map(content -> new ContentResult(content, TYPE_RECENT_CHAPTERS, id))
                .onErrorReturn(new ContentResult("", TYPE_RECENT_CHAPTERS, id));
    }

    @Override
    public String getType() { 
        return TYPE_RECENT_CHAPTERS; 
    }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, 
                                                 Map<String, Object> parameters) {
        log.debug("获取前五章内容用于占位符: userId={}, novelId={}, contentId={}", userId, novelId, contentId);
        
        // 从参数中获取当前章节ID
        String currentChapterId = (String) parameters.get("currentChapterId");
        
        return getRecentChaptersContent(novelId, currentChapterId, DEFAULT_CHAPTER_COUNT)
                .onErrorReturn("[前五章内容获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(Map<String, Object> contextParameters) {
        String novelId = (String) contextParameters.get("novelId");
        String currentChapterId = (String) contextParameters.get("currentChapterId");
        
        if (novelId == null || novelId.isBlank()) {
            return Mono.just(0);
        }
        
        log.debug("估算前五章内容长度: novelId={}, currentChapterId={}", novelId, currentChapterId);
        
        return getRecentChaptersContentLength(novelId, currentChapterId, DEFAULT_CHAPTER_COUNT)
                .defaultIfEmpty(0)
                .doOnNext(length -> log.debug("前五章内容长度: novelId={}, length={}", novelId, length))
                .onErrorResume(error -> {
                    log.error("估算前五章内容长度失败: novelId={}, error={}", novelId, error.getMessage());
                    return Mono.just(0);
                });
    }

    /**
     * 获取前五章的内容
     */
    private Mono<String> getRecentChaptersContent(String novelId, String currentChapterId, int chapterCount) {
        return novelService.findNovelById(novelId)
                .flatMap(novel -> {
                    List<String> recentChapterIds = getRecentChapterIds(novel, currentChapterId, chapterCount);
                    
                    if (recentChapterIds.isEmpty()) {
                        return Mono.just("");
                    }
                    
                    // 为每个章节获取场景内容
                    return getChaptersWithScenesContent(novel, recentChapterIds);
                });
    }

    /**
     * 获取前五章的内容长度估算
     */
    private Mono<Integer> getRecentChaptersContentLength(String novelId, String currentChapterId, int chapterCount) {
        return novelService.findNovelById(novelId)
                .flatMap(novel -> {
                    List<String> recentChapterIds = getRecentChapterIds(novel, currentChapterId, chapterCount);
                    
                    if (recentChapterIds.isEmpty()) {
                        return Mono.just(0);
                    }
                    
                    // 估算每个章节的内容长度
                    return estimateChaptersContentLength(recentChapterIds);
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
     * 获取多个章节的场景内容
     */
    private Mono<String> getChaptersWithScenesContent(Novel novel, List<String> chapterIds) {
        StringBuilder contentBuilder = new StringBuilder();
        contentBuilder.append("<recent_chapters_content>\n");
        contentBuilder.append("  <novel_title>").append(novel.getTitle()).append("</novel_title>\n");
        contentBuilder.append("  <chapters_count>").append(chapterIds.size()).append("</chapters_count>\n");
        
        // 准备章节顺序映射
        java.util.Map<String, Integer> chapterOrderMap = ChapterOrderUtil.buildChapterOrderMap(novel);

        // 获取每个章节的内容
        return getChapterContents(chapterIds)
                .collectList()
                .map(chapterContents -> {
                    for (int i = 0; i < chapterIds.size(); i++) {
                        String chapterId = chapterIds.get(i);
                        int chapterOrder = ChapterOrderUtil.getChapterOrder(chapterOrderMap, chapterId);
                        String chapterContent = i < chapterContents.size() ? chapterContents.get(i) : "";
                        
                        if (!chapterContent.isEmpty()) {
                            contentBuilder.append("  <chapter order=\"").append(chapterOrder).append("\">\n");
                            contentBuilder.append("    ").append(chapterContent.replace("\n", "\n    ")).append("\n");
                            contentBuilder.append("  </chapter>\n");
                        }
                    }
                    
                    contentBuilder.append("</recent_chapters_content>");
                    return contentBuilder.toString();
                });
    }

    /**
     * 获取多个章节的内容
     */
    private reactor.core.publisher.Flux<String> getChapterContents(List<String> chapterIds) {
        return reactor.core.publisher.Flux.fromIterable(chapterIds)
                .flatMap(chapterId -> 
                    sceneService.findSceneByChapterIdOrdered(chapterId)
                            .collectList()
                            .map(scenes -> formatChapterScenes(chapterId, scenes))
                            .onErrorReturn("")
                );
    }

    /**
     * 格式化章节的场景内容
     */
    private String formatChapterScenes(String chapterId, List<Scene> scenes) {
        if (scenes.isEmpty()) {
            return "";
        }
        
        StringBuilder chapterBuilder = new StringBuilder();
        
        for (Scene scene : scenes) {
            String sceneXml = promptXmlFormatter.formatScene(scene);
            if (!sceneXml.isEmpty()) {
                chapterBuilder.append(sceneXml).append("\n");
            }
        }
        
        return chapterBuilder.toString();
    }

    /**
     * 估算多个章节的内容长度
     */
    private Mono<Integer> estimateChaptersContentLength(List<String> chapterIds) {
        return reactor.core.publisher.Flux.fromIterable(chapterIds)
                .flatMap(chapterId -> 
                    sceneService.findSceneByChapterIdOrdered(chapterId)
                            .map(scene -> estimateSceneContentLength(scene))
                            .reduce(0, Integer::sum)
                            .onErrorReturn(0)
                )
                .reduce(0, Integer::sum);
    }

    /**
     * 估算单个场景的内容长度
     */
    private int estimateSceneContentLength(Scene scene) {
        String content = scene.getContent();
        if (content == null || content.isEmpty()) {
            return 0;
        }
        
        // 如果是Quill Delta格式，尝试解析
        if (content.startsWith("{\"ops\":")) {
            try {
                com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                com.fasterxml.jackson.databind.JsonNode root = mapper.readTree(content);
                com.fasterxml.jackson.databind.JsonNode ops = root.get("ops");
                int length = 0;
                if (ops != null && ops.isArray()) {
                    for (com.fasterxml.jackson.databind.JsonNode op : ops) {
                        if (op.has("insert")) {
                            length += op.get("insert").asText().length();
                        }
                    }
                }
                return length;
            } catch (Exception e) {
                log.warn("解析Quill Delta格式失败，使用原始长度: sceneId={}", scene.getId());
                return content.length();
            }
        }
        
        return content.length();
    }
} 