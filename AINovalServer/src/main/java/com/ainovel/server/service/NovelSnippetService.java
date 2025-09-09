package com.ainovel.server.service;

import org.springframework.data.domain.Pageable;

import com.ainovel.server.domain.model.NovelSnippet;
import com.ainovel.server.domain.model.NovelSnippetHistory;
import com.ainovel.server.web.dto.request.NovelSnippetRequest;
import com.ainovel.server.web.dto.response.NovelSnippetResponse;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 小说片段服务接口
 */
public interface NovelSnippetService {

    /**
     * 创建片段
     */
    Mono<NovelSnippet> createSnippet(String userId, NovelSnippetRequest.Create request);

    /**
     * 获取小说的所有片段（分页）
     */
    Mono<NovelSnippetResponse.PageResult<NovelSnippet>> getSnippetsByNovelId(
            String userId, String novelId, Pageable pageable);

    /**
     * 获取片段详情
     */
    Mono<NovelSnippet> getSnippetDetail(String userId, String snippetId);

    /**
     * 更新片段内容
     */
    Mono<NovelSnippet> updateSnippetContent(String userId, String snippetId, 
            NovelSnippetRequest.UpdateContent request);

    /**
     * 更新片段标题
     */
    Mono<NovelSnippet> updateSnippetTitle(String userId, String snippetId, 
            NovelSnippetRequest.UpdateTitle request);

    /**
     * 收藏/取消收藏片段
     */
    Mono<NovelSnippet> updateSnippetFavorite(String userId, String snippetId, 
            NovelSnippetRequest.UpdateFavorite request);

    /**
     * 获取片段历史记录
     */
    Mono<NovelSnippetResponse.PageResult<NovelSnippetHistory>> getSnippetHistory(
            String userId, String snippetId, Pageable pageable);

    /**
     * 预览历史版本内容
     */
    Mono<NovelSnippetHistory> previewHistoryVersion(String userId, String snippetId, Integer version);

    /**
     * 回退到历史版本（创建新片段）
     */
    Mono<NovelSnippet> revertToHistoryVersion(String userId, String snippetId, 
            NovelSnippetRequest.RevertToVersion request);

    /**
     * 删除片段
     */
    Mono<Void> deleteSnippet(String userId, String snippetId);

    /**
     * 获取用户收藏的片段
     */
    Mono<NovelSnippetResponse.PageResult<NovelSnippet>> getFavoriteSnippets(
            String userId, Pageable pageable);

    /**
     * 搜索片段
     */
    Mono<NovelSnippetResponse.PageResult<NovelSnippet>> searchSnippets(
            String userId, String novelId, String searchText, Pageable pageable);
} 