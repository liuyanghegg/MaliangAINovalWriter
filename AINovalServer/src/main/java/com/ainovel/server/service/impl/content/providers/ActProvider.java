package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.NovelService;
import com.ainovel.server.service.SceneService;
import com.ainovel.server.common.util.PromptXmlFormatter;
import com.ainovel.server.domain.model.Novel;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Flux;
import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.List;

/**
 * Act提供器
 */
@Slf4j
@Component
public class ActProvider implements ContentProvider {

    private static final String TYPE_ACT = "act";

    @Autowired
    private NovelService novelService;

    @Autowired
    private SceneService sceneService;

    @Autowired
    private PromptXmlFormatter promptXmlFormatter;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        String actId = extractIdFromContextId(id);
        return getActContent(request.getNovelId(), actId)
                .map(content -> new ContentResult(content, TYPE_ACT, id));
    }

    @Override
    public String getType() { 
        return TYPE_ACT; 
    }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, 
                                                 java.util.Map<String, Object> parameters) {
        log.debug("获取Act内容用于占位符: userId={}, novelId={}, contentId={}", userId, novelId, contentId);
        
        // contentId就是actId
        return getActContent(novelId, contentId)
                .onErrorReturn("[Act内容获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        String actId = (String) contextParameters.get("actId");
        String novelId = (String) contextParameters.get("novelId");
        
        if (actId == null || actId.isBlank() || novelId == null || novelId.isBlank()) {
            return Mono.just(0);
        }
        
        log.debug("获取Act内容长度: novelId={}, actId={}", novelId, actId);
        
        return novelService.findNovelById(novelId)
                .flatMap(novel -> {
                    // 从小说结构中找到指定的Act
                    Novel.Act targetAct = null;
                    if (novel.getStructure() != null && novel.getStructure().getActs() != null) {
                        for (Novel.Act act : novel.getStructure().getActs()) {
                            if (actId.equals(act.getId())) {
                                targetAct = act;
                                break;
                            }
                        }
                    }
                    
                    if (targetAct == null) {
                        log.warn("未找到指定的Act: {}", actId);
                        return Mono.just(0);
                    }
                    
                    // 收集该Act下所有章节的场景ID
                    List<String> allSceneIds = new ArrayList<>();
                    if (targetAct.getChapters() != null) {
                        for (Novel.Chapter chapter : targetAct.getChapters()) {
                            if (chapter.getSceneIds() != null) {
                                allSceneIds.addAll(chapter.getSceneIds());
                            }
                        }
                    }
                    
                    if (allSceneIds.isEmpty()) {
                        log.debug("Act {} 没有场景", actId);
                        return Mono.just(0);
                    }
                    
                    // 获取所有场景的内容长度并累加
                    return Flux.fromIterable(allSceneIds)
                            .flatMap(sceneId -> sceneService.findSceneById(sceneId)
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
                                    .onErrorReturn(0)) // 如果场景获取失败，长度为0
                            .reduce(0, Integer::sum) // 累加所有场景的长度
                            .doOnNext(totalLength -> log.debug("Act总内容长度: actId={}, totalLength={}", actId, totalLength));
                })
                .onErrorResume(error -> {
                    log.error("获取Act内容长度失败: novelId={}, actId={}, error={}", novelId, actId, error.getMessage());
                    return Mono.just(0);
                });
    }

    /**
     * 获取Act内容（包含该Act下的所有章节和场景）
     */
    private Mono<String> getActContent(String novelId, String actId) {
        return novelService.findNovelById(novelId)
                .flatMap(novel -> {
                    log.info("获取Act内容 - 小说ID: {}, ActID: {}", novelId, actId);
                    
                    // 从小说结构中找到指定的Act
                    Novel.Act targetAct = null;
                    if (novel.getStructure() != null && novel.getStructure().getActs() != null) {
                        for (Novel.Act act : novel.getStructure().getActs()) {
                            if (actId.equals(act.getId())) {
                                targetAct = act;
                                break;
                            }
                        }
                    }
                    
                    if (targetAct == null) {
                        log.warn("未找到指定的Act: {}", actId);
                        return Mono.just("");
                    }
                    
                    final Novel.Act finalAct = targetAct;
                    
                    // 获取该Act下所有章节的场景
                    if (finalAct.getChapters() == null || finalAct.getChapters().isEmpty()) {
                        log.info("Act {} 没有章节", actId);
                        return Mono.just(promptXmlFormatter.formatAct(
                                finalAct.getOrder(), 
                                finalAct.getTitle(), 
                                finalAct.getDescription(), 
                                List.of()
                        ));
                    }
                    
                    // 收集所有章节的场景ID
                    List<String> allSceneIds = new ArrayList<>();
                    for (Novel.Chapter chapter : finalAct.getChapters()) {
                        if (chapter.getSceneIds() != null) {
                            allSceneIds.addAll(chapter.getSceneIds());
                        }
                    }
                    
                    if (allSceneIds.isEmpty()) {
                        log.info("Act {} 的章节中没有场景", actId);
                        return Mono.just(promptXmlFormatter.formatAct(
                                finalAct.getOrder(), 
                                finalAct.getTitle(), 
                                finalAct.getDescription(), 
                                List.of()
                        ));
                    }
                    
                    // 获取所有场景的详细信息
                    return Flux.fromIterable(allSceneIds)
                            .flatMap(sceneId -> sceneService.findSceneById(sceneId)
                                    .onErrorResume(e -> {
                                        log.warn("获取场景 {} 失败: {}", sceneId, e.getMessage());
                                        return Mono.empty();
                                    }))
                            .collectList()
                            .map(scenes -> {
                                log.info("Act {} 获取到 {} 个场景", actId, scenes.size());
                                return promptXmlFormatter.formatAct(
                                        finalAct.getOrder(), 
                                        finalAct.getTitle(), 
                                        finalAct.getDescription(), 
                                        scenes
                                );
                            });
                })
                .onErrorReturn("");
    }

    /**
     * 从上下文ID中提取实际ID
     */
    private String extractIdFromContextId(String contextId) {
        if (contextId == null || contextId.isEmpty()) {
            return null;
        }
        
        // 处理格式如：chapter_xxx, scene_xxx, setting_xxx, snippet_xxx
        if (contextId.contains("_")) {
            return contextId.substring(contextId.lastIndexOf("_") + 1);
        }
        
        return contextId;
    }
} 