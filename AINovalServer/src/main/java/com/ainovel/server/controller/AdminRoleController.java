package com.ainovel.server.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.domain.model.Role;
import com.ainovel.server.service.RoleService;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 管理员角色管理控制器
 */
@RestController
@RequestMapping("/api/v1/admin/roles")
@PreAuthorize("hasAuthority('ADMIN_MANAGE_ROLES') or hasRole('SUPER_ADMIN')")
public class AdminRoleController {
    
    private final RoleService roleService;
    
    @Autowired
    public AdminRoleController(RoleService roleService) {
        this.roleService = roleService;
    }
    
    /**
     * 获取所有角色列表
     */
    @GetMapping
    public Mono<ResponseEntity<ApiResponse<List<Role>>>> getAllRoles() {
        return roleService.findAll()
                .collectList()
                .map(roles -> ResponseEntity.ok(ApiResponse.success(roles)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 根据ID获取角色
     */
    @GetMapping("/{id}")
    public Mono<ResponseEntity<ApiResponse<Role>>> getRoleById(@PathVariable String id) {
        return roleService.findById(id)
                .map(role -> ResponseEntity.ok(ApiResponse.success(role)))
                .defaultIfEmpty(ResponseEntity.notFound().build());
    }
    
    /**
     * 创建新角色
     */
    @PostMapping
    public Mono<ResponseEntity<ApiResponse<Role>>> createRole(@RequestBody Role role) {
        return roleService.createRole(role)
                .map(savedRole -> ResponseEntity.ok(ApiResponse.success(savedRole)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 更新角色
     */
    @PutMapping("/{id}")
    public Mono<ResponseEntity<ApiResponse<Role>>> updateRole(@PathVariable String id, @RequestBody Role role) {
        return roleService.updateRole(id, role)
                .map(updatedRole -> ResponseEntity.ok(ApiResponse.success(updatedRole)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 删除角色
     */
    @DeleteMapping("/{id}")
    public Mono<ResponseEntity<ApiResponse<Void>>> deleteRole(@PathVariable String id) {
        return roleService.deleteRole(id)
                .then(Mono.just(ResponseEntity.ok(ApiResponse.<Void>success())))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.<Void>error(e.getMessage()))
                ));
    }
    
    /**
     * 为角色添加权限
     */
    @PostMapping("/{id}/permissions")
    public Mono<ResponseEntity<ApiResponse<Role>>> addPermissionToRole(
            @PathVariable String id, 
            @RequestBody PermissionRequest request) {
        return roleService.addPermissionToRole(id, request.getPermission())
                .map(updatedRole -> ResponseEntity.ok(ApiResponse.success(updatedRole)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 从角色移除权限
     */
    @DeleteMapping("/{id}/permissions/{permission}")
    public Mono<ResponseEntity<ApiResponse<Role>>> removePermissionFromRole(
            @PathVariable String id, 
            @PathVariable String permission) {
        return roleService.removePermissionFromRole(id, permission)
                .map(updatedRole -> ResponseEntity.ok(ApiResponse.success(updatedRole)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 权限请求DTO
     */
    public static class PermissionRequest {
        private String permission;
        
        public String getPermission() {
            return permission;
        }
        
        public void setPermission(String permission) {
            this.permission = permission;
        }
    }
}