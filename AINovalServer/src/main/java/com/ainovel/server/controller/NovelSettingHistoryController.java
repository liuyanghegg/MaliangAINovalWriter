package com.ainovel.server.controller;

import com.ainovel.server.domain.model.NovelSettingGenerationHistory;
import com.ainovel.server.domain.model.NovelSettingItemHistory;
import com.ainovel.server.domain.model.setting.generation.SettingGenerationSession;
import com.ainovel.server.security.CurrentUser;
import com.ainovel.server.service.setting.NovelSettingHistoryService;
import com.ainovel.server.service.setting.generation.ISettingGenerationService;
import com.ainovel.server.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;
import java.util.Map;

/**
 * 设定生成历史记录控制器
 * 
 * 设定历史记录管理说明：
 * 1. 设定历史记录与小说无关，与用户有关 - 历史记录是按用户维度管理的
 * 2. 小说与历史记录的关系：
 *    - 当用户进入小说设定生成页面时，如果没有历史记录，会创建一个历史记录，收集当前小说的设定作为快照
 *    - 用户从小说列表页面发起提示词生成设定请求，生成完后会自动生成一个历史记录
 * 3. 历史记录相当于小说设定的快照，供用户修改和版本管理
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/setting-histories")
@RequiredArgsConstructor
@Tag(name = "设定生成历史记录管理", description = "管理用户的设定生成历史记录")
public class NovelSettingHistoryController {

    private final NovelSettingHistoryService historyService;
    private final ISettingGenerationService settingGenerationService;

    /**
     * 获取用户的设定生成历史记录列表
     */
    @GetMapping
    @Operation(summary = "获取历史记录列表", description = "获取当前用户的所有设定生成历史记录 (仅返回概要信息，减少数据量)")
    public Flux<Map<String, Object>> getHistories(
            @Parameter(description = "页码") @RequestParam(defaultValue = "0") int page,
            @Parameter(description = "每页大小") @RequestParam(defaultValue = "20") int size,
            @Parameter(description = "小说ID过滤（可选）") @RequestParam(required = false) String novelId,
            @AuthenticationPrincipal CurrentUser currentUser) {

        log.info("获取用户 {} 的历史记录列表，小说过滤: {}", currentUser.getId(), novelId);
        
        Pageable pageable = PageRequest.of(page, size);
        return historyService.getUserHistories(currentUser.getId(), novelId, pageable)
                .map(history -> {
                    // 只返回概要信息，避免大字段导致的超时与带宽浪费
                    Map<String, Object> summary = new java.util.HashMap<>();
                    summary.put("sessionId", history.getHistoryId()); // 兼容前端现有解析逻辑
                    summary.put("historyId", history.getHistoryId());
                    summary.put("userId", history.getUserId());
                    summary.put("novelId", history.getNovelId());
                    summary.put("initialPrompt", history.getInitialPrompt());
                    summary.put("strategy", history.getStrategy());
                    summary.put("modelConfigId", history.getModelConfigId());
                    summary.put("status", history.getStatus() != null ? history.getStatus().name() : null);
                    summary.put("settingsCount", history.getSettingsCount());
                    summary.put("title", history.getTitle());
                    summary.put("description", history.getDescription());
                    if (history.getCreatedAt() != null) {
                        summary.put("createdAt", history.getCreatedAt().toString());
                    }
                    if (history.getUpdatedAt() != null) {
                        summary.put("updatedAt", history.getUpdatedAt().toString());
                    }
                    summary.put("metadata", history.getMetadata());
                    return summary;
                });
    }

    /**
     * 获取历史记录详情
     */
    @GetMapping("/{historyId}")
    @Operation(summary = "获取历史记录详情", description = "获取指定历史记录的详细信息")
    public Mono<ApiResponse<Map<String, Object>>> getHistory(
            @Parameter(description = "历史记录ID") @PathVariable String historyId,
            @AuthenticationPrincipal CurrentUser currentUser) {

        log.info("获取历史记录详情: {} by user: {}", historyId, currentUser.getId());
        
        return historyService.getHistoryWithSettings(historyId)
                .map(historyWithSettings -> {
                    // 构建返回给前端的数据结构
                    Map<String, Object> response = new java.util.HashMap<>();
                    response.put("history", historyWithSettings.history());
                    response.put("rootNodes", historyWithSettings.rootNodes());
                    
                    return ApiResponse.<Map<String, Object>>success(response);
                })
                .onErrorResume(error -> {
                    log.error("获取历史记录详情失败", error);
                    return Mono.just(ApiResponse.<Map<String, Object>>error("HISTORY_NOT_FOUND", error.getMessage()));
                });
    }

    /**
     * 从历史记录创建新的编辑会话
     */
    @PostMapping("/{historyId}/edit")
    @Operation(summary = "编辑历史记录", description = "基于历史记录创建新的编辑会话")
    public Mono<ApiResponse<SessionCreatedResponse>> createEditSession(
            @Parameter(description = "历史记录ID") @PathVariable String historyId,
            @Valid @RequestBody CreateEditSessionRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        log.info("从历史记录 {} 创建编辑会话 by user: {}", historyId, currentUser.getId());
        
        return settingGenerationService.startSessionFromHistory(
                historyId, 
                request.getEditReason(), 
                request.getModelConfigId()
        ).map(session -> {
            SessionCreatedResponse response = new SessionCreatedResponse();
            response.setSessionId(session.getSessionId());
            response.setMessage("编辑会话创建成功");
            return ApiResponse.<SessionCreatedResponse>success(response);
        }).onErrorResume(error -> {
            log.error("创建编辑会话失败", error);
            return Mono.just(ApiResponse.<SessionCreatedResponse>error("SESSION_CREATE_FAILED", error.getMessage()));
        });
    }

    /**
     * 复制历史记录
     */
    @PostMapping("/{historyId}/copy")
    @Operation(summary = "复制历史记录", description = "复制现有历史记录创建新的历史记录")
    public Mono<ApiResponse<NovelSettingGenerationHistory>> copyHistory(
            @Parameter(description = "历史记录ID") @PathVariable String historyId,
            @Valid @RequestBody CopyHistoryRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        log.info("复制历史记录 {} by user: {}", historyId, currentUser.getId());
        
        return historyService.copyHistory(historyId, request.getCopyReason(), currentUser.getId())
                .map(history -> ApiResponse.<NovelSettingGenerationHistory>success(history))
                .onErrorResume(error -> {
                    log.error("复制历史记录失败", error);
                    return Mono.just(ApiResponse.<NovelSettingGenerationHistory>error("COPY_FAILED", error.getMessage()));
                });
    }

    /**
     * 恢复历史记录到小说设定中
     */
    @PostMapping("/{historyId}/restore")
    @Operation(summary = "恢复历史记录", description = "将历史记录中的设定恢复到指定小说设定中")
    public Mono<ApiResponse<RestoreResponse>> restoreHistory(
            @Parameter(description = "历史记录ID") @PathVariable String historyId,
            @Valid @RequestBody RestoreHistoryRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        log.info("恢复历史记录 {} to novel {} by user: {}", historyId, request.getNovelId(), currentUser.getId());
        
        return historyService.restoreHistoryToNovel(historyId, request.getNovelId(), currentUser.getId())
                .map(settingIds -> {
                    RestoreResponse response = new RestoreResponse();
                    response.setSuccess(true);
                    response.setMessage("历史记录恢复成功");
                    response.setRestoredSettingIds(settingIds);
                    return ApiResponse.<RestoreResponse>success(response);
                })
                .onErrorResume(error -> {
                    log.error("恢复历史记录失败", error);
                    return Mono.just(ApiResponse.<RestoreResponse>error("RESTORE_FAILED", error.getMessage()));
                });
    }

    /**
     * 删除历史记录
     */
    @DeleteMapping("/{historyId}")
    @Operation(summary = "删除历史记录", description = "删除指定的历史记录")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteHistory(
            @Parameter(description = "历史记录ID") @PathVariable String historyId,
            @AuthenticationPrincipal CurrentUser currentUser) {

        log.info("删除历史记录 {} by user: {}", historyId, currentUser.getId());
        
        return historyService.deleteHistory(historyId, currentUser.getId());
    }

    /**
     * 获取节点历史记录
     */
    @GetMapping("/{historyId}/nodes/{nodeId}/history")
    @Operation(summary = "获取节点历史记录", description = "获取指定设定节点的变更历史")
    public Flux<NovelSettingItemHistory> getNodeHistory(
            @Parameter(description = "历史记录ID") @PathVariable String historyId,
            @Parameter(description = "节点ID") @PathVariable String nodeId,
            @Parameter(description = "页码") @RequestParam(defaultValue = "0") int page,
            @Parameter(description = "每页大小") @RequestParam(defaultValue = "10") int size,
            @AuthenticationPrincipal CurrentUser currentUser) {

        log.info("获取节点 {} 的历史记录 by user: {}", nodeId, currentUser.getId());
        
        Pageable pageable = PageRequest.of(page, size);
        return historyService.getNodeHistories(nodeId, pageable);
    }

    /**
     * 统计历史记录数量
     */
    @GetMapping("/count")
    @Operation(summary = "统计历史记录数量", description = "统计用户的历史记录数量")
    public Mono<ApiResponse<Long>> countHistories(
            @Parameter(description = "小说ID过滤（可选）") @RequestParam(required = false) String novelId,
            @AuthenticationPrincipal CurrentUser currentUser) {

        return historyService.countUserHistories(currentUser.getId(), novelId)
                .map(count -> ApiResponse.<Long>success(count));
    }

    /**
     * 批量删除历史记录
     */
    @DeleteMapping("/batch")
    @Operation(summary = "批量删除历史记录", description = "批量删除指定的历史记录")
    public Mono<ApiResponse<BatchDeleteResponse>> batchDeleteHistories(
            @Valid @RequestBody BatchDeleteRequest request,
            @AuthenticationPrincipal CurrentUser currentUser) {

        log.info("批量删除历史记录 {} by user: {}", request.getHistoryIds(), currentUser.getId());
        
        return historyService.batchDeleteHistories(request.getHistoryIds(), currentUser.getId())
                .map(deletedCount -> {
                    BatchDeleteResponse response = new BatchDeleteResponse();
                    response.setDeletedCount(deletedCount);
                    response.setMessage("成功删除 " + deletedCount + " 条历史记录");
                    return ApiResponse.<BatchDeleteResponse>success(response);
                })
                .onErrorResume(error -> {
                    log.error("批量删除历史记录失败", error);
                    return Mono.just(ApiResponse.<BatchDeleteResponse>error("BATCH_DELETE_FAILED", error.getMessage()));
                });
    }

    // ==================== DTO 类 ====================

    /**
     * 创建编辑会话请求
     */
    @Data
    public static class CreateEditSessionRequest {
        /**
         * 编辑原因/说明
         */
        private String editReason;
        
        /**
         * 模型配置ID
         */
        @NotBlank(message = "模型配置ID不能为空")
        private String modelConfigId;
    }

    /**
     * 复制历史记录请求
     */
    @Data
    public static class CopyHistoryRequest {
        /**
         * 复制原因
         */
        @NotBlank(message = "复制原因不能为空")
        private String copyReason;
    }

    /**
     * 恢复历史记录请求
     */
    @Data
    public static class RestoreHistoryRequest {
        /**
         * 目标小说ID
         */
        @NotBlank(message = "小说ID不能为空")
        private String novelId;
    }

    /**
     * 批量删除请求
     */
    @Data
    public static class BatchDeleteRequest {
        /**
         * 历史记录ID列表
         */
        @NotEmpty(message = "历史记录ID列表不能为空")
        private List<String> historyIds;
    }

    /**
     * 会话创建响应
     */
    @Data
    public static class SessionCreatedResponse {
        private String sessionId;
        private String message;
    }

    /**
     * 恢复响应
     */
    @Data
    public static class RestoreResponse {
        private Boolean success;
        private String message;
        private List<String> restoredSettingIds;
    }

    /**
     * 批量删除响应
     */
    @Data
    public static class BatchDeleteResponse {
        private Integer deletedCount;
        private String message;
    }
} 