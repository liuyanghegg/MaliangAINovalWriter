package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.NovelSettingService;
import com.ainovel.server.common.util.PromptXmlFormatter;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Flux;
import java.util.Collections;
import lombok.extern.slf4j.Slf4j;

/**
 * 设定项目提供器
 */
@Slf4j
@Component
public class SettingProvider implements ContentProvider {

    @Autowired
    private NovelSettingService novelSettingService;

    @Autowired
    private PromptXmlFormatter promptXmlFormatter;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        // 先判断是否为设定组
        if (id != null && (id.startsWith("setting_group_") || id.startsWith("setting_groups_"))) {
            String groupId = extractIdFromContextId(id);
            return novelSettingService.getSettingGroupById(groupId)
                    .flatMap(group -> Flux.fromIterable(group.getItemIds() != null ? group.getItemIds() : Collections.emptyList())
                            .flatMap(novelSettingService::getSettingItemById)
                            // 设定组下隐藏UUID
                            .map(promptXmlFormatter::formatSettingWithoutId)
                            .collectList()
                            .map(list -> String.join("\n", list))
                            .map(content -> new ContentResult(content, "setting_group", id)))
                    .onErrorReturn(new ContentResult("", "setting_group", id));
        }

        // 按设定类型分组：id形如 type_xxx
        if (id != null && id.startsWith("type_")) {
            String type = id.substring("type_".length());
            return novelSettingService.getNovelSettingItems(request.getNovelId(), type, null, null, null, null, org.springframework.data.domain.Pageable.unpaged())
                    .map(promptXmlFormatter::formatSettingWithoutId)
                    .collectList()
                    .map(list -> String.join("\n", list))
                    .map(content -> new ContentResult(content, "settings_by_type", id))
                    .onErrorReturn(new ContentResult("", "settings_by_type", id));
        }

        // 默认按单个设定项处理
        String settingId = extractIdFromContextId(id);
        return novelSettingService.getSettingItemById(settingId)
                .map(setting -> {
                    String content = promptXmlFormatter.formatSetting(setting);
                    String settingType = setting.getType() != null ? setting.getType().toLowerCase() : "setting";
                    return new ContentResult(content, settingType, id);
                })
                .onErrorReturn(new ContentResult("", "setting", id));
    }

    @Override
    public String getType() { 
        return "setting"; 
    }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, 
                                                 java.util.Map<String, Object> parameters) {
        log.debug("获取设定内容用于占位符: userId={}, novelId={}, contentId={}", userId, novelId, contentId);
        
        // 先尝试作为设定组处理
        // 处理设定类型：id形如 type_xxx
        if (contentId != null && contentId.startsWith("type_")) {
            String type = contentId.substring("type_".length());
            return novelSettingService.getNovelSettingItems(novelId, type, null, null, null, null, org.springframework.data.domain.Pageable.unpaged())
                    .map(promptXmlFormatter::formatSettingWithoutId)
                    .collectList()
                    .map(list -> String.join("\n", list));
        }

        // 处理设定组，支持前缀ID
        String groupIdForLookup = contentId;
        if (groupIdForLookup != null && (groupIdForLookup.startsWith("setting_group_") || groupIdForLookup.startsWith("setting_groups_"))) {
            groupIdForLookup = extractIdFromContextId(groupIdForLookup);
        }

        return novelSettingService.getSettingGroupById(groupIdForLookup)
                .flatMap(group -> Flux.fromIterable(group.getItemIds() != null ? group.getItemIds() : Collections.emptyList())
                        .flatMap(novelSettingService::getSettingItemById)
                        // 设定组下隐藏UUID
                        .map(promptXmlFormatter::formatSettingWithoutId)
                        .collectList()
                        .map(list -> String.join("\n", list)))
                // 如果找不到设定组，则回退到单条设定
                .switchIfEmpty(novelSettingService.getSettingItemById(contentId)
                        .map(promptXmlFormatter::formatSetting))
                .onErrorReturn("[设定内容获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        // 检查是否为设定组
        String settingGroupId = (String) contextParameters.get("settingGroupId");
        if (settingGroupId != null && !settingGroupId.isBlank()) {
            log.debug("获取设定组内容长度: settingGroupId={}", settingGroupId);
            
            return novelSettingService.getSettingGroupById(settingGroupId)
                    .flatMap(group -> {
                        if (group.getItemIds() == null || group.getItemIds().isEmpty()) {
                            return Mono.just(0);
                        }
                        
                        // 获取该组下所有设定项的内容长度并累加
                        return Flux.fromIterable(group.getItemIds())
                                .flatMap(itemId -> novelSettingService.getSettingItemById(itemId)
                                        .map(setting -> {
                                            String description = setting.getDescription();
                                            
                                            int totalLength = 0;
                                            if (description != null && !description.isEmpty()) {
                                                totalLength += description.length();
                                            }
                                            
                                            return totalLength;
                                        })
                                        .onErrorReturn(0)) // 如果设定项获取失败，长度为0
                                .reduce(0, Integer::sum) // 累加所有设定项的长度
                                .doOnNext(totalLength -> log.debug("设定组总内容长度: settingGroupId={}, totalLength={}", settingGroupId, totalLength));
                    })
                    .onErrorResume(error -> {
                        log.error("获取设定组内容长度失败: settingGroupId={}, error={}", settingGroupId, error.getMessage());
                        return Mono.just(0);
                    });
        }
        
        // 检查是否为单个设定项
        String settingId = (String) contextParameters.get("settingId");
        if (settingId != null && !settingId.isBlank()) {
            log.debug("获取设定项内容长度: settingId={}", settingId);
            
            return novelSettingService.getSettingItemById(settingId)
                    .map(setting -> {
                        String description = setting.getDescription();
                        
                        int totalLength = 0;
                        if (description != null && !description.isEmpty()) {
                            totalLength += description.length();
                        }
                        
                        log.debug("设定项内容长度: settingId={}, descriptionLength={}", 
                                settingId, totalLength);
                        
                        return totalLength;
                    })
                    .defaultIfEmpty(0)
                    .onErrorResume(error -> {
                        log.error("获取设定项内容长度失败: settingId={}, error={}", settingId, error.getMessage());
                        return Mono.just(0);
                    });
        }
        
        // 如果没有相关参数，返回0
        log.debug("未找到设定相关参数，返回长度0");
        return Mono.just(0);
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