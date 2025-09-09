package com.ainovel.server.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.domain.model.User;
import com.ainovel.server.service.AdminUserService;
import com.ainovel.server.service.CreditService;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;

/**
 * 管理员用户管理控制器
 */
@RestController
@RequestMapping("/api/v1/admin/users")
@PreAuthorize("hasAuthority('ADMIN_MANAGE_USERS')")
public class AdminUserController {
    
    private final AdminUserService adminUserService;
    private final CreditService creditService;
    
    @Autowired
    public AdminUserController(AdminUserService adminUserService, CreditService creditService) {
        this.adminUserService = adminUserService;
        this.creditService = creditService;
    }
    
    /**
     * 获取用户列表（分页）
     */
    @GetMapping
    public Mono<ResponseEntity<ApiResponse<List<User>>>> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String search) {
        
        Pageable pageable = PageRequest.of(page, size);
        
        Flux<User> usersFlux;
        if (search != null && !search.trim().isEmpty()) {
            usersFlux = adminUserService.searchUsers(search, pageable);
        } else {
            usersFlux = adminUserService.findAllUsers(pageable);
        }
        
        // 将Flux转换为List后返回，确保前端能正确解析
        return usersFlux.collectList()
                .map(users -> ResponseEntity.ok(ApiResponse.success(users)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 根据ID获取用户详情
     */
    @GetMapping("/{id}")
    public Mono<ResponseEntity<ApiResponse<User>>> getUserById(@PathVariable String id) {
        return adminUserService.findUserById(id)
                .map(user -> ResponseEntity.ok(ApiResponse.success(user)))
                .defaultIfEmpty(ResponseEntity.notFound().build());
    }
    
    /**
     * 更新用户信息
     */
    @PutMapping("/{id}")
    public Mono<ResponseEntity<ApiResponse<User>>> updateUser(@PathVariable String id, @RequestBody UserUpdateRequest request) {
        return adminUserService.updateUser(id, request)
                .map(updatedUser -> ResponseEntity.ok(ApiResponse.success(updatedUser)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 禁用/启用用户账户
     */
    @PatchMapping("/{id}/status")
    public Mono<ResponseEntity<ApiResponse<User>>> toggleUserStatus(
            @PathVariable String id, 
            @RequestBody UserStatusRequest request) {
        return adminUserService.updateUserStatus(id, request.getStatus())
                .map(updatedUser -> ResponseEntity.ok(ApiResponse.success(updatedUser)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 为用户分配角色
     */
    @PostMapping("/{id}/roles")
    public Mono<ResponseEntity<ApiResponse<User>>> assignRoleToUser(
            @PathVariable String id, 
            @RequestBody RoleAssignmentRequest request) {
        return adminUserService.assignRoleToUser(id, request.getRoleId())
                .map(updatedUser -> ResponseEntity.ok(ApiResponse.success(updatedUser)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 移除用户角色
     */
    @DeleteMapping("/{id}/roles/{roleId}")
    public Mono<ResponseEntity<ApiResponse<User>>> removeRoleFromUser(
            @PathVariable String id, 
            @PathVariable String roleId) {
        return adminUserService.removeRoleFromUser(id, roleId)
                .map(updatedUser -> ResponseEntity.ok(ApiResponse.success(updatedUser)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 为用户添加积分
     */
    @PostMapping("/{id}/credits")
    public Mono<ResponseEntity<ApiResponse<Long>>> addCreditsToUser(
            @PathVariable String id, 
            @RequestBody CreditOperationRequest request) {
        return creditService.addCredits(id, request.getAmount(), request.getReason())
                .then(creditService.getUserCredits(id))
                .map(credits -> ResponseEntity.ok(ApiResponse.success(credits)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 扣减用户积分
     */
    @DeleteMapping("/{id}/credits")
    public Mono<ResponseEntity<ApiResponse<Long>>> deductCreditsFromUser(
            @PathVariable String id, 
            @RequestBody CreditOperationRequest request) {
        return creditService.deductCredits(id, request.getAmount())
                .then(creditService.getUserCredits(id))
                .map(credits -> ResponseEntity.ok(ApiResponse.success(credits)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 获取用户统计信息
     */
    @GetMapping("/statistics")
    public Mono<ResponseEntity<ApiResponse<UserStatistics>>> getUserStatistics() {
        return adminUserService.getUserStatistics()
                .map(stats -> ResponseEntity.ok(ApiResponse.success(stats)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 用户更新请求DTO
     */
    public static class UserUpdateRequest {
        private String email;
        private String displayName;
        private User.AccountStatus accountStatus;
        
        // Getters and setters
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        
        public String getDisplayName() { return displayName; }
        public void setDisplayName(String displayName) { this.displayName = displayName; }
        
        public User.AccountStatus getAccountStatus() { return accountStatus; }
        public void setAccountStatus(User.AccountStatus accountStatus) { this.accountStatus = accountStatus; }
    }
    
    /**
     * 用户状态请求DTO
     */
    public static class UserStatusRequest {
        private User.AccountStatus status;
        
        public User.AccountStatus getStatus() { return status; }
        public void setStatus(User.AccountStatus status) { this.status = status; }
    }
    
    /**
     * 角色分配请求DTO
     */
    public static class RoleAssignmentRequest {
        private String roleId;
        
        public String getRoleId() { return roleId; }
        public void setRoleId(String roleId) { this.roleId = roleId; }
    }
    
    /**
     * 积分操作请求DTO
     */
    public static class CreditOperationRequest {
        private long amount;
        private String reason;
        
        public long getAmount() { return amount; }
        public void setAmount(long amount) { this.amount = amount; }
        
        public String getReason() { return reason; }
        public void setReason(String reason) { this.reason = reason; }
    }
    
    /**
     * 用户统计信息DTO
     */
    public static class UserStatistics {
        private long totalUsers;
        private long activeUsers;
        private long suspendedUsers;
        private long newUsersToday;
        private long newUsersThisWeek;
        private long newUsersThisMonth;
        
        // Getters and setters
        public long getTotalUsers() { return totalUsers; }
        public void setTotalUsers(long totalUsers) { this.totalUsers = totalUsers; }
        
        public long getActiveUsers() { return activeUsers; }
        public void setActiveUsers(long activeUsers) { this.activeUsers = activeUsers; }
        
        public long getSuspendedUsers() { return suspendedUsers; }
        public void setSuspendedUsers(long suspendedUsers) { this.suspendedUsers = suspendedUsers; }
        
        public long getNewUsersToday() { return newUsersToday; }
        public void setNewUsersToday(long newUsersToday) { this.newUsersToday = newUsersToday; }
        
        public long getNewUsersThisWeek() { return newUsersThisWeek; }
        public void setNewUsersThisWeek(long newUsersThisWeek) { this.newUsersThisWeek = newUsersThisWeek; }
        
        public long getNewUsersThisMonth() { return newUsersThisMonth; }
        public void setNewUsersThisMonth(long newUsersThisMonth) { this.newUsersThisMonth = newUsersThisMonth; }
    }
}