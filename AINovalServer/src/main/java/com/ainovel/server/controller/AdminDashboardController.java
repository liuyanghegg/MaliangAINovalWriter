package com.ainovel.server.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.service.AdminDashboardService;

import reactor.core.publisher.Mono;

/**
 * 管理员仪表板控制器
 */
@RestController
@RequestMapping("/api/v1/admin/dashboard")
@PreAuthorize("hasAuthority('ADMIN_VIEW_DASHBOARD')")
public class AdminDashboardController {
    
    private final AdminDashboardService adminDashboardService;
    
    @Autowired
    public AdminDashboardController(AdminDashboardService adminDashboardService) {
        this.adminDashboardService = adminDashboardService;
    }
    
    /**
     * 获取仪表板统计数据
     */
    @GetMapping("/stats")
    public Mono<ResponseEntity<ApiResponse<DashboardStats>>> getDashboardStats() {
        return adminDashboardService.getDashboardStats()
                .map(stats -> ResponseEntity.ok(ApiResponse.success(stats)))
                .onErrorResume(e -> Mono.just(
                    ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()))
                ));
    }
    
    /**
     * 仪表板统计数据DTO
     */
    public static class DashboardStats {
        private int totalUsers;
        private int activeUsers;
        private int totalNovels;
        private int aiRequestsToday;
        private double creditsConsumed;
        private java.util.List<ChartData> userGrowthData;
        private java.util.List<ChartData> requestsData;
        private java.util.List<ActivityItem> recentActivities;
        
        public DashboardStats() {}
        
        public DashboardStats(int totalUsers, int activeUsers, int totalNovels, 
                           int aiRequestsToday, double creditsConsumed,
                           java.util.List<ChartData> userGrowthData,
                           java.util.List<ChartData> requestsData,
                           java.util.List<ActivityItem> recentActivities) {
            this.totalUsers = totalUsers;
            this.activeUsers = activeUsers;
            this.totalNovels = totalNovels;
            this.aiRequestsToday = aiRequestsToday;
            this.creditsConsumed = creditsConsumed;
            this.userGrowthData = userGrowthData;
            this.requestsData = requestsData;
            this.recentActivities = recentActivities;
        }
        
        // Getters and setters
        public int getTotalUsers() { return totalUsers; }
        public void setTotalUsers(int totalUsers) { this.totalUsers = totalUsers; }
        
        public int getActiveUsers() { return activeUsers; }
        public void setActiveUsers(int activeUsers) { this.activeUsers = activeUsers; }
        
        public int getTotalNovels() { return totalNovels; }
        public void setTotalNovels(int totalNovels) { this.totalNovels = totalNovels; }
        
        public int getAiRequestsToday() { return aiRequestsToday; }
        public void setAiRequestsToday(int aiRequestsToday) { this.aiRequestsToday = aiRequestsToday; }
        
        public double getCreditsConsumed() { return creditsConsumed; }
        public void setCreditsConsumed(double creditsConsumed) { this.creditsConsumed = creditsConsumed; }
        
        public java.util.List<ChartData> getUserGrowthData() { return userGrowthData; }
        public void setUserGrowthData(java.util.List<ChartData> userGrowthData) { this.userGrowthData = userGrowthData; }
        
        public java.util.List<ChartData> getRequestsData() { return requestsData; }
        public void setRequestsData(java.util.List<ChartData> requestsData) { this.requestsData = requestsData; }
        
        public java.util.List<ActivityItem> getRecentActivities() { return recentActivities; }
        public void setRecentActivities(java.util.List<ActivityItem> recentActivities) { this.recentActivities = recentActivities; }
    }
    
    /**
     * 图表数据DTO
     */
    public static class ChartData {
        private String label;
        private double value;
        private java.time.LocalDateTime date;
        
        public ChartData() {}
        
        public ChartData(String label, double value, java.time.LocalDateTime date) {
            this.label = label;
            this.value = value;
            this.date = date;
        }
        
        public String getLabel() { return label; }
        public void setLabel(String label) { this.label = label; }
        
        public double getValue() { return value; }
        public void setValue(double value) { this.value = value; }
        
        public java.time.LocalDateTime getDate() { return date; }
        public void setDate(java.time.LocalDateTime date) { this.date = date; }
    }
    
    /**
     * 活动项DTO
     */
    public static class ActivityItem {
        private String id;
        private String userId;
        private String userName;
        private String action;
        private String description;
        private java.time.LocalDateTime timestamp;
        private String metadata;
        
        public ActivityItem() {}
        
        public ActivityItem(String id, String userId, String userName, String action, 
                          String description, java.time.LocalDateTime timestamp, String metadata) {
            this.id = id;
            this.userId = userId;
            this.userName = userName;
            this.action = action;
            this.description = description;
            this.timestamp = timestamp;
            this.metadata = metadata;
        }
        
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        
        public String getUserId() { return userId; }
        public void setUserId(String userId) { this.userId = userId; }
        
        public String getUserName() { return userName; }
        public void setUserName(String userName) { this.userName = userName; }
        
        public String getAction() { return action; }
        public void setAction(String action) { this.action = action; }
        
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        
        public java.time.LocalDateTime getTimestamp() { return timestamp; }
        public void setTimestamp(java.time.LocalDateTime timestamp) { this.timestamp = timestamp; }
        
        public String getMetadata() { return metadata; }
        public void setMetadata(String metadata) { this.metadata = metadata; }
    }
}