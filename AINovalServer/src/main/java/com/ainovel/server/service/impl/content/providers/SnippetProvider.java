package com.ainovel.server.service.impl.content.providers;

import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.ContentResult;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.NovelSnippetService;
import com.ainovel.server.common.util.PromptXmlFormatter;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j;

/**
 * 片段提供器
 */
@Slf4j
@Component
public class SnippetProvider implements ContentProvider {

    private static final String TYPE_SNIPPET = "snippet";

    @Autowired
    private NovelSnippetService novelSnippetService;

    @Autowired
    private PromptXmlFormatter promptXmlFormatter;

    @Override
    public Mono<ContentResult> getContent(String id, UniversalAIRequestDto request) {
        String snippetId = extractIdFromContextId(id);
        // 从请求中获取userId，如果没有则使用默认值
        String userId = request.getUserId() != null ? request.getUserId() : "system";
        
        return novelSnippetService.getSnippetDetail(userId, snippetId)
                .map(snippet -> {
                    // 使用XML格式化器生成正确的XML
                    String content = promptXmlFormatter.formatSnippet(snippet);
                    return new ContentResult(content, TYPE_SNIPPET, id);
                })
                .onErrorReturn(new ContentResult("", TYPE_SNIPPET, id));
    }

    @Override
    public String getType() { 
        return TYPE_SNIPPET; 
    }

    @Override
    public Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, 
                                                 java.util.Map<String, Object> parameters) {
        log.debug("获取片段内容用于占位符: userId={}, novelId={}, contentId={}", userId, novelId, contentId);
        
        // contentId就是snippetId
        return novelSnippetService.getSnippetDetail(userId, contentId)
                .map(snippet -> promptXmlFormatter.formatSnippet(snippet))
                .onErrorReturn("[片段内容获取失败]");
    }

    @Override
    public Mono<Integer> getEstimatedContentLength(java.util.Map<String, Object> contextParameters) {
        String snippetId = (String) contextParameters.get("snippetId");
        String userIdParam = (String) contextParameters.get("userId");
        
        if (snippetId == null || snippetId.isBlank()) {
            return Mono.just(0);
        }
        
        // 如果没有提供userId，使用默认值
        final String userId = (userIdParam == null || userIdParam.isBlank()) ? "system" : userIdParam;
        
        log.debug("获取片段内容长度: snippetId={}, userId={}", snippetId, userId);
        
        return novelSnippetService.getSnippetDetail(userId, snippetId)
                .map(snippet -> {
                    String content = snippet.getContent();
                    int contentLength = (content != null) ? content.length() : 0;
                    
                    log.debug("片段内容长度: snippetId={}, contentLength={}", snippetId, contentLength);
                    
                    return contentLength;
                })
                .defaultIfEmpty(0)
                .onErrorResume(error -> {
                    log.error("获取片段内容长度失败: snippetId={}, userId={}, error={}", snippetId, userId, error.getMessage());
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
        
        // 处理格式如：chapter_xxx, scene_xxx, setting_xxx, snippet_xxx
        if (contextId.contains("_")) {
            return contextId.substring(contextId.lastIndexOf("_") + 1);
        }
        
        return contextId;
    }
} 