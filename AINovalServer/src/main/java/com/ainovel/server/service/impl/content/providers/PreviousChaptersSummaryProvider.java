package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.NovelService;
import com.ainovel.server.service.SceneService;
import com.ainovel.server.domain.model.Novel;
import com.ainovel.server.domain.model.Scene;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

import java.util.List;
import java.util.Map;
 
import com.ainovel.server.common.util.ChapterOrderUtil;

/**
 * 之前所有章节摘要（不含当前章节）
 */
@Slf4j
@Component
public class PreviousChaptersSummaryProvider implements ContentProvider {
    private static final String TYPE = "previous_chapters_summary";

    @Autowired
    private NovelService novelService;

    @Autowired
    private SceneService sceneService;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        return getPreviousChaptersSummary(request.getNovelId(), request.getChapterId())
                .map(content -> new ContentResult(content, TYPE, id))
                .onErrorReturn(new ContentResult("", TYPE, id));
    }

    @Override
    public String getType() { return TYPE; }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, java.util.Map<String, Object> parameters) {
        String currentChapterId = (String) parameters.get("chapterId");
        return getPreviousChaptersSummary(novelId, currentChapterId).onErrorReturn("");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        String novelId = (String) contextParameters.get("novelId");
        String currentChapterId = (String) contextParameters.get("chapterId");
        if (novelId == null || novelId.isBlank()) return Mono.just(0);
        return getPreviousChapterIds(novelId, currentChapterId)
                .flatMap(chapterIds -> reactor.core.publisher.Flux.fromIterable(chapterIds)
                        .flatMap(chapterId -> sceneService.findSceneByChapterIdOrdered(chapterId))
                        .map(scene -> {
                            String summary = scene.getSummary();
                            if (summary != null && !summary.isEmpty()) return summary.length();
                            return 150;
                        })
                        .reduce(0, Integer::sum)
                )
                .onErrorResume(e -> Mono.just(0));
    }

    private Mono<String> getPreviousChaptersSummary(String novelId, String currentChapterId) {
        return novelService.findNovelById(novelId)
                .flatMap(novel -> getPreviousChapterIds(novel, currentChapterId)
                        .flatMap(chapterIds -> {
                            Map<String, Integer> chapterOrderMap = ChapterOrderUtil.buildChapterOrderMap(novel);

                            return reactor.core.publisher.Flux.fromIterable(chapterIds)
                                    .flatMap(chapterId -> sceneService.findSceneByChapterIdOrdered(chapterId)
                                            .collectList()
                                            .map(scenes -> formatSummaries(java.util.List.of(chapterId), scenes, chapterOrderMap)))
                                    .collectList()
                                    .map(parts -> String.join("\n", parts));
                        })
                );
    }

    private String formatSummaries(List<String> chapterIds, List<Scene> scenes, Map<String, Integer> chapterOrderMap) {
        StringBuilder sb = new StringBuilder();
        sb.append("<previous_chapters_summary>\n");
        for (String chapterId : chapterIds) {
            int chapterOrder = ChapterOrderUtil.getChapterOrder(chapterOrderMap, chapterId);
            sb.append("  <chapter order=\"").append(chapterOrder).append("\">\n");
            int sceneIndex = 0;
            for (Scene scene : ChapterOrderUtil.sortScenesBySequence(scenes)) {
                if (chapterId.equals(scene.getChapterId())) {
                    String summary = scene.getSummary();
                    if (summary != null && !summary.isEmpty()) {
                        // 统一将摘要转换为纯文本
                        summary = com.ainovel.server.common.util.RichTextUtil.deltaJsonToPlainText(summary);
                        sceneIndex++;
                        sb.append("    <scene_summary order=\"")
                                .append(ChapterOrderUtil.buildSceneOrderTag(chapterOrder, sceneIndex))
                                .append("\">\n");
                        sb.append("      <title>").append(scene.getTitle() != null ? scene.getTitle() : "").append("</title>\n");
                        sb.append("      <summary>").append(summary).append("</summary>\n");
                        sb.append("    </scene_summary>\n");
                    }
                }
            }
            sb.append("  </chapter>\n");
        }
        sb.append("</previous_chapters_summary>");
        return sb.toString();
    }

    private Mono<List<String>> getPreviousChapterIds(String novelId, String currentChapterId) {
        return novelService.findNovelById(novelId).map(novel -> getAllPreviousChapterIds(novel, currentChapterId));
    }

    private Mono<List<String>> getPreviousChapterIds(Novel novel, String currentChapterId) {
        return Mono.just(getAllPreviousChapterIds(novel, currentChapterId));
    }

    private List<String> getAllPreviousChapterIds(Novel novel, String currentChapterId) {
        List<String> all = novel.getStructure().getActs().stream()
                .flatMap(a -> a.getChapters().stream())
                .sorted((c1, c2) -> Integer.compare(c1.getOrder(), c2.getOrder()))
                .map(Novel.Chapter::getId).toList();
        if (currentChapterId == null || currentChapterId.isEmpty()) {
            return List.of();
        }
        int idx = all.indexOf(currentChapterId);
        if (idx <= 0) {
            return List.of();
        }
        return all.subList(0, idx);
    }
}


