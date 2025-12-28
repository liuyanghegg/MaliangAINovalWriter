package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.SceneService;
import com.ainovel.server.common.util.PromptXmlFormatter;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

/**
 * 场景提供器
 */
@Slf4j
@Component
public class SceneProvider implements ContentProvider {

    private static final String TYPE_SCENE = "scene";

    @Autowired
    private SceneService sceneService;

    @Autowired
    private PromptXmlFormatter promptXmlFormatter;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        String sceneId = extractIdFromContextId(id);
        return sceneService.findSceneById(sceneId)
                .map(scene -> {
                    // 使用XML格式化器生成正确的XML
                    String content = promptXmlFormatter.formatScene(scene);
                    return new ContentResult(content, TYPE_SCENE, id);
                })
                .onErrorReturn(new ContentResult("", TYPE_SCENE, id));
    }

    @Override
    public String getType() { 
        return TYPE_SCENE; 
    }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, 
                                                 java.util.Map<String, Object> parameters) {
        log.debug("获取场景内容用于占位符: userId={}, novelId={}, contentId={}", userId, novelId, contentId);
        
        // contentId就是sceneId
        return sceneService.findSceneById(contentId)
                .map(scene -> promptXmlFormatter.formatScene(scene))
                .onErrorReturn("[场景内容获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        String sceneId = (String) contextParameters.get("sceneId");
        if (sceneId == null || sceneId.isBlank()) {
            return Mono.just(0);
        }
        
        log.debug("获取场景内容长度: sceneId={}", sceneId);
        
        // 查询场景，仅获取content字段的长度
        return sceneService.findSceneById(sceneId)
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
                            log.debug("解析Quill Delta格式，提取纯文本长度: {}", length);
                            return length;
                        } catch (Exception e) {
                            log.warn("解析Quill Delta格式失败，使用原始长度: sceneId={}, error={}", sceneId, e.getMessage());
                            return content.length(); // 解析失败则返回原始长度
                        }
                    }
                    
                    // 非Quill Delta格式，直接返回字符串长度
                    return content.length();
                })
                .defaultIfEmpty(0)
                .doOnNext(length -> log.debug("场景内容长度: sceneId={}, length={}", sceneId, length))
                .onErrorResume(error -> {
                    log.error("获取场景内容长度失败: sceneId={}, error={}", sceneId, error.getMessage());
                    return Mono.just(0);
                });
    }

    /**
     * 从上下文ID中提取实际ID
     */
    private String extractIdFromContextId(String contextId) {
        if (contextId == null || contextId.isEmpty()) {
            return null;
        }
        
        // 同 ChapterProvider 逻辑
        if (contextId.startsWith("flat_")) {
            String withoutFlat = contextId.substring("flat_".length());
            int idx = withoutFlat.indexOf("_");
            if (idx >= 0 && idx + 1 < withoutFlat.length()) {
                return withoutFlat.substring(idx + 1);
            }
            return withoutFlat;
        }

        int first = contextId.indexOf("_");
        if (first >= 0 && first + 1 < contextId.length()) {
            return contextId.substring(first + 1);
        }
        return contextId;
    }
} 