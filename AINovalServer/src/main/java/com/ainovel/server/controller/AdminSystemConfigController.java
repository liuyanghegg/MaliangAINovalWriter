package com.ainovel.server.controller;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.domain.model.SystemConfig;
import com.ainovel.server.service.SystemConfigService;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 管理员系统配置管理控制器
 */
@RestController
@RequestMapping("/api/v1/admin/system-configs")
@PreAuthorize("hasAuthority('ADMIN_MANAGE_CONFIGS') or hasRole('SUPER_ADMIN')")
public class AdminSystemConfigController {
    
    private final SystemConfigService systemConfigService;
    
    @Autowired
    public AdminSystemConfigController(SystemConfigService systemConfigService) {
        this.systemConfigService = systemConfigService;
    }
    
    /**
     * 获取所有系统配置
     */
    @GetMapping
    public Mono<ResponseEntity<ApiResponse<List<SystemConfig>>>> getAllConfigs() {
        return systemConfigService.findAll()
                .collectList()
                .map(configs -> ResponseEntity.ok(ApiResponse.success(configs)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 根据配置分组获取配置
     */
    @GetMapping("/group/{group}")
    public Mono<ResponseEntity<ApiResponse<List<SystemConfig>>>> getConfigsByGroup(@PathVariable String group) {
        return systemConfigService.findByGroup(group)
                .collectList()
                .map(configs -> ResponseEntity.ok(ApiResponse.success(configs)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 获取所有非只读配置
     */
    @GetMapping("/editable")
    public Mono<ResponseEntity<ApiResponse<List<SystemConfig>>>> getEditableConfigs() {
        return systemConfigService.findAllNonReadOnly()
                .collectList()
                .map(configs -> ResponseEntity.ok(ApiResponse.success(configs)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 根据配置键获取配置
     */
    @GetMapping("/{configKey}")
    public Mono<ResponseEntity<ApiResponse<SystemConfig>>> getConfigByKey(@PathVariable String configKey) {
        return systemConfigService.getConfig(configKey)
                .map(config -> ResponseEntity.ok(ApiResponse.success(config)))
                .defaultIfEmpty(ResponseEntity.notFound().build());
    }
    
    /**
     * 创建新系统配置
     */
    @PostMapping
    public Mono<ResponseEntity<ApiResponse<SystemConfig>>> createConfig(@RequestBody SystemConfig config) {
        return systemConfigService.createConfig(config)
                .map(savedConfig -> ResponseEntity.ok(ApiResponse.success(savedConfig)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 更新系统配置
     */
    @PutMapping("/{id}")
    public Mono<ResponseEntity<ApiResponse<SystemConfig>>> updateConfig(@PathVariable String id, @RequestBody SystemConfig config) {
        return systemConfigService.updateConfig(id, config)
                .map(updatedConfig -> ResponseEntity.ok(ApiResponse.success(updatedConfig)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 删除系统配置
     */
    @DeleteMapping("/{id}")
    public Mono<ResponseEntity<ApiResponse<Void>>> deleteConfig(@PathVariable String id) {
        return systemConfigService.deleteConfig(id)
                .then(Mono.just(ResponseEntity.ok(ApiResponse.<Void>success())))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.<Void>error(e.getMessage()))
                ));
    }
    
    /**
     * 设置配置值
     */
    @PatchMapping("/{configKey}/value")
    public Mono<ResponseEntity<ApiResponse<Boolean>>> setConfigValue(
            @PathVariable String configKey, 
            @RequestBody ValueRequest request) {
        return systemConfigService.setConfigValue(configKey, request.getValue())
                .map(result -> ResponseEntity.ok(ApiResponse.success(result)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 批量设置配置值
     */
    @PatchMapping("/batch")
    public Mono<ResponseEntity<ApiResponse<Boolean>>> setConfigValues(@RequestBody Map<String, String> configs) {
        return systemConfigService.setConfigValues(configs)
                .map(result -> ResponseEntity.ok(ApiResponse.success(result)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 初始化默认配置
     */
    @PostMapping("/initialize")
    public Mono<ResponseEntity<ApiResponse<Boolean>>> initializeDefaultConfigs() {
        return systemConfigService.initializeDefaultConfigs()
                .map(result -> ResponseEntity.ok(ApiResponse.success(result)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 验证配置值
     */
    @PostMapping("/{configKey}/validate")
    public Mono<ResponseEntity<ApiResponse<Boolean>>> validateConfigValue(
            @PathVariable String configKey, 
            @RequestBody ValueRequest request) {
        return systemConfigService.validateConfigValue(configKey, request.getValue())
                .map(result -> ResponseEntity.ok(ApiResponse.success(result)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 值请求DTO
     */
    public static class ValueRequest {
        private String value;
        
        public String getValue() {
            return value;
        }
        
        public void setValue(String value) {
            this.value = value;
        }
    }
}