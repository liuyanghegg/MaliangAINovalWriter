package com.ainovel.server.controller;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.AIPromptPreset;
import com.ainovel.server.domain.model.EnhancedUserPromptTemplate;
import com.ainovel.server.repository.AIPromptPresetRepository;
import com.ainovel.server.repository.EnhancedUserPromptTemplateRepository;
import com.ainovel.server.web.dto.request.CreatePresetRequestDto;
import com.ainovel.server.web.dto.request.UpdatePresetInfoRequest;
import io.swagger.v3.oas.annotations.Operation;

import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;


/**
 * AI提示词预设管理控制器
 * 提供预设的CRUD操作和管理功能
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/ai/presets")
@Tag(name = "预设管理", description = "AI提示词预设的管理接口")
public class AIPromptPresetController {

    @Autowired
    private AIPromptPresetRepository presetRepository;

    @Autowired
    private EnhancedUserPromptTemplateRepository templateRepository;
    
    @Autowired
    private com.ainovel.server.service.AIPresetService aiPresetService;

    /**
     * 创建新的用户预设（新逻辑：直接存储原始请求数据）
     */
    @PostMapping
    @Operation(summary = "创建预设", description = "创建新的用户预设，直接存储原始请求数据")
    public Mono<ApiResponse<AIPromptPreset>> createPreset(
            @RequestBody CreatePresetRequestDto request,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("创建预设: userId={}, presetName={}", userId, request.getPresetName());
        
        // 🚀 使用新的AIPresetService创建预设
        return aiPresetService.createPreset(
                request.getRequest(),
                request.getPresetName(), 
                request.getPresetDescription(),
                request.getPresetTags()
        )
                .map(savedPreset -> {
                    log.info("预设创建成功: userId={}, presetId={}, presetName={}", 
                            userId, savedPreset.getPresetId(), savedPreset.getPresetName());
                    return ApiResponse.success(savedPreset);
                })
                .onErrorMap(error -> {
                    log.error("创建预设失败: userId={}, error={}", userId, error.getMessage());
                    // 直接抛出异常，让全局异常处理器处理
                    return new RuntimeException("创建预设失败: " + error.getMessage());
                });
    }



    /**
     * 获取预设列表（按功能分组）
     */
    @GetMapping
    @Operation(summary = "获取预设列表", description = "获取指定功能下的预设列表，包含用户预设和系统预设")
    public Mono<ApiResponse<List<AIPromptPreset>>> getPresetList(
            @RequestParam String featureType,
            @RequestParam(required = false) String novelId,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("获取预设列表: userId={}, featureType={}, novelId={}", userId, featureType, novelId);
        
        return presetRepository.findUserAndSystemPresetsByFeatureType(userId, featureType)
                .collectList()
                .map(presets -> {
                    log.info("返回预设列表: userId={}, featureType={}, 预设数={}", userId, featureType, presets.size());
                    return ApiResponse.success(presets);
                })
                .onErrorMap(error -> {
                    log.error("获取预设列表失败: userId={}, featureType={}, error={}", userId, featureType, error.getMessage());
                    return new RuntimeException("获取预设列表失败: " + error.getMessage());
                });
    }

    /**
     * 获取快捷访问预设列表
     */
    @GetMapping("/quick-access")
    @Operation(summary = "获取快捷访问预设", description = "获取所有标记为快捷访问的预设，按功能分组")
    public Mono<ApiResponse<List<AIPromptPreset>>> getQuickAccessPresets(
            @RequestParam(required = false) String featureType,
            @RequestParam(required = false) String novelId,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("获取快捷访问预设: userId={}, featureType={}, novelId={}", userId, featureType, novelId);
        
        Mono<List<AIPromptPreset>> presetsMono;
        if (featureType != null) {
            presetsMono = presetRepository.findQuickAccessPresetsByUserAndFeatureType(userId, featureType)
                    .collectList();
        } else {
            presetsMono = presetRepository.findByUserIdAndShowInQuickAccessTrue(userId)
                    .concatWith(presetRepository.findByIsSystemTrueAndShowInQuickAccessTrue())
                    .distinct()
                    .collectList();
        }
        
        return presetsMono
                .map(presets -> {
                    log.info("返回快捷访问预设: userId={}, featureType={}, 预设数={}", userId, featureType, presets.size());
                    return ApiResponse.success(presets);
                })
                .onErrorMap(error -> {
                    log.error("获取快捷访问预设失败: userId={}, error={}", userId, error.getMessage());
                    return new RuntimeException("获取快捷访问预设失败: " + error.getMessage());
                });
    }



    /**
     * 覆盖更新预设（完整对象）
     */
    @PutMapping("/{presetId}")
    @Operation(summary = "覆盖更新预设", description = "提交完整的 AIPromptPreset JSON，后端用新数据覆盖旧预设")
    public Mono<ApiResponse<AIPromptPreset>> overwritePreset(
            @PathVariable String presetId,
            @RequestBody AIPromptPreset newPreset,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("覆盖更新预设: userId={}, presetId={}", userId, presetId);
        
        return aiPresetService.overwritePreset(presetId, newPreset)
                .map(savedPreset -> {
                    log.info("预设覆盖更新成功: userId={}, presetId={}", userId, presetId);
                    return ApiResponse.success(savedPreset);
                })
                .onErrorMap(error -> {
                    log.error("覆盖更新预设失败: userId={}, presetId={}, error={}", userId, presetId, error.getMessage());
                    return new RuntimeException("覆盖更新预设失败: " + error.getMessage());
                });
    }

    /**
     * 更新预设基本信息（兼容旧接口）
     */
    @PutMapping("/{presetId}/info")
    @Operation(summary = "更新预设基本信息", description = "更新预设的名称、描述和标签")
    public Mono<ApiResponse<AIPromptPreset>> updatePresetInfo(
            @PathVariable String presetId,
            @RequestBody UpdatePresetInfoRequest request,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("更新预设基本信息: userId={}, presetId={}", userId, presetId);
        
        return aiPresetService.updatePresetInfo(
                presetId,
                request.getPresetName(),
                request.getPresetDescription(),
                request.getPresetTags()
        )
                .map(savedPreset -> {
                    log.info("预设基本信息更新成功: userId={}, presetId={}", userId, presetId);
                    return ApiResponse.success(savedPreset);
                })
                .onErrorMap(error -> {
                    log.error("更新预设基本信息失败: userId={}, presetId={}, error={}", userId, presetId, error.getMessage());
                    return new RuntimeException("更新预设基本信息失败: " + error.getMessage());
                });
    }

    /**
     * 删除用户预设
     */
    @DeleteMapping("/{presetId}")
    @Operation(summary = "删除预设", description = "删除用户自己的预设")
    public Mono<ApiResponse<String>> deletePreset(
            @PathVariable String presetId,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("删除预设: userId={}, presetId={}", userId, presetId);
        
        return aiPresetService.deletePreset(presetId)
                .thenReturn("预设删除成功")
                .map(result -> {
                    log.info("预设删除成功: userId={}, presetId={}", userId, presetId);
                    return ApiResponse.success(result);
                })
                .onErrorMap(error -> {
                    log.error("删除预设失败: userId={}, presetId={}, error={}", userId, presetId, error.getMessage());
                    return new RuntimeException("删除预设失败: " + error.getMessage());
                });
    }

    /**
     * 复制预设（可以复制系统预设或自己的预设）
     */
    @PostMapping("/{presetId}/duplicate")
    @Operation(summary = "复制预设", description = "复制预设，无论是系统预设还是自己的预设")
    public Mono<ApiResponse<AIPromptPreset>> duplicatePreset(
            @PathVariable String presetId,
            @RequestBody(required = false) Map<String, String> request,
            @RequestParam(required = false, defaultValue = "") String newName,
            @RequestHeader("X-User-Id") String userId) {
        
        // 支持两种方式：请求体中的newPresetName或查询参数中的newName
        String presetName = null;
        if (request != null && request.containsKey("newPresetName")) {
            presetName = request.get("newPresetName");
        } else if (!newName.isEmpty()) {
            presetName = newName;
        }
        
        log.info("复制预设: userId={}, presetId={}, newName={}", userId, presetId, presetName);
        
        return aiPresetService.duplicatePreset(presetId, presetName)
                .map(savedPreset -> {
                    log.info("预设复制成功: userId={}, originalPresetId={}, newPresetId={}", 
                            userId, presetId, savedPreset.getPresetId());
                    return ApiResponse.success(savedPreset);
                })
                .onErrorMap(error -> {
                    log.error("复制预设失败: userId={}, presetId={}, error={}", userId, presetId, error.getMessage());
                    return new RuntimeException("复制预设失败: " + error.getMessage());
                });
    }

    /**
     * 更新预设提示词
     */
    @PutMapping("/{presetId}/prompts")
    @Operation(summary = "更新预设提示词", description = "更新预设的自定义提示词")
    public Mono<ApiResponse<AIPromptPreset>> updatePresetPrompts(
            @PathVariable String presetId,
            @RequestBody Map<String, String> request,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("更新预设提示词: userId={}, presetId={}", userId, presetId);
        
        String customSystemPrompt = request.get("customSystemPrompt");
        String customUserPrompt = request.get("customUserPrompt");
        
        return aiPresetService.updatePresetPrompts(presetId, customSystemPrompt, customUserPrompt)
                .map(savedPreset -> {
                    log.info("预设提示词更新成功: userId={}, presetId={}", userId, presetId);
                    return ApiResponse.success(savedPreset);
                })
                .onErrorMap(error -> {
                    log.error("更新预设提示词失败: userId={}, presetId={}, error={}", userId, presetId, error.getMessage());
                    return new RuntimeException("更新预设提示词失败: " + error.getMessage());
                });
    }

    /**
     * 切换收藏状态
     */
    @PostMapping("/{presetId}/favorite")
    @Operation(summary = "切换收藏状态", description = "切换预设的收藏状态")
    public Mono<ApiResponse<AIPromptPreset>> toggleFavorite(
            @PathVariable String presetId,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("切换预设收藏状态: userId={}, presetId={}", userId, presetId);
        
        return aiPresetService.toggleFavorite(presetId)
                .map(savedPreset -> {
                    log.info("预设收藏状态切换成功: userId={}, presetId={}, isFavorite={}", 
                            userId, presetId, savedPreset.getIsFavorite());
                    return ApiResponse.success(savedPreset);
                })
                .onErrorMap(error -> {
                    log.error("切换预设收藏状态失败: userId={}, presetId={}, error={}", userId, presetId, error.getMessage());
                    return new RuntimeException("切换预设收藏状态失败: " + error.getMessage());
                });
    }

    /**
     * 记录预设使用
     */
    @PostMapping("/{presetId}/usage")
    @Operation(summary = "记录预设使用", description = "记录预设的使用情况，更新使用次数和最后使用时间")
    public Mono<ApiResponse<String>> recordPresetUsage(
            @PathVariable String presetId,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("记录预设使用: userId={}, presetId={}", userId, presetId);
        
        return aiPresetService.recordUsage(presetId)
                .thenReturn("预设使用记录成功")
                .map(result -> {
                    log.info("预设使用记录成功: userId={}, presetId={}", userId, presetId);
                    return ApiResponse.success(result);
                })
                .onErrorMap(error -> {
                    log.error("记录预设使用失败: userId={}, presetId={}, error={}", userId, presetId, error.getMessage());
                    return new RuntimeException("记录预设使用失败: " + error.getMessage());
                });
    }

    /**
     * 设置/取消快捷访问
     */
    @PostMapping("/{presetId}/quick-access")
    @Operation(summary = "切换快捷访问", description = "切换预设的快捷访问状态")
    public Mono<ApiResponse<AIPromptPreset>> toggleQuickAccess(
            @PathVariable String presetId,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("切换快捷访问: userId={}, presetId={}", userId, presetId);
        
        return aiPresetService.toggleQuickAccess(presetId)
                .map(savedPreset -> {
                    log.info("快捷访问状态切换成功: userId={}, presetId={}, showInQuickAccess={}", 
                            userId, presetId, savedPreset.getShowInQuickAccess());
                    return ApiResponse.success(savedPreset);
                })
                .onErrorMap(error -> {
                    log.error("切换快捷访问失败: userId={}, presetId={}, error={}", userId, presetId, error.getMessage());
                    return new RuntimeException("切换快捷访问失败: " + error.getMessage());
                });
    }

    /**
     * 获取预设详情
     */
    @GetMapping("/detail/{presetId}")
    @Operation(summary = "获取预设详情", description = "获取指定预设的详细信息")
    public Mono<ApiResponse<AIPromptPreset>> getPresetDetail(
            @PathVariable String presetId,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("获取预设详情: userId={}, presetId={}", userId, presetId);
        
        return presetRepository.findByPresetId(presetId)
                .switchIfEmpty(Mono.error(new RuntimeException("预设不存在")))
                .map(preset -> {
                    log.info("返回预设详情: userId={}, presetId={}, presetName={}", 
                            userId, presetId, preset.getPresetName());
                    return ApiResponse.success(preset);
                })
                .onErrorMap(error -> {
                    log.error("获取预设详情失败: userId={}, presetId={}, error={}", userId, presetId, error.getMessage());
                    return new RuntimeException("获取预设详情失败: " + error.getMessage());
                });
    }

    /**
     * 修改预设关联的模板ID
     */
    @PutMapping("/{presetId}/template")
    @Operation(summary = "修改预设模板关联", description = "修改预设关联的EnhancedUserPromptTemplate模板ID")
    public Mono<ApiResponse<AIPromptPreset>> updatePresetTemplate(
            @PathVariable String presetId,
            @RequestParam String templateId,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("修改预设模板关联: userId={}, presetId={}, templateId={}", userId, presetId, templateId);
        
        return presetRepository.findByPresetId(presetId)
                .switchIfEmpty(Mono.error(new RuntimeException("预设不存在")))
                .flatMap(preset -> {
                    // 仅允许修改自己的用户预设
                    if (!userId.equals(preset.getUserId()) || preset.getIsSystem()) {
                        return Mono.error(new RuntimeException("无权修改此预设的模板关联"));
                    }
                    // 交由服务层做功能类型与范围校验
                    return aiPresetService.updatePresetTemplate(presetId, templateId);
                })
                .map(savedPreset -> {
                    log.info("预设模板关联修改成功: userId={}, presetId={}, templateId={}", 
                            userId, presetId, templateId);
                    return ApiResponse.success(savedPreset);
                })
                .onErrorMap(error -> {
                    log.error("修改预设模板关联失败: userId={}, presetId={}, templateId={}, error={}", 
                            userId, presetId, templateId, error.getMessage());
                    return new RuntimeException("修改预设模板关联失败: " + error.getMessage());
                });
    }

    /**
     * 获取可用的模板列表（用于关联预设）
     */
    @GetMapping("/templates/available")
    @Operation(summary = "获取可用模板", description = "获取用户可用的EnhancedUserPromptTemplate列表，用于关联预设")
    public Mono<ApiResponse<List<EnhancedUserPromptTemplate>>> getAvailableTemplates(
            @RequestParam(required = false) String featureType,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("获取可用模板列表: userId={}, featureType={}", userId, featureType);
        
        Mono<List<EnhancedUserPromptTemplate>> templatesMono;
        
        if (featureType != null) {
            try {
                AIFeatureType feature = AIFeatureType.valueOf(featureType);
                // 获取用户的模板 + 公开的模板
                templatesMono = templateRepository.findByUserIdAndFeatureType(userId, feature)
                        .concatWith(templateRepository.findPublicTemplatesByFeatureType(feature))
                        .distinct() // 去重
                        .collectList();
            } catch (IllegalArgumentException e) {
                return Mono.error(new RuntimeException("无效的功能类型: " + featureType));
            }
        } else {
            // 获取用户的所有模板 + 所有公开模板
            templatesMono = templateRepository.findByUserId(userId)
                    .concatWith(templateRepository.findByIsPublicTrue())
                    .distinct() // 去重
                    .collectList();
        }
        
        return templatesMono
                .map(templates -> {
                    log.info("返回可用模板列表: userId={}, featureType={}, 模板数={}", 
                            userId, featureType, templates.size());
                    return ApiResponse.success(templates);
                })
                .onErrorMap(error -> {
                    log.error("获取可用模板列表失败: userId={}, featureType={}, error={}", 
                            userId, featureType, error.getMessage());
                    return new RuntimeException("获取可用模板列表失败: " + error.getMessage());
                });
    }

    /**
     * 根据模板ID获取模板详情
     */
    @GetMapping("/templates/{templateId}")
    @Operation(summary = "获取模板详情", description = "获取指定模板的详细信息")
    public Mono<ApiResponse<EnhancedUserPromptTemplate>> getTemplateDetail(
            @PathVariable String templateId,
            @RequestHeader("X-User-Id") String userId) {
        
        log.info("获取模板详情: userId={}, templateId={}", userId, templateId);
        
        return templateRepository.findById(templateId)
                .switchIfEmpty(Mono.error(new RuntimeException("模板不存在")))
                .map(template -> {
                    log.info("返回模板详情: userId={}, templateId={}, templateName={}", 
                            userId, templateId, template.getName());
                    return ApiResponse.success(template);
                })
                .onErrorMap(error -> {
                    log.error("获取模板详情失败: userId={}, templateId={}, error={}", 
                            userId, templateId, error.getMessage());
                    return new RuntimeException("获取模板详情失败: " + error.getMessage());
                });
    }

    /**
     * 获取收藏预设列表
     */
    @GetMapping("/favorites")
    @Operation(summary = "获取收藏预设", description = "获取用户收藏的预设列表，可按功能类型和小说ID过滤")
    public Mono<ApiResponse<List<AIPromptPreset>>> getFavoritePresets(
            @RequestParam(required = false) String featureType,
            @RequestParam(required = false) String novelId,
            @RequestHeader("X-User-Id") String userId) {

        log.info("获取收藏预设: userId={}, featureType={}, novelId={}", userId, featureType, novelId);

        return aiPresetService.getFavoritePresets(userId, featureType, novelId)
                .collectList()
                .map(ApiResponse::success)
                .onErrorMap(error -> {
                    log.error("获取收藏预设失败: userId={}, error={}", userId, error.getMessage());
                    return new RuntimeException("获取收藏预设失败: " + error.getMessage());
                });
    }

    /**
     * 获取最近使用预设列表
     */
    @GetMapping("/recent")
    @Operation(summary = "获取最近使用预设", description = "按使用时间倒序返回最近使用的预设")
    public Mono<ApiResponse<List<AIPromptPreset>>> getRecentPresets(
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(required = false) String featureType,
            @RequestParam(required = false) String novelId,
            @RequestHeader("X-User-Id") String userId) {

        log.info("获取最近使用预设: userId={}, limit={}, featureType={}, novelId={}", userId, limit, featureType, novelId);

        return aiPresetService.getRecentPresets(userId, limit, featureType, novelId)
                .collectList()
                .map(ApiResponse::success)
                .onErrorMap(error -> {
                    log.error("获取最近使用预设失败: userId={}, error={}", userId, error.getMessage());
                    return new RuntimeException("获取最近使用预设失败: " + error.getMessage());
                });
    }

    /**
     * 获取功能预设列表（收藏、最近使用、推荐）
     */
    @GetMapping("/feature-list")
    @Operation(summary = "获取功能预设列表", description = "获取收藏、最近使用和推荐的预设列表")
    public Mono<ApiResponse<com.ainovel.server.dto.response.PresetListResponse>> getFeaturePresetList(
            @RequestParam String featureType,
            @RequestParam(required = false) String novelId,
            @RequestHeader("X-User-Id") String userId) {

        log.info("获取功能预设列表: userId={}, featureType={}, novelId={}", userId, featureType, novelId);

        return aiPresetService.getFeaturePresetList(userId, featureType, novelId)
                .map(ApiResponse::success)
                .onErrorMap(error -> {
                    log.error("获取功能预设列表失败: userId={}, featureType={}, error={}", userId, featureType, error.getMessage());
                    return new RuntimeException("获取功能预设列表失败: " + error.getMessage());
                });
    }

    /**
     * 获取系统预设列表（可按功能类型过滤）
     */
    @GetMapping("/system")
    @Operation(summary = "获取系统预设", description = "获取所有系统预设，可按功能类型过滤")
    public Mono<ApiResponse<List<AIPromptPreset>>> getSystemPresets(
            @RequestParam(required = false) String featureType) {

        return aiPresetService.getSystemPresets(featureType)
                .collectList()
                .map(ApiResponse::success)
                .onErrorMap(error -> new RuntimeException("获取系统预设失败: " + error.getMessage()));
    }

    /**
     * 批量获取预设
     */
    @PostMapping("/batch")
    @Operation(summary = "批量获取预设", description = "根据预设ID列表批量获取预设")
    public Mono<ApiResponse<List<AIPromptPreset>>> getPresetsBatch(@RequestBody Map<String, Object> body,
                                                                   @RequestHeader("X-User-Id") String userId) {
        Object ids = body != null ? body.get("presetIds") : null;
        if (!(ids instanceof List)) {
            return Mono.just(ApiResponse.error("请求体缺少presetIds数组"));
        }
        @SuppressWarnings("unchecked")
        List<String> presetIds = (List<String>) ids;
        return aiPresetService.getPresetsBatch(presetIds)
                .collectList()
                .map(ApiResponse::success)
                .onErrorMap(error -> new RuntimeException("批量获取预设失败: " + error.getMessage()));
    }

    /**
     * 按功能类型获取当前用户的预设
     */
    @GetMapping("/feature/{featureType}")
    @Operation(summary = "按功能类型获取预设", description = "按功能类型获取当前用户的预设")
    public Mono<ApiResponse<List<AIPromptPreset>>> getUserPresetsByFeatureType(
            @PathVariable String featureType,
            @RequestHeader("X-User-Id") String userId) {

        return aiPresetService.getUserPresetsByFeatureType(userId, featureType)
                .collectList()
                .map(ApiResponse::success)
                .onErrorMap(error -> new RuntimeException("按功能类型获取预设失败: " + error.getMessage()));
    }

    /**
     * 获取用户的预设，按功能类型分组
     */
    @GetMapping("/grouped")
    @Operation(summary = "分组获取预设", description = "按功能类型分组获取用户预设")
    public Mono<ApiResponse<Map<String, List<AIPromptPreset>>>> getGroupedUserPresets(
            @RequestParam(required = false) String userId,
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId) {

        String targetUserId = (userId != null && !userId.isEmpty()) ? userId : headerUserId;
        if (targetUserId == null || targetUserId.isEmpty()) {
            return Mono.just(ApiResponse.error("缺少用户标识"));
        }

        return aiPresetService.getUserPresetsGrouped(targetUserId)
                .map(ApiResponse::success)
                .onErrorMap(error -> new RuntimeException("分组获取预设失败: " + error.getMessage()));
    }

    /**
     * 预设搜索
     */
    @GetMapping("/search")
    @Operation(summary = "搜索预设", description = "按关键词/标签/功能类型搜索当前用户的预设")
    public Mono<ApiResponse<List<AIPromptPreset>>> searchPresets(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String tags,
            @RequestParam(required = false) String featureType,
            @RequestParam(required = false) String novelId,
            @RequestHeader("X-User-Id") String userId) {

        List<String> tagList = null;
        if (tags != null && !tags.isEmpty()) {
            String cleaned = tags.replace("[", "").replace("]", "");
            tagList = List.of(cleaned.split(","))
                    .stream()
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .toList();
        }

        if (novelId != null && !novelId.isEmpty()) {
            return aiPresetService.searchUserPresetsByNovelId(userId, keyword, tagList, featureType, novelId)
                    .collectList()
                    .map(ApiResponse::success)
                    .onErrorMap(error -> new RuntimeException("搜索预设失败: " + error.getMessage()));
        }

        return aiPresetService.searchUserPresets(userId, keyword, tagList, featureType)
                .collectList()
                .map(ApiResponse::success)
                .onErrorMap(error -> new RuntimeException("搜索预设失败: " + error.getMessage()));
    }

    /**
     * 预设统计信息
     */
    @GetMapping("/statistics")
    @Operation(summary = "获取预设统计信息", description = "返回总数/收藏/最近使用/按功能类型分布/热门标签")
    public Mono<ApiResponse<Map<String, Object>>> getPresetStatistics(
            @RequestHeader("X-User-Id") String userId) {

        var since = java.time.LocalDateTime.now().minusDays(30);

        Mono<Long> totalMono = presetRepository.countByUserId(userId);
        Mono<Long> favMono = presetRepository.countByUserIdAndIsFavoriteTrue(userId);
        Mono<Long> recentMono = presetRepository.findRecentlyUsedPresets(userId, since).count();

        Mono<Map<String, Long>> byFeatureMono = presetRepository.findByUserId(userId)
                .collectList()
                .map(list -> {
                    java.util.Map<String, Long> map = new java.util.HashMap<>();
                    for (var p : list) {
                        String ft = p.getAiFeatureType() != null ? p.getAiFeatureType() : "UNKNOWN";
                        map.put(ft, map.getOrDefault(ft, 0L) + 1L);
                    }
                    return map;
                });

        Mono<List<String>> popularTagsMono = presetRepository.findByUserId(userId)
                .collectList()
                .map(list -> {
                    java.util.Map<String, Integer> tagCount = new java.util.HashMap<>();
                    for (var p : list) {
                        if (p.getPresetTags() != null) {
                            for (var t : p.getPresetTags()) {
                                if (t != null && !t.isEmpty()) {
                                    tagCount.put(t, tagCount.getOrDefault(t, 0) + 1);
                                }
                            }
                        }
                    }
                    return tagCount.entrySet().stream()
                            .sorted((a, b) -> Integer.compare(b.getValue(), a.getValue()))
                            .limit(10)
                            .map(java.util.Map.Entry::getKey)
                            .toList();
                });

        return Mono.zip(totalMono, favMono, recentMono, byFeatureMono, popularTagsMono)
                .map(tuple -> {
                    Map<String, Object> res = new java.util.HashMap<>();
                    res.put("totalPresets", tuple.getT1());
                    res.put("favoritePresets", tuple.getT2());
                    res.put("recentlyUsedPresets", tuple.getT3());
                    res.put("presetsByFeatureType", tuple.getT4());
                    res.put("popularTags", tuple.getT5());
                    return ApiResponse.success(res);
                })
                .onErrorMap(error -> new RuntimeException("获取预设统计信息失败: " + error.getMessage()));
    }

    /**
     * 功能类型预设管理聚合（轻量）
     */
    @GetMapping("/management/{featureType}")
    @Operation(summary = "功能预设管理聚合", description = "返回该功能下用户/系统/快捷/收藏及简单统计")
    public Mono<ApiResponse<Map<String, Object>>> getFeatureTypePresetManagement(
            @PathVariable String featureType,
            @RequestParam(required = false) String novelId,
            @RequestHeader("X-User-Id") String userId) {

        Mono<List<AIPromptPreset>> userPresetsMono = (novelId != null && !novelId.isEmpty())
                ? aiPresetService.getUserPresetsByFeatureTypeAndNovelId(userId, featureType, novelId).collectList()
                : aiPresetService.getUserPresetsByFeatureType(userId, featureType).collectList();

        Mono<List<AIPromptPreset>> systemPresetsMono = aiPresetService.getSystemPresets(featureType).collectList();
        Mono<List<AIPromptPreset>> quickAccessMono = aiPresetService.getQuickAccessPresets(userId, featureType).collectList();
        Mono<List<AIPromptPreset>> favoritesMono = aiPresetService.getFavoritePresets(userId, featureType, novelId).collectList();

        return Mono.zip(userPresetsMono, systemPresetsMono, quickAccessMono, favoritesMono)
                .map(tuple -> {
                    Map<String, Object> data = new java.util.HashMap<>();
                    data.put("featureType", featureType);
                    data.put("userPresets", tuple.getT1());
                    data.put("systemPresets", tuple.getT2());
                    data.put("quickAccessPresets", tuple.getT3());
                    data.put("favoritePresets", tuple.getT4());
                    data.put("total", tuple.getT1().size() + tuple.getT2().size());
                    return ApiResponse.success(data);
                })
                .onErrorMap(error -> new RuntimeException("获取功能预设管理信息失败: " + error.getMessage()));
    }
}