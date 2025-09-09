package com.ainovel.server.service.impl;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ainovel.server.domain.model.NovelSnippet;
import com.ainovel.server.domain.model.NovelSnippetHistory;
import com.ainovel.server.repository.NovelSnippetHistoryRepository;
import com.ainovel.server.repository.NovelSnippetRepository;
import com.ainovel.server.service.NovelSnippetService;
import com.ainovel.server.web.dto.request.NovelSnippetRequest;
import com.ainovel.server.web.dto.response.NovelSnippetResponse;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 小说片段服务实现类
 */
@Service
@Transactional
public class NovelSnippetServiceImpl implements NovelSnippetService {

    private static final Logger logger = LoggerFactory.getLogger(NovelSnippetServiceImpl.class);

    private final NovelSnippetRepository snippetRepository;
    private final NovelSnippetHistoryRepository historyRepository;

    @Autowired
    public NovelSnippetServiceImpl(
            NovelSnippetRepository snippetRepository,
            NovelSnippetHistoryRepository historyRepository) {
        this.snippetRepository = snippetRepository;
        this.historyRepository = historyRepository;
    }

    @Override
    public Mono<NovelSnippet> createSnippet(String userId, NovelSnippetRequest.Create request) {
        logger.debug("创建片段: userId={}, novelId={}, title={}", userId, request.getNovelId(), request.getTitle());

        NovelSnippet snippet = NovelSnippet.builder()
                .userId(userId)
                .novelId(request.getNovelId())
                .title(request.getTitle())
                .content(request.getContent())
                .initialGenerationInfo(NovelSnippet.InitialGenerationInfo.builder()
                        .sourceChapterId(request.getSourceChapterId())
                        .sourceSceneId(request.getSourceSceneId())
                        .build())
                .tags(request.getTags() != null ? request.getTags() : new ArrayList<>())
                .category(request.getCategory())
                .notes(request.getNotes())
                .metadata(NovelSnippet.SnippetMetadata.builder()
                        .wordCount(calculateWordCount(request.getContent()))
                        .characterCount(request.getContent() != null ? request.getContent().length() : 0)
                        .viewCount(0)
                        .sortWeight(0)
                        .build())
                .isFavorite(false)
                .status("ACTIVE")
                .version(1)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        return snippetRepository.save(snippet)
                .flatMap(savedSnippet -> {
                    // 创建历史记录
                    NovelSnippetHistory history = createHistoryRecord(savedSnippet, "CREATE", null, null, "创建片段");
                    return historyRepository.save(history)
                            .thenReturn(savedSnippet);
                })
                .doOnSuccess(s -> logger.debug("片段创建成功: id={}", s.getId()))
                .doOnError(e -> logger.error("片段创建失败: userId={}, error={}", userId, e.getMessage()));
    }

    @Override
    public Mono<NovelSnippetResponse.PageResult<NovelSnippet>> getSnippetsByNovelId(
            String userId, String novelId, Pageable pageable) {
        logger.debug("获取小说片段列表: userId={}, novelId={}, page={}", userId, novelId, pageable.getPageNumber());

        // 确保按创建时间倒序排列
        Pageable sortedPageable = PageRequest.of(
                pageable.getPageNumber(),
                pageable.getPageSize(),
                Sort.by(Sort.Direction.DESC, "createdAt")
        );

        return snippetRepository.findByUserIdAndNovelIdAndStatusActive(userId, novelId, sortedPageable)
                .collectList()
                .zipWith(snippetRepository.countByUserIdAndNovelIdAndStatusActive(userId, novelId))
                .map(tuple -> {
                    List<NovelSnippet> content = tuple.getT1();
                    long totalElements = tuple.getT2();
                    int totalPages = (int) Math.ceil((double) totalElements / pageable.getPageSize());

                    return NovelSnippetResponse.PageResult.<NovelSnippet>builder()
                            .content(content)
                            .page(pageable.getPageNumber())
                            .size(pageable.getPageSize())
                            .totalElements(totalElements)
                            .totalPages(totalPages)
                            .hasNext(pageable.getPageNumber() < totalPages - 1)
                            .hasPrevious(pageable.getPageNumber() > 0)
                            .build();
                });
    }

    @Override
    public Mono<NovelSnippet> getSnippetDetail(String userId, String snippetId) {
        logger.debug("获取片段详情: userId={}, snippetId={}", userId, snippetId);

        return snippetRepository.findByIdAndUserId(snippetId, userId)
                .switchIfEmpty(Mono.error(new RuntimeException("片段不存在或无权限访问")))
                .flatMap(snippet -> {
                    // 增加浏览次数
                    snippet.getMetadata().setViewCount(snippet.getMetadata().getViewCount() + 1);
                    snippet.getMetadata().setLastViewedAt(LocalDateTime.now());
                    snippet.setUpdatedAt(LocalDateTime.now());
                    
                    return snippetRepository.save(snippet);
                });
    }

    @Override
    public Mono<NovelSnippet> updateSnippetContent(String userId, String snippetId, 
            NovelSnippetRequest.UpdateContent request) {
        logger.debug("更新片段内容: userId={}, snippetId={}", userId, snippetId);

        return snippetRepository.findByIdAndUserId(snippetId, userId)
                .switchIfEmpty(Mono.error(new RuntimeException("片段不存在或无权限访问")))
                .flatMap(snippet -> {
                    String oldContent = snippet.getContent();
                    
                    // 更新内容和版本
                    snippet.setContent(request.getContent());
                    snippet.setVersion(snippet.getVersion() + 1);
                    snippet.setUpdatedAt(LocalDateTime.now());
                    
                    // 更新元数据
                    snippet.getMetadata().setWordCount(calculateWordCount(request.getContent()));
                    snippet.getMetadata().setCharacterCount(request.getContent().length());

                    return snippetRepository.save(snippet)
                            .flatMap(savedSnippet -> {
                                // 创建历史记录
                                NovelSnippetHistory history = createHistoryRecord(
                                        savedSnippet, "UPDATE_CONTENT", 
                                        snippet.getTitle(), snippet.getTitle(),
                                        oldContent, request.getContent(),
                                        request.getChangeDescription() != null 
                                                ? request.getChangeDescription() 
                                                : "更新片段内容"
                                );
                                return historyRepository.save(history)
                                        .thenReturn(savedSnippet);
                            });
                });
    }

    @Override
    public Mono<NovelSnippet> updateSnippetTitle(String userId, String snippetId, 
            NovelSnippetRequest.UpdateTitle request) {
        logger.debug("更新片段标题: userId={}, snippetId={}", userId, snippetId);

        return snippetRepository.findByIdAndUserId(snippetId, userId)
                .switchIfEmpty(Mono.error(new RuntimeException("片段不存在或无权限访问")))
                .flatMap(snippet -> {
                    String oldTitle = snippet.getTitle();
                    
                    // 更新标题和版本
                    snippet.setTitle(request.getTitle());
                    snippet.setVersion(snippet.getVersion() + 1);
                    snippet.setUpdatedAt(LocalDateTime.now());

                    return snippetRepository.save(snippet)
                            .flatMap(savedSnippet -> {
                                // 创建历史记录
                                NovelSnippetHistory history = createHistoryRecord(
                                        savedSnippet, "UPDATE_TITLE",
                                        oldTitle, request.getTitle(),
                                        snippet.getContent(), snippet.getContent(),
                                        request.getChangeDescription() != null 
                                                ? request.getChangeDescription() 
                                                : "更新片段标题"
                                );
                                return historyRepository.save(history)
                                        .thenReturn(savedSnippet);
                            });
                });
    }

    @Override
    public Mono<NovelSnippet> updateSnippetFavorite(String userId, String snippetId, 
            NovelSnippetRequest.UpdateFavorite request) {
        logger.debug("更新片段收藏状态: userId={}, snippetId={}, isFavorite={}", 
                userId, snippetId, request.getIsFavorite());

        return snippetRepository.findByIdAndUserId(snippetId, userId)
                .switchIfEmpty(Mono.error(new RuntimeException("片段不存在或无权限访问")))
                .flatMap(snippet -> {
                    boolean oldFavorite = snippet.getIsFavorite();
                    
                    snippet.setIsFavorite(request.getIsFavorite());
                    snippet.setUpdatedAt(LocalDateTime.now());

                    return snippetRepository.save(snippet)
                            .flatMap(savedSnippet -> {
                                // 创建历史记录
                                String operationType = request.getIsFavorite() ? "FAVORITE" : "UNFAVORITE";
                                NovelSnippetHistory history = createHistoryRecord(
                                        savedSnippet, operationType,
                                        snippet.getTitle(), snippet.getTitle(),
                                        snippet.getContent(), snippet.getContent(),
                                        request.getIsFavorite() ? "收藏片段" : "取消收藏片段"
                                );
                                return historyRepository.save(history)
                                        .thenReturn(savedSnippet);
                            });
                });
    }

    @Override
    public Mono<NovelSnippetResponse.PageResult<NovelSnippetHistory>> getSnippetHistory(
            String userId, String snippetId, Pageable pageable) {
        logger.debug("获取片段历史记录: userId={}, snippetId={}", userId, snippetId);

        // 首先验证权限
        return snippetRepository.findByIdAndUserId(snippetId, userId)
                .switchIfEmpty(Mono.error(new RuntimeException("片段不存在或无权限访问")))
                .flatMap(snippet -> {
                    Pageable sortedPageable = PageRequest.of(
                            pageable.getPageNumber(),
                            pageable.getPageSize(),
                            Sort.by(Sort.Direction.DESC, "createdAt")
                    );

                    return historyRepository.findBySnippetIdAndUserId(snippetId, userId, sortedPageable)
                            .collectList()
                            .zipWith(historyRepository.countBySnippetId(snippetId))
                            .map(tuple -> {
                                List<NovelSnippetHistory> content = tuple.getT1();
                                long totalElements = tuple.getT2();
                                int totalPages = (int) Math.ceil((double) totalElements / pageable.getPageSize());

                                return NovelSnippetResponse.PageResult.<NovelSnippetHistory>builder()
                                        .content(content)
                                        .page(pageable.getPageNumber())
                                        .size(pageable.getPageSize())
                                        .totalElements(totalElements)
                                        .totalPages(totalPages)
                                        .hasNext(pageable.getPageNumber() < totalPages - 1)
                                        .hasPrevious(pageable.getPageNumber() > 0)
                                        .build();
                            });
                });
    }

    @Override
    public Mono<NovelSnippetHistory> previewHistoryVersion(String userId, String snippetId, Integer version) {
        logger.debug("预览历史版本: userId={}, snippetId={}, version={}", userId, snippetId, version);

        // 首先验证权限
        return snippetRepository.findByIdAndUserId(snippetId, userId)
                .switchIfEmpty(Mono.error(new RuntimeException("片段不存在或无权限访问")))
                .flatMap(snippet -> historyRepository.findBySnippetIdAndVersion(snippetId, version)
                        .switchIfEmpty(Mono.error(new RuntimeException("指定版本不存在"))));
    }

    @Override
    public Mono<NovelSnippet> revertToHistoryVersion(String userId, String snippetId, 
            NovelSnippetRequest.RevertToVersion request) {
        logger.debug("回退到历史版本: userId={}, snippetId={}, version={}", 
                userId, snippetId, request.getVersion());

        // 首先验证权限和获取原片段
        return snippetRepository.findByIdAndUserId(snippetId, userId)
                .switchIfEmpty(Mono.error(new RuntimeException("片段不存在或无权限访问")))
                .flatMap(originalSnippet -> 
                        historyRepository.findBySnippetIdAndVersion(snippetId, request.getVersion())
                                .switchIfEmpty(Mono.error(new RuntimeException("指定版本不存在")))
                                .flatMap(historyVersion -> {
                                    // 创建新片段，基于历史版本的内容
                                    NovelSnippet newSnippet = NovelSnippet.builder()
                                            .userId(userId)
                                            .novelId(originalSnippet.getNovelId())
                                            .title(historyVersion.getAfterTitle() + " (回退副本)")
                                            .content(historyVersion.getAfterContent())
                                            .initialGenerationInfo(originalSnippet.getInitialGenerationInfo())
                                            .tags(originalSnippet.getTags())
                                            .category(originalSnippet.getCategory())
                                            .notes("从版本 " + request.getVersion() + " 回退创建")
                                            .metadata(NovelSnippet.SnippetMetadata.builder()
                                                    .wordCount(calculateWordCount(historyVersion.getAfterContent()))
                                                    .characterCount(historyVersion.getAfterContent() != null 
                                                            ? historyVersion.getAfterContent().length() : 0)
                                                    .viewCount(0)
                                                    .sortWeight(0)
                                                    .build())
                                            .isFavorite(false)
                                            .status("ACTIVE")
                                            .version(1)
                                            .createdAt(LocalDateTime.now())
                                            .updatedAt(LocalDateTime.now())
                                            .build();

                                    return snippetRepository.save(newSnippet)
                                            .flatMap(savedSnippet -> {
                                                // 创建历史记录
                                                NovelSnippetHistory history = createHistoryRecord(
                                                        savedSnippet, "REVERT",
                                                        null, savedSnippet.getTitle(),
                                                        null, savedSnippet.getContent(),
                                                        request.getChangeDescription() != null 
                                                                ? request.getChangeDescription() 
                                                                : "从版本 " + request.getVersion() + " 回退创建新片段"
                                                );
                                                return historyRepository.save(history)
                                                        .thenReturn(savedSnippet);
                                            });
                                })
                );
    }

    @Override
    public Mono<Void> deleteSnippet(String userId, String snippetId) {
        logger.debug("删除片段: userId={}, snippetId={}", userId, snippetId);

        return snippetRepository.findByIdAndUserId(snippetId, userId)
                .switchIfEmpty(Mono.error(new RuntimeException("片段不存在或无权限访问")))
                .flatMap(snippet -> {
                    // 软删除：更新状态为DELETED
                    snippet.setStatus("DELETED");
                    snippet.setUpdatedAt(LocalDateTime.now());
                    
                    return snippetRepository.save(snippet)
                            .flatMap(savedSnippet -> {
                                // 创建历史记录
                                NovelSnippetHistory history = createHistoryRecord(
                                        savedSnippet, "DELETE",
                                        snippet.getTitle(), null,
                                        snippet.getContent(), null,
                                        "删除片段"
                                );
                                return historyRepository.save(history);
                            })
                            .then();
                });
    }

    @Override
    public Mono<NovelSnippetResponse.PageResult<NovelSnippet>> getFavoriteSnippets(
            String userId, Pageable pageable) {
        logger.debug("获取收藏片段: userId={}, page={}", userId, pageable.getPageNumber());

        Pageable sortedPageable = PageRequest.of(
                pageable.getPageNumber(),
                pageable.getPageSize(),
                Sort.by(Sort.Direction.DESC, "updatedAt")
        );

        return snippetRepository.findFavoritesByUserId(userId, sortedPageable)
                .collectList()
                .zipWith(snippetRepository.countFavoritesByUserId(userId))
                .map(tuple -> {
                    List<NovelSnippet> content = tuple.getT1();
                    long totalElements = tuple.getT2();
                    int totalPages = (int) Math.ceil((double) totalElements / pageable.getPageSize());

                    return NovelSnippetResponse.PageResult.<NovelSnippet>builder()
                            .content(content)
                            .page(pageable.getPageNumber())
                            .size(pageable.getPageSize())
                            .totalElements(totalElements)
                            .totalPages(totalPages)
                            .hasNext(pageable.getPageNumber() < totalPages - 1)
                            .hasPrevious(pageable.getPageNumber() > 0)
                            .build();
                });
    }

    @Override
    public Mono<NovelSnippetResponse.PageResult<NovelSnippet>> searchSnippets(
            String userId, String novelId, String searchText, Pageable pageable) {
        logger.debug("搜索片段: userId={}, novelId={}, searchText={}", userId, novelId, searchText);

        return snippetRepository.findByUserIdAndNovelIdAndFullTextSearch(userId, novelId, searchText, pageable)
                .collectList()
                .map(content -> NovelSnippetResponse.PageResult.<NovelSnippet>builder()
                        .content(content)
                        .page(pageable.getPageNumber())
                        .size(pageable.getPageSize())
                        .totalElements(content.size())
                        .totalPages(1)  // 搜索结果暂时不支持精确分页
                        .hasNext(false)
                        .hasPrevious(false)
                        .build());
    }

    /**
     * 创建历史记录
     */
    private NovelSnippetHistory createHistoryRecord(NovelSnippet snippet, String operationType, 
            String beforeTitle, String afterTitle, String changeDescription) {
        return createHistoryRecord(snippet, operationType, beforeTitle, afterTitle, 
                snippet.getContent(), snippet.getContent(), changeDescription);
    }

    /**
     * 创建历史记录（完整版本）
     */
    private NovelSnippetHistory createHistoryRecord(NovelSnippet snippet, String operationType,
            String beforeTitle, String afterTitle, String beforeContent, String afterContent, 
            String changeDescription) {
        return NovelSnippetHistory.builder()
                .snippetId(snippet.getId())
                .userId(snippet.getUserId())
                .operationType(operationType)
                .version(snippet.getVersion())
                .beforeTitle(beforeTitle)
                .afterTitle(afterTitle)
                .beforeContent(beforeContent)
                .afterContent(afterContent)
                .changeDescription(changeDescription)
                .createdAt(LocalDateTime.now())
                .build();
    }

    /**
     * 计算字数（简单实现，按非空白字符计算）
     */
    private Integer calculateWordCount(String content) {
        if (content == null || content.trim().isEmpty()) {
            return 0;
        }
        // 移除空白字符后计算字符数作为字数
        return content.replaceAll("\\s+", "").length();
    }

    /**
     * 🚀 新增：获取片段内容（用于上下文）
     */
    public Mono<String> getSnippetContentForContext(String snippetId) {
        return snippetRepository.findById(snippetId)
                .map(snippet -> {
                    StringBuilder context = new StringBuilder();
                    context.append("=== 片段内容 ===\n");
                    context.append("标题: ").append(snippet.getTitle()).append("\n");
                    
                    if (snippet.getNotes() != null && !snippet.getNotes().isEmpty()) {
                        context.append("备注: ").append(snippet.getNotes()).append("\n");
                    }
                    
                    if (snippet.getContent() != null) {
                        String content = snippet.getContent();
                        // 限制内容长度，避免提示词过长
                        if (content.length() > 2000) {
                            content = content.substring(0, 2000) + "...";
                        }
                        context.append("内容: ").append(content).append("\n");
                    }
                    
                    if (snippet.getTags() != null && !snippet.getTags().isEmpty()) {
                        context.append("标签: ").append(String.join(", ", snippet.getTags())).append("\n");
                    }
                    
                    return context.toString();
                })
                .onErrorReturn("=== 片段内容 ===\n片段ID: " + snippetId + "\n（无法获取片段内容）");
    }


} 