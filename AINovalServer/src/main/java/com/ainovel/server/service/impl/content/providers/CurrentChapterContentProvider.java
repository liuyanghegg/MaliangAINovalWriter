package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.SceneService;
import com.ainovel.server.service.NovelService;
import com.ainovel.server.common.util.PromptXmlFormatter;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

/**
 * 当前章节内容提供器
 * 使用请求中的 chapterId 获取当前章节内容（包含场景）
 */
@Slf4j
@Component
public class CurrentChapterContentProvider implements ContentProvider {

    private static final String TYPE = "current_chapter_content";

    @Autowired
    private SceneService sceneService;

    @Autowired
    private NovelService novelService;

    @Autowired
    private PromptXmlFormatter promptXmlFormatter;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        String chapterId = request.getChapterId();
        if (chapterId == null || chapterId.isEmpty()) {
            log.warn("CurrentChapterContentProvider: chapterId 为空");
            return Mono.just(new ContentResult("", TYPE, id));
        }
        return getChapterContentWithScenes(request.getNovelId(), chapterId)
                .map(content -> new ContentResult(content, TYPE, id))
                .onErrorReturn(new ContentResult("", TYPE, id));
    }

    @Override
    public String getType() { 
        return TYPE; 
    }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, 
                                                 java.util.Map<String, Object> parameters) {
        // 优先从 parameters 读取 chapterId
        String chapterId = (String) parameters.getOrDefault("chapterId", parameters.get("currentChapterId"));
        if (chapterId == null || chapterId.isEmpty()) {
            return Mono.just("");
        }
        return getChapterContentWithScenes(novelId, chapterId)
                .onErrorReturn("[章节内容获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        String chapterId = (String) contextParameters.getOrDefault("chapterId", contextParameters.get("currentChapterId"));
        if (chapterId == null || chapterId.isBlank()) {
            return Mono.just(0);
        }
        // 统计该章节下所有场景的内容长度
        String normalizedChapterId = normalizeChapterIdForQuery(chapterId);
        return sceneService.findSceneByChapterIdOrdered(normalizedChapterId)
                .map(scene -> estimateSceneContentLength(scene.getContent(), scene.getId()))
                .reduce(0, Integer::sum)
                .onErrorResume(error -> {
                    log.error("获取当前章节内容长度失败: chapterId={}, error={}", chapterId, error.getMessage());
                    return Mono.just(0);
                });
    }

    private Mono<String> getChapterContentWithScenes(String novelId, String chapterId) {
        String normalizedChapterId = normalizeChapterIdForQuery(chapterId);
        return sceneService.findSceneByChapterIdOrdered(normalizedChapterId)
                .collectList()
                .map(scenes -> getChapterSequenceNumber(novelId, chapterId)
                        .map(chapterNumber -> promptXmlFormatter.formatChapter(chapterId, chapterNumber, scenes))
                        .defaultIfEmpty(promptXmlFormatter.formatChapter(chapterId, 1, scenes)))
                .flatMap(mono -> mono)
                .onErrorReturn("<chapter order=\"-1\"><error>无法获取章节内容</error></chapter>");
    }

    private Mono<Integer> getChapterSequenceNumber(String novelId, String chapterId) {
        return novelService.findNovelById(novelId)
                .map(novel -> {
                    if (novel.getStructure() == null || novel.getStructure().getActs() == null) {
                        return 1;
                    }
                    int chapterSequence = 1;
                    for (com.ainovel.server.domain.model.Novel.Act act : novel.getStructure().getActs()) {
                        if (act.getChapters() != null) {
                            for (com.ainovel.server.domain.model.Novel.Chapter chapter : act.getChapters()) {
                                if (chapterId.equals(chapter.getId())) {
                                    return chapterSequence;
                                }
                                chapterSequence++;
                            }
                        }
                    }
                    return 1;
                })
                .onErrorReturn(1);
    }

    private int estimateSceneContentLength(String content, String sceneId) {
        if (content == null || content.isEmpty()) {
            return 0;
        }
        if (content.startsWith("{\"ops\":")) {
            try {
                ObjectMapper mapper = new ObjectMapper();
                JsonNode root = mapper.readTree(content);
                JsonNode ops = root.get("ops");
                int length = 0;
                if (ops != null && ops.isArray()) {
                    for (JsonNode op : ops) {
                        if (op.has("insert")) {
                            length += op.get("insert").asText().length();
                        }
                    }
                }
                return length;
            } catch (Exception e) {
                log.warn("解析Quill Delta失败，使用原始长度: sceneId={}", sceneId);
                return content.length();
            }
        }
        return content.length();
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


