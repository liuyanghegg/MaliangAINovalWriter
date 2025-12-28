package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.SceneService;
import com.ainovel.server.domain.model.Scene;
import com.ainovel.server.common.util.RichTextUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

/**
 * 当前场景摘要提供器
 * 按 sceneId 返回当前场景的摘要信息
 */
@Slf4j
@Component
public class CurrentSceneSummaryProvider implements ContentProvider {

    private static final String TYPE = "current_scene_summary";

    @Autowired
    private SceneService sceneService;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        String sceneId = request.getSceneId();
        if (sceneId == null || sceneId.isEmpty()) {
            log.warn("CurrentSceneSummaryProvider: sceneId 为空");
            return Mono.just(new ContentResult("", TYPE, id));
        }
        return sceneService.findSceneById(sceneId)
                .map(scene -> new ContentResult(buildSceneSummaryXml(scene), TYPE, id))
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
                .map(this::buildSceneSummaryXml)
                .defaultIfEmpty("")
                .onErrorReturn("[场景摘要获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        String sceneId = (String) contextParameters.getOrDefault("sceneId", contextParameters.get("currentSceneId"));
        if (sceneId == null || sceneId.isBlank()) return Mono.just(0);
        return sceneService.findSceneById(sceneId)
                .map(this::estimateSceneSummaryLength)
                .defaultIfEmpty(0)
                .onErrorResume(e -> Mono.just(0));
    }

    private String buildSceneSummaryXml(Scene scene) {
        if (scene == null) return "";
        String summary = extractSceneSummary(scene);
        StringBuilder sb = new StringBuilder();
        sb.append("<current_scene_summary id=\"").append(scene.getId()).append("\">\n");
        sb.append("  <title>").append(scene.getTitle() != null ? scene.getTitle() : "").append("</title>\n");
        sb.append("  <summary>").append(summary != null ? summary : "").append("</summary>\n");
        sb.append("</current_scene_summary>");
        return sb.toString();
    }

    private String extractSceneSummary(Scene scene) {
        if (scene.getSummary() != null && !scene.getSummary().isEmpty()) {
            return RichTextUtil.deltaJsonToPlainText(scene.getSummary());
        }
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




