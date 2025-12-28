package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.NovelService;
import com.ainovel.server.common.util.PromptXmlFormatter;
import com.ainovel.server.domain.model.Scene;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

import java.util.List;

/**
 * 完整小说摘要提供器
 */
@Slf4j
@Component
public class FullNovelSummaryProvider implements ContentProvider {

    private static final String TYPE_FULL_NOVEL_SUMMARY = "full_novel_summary";

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
        
        return getFullNovelSummaryContent(targetNovelId)
                .map(content -> new ContentResult(content, TYPE_FULL_NOVEL_SUMMARY, id))
                .onErrorReturn(new ContentResult("", TYPE_FULL_NOVEL_SUMMARY, id));
    }

    @Override
    public String getType() { 
        return TYPE_FULL_NOVEL_SUMMARY; 
    }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, 
                                                 java.util.Map<String, Object> parameters) {
        log.debug("获取完整小说摘要用于占位符: userId={}, novelId={}", userId, novelId);
        
        return getFullNovelSummaryContent(novelId)
                .onErrorReturn("[完整小说摘要获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        String novelId = (String) contextParameters.get("novelId");
        
        if (novelId == null || novelId.isBlank()) {
            return Mono.just(0);
        }
        
        log.debug("获取完整小说摘要长度: novelId={}", novelId);
        
        // 获取整个小说的所有场景摘要长度
        return novelService.findScenesByNovelIdInOrder(novelId)
                .map(scene -> {
                    String summary = scene.getSummary();
                    if (summary == null || summary.isEmpty()) {
                        return 0;
                    }
                    
                    // 直接返回摘要字符串长度
                    return summary.length();
                })
                .reduce(0, Integer::sum) // 累加所有场景摘要的长度
                .doOnNext(totalLength -> log.debug("完整小说摘要总长度: novelId={}, totalLength={}", novelId, totalLength))
                .onErrorResume(error -> {
                    log.error("获取完整小说摘要长度失败: novelId={}, error={}", novelId, error.getMessage());
                    return Mono.just(0);
                });
    }

    /**
     * 获取完整小说摘要内容
     */
    private Mono<String> getFullNovelSummaryContent(String novelId) {
        return novelService.findNovelById(novelId)
                .flatMap(novel -> {
                    log.info("获取完整小说摘要 - 小说ID: {}, 标题: {}", novelId, novel.getTitle());
                    // 获取所有有摘要的场景
                    return novelService.findScenesByNovelIdInOrder(novelId)
                            .doOnNext(scene -> log.debug("检查场景摘要 - ID: {}, 标题: {}, 摘要: {}", 
                                                        scene.getId(), scene.getTitle(), 
                                                        scene.getSummary() != null ? scene.getSummary().substring(0, Math.min(100, scene.getSummary().length())) + "..." : "无摘要"))
                            .filter(scene -> scene.getSummary() != null && !scene.getSummary().isEmpty())
                            .collectList()
                            .map(scenes -> {
                                log.info("获取到有摘要的场景数量: {}", scenes.size());
                                
                                // 使用XML格式化器生成正确的XML
                                String result = promptXmlFormatter.formatNovelSummary(
                                        novel.getTitle(), 
                                        novel.getDescription(), 
                                        scenes
                                );
                                log.info("格式化完整小说摘要完成，结果长度: {}", result.length());
                                if (result.length() > 0) {
                                    log.debug("格式化结果预览: {}", result.length() > 500 ? result.substring(0, 500) + "..." : result);
                                }
                                return result;
                            });
                })
                .onErrorReturn(promptXmlFormatter.formatNovelSummary("未知小说", "无法获取小说摘要", List.of()));
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