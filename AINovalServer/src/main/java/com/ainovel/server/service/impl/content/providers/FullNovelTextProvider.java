package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.NovelService;
import com.ainovel.server.common.util.PromptXmlFormatter;
import com.ainovel.server.common.util.ChapterOrderUtil;
import com.ainovel.server.common.util.RichTextUtil;
import com.ainovel.server.domain.model.Scene;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

import java.util.List;

/**
 * 完整小说文本提供器
 */
@Slf4j
@Component
public class FullNovelTextProvider implements ContentProvider {

    private static final String TYPE_FULL_NOVEL_TEXT = "full_novel_text";

    @Autowired
    private NovelService novelService;

    @Autowired
    private PromptXmlFormatter promptXmlFormatter;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        // 从上下文选择ID中提取小说ID，而不是使用request.getNovelId()
        String targetNovelId = extractNovelIdFromContextId(id);
        if (targetNovelId == null || targetNovelId.isEmpty()) {
            // 如果无法从ID中提取小说ID，回退到使用request.getNovelId()
            targetNovelId = request.getNovelId();
            log.warn("无法从上下文ID {} 中提取小说ID，使用请求中的小说ID: {}", id, targetNovelId);
        } else {
            log.info("从上下文ID {} 中提取到小说ID: {}", id, targetNovelId);
        }
        
        return getFullNovelTextContent(targetNovelId)
                .map(content -> new ContentResult(content, TYPE_FULL_NOVEL_TEXT, id))
                .onErrorReturn(new ContentResult("", TYPE_FULL_NOVEL_TEXT, id));
    }

    @Override
    public String getType() { 
        return TYPE_FULL_NOVEL_TEXT; 
    }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, 
                                                 java.util.Map<String, Object> parameters) {
        log.debug("获取完整小说文本用于占位符: userId={}, novelId={}", userId, novelId);
        
        return getFullNovelTextContent(novelId)
                .onErrorReturn("[完整小说文本获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        String novelId = (String) contextParameters.get("novelId");
        
        if (novelId == null || novelId.isBlank()) {
            return Mono.just(0);
        }
        
        log.debug("获取完整小说内容长度: novelId={}", novelId);
        
        // 获取整个小说的所有场景内容长度
        return novelService.findScenesByNovelIdInOrder(novelId)
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
                .doOnNext(totalLength -> log.debug("完整小说总内容长度: novelId={}, totalLength={}", novelId, totalLength))
                .onErrorResume(error -> {
                    log.error("获取完整小说内容长度失败: novelId={}, error={}", novelId, error.getMessage());
                    return Mono.just(0);
                });
    }

    /**
     * 获取完整小说文本内容
     */
    private Mono<String> getFullNovelTextContent(String novelId) {
        return novelService.findNovelById(novelId)
                .flatMap(novel -> {
                    log.info("获取完整小说文本 - 小说ID: {}, 标题: {}", novelId, novel.getTitle());
                    // 获取所有场景，按章节和序号排序
                    return novelService.findScenesByNovelIdInOrder(novelId)
                            .filter(scene -> scene.getContent() != null && !RichTextUtil.deltaJsonToPlainText(scene.getContent()).trim().isEmpty())
                            .collectList()
                            .map(scenes -> {
                                log.info("获取到场景数量: {}", scenes.size());
                                for (Scene scene : scenes) {
                                    log.debug("场景详情 - ID: {}, 标题: {}, 章节ID: {}, 内容长度: {}", 
                                             scene.getId(), scene.getTitle(), scene.getChapterId(), 
                                             scene.getContent() != null ? scene.getContent().length() : 0);
                                }
                                
                                // 使用章节顺序映射生成XML（对齐 ChapterOrderUtil 的序号规则）
                                java.util.Map<String, Integer> chapterOrderMap = ChapterOrderUtil.buildChapterOrderMap(novel);
                                // 默认隐藏UUID（仅保留序号）
                                boolean includeIds = false;

                                String result = promptXmlFormatter.formatFullNovelTextUsingChapterOrderMap(
                                        novel.getTitle(),
                                        novel.getDescription(),
                                        scenes,
                                        chapterOrderMap,
                                        includeIds
                                );
                                log.info("格式化完整小说文本完成，结果长度: {}", result.length());
                                if (result.length() > 0) {
                                    log.debug("格式化结果预览: {}", result.length() > 500 ? result.substring(0, 500) + "..." : result);
                                }
                                return result;
                            });
                })
                .onErrorReturn(promptXmlFormatter.formatFullNovelText("未知小说", "无法获取完整小说文本", List.of()));
    }

    /**
     * 从完整小说上下文ID中提取小说ID
     */
    private String extractNovelIdFromContextId(String contextId) {
        if (contextId == null || contextId.isEmpty()) {
            return null;
        }
        
        // 处理格式如：full_novel_67f0da32b3c31d31e869ff31
        if (contextId.startsWith("full_novel_")) {
            return contextId.substring("full_novel_".length());
        }
        
        // 处理其他可能的格式
        if (contextId.contains("_")) {
            String suffix = contextId.substring(contextId.lastIndexOf("_") + 1);
            // 检查是否是有效的MongoDB ObjectId格式（24个字符的十六进制字符串）
            if (suffix.length() == 24 && suffix.matches("[0-9a-fA-F]+")) {
                return suffix;
            }
        }
        
        return null;
    }
} 