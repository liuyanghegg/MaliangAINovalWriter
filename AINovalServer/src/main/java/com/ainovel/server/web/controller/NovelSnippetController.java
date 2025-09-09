package com.ainovel.server.web.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

import com.ainovel.server.domain.model.NovelSnippet;
import com.ainovel.server.domain.model.NovelSnippetHistory;
import com.ainovel.server.service.NovelSnippetService;
import com.ainovel.server.web.dto.request.NovelSnippetRequest;
import com.ainovel.server.web.dto.response.NovelSnippetResponse;

import jakarta.validation.Valid;
import reactor.core.publisher.Mono;

/**
 * 小说片段控制器
 */
@RestController
@RequestMapping("/api/v1/novel-snippets")
public class NovelSnippetController {

    private static final Logger logger = LoggerFactory.getLogger(NovelSnippetController.class);

    private final NovelSnippetService snippetService;

    @Autowired
    public NovelSnippetController(NovelSnippetService snippetService) {
        this.snippetService = snippetService;
    }

    /**
     * 创建片段
     */
    @PostMapping("/create")
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<NovelSnippet> createSnippet(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody NovelSnippetRequest.Create request) {
        
        logger.debug("创建片段请求: userId={}, novelId={}", userId, request.getNovelId());
        
        return snippetService.createSnippet(userId, request)
                .doOnError(e -> logger.error("创建片段失败: userId={}, error={}", userId, e.getMessage()));
    }

    /**
     * 获取小说的所有片段（分页）
     */
    @PostMapping("/get-by-novel")
    public Mono<NovelSnippetResponse.PageResult<NovelSnippet>> getSnippetsByNovelId(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody Map<String, Object> request) {
        
        String novelId = (String) request.get("novelId");
        Integer page = (Integer) request.getOrDefault("page", 0);
        Integer size = (Integer) request.getOrDefault("size", 20);
        
        logger.debug("获取小说片段列表: userId={}, novelId={}, page={}, size={}", userId, novelId, page, size);
        
        Pageable pageable = PageRequest.of(page, size);
        
        return snippetService.getSnippetsByNovelId(userId, novelId, pageable)
                .doOnError(e -> logger.error("获取片段列表失败: userId={}, novelId={}, error={}", 
                        userId, novelId, e.getMessage()));
    }

    /**
     * 获取片段详情
     */
    @PostMapping("/get-detail")
    public Mono<NovelSnippet> getSnippetDetail(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody Map<String, String> request) {
        
        String snippetId = request.get("snippetId");
        logger.debug("获取片段详情: userId={}, snippetId={}", userId, snippetId);
        
        return snippetService.getSnippetDetail(userId, snippetId)
                .doOnError(e -> logger.error("获取片段详情失败: userId={}, snippetId={}, error={}", 
                        userId, snippetId, e.getMessage()));
    }

    /**
     * 更新片段内容
     */
    @PostMapping("/update-content")
    public Mono<NovelSnippet> updateSnippetContent(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody NovelSnippetRequest.UpdateContent request) {
        
        logger.debug("更新片段内容: userId={}, snippetId={}", userId, request.getSnippetId());
        
        return snippetService.updateSnippetContent(userId, request.getSnippetId(), request)
                .doOnError(e -> logger.error("更新片段内容失败: userId={}, snippetId={}, error={}", 
                        userId, request.getSnippetId(), e.getMessage()));
    }

    /**
     * 更新片段标题
     */
    @PostMapping("/update-title")
    public Mono<NovelSnippet> updateSnippetTitle(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody NovelSnippetRequest.UpdateTitle request) {
        
        logger.debug("更新片段标题: userId={}, snippetId={}", userId, request.getSnippetId());
        
        return snippetService.updateSnippetTitle(userId, request.getSnippetId(), request)
                .doOnError(e -> logger.error("更新片段标题失败: userId={}, snippetId={}, error={}", 
                        userId, request.getSnippetId(), e.getMessage()));
    }

    /**
     * 收藏/取消收藏片段
     */
    @PostMapping("/update-favorite")
    public Mono<NovelSnippet> updateSnippetFavorite(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody NovelSnippetRequest.UpdateFavorite request) {
        
        logger.debug("更新片段收藏状态: userId={}, snippetId={}, isFavorite={}", 
                userId, request.getSnippetId(), request.getIsFavorite());
        
        return snippetService.updateSnippetFavorite(userId, request.getSnippetId(), request)
                .doOnError(e -> logger.error("更新片段收藏状态失败: userId={}, snippetId={}, error={}", 
                        userId, request.getSnippetId(), e.getMessage()));
    }

    /**
     * 获取片段历史记录
     */
    @PostMapping("/get-history")
    public Mono<NovelSnippetResponse.PageResult<NovelSnippetHistory>> getSnippetHistory(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody Map<String, Object> request) {
        
        String snippetId = (String) request.get("snippetId");
        Integer page = (Integer) request.getOrDefault("page", 0);
        Integer size = (Integer) request.getOrDefault("size", 10);
        
        logger.debug("获取片段历史记录: userId={}, snippetId={}, page={}, size={}", 
                userId, snippetId, page, size);
        
        Pageable pageable = PageRequest.of(page, size);
        
        return snippetService.getSnippetHistory(userId, snippetId, pageable)
                .doOnError(e -> logger.error("获取片段历史记录失败: userId={}, snippetId={}, error={}", 
                        userId, snippetId, e.getMessage()));
    }

    /**
     * 预览历史版本内容
     */
    @PostMapping("/preview-history")
    public Mono<NovelSnippetHistory> previewHistoryVersion(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody Map<String, Object> request) {
        
        String snippetId = (String) request.get("snippetId");
        Integer version = (Integer) request.get("version");
        
        logger.debug("预览历史版本: userId={}, snippetId={}, version={}", userId, snippetId, version);
        
        return snippetService.previewHistoryVersion(userId, snippetId, version)
                .doOnError(e -> logger.error("预览历史版本失败: userId={}, snippetId={}, version={}, error={}", 
                        userId, snippetId, version, e.getMessage()));
    }

    /**
     * 回退到历史版本（创建新片段）
     */
    @PostMapping("/revert-to-version")
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<NovelSnippet> revertToHistoryVersion(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody NovelSnippetRequest.RevertToVersion request) {
        
        logger.debug("回退到历史版本: userId={}, snippetId={}, version={}", 
                userId, request.getSnippetId(), request.getVersion());
        
        return snippetService.revertToHistoryVersion(userId, request.getSnippetId(), request)
                .doOnError(e -> logger.error("版本回退失败: userId={}, snippetId={}, version={}, error={}", 
                        userId, request.getSnippetId(), request.getVersion(), e.getMessage()));
    }

    /**
     * 删除片段
     */
    @PostMapping("/delete")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteSnippet(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody Map<String, String> request) {
        
        String snippetId = request.get("snippetId");
        logger.debug("删除片段: userId={}, snippetId={}", userId, snippetId);
        
        return snippetService.deleteSnippet(userId, snippetId)
                .doOnError(e -> logger.error("删除片段失败: userId={}, snippetId={}, error={}", 
                        userId, snippetId, e.getMessage()));
    }

    /**
     * 获取用户收藏的片段
     */
    @PostMapping("/get-favorites")
    public Mono<NovelSnippetResponse.PageResult<NovelSnippet>> getFavoriteSnippets(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody Map<String, Object> request) {
        
        Integer page = (Integer) request.getOrDefault("page", 0);
        Integer size = (Integer) request.getOrDefault("size", 20);
        
        logger.debug("获取收藏片段: userId={}, page={}, size={}", userId, page, size);
        
        Pageable pageable = PageRequest.of(page, size);
        
        return snippetService.getFavoriteSnippets(userId, pageable)
                .doOnError(e -> logger.error("获取收藏片段失败: userId={}, error={}", userId, e.getMessage()));
    }

    /**
     * 搜索片段
     */
    @PostMapping("/search")
    public Mono<NovelSnippetResponse.PageResult<NovelSnippet>> searchSnippets(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody Map<String, Object> request) {
        
        String novelId = (String) request.get("novelId");
        String searchText = (String) request.get("searchText");
        Integer page = (Integer) request.getOrDefault("page", 0);
        Integer size = (Integer) request.getOrDefault("size", 20);
        
        logger.debug("搜索片段: userId={}, novelId={}, searchText={}", userId, novelId, searchText);
        
        Pageable pageable = PageRequest.of(page, size);
        
        return snippetService.searchSnippets(userId, novelId, searchText, pageable)
                .doOnError(e -> logger.error("搜索片段失败: userId={}, novelId={}, searchText={}, error={}", 
                        userId, novelId, searchText, e.getMessage()));
    }
} 