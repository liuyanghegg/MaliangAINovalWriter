package com.ainovel.server.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.EnhancedUserPromptTemplate;
import com.ainovel.server.dto.CreatePromptTemplateRequest;
import com.ainovel.server.dto.PublishTemplateRequest;
import com.ainovel.server.dto.UpdatePromptTemplateRequest;
import com.ainovel.server.service.EnhancedUserPromptService;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 增强用户提示词管理控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/prompt-templates")
@Tag(name = "用户提示词模板管理", description = "提供用户自定义提示词模板的创建、更新、删除、分享等功能")
public class EnhancedUserPromptController {

    @Autowired
    private EnhancedUserPromptService promptService;

    /**
     * 获取当前用户ID的辅助方法
     */
    private String getCurrentUserId(Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new IllegalArgumentException("用户未认证");
        }
        
        Object principal = authentication.getPrincipal();
        if (!(principal instanceof com.ainovel.server.domain.model.User)) {
            throw new IllegalArgumentException("无效的用户认证信息");
        }
        
        return ((com.ainovel.server.domain.model.User) principal).getId();
    }

    /**
     * 创建用户提示词模板
     */
    @Operation(summary = "创建提示词模板", description = "用户创建新的自定义提示词模板")
    @PostMapping
    public Mono<ApiResponse<EnhancedUserPromptTemplate>> createPromptTemplate(
            @Valid @RequestBody CreatePromptTemplateRequest request,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.info("创建用户提示词模板请求: userId={}, name={}", userId, request.getName());

        return promptService.createPromptTemplate(
                userId,
                request.getName(),
                request.getDescription(),
                request.getFeatureType(),
                request.getSystemPrompt(),
                request.getUserPrompt(),
                request.getTags(),
                request.getCategories()
        )
        .map(ApiResponse::success)
        .onErrorResume(error -> {
            log.error("创建用户提示词模板失败: userId={}, error={}", userId, error.getMessage());
            return Mono.just(ApiResponse.error("创建失败: " + error.getMessage()));
        });
    }

    /**
     * 更新用户提示词模板
     */
    @PutMapping("/{templateId}")
    public Mono<ApiResponse<EnhancedUserPromptTemplate>> updatePromptTemplate(
            @PathVariable String templateId,
            @Valid @RequestBody UpdatePromptTemplateRequest request,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.info("更新用户提示词模板请求: userId={}, templateId={}", userId, templateId);

        return promptService.updatePromptTemplate(
                userId,
                templateId,
                request.getName(),
                request.getDescription(),
                request.getSystemPrompt(),
                request.getUserPrompt(),
                request.getTags(),
                request.getCategories()
        )
        .map(ApiResponse::success)
        .onErrorResume(error -> {
            log.error("更新用户提示词模板失败: templateId={}, error={}", templateId, error.getMessage());
            return Mono.just(ApiResponse.error("更新失败: " + error.getMessage()));
        });
    }

    /**
     * 删除用户提示词模板
     */
    @DeleteMapping("/{templateId}")
    public Mono<ApiResponse<Void>> deletePromptTemplate(
            @PathVariable String templateId,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.info("删除用户提示词模板请求: userId={}, templateId={}", userId, templateId);

        return promptService.deletePromptTemplate(userId, templateId)
                .then(Mono.just(ApiResponse.<Void>success()))
                .onErrorResume(error -> {
                    log.error("删除用户提示词模板失败: templateId={}, error={}", templateId, error.getMessage());
                    return Mono.just(ApiResponse.error("删除失败: " + error.getMessage()));
                });
    }

    /**
     * 获取用户提示词模板详情
     */
    @GetMapping("/{templateId}")
    public Mono<ApiResponse<EnhancedUserPromptTemplate>> getPromptTemplate(
            @PathVariable String templateId,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        
        return promptService.getPromptTemplateById(userId, templateId)
                .map(ApiResponse::success)
                .switchIfEmpty(Mono.just(ApiResponse.error("模板不存在")))
                .onErrorResume(error -> {
                    log.error("获取用户提示词模板失败: templateId={}, error={}", templateId, error.getMessage());
                    return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
                });
    }

    /**
     * 获取用户所有提示词模板
     */
    @GetMapping
    public Mono<ApiResponse<List<EnhancedUserPromptTemplate>>> getUserPromptTemplates(
            @RequestParam(required = false) AIFeatureType featureType,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.debug("获取用户提示词模板列表: userId={}, featureType={}", userId, featureType);

        Flux<EnhancedUserPromptTemplate> templates = featureType != null
                ? promptService.getUserPromptTemplatesByFeatureType(userId, featureType)
                : promptService.getUserPromptTemplates(userId);

        return templates.collectList()
                .map(ApiResponse::success)
                .onErrorResume(error -> {
                    log.error("获取用户提示词模板列表失败: userId={}, error={}", userId, error.getMessage());
                    return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
                });
    }

    /**
     * 获取用户收藏的模板
     */
    @GetMapping("/favorites")
    public Mono<ApiResponse<List<EnhancedUserPromptTemplate>>> getUserFavoriteTemplates(
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.debug("获取用户收藏模板: userId={}", userId);

        return promptService.getUserFavoriteTemplates(userId)
                .collectList()
                .map(ApiResponse::success)
                .onErrorResume(error -> {
                    log.error("获取用户收藏模板失败: userId={}, error={}", userId, error.getMessage());
                    return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
                });
    }

    /**
     * 获取最近使用的模板
     */
    @GetMapping("/recent")
    public Mono<ApiResponse<List<EnhancedUserPromptTemplate>>> getRecentlyUsedTemplates(
            @RequestParam(defaultValue = "10") @Min(1) @Max(50) int limit,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.debug("获取最近使用模板: userId={}, limit={}", userId, limit);

        return promptService.getRecentlyUsedTemplates(userId, limit)
                .collectList()
                .map(ApiResponse::success)
                .onErrorResume(error -> {
                    log.error("获取最近使用模板失败: userId={}, error={}", userId, error.getMessage());
                    return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
                });
    }

    /**
     * 发布模板为公开
     */
    @PostMapping("/{templateId}/publish")
    public Mono<ApiResponse<EnhancedUserPromptTemplate>> publishTemplate(
            @PathVariable String templateId,
            @Valid @RequestBody PublishTemplateRequest request,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.info("发布模板请求: userId={}, templateId={}", userId, templateId);

        return promptService.publishTemplate(userId, templateId, request.getShareCode())
                .map(ApiResponse::success)
                .onErrorResume(error -> {
                    log.error("发布模板失败: templateId={}, error={}", templateId, error.getMessage());
                    return Mono.just(ApiResponse.error("发布失败: " + error.getMessage()));
                });
    }

    /**
     * 通过分享码获取模板
     */
    @GetMapping("/share/{shareCode}")
    public Mono<ApiResponse<EnhancedUserPromptTemplate>> getTemplateByShareCode(
            @PathVariable String shareCode) {
        
        log.debug("通过分享码获取模板: shareCode={}", shareCode);

        return promptService.getTemplateByShareCode(shareCode)
                .map(ApiResponse::success)
                .switchIfEmpty(Mono.just(ApiResponse.error("分享码无效或模板不存在")))
                .onErrorResume(error -> {
                    log.error("通过分享码获取模板失败: shareCode={}, error={}", shareCode, error.getMessage());
                    return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
                });
    }

    /**
     * 复制公开模板
     */
    @PostMapping("/{templateId}/copy")
    public Mono<ApiResponse<EnhancedUserPromptTemplate>> copyPublicTemplate(
            @PathVariable String templateId,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.info("复制公开模板请求: userId={}, templateId={}", userId, templateId);

        return promptService.copyPublicTemplate(userId, templateId)
                .map(ApiResponse::success)
                .onErrorResume(error -> {
                    log.error("复制公开模板失败: templateId={}, error={}", templateId, error.getMessage());
                    return Mono.just(ApiResponse.error("复制失败: " + error.getMessage()));
                });
    }

    /**
     * 获取公开模板列表
     */
    @Operation(summary = "获取公开模板列表", description = "分页获取指定功能类型的公开提示词模板")
    @GetMapping("/public")
    public Mono<ApiResponse<List<EnhancedUserPromptTemplate>>> getPublicTemplates(
            @Parameter(description = "功能类型", required = true) @RequestParam AIFeatureType featureType,
            @Parameter(description = "页码，从0开始") @RequestParam(defaultValue = "0") @Min(0) int page,
            @Parameter(description = "每页大小，1-100之间") @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size) {
        
        log.debug("获取公开模板列表: featureType={}, page={}, size={}", featureType, page, size);

        return promptService.getPublicTemplates(featureType, page, size)
                .collectList()
                .map(ApiResponse::success)
                .onErrorResume(error -> {
                    log.error("获取公开模板列表失败: featureType={}, error={}", featureType, error.getMessage());
                    return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
                });
    }

    /**
     * 收藏模板
     */
    @PostMapping("/{templateId}/favorite")
    public Mono<ApiResponse<Void>> favoriteTemplate(
            @PathVariable String templateId,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.info("收藏模板请求: userId={}, templateId={}", userId, templateId);

        return promptService.favoriteTemplate(userId, templateId)
                .then(Mono.just(ApiResponse.<Void>success()))
                .onErrorResume(error -> {
                    log.error("收藏模板失败: templateId={}, error={}", templateId, error.getMessage());
                    return Mono.just(ApiResponse.error("收藏失败: " + error.getMessage()));
                });
    }

    /**
     * 取消收藏模板
     */
    @DeleteMapping("/{templateId}/favorite")
    public Mono<ApiResponse<Void>> unfavoriteTemplate(
            @PathVariable String templateId,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.info("取消收藏模板请求: userId={}, templateId={}", userId, templateId);

        return promptService.unfavoriteTemplate(userId, templateId)
                .then(Mono.just(ApiResponse.<Void>success()))
                .onErrorResume(error -> {
                    log.error("取消收藏模板失败: templateId={}, error={}", templateId, error.getMessage());
                    return Mono.just(ApiResponse.error("取消收藏失败: " + error.getMessage()));
                });
    }

    /**
     * 评分模板
     */
    @Operation(summary = "评分模板", description = "用户对公开模板进行评分（1-5星）")
    @PostMapping("/{templateId}/rate")
    public Mono<ApiResponse<EnhancedUserPromptTemplate>> rateTemplate(
            @Parameter(description = "模板ID") @PathVariable String templateId,
            @Parameter(description = "评分，1-5星") @RequestParam @Min(1) @Max(5) int rating,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.info("评分模板请求: userId={}, templateId={}, rating={}", userId, templateId, rating);

        return promptService.rateTemplate(userId, templateId, rating)
                .map(ApiResponse::success)
                .onErrorResume(error -> {
                    log.error("评分模板失败: templateId={}, error={}", templateId, error.getMessage());
                    return Mono.just(ApiResponse.error("评分失败: " + error.getMessage()));
                });
    }

    /**
     * 记录模板使用
     */
    @PostMapping("/{templateId}/usage")
    public Mono<ApiResponse<Void>> recordTemplateUsage(
            @PathVariable String templateId,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        
        return promptService.recordTemplateUsage(userId, templateId)
                .then(Mono.just(ApiResponse.<Void>success()))
                .onErrorResume(error -> {
                    log.debug("记录模板使用失败: templateId={}, error={}", templateId, error.getMessage());
                    return Mono.just(ApiResponse.<Void>success()); // 记录失败不影响主要功能
                });
    }

    /**
     * 获取用户所有标签
     */
    @GetMapping("/tags")
    public Mono<ApiResponse<List<String>>> getUserTags(Authentication authentication) {
        String userId = getCurrentUserId(authentication);
        log.debug("获取用户标签: userId={}", userId);

        return promptService.getUserTags(userId)
                .collectList()
                .map(ApiResponse::success)
                .onErrorResume(error -> {
                    log.error("获取用户标签失败: userId={}, error={}", userId, error.getMessage());
                    return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
                });
    }

    /**
     * 设置默认模板
     */
    @PostMapping("/{templateId}/set-default")
    public Mono<ApiResponse<EnhancedUserPromptTemplate>> setDefaultTemplate(
            @PathVariable String templateId,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.info("设置默认模板请求: userId={}, templateId={}", userId, templateId);

        return promptService.setDefaultTemplate(userId, templateId)
                .map(ApiResponse::success)
                .onErrorResume(error -> {
                    log.error("设置默认模板失败: templateId={}, error={}", templateId, error.getMessage());
                    return Mono.just(ApiResponse.error("设置失败: " + error.getMessage()));
                });
    }

    /**
     * 获取默认模板
     */
    @GetMapping("/default")
    public Mono<ApiResponse<EnhancedUserPromptTemplate>> getDefaultTemplate(
            @RequestParam AIFeatureType featureType,
            Authentication authentication) {
        
        String userId = getCurrentUserId(authentication);
        log.debug("获取默认模板请求: userId={}, featureType={}", userId, featureType);

        return promptService.getDefaultTemplate(userId, featureType)
                .map(ApiResponse::success)
                .switchIfEmpty(Mono.just(ApiResponse.error("未找到默认模板")))
                .onErrorResume(error -> {
                    log.error("获取默认模板失败: userId={}, featureType={}, error={}", userId, featureType, error.getMessage());
                    return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
                });
    }
} 