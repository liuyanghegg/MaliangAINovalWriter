package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.NovelService;
import com.ainovel.server.domain.model.Novel;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

import java.util.Map;

/**
 * 小说基本信息提供器
 * 负责处理小说的基本元信息，如标题、作者、简介、类型等
 */
@Slf4j
@Component
public class NovelBasicInfoProvider implements ContentProvider {

    private static final String TYPE_NOVEL_BASIC_INFO = "novel_basic_info";

    @Autowired
    private NovelService novelService;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        String targetNovelId = id != null ? id : request.getNovelId();
        if (targetNovelId == null || targetNovelId.isEmpty()) {
            log.warn("小说ID为空，无法获取基本信息");
            return Mono.just(new ContentResult("", TYPE_NOVEL_BASIC_INFO, id));
        }
        
        return getNovelBasicInfoContent(targetNovelId)
                .map(content -> new ContentResult(content, TYPE_NOVEL_BASIC_INFO, id))
                .onErrorReturn(new ContentResult("", TYPE_NOVEL_BASIC_INFO, id));
    }

    @Override
    public String getType() { 
        return TYPE_NOVEL_BASIC_INFO; 
    }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, 
                                                 Map<String, Object> parameters) {
        log.debug("获取小说基本信息用于占位符: userId={}, novelId={}", userId, novelId);
        
        if (novelId == null || novelId.isEmpty()) {
            log.warn("novelId为空，无法获取小说基本信息");
            return Mono.just("");
        }
        
        return getNovelBasicInfoContent(novelId)
                .onErrorReturn("[小说基本信息获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(Map<String, Object> contextParameters) {
        String novelId = (String) contextParameters.get("novelId");
        
        if (novelId == null || novelId.isBlank()) {
            return Mono.just(0);
        }
        
        log.debug("获取小说基本信息长度: novelId={}", novelId);
        
        return novelService.findNovelById(novelId)
                .map(novel -> {
                    int totalLength = 0;
                    
                    // 计算各个字段的长度
                    if (novel.getTitle() != null) {
                        totalLength += novel.getTitle().length();
                    }
                    
                    if (novel.getAuthor() != null && novel.getAuthor().getUsername() != null) {
                        totalLength += novel.getAuthor().getUsername().length();
                    }
                    
                    if (novel.getDescription() != null) {
                        totalLength += novel.getDescription().length();
                    }
                    
                    if (novel.getGenre() != null && !novel.getGenre().isEmpty()) {
                        totalLength += String.join(", ", novel.getGenre()).length();
                    }
                    
                    if (novel.getTags() != null && !novel.getTags().isEmpty()) {
                        totalLength += String.join(", ", novel.getTags()).length();
                    }
                    
                    if (novel.getStatus() != null) {
                        totalLength += novel.getStatus().length();
                    }
                    
                    log.debug("小说基本信息总长度: novelId={}, totalLength={}", novelId, totalLength);
                    
                    return totalLength;
                })
                .defaultIfEmpty(0)
                .onErrorResume(error -> {
                    log.error("获取小说基本信息长度失败: novelId={}, error={}", novelId, error.getMessage());
                    return Mono.just(0);
                });
    }

    /**
     * 获取小说基本信息内容
     */
    private Mono<String> getNovelBasicInfoContent(String novelId) {
        return novelService.findNovelById(novelId)
                .map(novel -> {
                    log.info("获取小说基本信息 - ID: {}, 标题: {}", novelId, novel.getTitle());
                    
                    StringBuilder info = new StringBuilder();
                    info.append("=== 小说基本信息 ===\n");
                    info.append("标题: ").append(novel.getTitle() != null ? novel.getTitle() : "未设置").append("\n");
                    
                    if (novel.getAuthor() != null) {
                        info.append("作者: ").append(novel.getAuthor().getUsername() != null ? novel.getAuthor().getUsername() : "未知作者").append("\n");
                    } else {
                        info.append("作者: 未知作者\n");
                    }
                    
                    if (novel.getDescription() != null && !novel.getDescription().trim().isEmpty()) {
                        info.append("简介: ").append(novel.getDescription()).append("\n");
                    }
                    
                    if (novel.getGenre() != null && !novel.getGenre().isEmpty()) {
                        info.append("类型: ").append(String.join(", ", novel.getGenre())).append("\n");
                    }
                    
                    if (novel.getTags() != null && !novel.getTags().isEmpty()) {
                        info.append("标签: ").append(String.join(", ", novel.getTags())).append("\n");
                    }
                    
                    info.append("状态: ").append(novel.getStatus() != null ? novel.getStatus() : "未设置").append("\n");
                    
                    if (novel.getMetadata() != null) {
                        Novel.Metadata metadata = novel.getMetadata();
                        info.append("字数: ").append(metadata.getWordCount()).append("字\n");
                        info.append("版本: ").append(metadata.getVersion()).append("\n");
                    }
                    
                    log.debug("格式化小说基本信息完成，结果长度: {}", info.length());
                    return info.toString();
                })
                .onErrorResume(error -> {
                    log.error("获取小说基本信息失败: novelId={}", novelId, error);
                    return Mono.just("=== 小说基本信息 ===\n获取失败: " + error.getMessage() + "\n");
                });
    }

    /**
     * 获取单个字段值（用于占位符解析）
     */
    public Mono<String> getFieldValue(String novelId, String fieldName) {
        return novelService.findNovelById(novelId)
                .map(novel -> {
                    return switch (fieldName.toLowerCase()) {
                        case "noveltitle", "title" -> novel.getTitle() != null ? novel.getTitle() : "";
                        case "authorname", "author" -> novel.getAuthor() != null && novel.getAuthor().getUsername() != null 
                                                      ? novel.getAuthor().getUsername() : "";
                        case "description" -> novel.getDescription() != null ? novel.getDescription() : "";
                        case "genre" -> novel.getGenre() != null && !novel.getGenre().isEmpty() 
                                       ? String.join(", ", novel.getGenre()) : "";
                        case "tags" -> novel.getTags() != null && !novel.getTags().isEmpty() 
                                      ? String.join(", ", novel.getTags()) : "";
                        case "status" -> novel.getStatus() != null ? novel.getStatus() : "";
                        default -> "";
                    };
                })
                .doOnNext(value -> log.debug("获取小说字段值: novelId={}, field={}, value={}", 
                                           novelId, fieldName, value))
                .onErrorReturn("");
    }
} 