package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.NovelService;
import com.ainovel.server.service.SceneService;
import com.ainovel.server.domain.model.Novel;
import com.ainovel.server.common.util.PromptXmlFormatter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

import java.util.List;

/**
 * 之前所有章节内容（不含当前章节）
 */
@Slf4j
@Component
public class PreviousChaptersContentProvider implements ContentProvider {
    private static final String TYPE = "previous_chapters_content";

    @Autowired
    private NovelService novelService;

    @Autowired
    private SceneService sceneService;

    @Autowired
    private PromptXmlFormatter promptXmlFormatter;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        return getPreviousChaptersContent(request.getNovelId(), normalizeChapterIdForQuery(request.getChapterId()))
                .map(content -> new ContentResult(content, TYPE, id))
                .onErrorReturn(new ContentResult("", TYPE, id));
    }

    @Override
    public String getType() { return TYPE; }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, java.util.Map<String, Object> parameters) {
        String currentChapterId = (String) parameters.get("chapterId");
        return getPreviousChaptersContent(novelId, normalizeChapterIdForQuery(currentChapterId)).onErrorReturn("");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        String novelId = (String) contextParameters.get("novelId");
        String currentChapterId = normalizeChapterIdForQuery((String) contextParameters.get("chapterId"));
        if (novelId == null || novelId.isBlank()) return Mono.just(0);
        return getPreviousChapterIds(novelId, currentChapterId)
                .flatMap(chapterIds -> reactor.core.publisher.Flux.fromIterable(chapterIds)
                        .flatMap(chapterId -> sceneService.findSceneByChapterIdOrdered(chapterId))
                        .map(scene -> scene.getContent() != null ? scene.getContent().length() : 0)
                        .reduce(0, Integer::sum)
                )
                .onErrorResume(e -> Mono.just(0));
    }

    private Mono<String> getPreviousChaptersContent(String novelId, String currentChapterId) {
        return novelService.findNovelById(novelId)
                .flatMap(novel -> getPreviousChapterIds(novel, currentChapterId)
                        .flatMap(chapterIds -> reactor.core.publisher.Flux.fromIterable(chapterIds)
                                .flatMap(chapterId -> sceneService.findSceneByChapterIdOrdered(chapterId)
                                        .collectList()
                                        .map(scenes -> promptXmlFormatter.formatChapter(chapterId, com.ainovel.server.common.util.ChapterOrderUtil
                                                .getChapterOrder(com.ainovel.server.common.util.ChapterOrderUtil
                                                        .buildChapterOrderMap(novel), chapterId), scenes)))
                                .collectList()
                                .map(chapterXmls -> String.join("\n", chapterXmls))
                        )
                );
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
}


