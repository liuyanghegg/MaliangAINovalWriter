package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.SceneService;
import com.ainovel.server.service.NovelService;
import com.ainovel.server.common.util.RichTextUtil;
import com.ainovel.server.domain.model.Scene;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

/**
 * 当前章节所有场景摘要提供器
 */
@Slf4j
@Component
public class CurrentChapterSummariesProvider implements ContentProvider {

    private static final String TYPE = "current_chapter_summary";

    @Autowired
    private SceneService sceneService;

    @Autowired
    private NovelService novelService;

    // PromptXmlFormatter 未使用，移除可以降低警告

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        String chapterId = normalizeChapterIdForQuery(request.getChapterId());
        if (chapterId == null || chapterId.isEmpty()) {
            log.warn("CurrentChapterSummariesProvider: chapterId 为空");
            return Mono.just(new ContentResult("", TYPE, id));
        }
        return buildChapterSummaries(request.getNovelId(), chapterId)
                .map(content -> new ContentResult(content, TYPE, id))
                .onErrorReturn(new ContentResult("", TYPE, id));
    }

    @Override
    public String getType() { return TYPE; }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, java.util.Map<String, Object> parameters) {
        String chapterId = (String) parameters.getOrDefault("chapterId", parameters.get("currentChapterId"));
        chapterId = normalizeChapterIdForQuery(chapterId);
        if (chapterId == null || chapterId.isEmpty()) return Mono.just("");
        return buildChapterSummaries(novelId, chapterId).onErrorReturn("[章节摘要获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        String chapterId = (String) contextParameters.getOrDefault("chapterId", contextParameters.get("currentChapterId"));
        chapterId = normalizeChapterIdForQuery(chapterId);
        if (chapterId == null || chapterId.isBlank()) return Mono.just(0);
        return sceneService.findSceneByChapterIdOrdered(chapterId)
                .map(this::estimateSceneSummaryLength)
                .reduce(0, Integer::sum)
                .onErrorResume(e -> Mono.just(0));
    }

    private Mono<String> buildChapterSummaries(String novelId, String chapterId) {
        return novelService.findNovelById(novelId)
                .flatMap(novel -> {
                    java.util.Map<String, Integer> chapterOrderMap = com.ainovel.server.common.util.ChapterOrderUtil.buildChapterOrderMap(novel);
                    int chapterOrder = com.ainovel.server.common.util.ChapterOrderUtil.getChapterOrder(chapterOrderMap, chapterId);
                    return sceneService.findSceneByChapterIdOrdered(chapterId)
                            .collectList()
                            .map(scenes -> {
                                StringBuilder sb = new StringBuilder();
                                sb.append("<current_chapter_summary chapter_order=\"").append(chapterOrder).append("\">\n");
                                sb.append("  <scenes_count>").append(scenes.size()).append("</scenes_count>\n");
                                int sceneIndex = 0;
                                for (Scene scene : com.ainovel.server.common.util.ChapterOrderUtil.sortScenesBySequence(scenes)) {
                                    String summary = extractSceneSummary(scene);
                                    if (summary != null && !summary.isEmpty()) {
                                        sceneIndex++;
                                        sb.append("  <scene_summary order=\"")
                                                .append(com.ainovel.server.common.util.ChapterOrderUtil.buildSceneOrderTag(chapterOrder, sceneIndex))
                                                .append("\">\n");
                                        sb.append("    <title>").append(scene.getTitle() != null ? scene.getTitle() : "").append("</title>\n");
                                        sb.append("    <summary>").append(summary).append("</summary>\n");
                                        sb.append("  </scene_summary>\n");
                                    }
                                }
                                sb.append("</current_chapter_summary>");
                                return sb.toString();
                            });
                });
    }

    // 与 ChapterProvider/CurrentChapterContentProvider 保持一致的归一化逻辑
    private String normalizeChapterIdForQuery(String chapterId) {
        if (chapterId == null || chapterId.isEmpty()) {
            return chapterId;
        }
        if (chapterId.startsWith("chapter_")) {
            return chapterId.substring("chapter_".length());
        }
        if (chapterId.startsWith("flat_chapter_")) {
            return chapterId.substring("flat_chapter_".length());
        }
        if (chapterId.startsWith("flat_")) {
            return chapterId.substring("flat_".length());
        }
        return chapterId;
    }

    private String extractSceneSummary(Scene scene) {
        // 优先使用摘要字段，并统一转换为纯文本
        if (scene.getSummary() != null && !scene.getSummary().isEmpty()) {
            String plain = RichTextUtil.deltaJsonToPlainText(scene.getSummary());
            return plain;
        }
        // 回退到内容字段，转换为纯文本后截断
        String content = scene.getContent();
        if (content == null || content.isEmpty()) return "";
        String plain = RichTextUtil.deltaJsonToPlainText(content);
        if (plain.length() > 150) return plain.substring(0, 150) + "...";
        return plain;
    }

    private int estimateSceneSummaryLength(Scene scene) {
        if (scene.getSummary() != null && !scene.getSummary().isEmpty()) {
            return scene.getSummary().length();
        }
        return 150;
    }
}


