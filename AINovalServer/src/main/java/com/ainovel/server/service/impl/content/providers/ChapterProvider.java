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
 * 章节提供器
 */
@Slf4j
@Component
public class ChapterProvider implements ContentProvider {

    private static final String TYPE_CHAPTER = "chapter";

    @Autowired
    private SceneService sceneService;

    @Autowired
    private NovelService novelService;

    @Autowired
    private PromptXmlFormatter promptXmlFormatter;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        String chapterId = extractIdFromContextId(id);
        return getChapterContentWithScenes(request.getNovelId(), chapterId)
                .map(content -> new ContentResult(content, TYPE_CHAPTER, id))
                .onErrorReturn(new ContentResult("", TYPE_CHAPTER, id));
    }

    @Override
    public String getType() { 
        return TYPE_CHAPTER; 
    }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, 
                                                 java.util.Map<String, Object> parameters) {
        log.debug("获取章节内容用于占位符: userId={}, novelId={}, contentId={}", userId, novelId, contentId);
        
        // 兼容前端扁平化ID：支持 flat_<uuid> 与 flat_chapter_<uuid>
        String resolvedChapterId = extractIdFromContextId(contentId);
        return getChapterContentWithScenes(novelId, resolvedChapterId)
                .onErrorReturn("[章节内容获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        String chapterId = (String) contextParameters.get("chapterId");
        if (chapterId == null || chapterId.isBlank()) {
            return Mono.just(0);
        }
        
        log.debug("获取章节内容长度: chapterId={}", chapterId);
        
        // 🚀 修复：确保章节ID格式正确（去掉前缀），适配数据库字段格式变更
        String normalizedChapterId = normalizeChapterIdForQuery(chapterId);
        
        // 获取该章节下所有场景的内容长度总和
        return sceneService.findSceneByChapterIdOrdered(normalizedChapterId)
                .map(scene -> {
                    String content = scene.getContent();
                    if (content == null || content.isEmpty()) {
                        return 0;
                    }
                    
                    // 对于Quill Delta格式，解析JSON并提取纯文本长度
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
                            log.warn("解析场景Quill Delta格式失败，使用原始长度: sceneId={}, error={}", scene.getId(), e.getMessage());
                            return content.length(); // 解析失败则返回原始长度
                        }
                    }
                    
                    // 非Quill Delta格式，直接返回字符串长度
                    return content.length();
                })
                .reduce(0, Integer::sum) // 累加所有场景的长度
                .doOnNext(totalLength -> log.debug("章节总内容长度: chapterId={}, totalLength={}", chapterId, totalLength))
                .onErrorResume(error -> {
                    log.error("获取章节内容长度失败: chapterId={}, error={}", chapterId, error.getMessage());
                    return Mono.just(0);
                });
    }

    /**
     * 获取章节内容（包含场景）
     */
    private Mono<String> getChapterContentWithScenes(String novelId, String chapterId) {
        // 🚀 修复：确保章节ID格式正确（去掉前缀），适配数据库字段格式变更
        String normalizedChapterId = normalizeChapterIdForQuery(chapterId);
        return sceneService.findSceneByChapterIdOrdered(normalizedChapterId)
                .collectList()
                .map(scenes -> {
                    // 获取章节在小说中的顺序号，而不是硬编码为1
                    return getChapterSequenceNumber(novelId, chapterId)
                            .map(chapterNumber -> promptXmlFormatter.formatChapter(chapterId, chapterNumber, scenes))
                            .defaultIfEmpty(promptXmlFormatter.formatChapter(chapterId, 1, scenes));
                })
                .flatMap(mono -> mono) // 展开内层Mono
                .onErrorReturn("<chapter order=\"-1\"><error>无法获取章节内容</error></chapter>");
    }

    /**
     * 获取章节在小说中的顺序号
     */
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
                    return 1; // 如果找不到，使用默认值1
                })
                .onErrorReturn(1);
    }

    /**
     * 从上下文ID中提取实际ID
     */
    private String extractIdFromContextId(String contextId) {
        if (contextId == null || contextId.isEmpty()) {
            return null;
        }
        
        // 常见格式:
        // 1) chapter_<uuid>
        // 2) scene_<uuid>
        // 3) flat_chapter_<uuid> (前端扁平化用)
        // 4) flat_scene_<uuid>

        // 处理扁平化前缀 flat_*
        if (contextId.startsWith("flat_")) {
            // 跳过 "flat_"
            String withoutFlat = contextId.substring("flat_".length());
            int idx = withoutFlat.indexOf("_");
            if (idx >= 0 && idx + 1 < withoutFlat.length()) {
                return withoutFlat.substring(idx + 1); // 去掉类型前缀 (chapter_/scene_)
            }
            return withoutFlat; // 兜底
        }

        // 常规形式 chapter_<uuid> / scene_<uuid>
        int first = contextId.indexOf("_");
        if (first >= 0 && first + 1 < contextId.length()) {
            return contextId.substring(first + 1);
        }
        return contextId;
    }

    /**
     * 🚀 新增：确保章节ID为纯UUID格式（去掉前缀）
     * 用于修复数据库中chapterId字段格式变更后的兼容性问题
     */
    private String normalizeChapterIdForQuery(String chapterId) {
        if (chapterId == null || chapterId.isEmpty()) {
            return chapterId;
        }
        
        // 如果包含"chapter_"前缀，去掉它
        if (chapterId.startsWith("chapter_")) {
            return chapterId.substring("chapter_".length());
        }
        
        // 如果是扁平化格式 flat_chapter_xxx
        if (chapterId.startsWith("flat_chapter_")) {
            return chapterId.substring("flat_chapter_".length());
        }

        // 兜底：如果是通用扁平化前缀 flat_<uuid>（无类型段），去掉flat_
        if (chapterId.startsWith("flat_")) {
            return chapterId.substring("flat_".length());
        }
        
        // 其他情况直接返回
        return chapterId;
    }
} 