package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.SceneService;
import com.ainovel.server.common.util.PromptXmlFormatter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

/**
 * 当前场景内容提供器
 */
@Slf4j
@Component
public class CurrentSceneContentProvider implements ContentProvider {

    private static final String TYPE = "current_scene_content";

    @Autowired
    private SceneService sceneService;

    @Autowired
    private PromptXmlFormatter promptXmlFormatter;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        String sceneId = request.getSceneId();
        if (sceneId == null || sceneId.isEmpty()) {
            log.warn("CurrentSceneContentProvider: sceneId 为空");
            return Mono.just(new ContentResult("", TYPE, id));
        }
        return sceneService.findSceneById(sceneId)
                .map(scene -> new ContentResult(promptXmlFormatter.formatScene(scene), TYPE, id))
                .defaultIfEmpty(new ContentResult("", TYPE, id))
                .onErrorReturn(new ContentResult("", TYPE, id));
    }

    @Override
    public String getType() { return TYPE; }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, java.util.Map<String, Object> parameters) {
        String sceneId = (String) parameters.getOrDefault("sceneId", parameters.get("currentSceneId"));
        if (sceneId == null || sceneId.isEmpty()) return Mono.just("");
        return sceneService.findSceneById(sceneId)
                .map(scene -> promptXmlFormatter.formatScene(scene))
                .onErrorReturn("[场景内容获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        String sceneId = (String) contextParameters.getOrDefault("sceneId", contextParameters.get("currentSceneId"));
        if (sceneId == null || sceneId.isBlank()) return Mono.just(0);
        return sceneService.findSceneById(sceneId)
                .map(scene -> {
                    String content = scene.getContent();
                    if (content == null) return 0;
                    return content.length();
                })
                .defaultIfEmpty(0)
                .onErrorResume(e -> Mono.just(0));
    }
}


