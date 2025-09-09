package com.ainovel.server.controller;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.AIPromptPreset;
import com.ainovel.server.service.AdminPromptPresetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

/**
 * 管理员系统预设管理控制器
 * 提供系统级AI预设的完整管理功能
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/admin/prompt-presets")
@PreAuthorize("hasAuthority('ADMIN_MANAGE_PRESETS') or hasRole('SUPER_ADMIN')")
@Tag(name = "管理员预设管理", description = "系统级AI预设的管理接口")
public class AdminPromptPresetController {

    @Autowired
    private AdminPromptPresetService adminPresetService;

    /**
     * 获取所有系统预设
     */
    @GetMapping
    @Operation(summary = "获取所有系统预设", description = "获取系统中所有的官方预设")
    public Mono<ResponseEntity<ApiResponse<List<AIPromptPreset>>>> getAllSystemPresets(
            @RequestParam(required = false) String featureType) {
        
        log.info("获取系统预设列表，功能类型: {}", featureType);
        
        Mono<List<AIPromptPreset>> presetsMono;
        if (featureType != null && !featureType.isEmpty()) {
            try {
                AIFeatureType feature = AIFeatureType.valueOf(featureType.toUpperCase());
                presetsMono = adminPresetService.findSystemPresetsByFeatureType(feature).collectList();
            } catch (IllegalArgumentException e) {
                return Mono.just(ResponseEntity.badRequest()
                    .body(ApiResponse.error("无效的功能类型: " + featureType)));
            }
        } else {
            presetsMono = adminPresetService.findAllSystemPresets().collectList();
        }
        
        return presetsMono
                .map(presets -> {
                    log.info("返回 {} 个系统预设", presets.size());
                    return ResponseEntity.ok(ApiResponse.success(presets));
                })
                .onErrorResume(e -> {
                    log.error("获取系统预设失败", e);
                    return Mono.just(ResponseEntity.badRequest()
                        .body(ApiResponse.error("获取系统预设失败: " + e.getMessage())));
                });
    }

    /**
     * 创建系统预设
     */
    @PostMapping
    @Operation(summary = "创建系统预设", description = "创建新的系统级预设")
    public Mono<ResponseEntity<ApiResponse<AIPromptPreset>>> createSystemPreset(
            @RequestBody AIPromptPreset preset,
            Authentication authentication) {
        
        String adminId = authentication.getName();
        log.info("管理员 {} 创建系统预设: {}", adminId, preset.getPresetName());
        
        return adminPresetService.createSystemPreset(preset, adminId)
                .map(savedPreset -> {
                    log.info("系统预设创建成功: {} (ID: {})", savedPreset.getPresetName(), savedPreset.getPresetId());
                    return ResponseEntity.ok(ApiResponse.success(savedPreset));
                })
                .onErrorResume(e -> {
                    log.error("创建系统预设失败: {}", preset.getPresetName(), e);
                    return Mono.just(ResponseEntity.badRequest()
                        .body(ApiResponse.error("创建系统预设失败: " + e.getMessage())));
                });
    }

    /**
     * 更新系统预设
     */
    @PutMapping("/{presetId}")
    @Operation(summary = "更新系统预设", description = "更新指定的系统预设")
    public Mono<ResponseEntity<ApiResponse<AIPromptPreset>>> updateSystemPreset(
            @PathVariable String presetId,
            @RequestBody AIPromptPreset preset,
            Authentication authentication) {
        
        String adminId = authentication.getName();
        log.info("管理员 {} 更新系统预设: {}", adminId, presetId);
        
        return adminPresetService.updateSystemPreset(presetId, preset, adminId)
                .map(updatedPreset -> {
                    log.info("系统预设更新成功: {}", presetId);
                    return ResponseEntity.ok(ApiResponse.success(updatedPreset));
                })
                .onErrorResume(e -> {
                    log.error("更新系统预设失败: {}", presetId, e);
                    return Mono.just(ResponseEntity.badRequest()
                        .body(ApiResponse.error("更新系统预设失败: " + e.getMessage())));
                });
    }

    /**
     * 删除系统预设
     */
    @DeleteMapping("/{presetId}")
    @Operation(summary = "删除系统预设", description = "删除指定的系统预设")
    public Mono<ResponseEntity<ApiResponse<String>>> deleteSystemPreset(@PathVariable String presetId) {
        
        log.info("删除系统预设: {}", presetId);
        
        return adminPresetService.deleteSystemPreset(presetId)
                .then(Mono.just(ResponseEntity.ok(ApiResponse.success("系统预设删除成功"))))
                .onErrorResume(e -> {
                    log.error("删除系统预设失败: {}", presetId, e);
                    return Mono.just(ResponseEntity.badRequest()
                        .body(ApiResponse.error("删除系统预设失败: " + e.getMessage())));
                });
    }

    /**
     * 切换系统预设的快捷访问状态
     */
    @PostMapping("/{presetId}/toggle-quick-access")
    @Operation(summary = "切换快捷访问", description = "切换系统预设的快捷访问状态")
    public Mono<ResponseEntity<ApiResponse<AIPromptPreset>>> toggleQuickAccess(@PathVariable String presetId) {
        
        log.info("切换系统预设快捷访问状态: {}", presetId);
        
        return adminPresetService.toggleSystemPresetQuickAccess(presetId)
                .map(updatedPreset -> {
                    log.info("系统预设快捷访问状态已更新: {} -> {}", presetId, updatedPreset.getShowInQuickAccess());
                    return ResponseEntity.ok(ApiResponse.success(updatedPreset));
                })
                .onErrorResume(e -> {
                    log.error("切换快捷访问状态失败: {}", presetId, e);
                    return Mono.just(ResponseEntity.badRequest()
                        .body(ApiResponse.error("切换快捷访问状态失败: " + e.getMessage())));
                });
    }

    /**
     * 批量更新系统预设可见性
     */
    @PatchMapping("/batch-visibility")
    @Operation(summary = "批量更新可见性", description = "批量设置系统预设的快捷访问状态")
    public Mono<ResponseEntity<ApiResponse<List<AIPromptPreset>>>> batchUpdateVisibility(
            @RequestBody BatchVisibilityRequest request) {
        
        log.info("批量更新 {} 个系统预设的可见性为: {}", request.getPresetIds().size(), request.isShowInQuickAccess());
        
        return adminPresetService.batchUpdateVisibility(request.getPresetIds(), request.isShowInQuickAccess())
                .map(updatedPresets -> {
                    log.info("批量更新完成，影响 {} 个预设", updatedPresets.size());
                    return ResponseEntity.ok(ApiResponse.success(updatedPresets));
                })
                .onErrorResume(e -> {
                    log.error("批量更新可见性失败", e);
                    return Mono.just(ResponseEntity.badRequest()
                        .body(ApiResponse.error("批量更新可见性失败: " + e.getMessage())));
                });
    }

    /**
     * 获取系统预设统计信息
     */
    @GetMapping("/statistics")
    @Operation(summary = "获取统计信息", description = "获取系统预设的整体统计信息")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getStatistics() {
        
        log.info("获取系统预设统计信息");
        
        return adminPresetService.getSystemPresetsStatistics()
                .map(stats -> {
                    log.info("返回系统预设统计信息");
                    return ResponseEntity.ok(ApiResponse.success(stats));
                })
                .onErrorResume(e -> {
                    log.error("获取统计信息失败", e);
                    return Mono.just(ResponseEntity.badRequest()
                        .body(ApiResponse.error("获取统计信息失败: " + e.getMessage())));
                });
    }

    /**
     * 获取预设详情和使用统计
     */
    @GetMapping("/{presetId}/details")
    @Operation(summary = "获取预设详情", description = "获取预设的详细信息和使用统计")
    public Mono<ResponseEntity<ApiResponse<Map<String, Object>>>> getPresetDetails(@PathVariable String presetId) {
        
        log.info("获取系统预设详情: {}", presetId);
        
        return adminPresetService.getPresetDetailsWithStats(presetId)
                .map(details -> {
                    log.info("返回预设详情: {}", presetId);
                    return ResponseEntity.ok(ApiResponse.success(details));
                })
                .onErrorResume(e -> {
                    log.error("获取预设详情失败: {}", presetId, e);
                    return Mono.just(ResponseEntity.badRequest()
                        .body(ApiResponse.error("获取预设详情失败: " + e.getMessage())));
                });
    }

    /**
     * 导出系统预设
     */
    @PostMapping("/export")
    @Operation(summary = "导出系统预设", description = "导出指定的系统预设，如果不指定则导出全部")
    public Mono<ResponseEntity<ApiResponse<List<AIPromptPreset>>>> exportPresets(
            @RequestBody(required = false) ExportRequest request) {
        
        List<String> presetIds = request != null ? request.getPresetIds() : List.of();
        log.info("导出系统预设，指定ID数量: {}", presetIds.size());
        
        return adminPresetService.exportSystemPresets(presetIds)
                .map(presets -> {
                    log.info("成功导出 {} 个系统预设", presets.size());
                    return ResponseEntity.ok(ApiResponse.success(presets));
                })
                .onErrorResume(e -> {
                    log.error("导出系统预设失败", e);
                    return Mono.just(ResponseEntity.badRequest()
                        .body(ApiResponse.error("导出系统预设失败: " + e.getMessage())));
                });
    }

    /**
     * 导入系统预设
     */
    @PostMapping("/import")
    @Operation(summary = "导入系统预设", description = "导入系统预设数据")
    public Mono<ResponseEntity<ApiResponse<List<AIPromptPreset>>>> importPresets(
            @RequestBody List<AIPromptPreset> presets,
            Authentication authentication) {
        
        String adminId = authentication.getName();
        log.info("管理员 {} 导入 {} 个系统预设", adminId, presets.size());
        
        return adminPresetService.importSystemPresets(presets, adminId)
                .map(savedPresets -> {
                    log.info("成功导入 {} 个系统预设", savedPresets.size());
                    return ResponseEntity.ok(ApiResponse.success(savedPresets));
                })
                .onErrorResume(e -> {
                    log.error("导入系统预设失败", e);
                    return Mono.just(ResponseEntity.badRequest()
                        .body(ApiResponse.error("导入系统预设失败: " + e.getMessage())));
                });
    }

    /**
     * 将用户预设提升为系统预设
     */
    @PostMapping("/promote/{userPresetId}")
    @Operation(summary = "提升为系统预设", description = "将用户预设提升为系统预设")
    public Mono<ResponseEntity<ApiResponse<AIPromptPreset>>> promoteUserPreset(
            @PathVariable String userPresetId,
            Authentication authentication) {
        
        String adminId = authentication.getName();
        log.info("管理员 {} 将用户预设 {} 提升为系统预设", adminId, userPresetId);
        
        return adminPresetService.promoteUserPresetToSystem(userPresetId, adminId)
                .map(systemPreset -> {
                    log.info("用户预设已成功提升为系统预设: {}", systemPreset.getPresetId());
                    return ResponseEntity.ok(ApiResponse.success(systemPreset));
                })
                .onErrorResume(e -> {
                    log.error("提升用户预设失败: {}", userPresetId, e);
                    return Mono.just(ResponseEntity.badRequest()
                        .body(ApiResponse.error("提升用户预设失败: " + e.getMessage())));
                });
    }

    /**
     * 批量可见性更新请求
     */
    public static class BatchVisibilityRequest {
        private List<String> presetIds;
        private boolean showInQuickAccess;

        public List<String> getPresetIds() {
            return presetIds;
        }

        public void setPresetIds(List<String> presetIds) {
            this.presetIds = presetIds;
        }

        public boolean isShowInQuickAccess() {
            return showInQuickAccess;
        }

        public void setShowInQuickAccess(boolean showInQuickAccess) {
            this.showInQuickAccess = showInQuickAccess;
        }
    }

    /**
     * 导出请求
     */
    public static class ExportRequest {
        private List<String> presetIds;

        public List<String> getPresetIds() {
            return presetIds;
        }

        public void setPresetIds(List<String> presetIds) {
            this.presetIds = presetIds;
        }
    }
}