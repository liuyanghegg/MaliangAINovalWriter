package com.ainovel.server.web.dto;

import java.util.List;

/**
 * 管理员认证响应DTO
 */
public class AdminAuthResponse {
    private String token;
    private String refreshToken;
    private String userId;
    private String username;
    private String displayName;
    private List<String> roles;
    private List<String> permissions;
    
    public AdminAuthResponse() {
    }
    
    public AdminAuthResponse(String token, String refreshToken, String userId, String username, 
                           String displayName, List<String> roles, List<String> permissions) {
        this.token = token;
        this.refreshToken = refreshToken;
        this.userId = userId;
        this.username = username;
        this.displayName = displayName;
        this.roles = roles;
        this.permissions = permissions;
    }
    
    public String getToken() {
        return token;
    }
    
    public void setToken(String token) {
        this.token = token;
    }
    
    public String getRefreshToken() {
        return refreshToken;
    }
    
    public void setRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }
    
    public String getUserId() {
        return userId;
    }
    
    public void setUserId(String userId) {
        this.userId = userId;
    }
    
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getDisplayName() {
        return displayName;
    }
    
    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }
    
    public List<String> getRoles() {
        return roles;
    }
    
    public void setRoles(List<String> roles) {
        this.roles = roles;
    }
    
    public List<String> getPermissions() {
        return permissions;
    }
    
    public void setPermissions(List<String> permissions) {
        this.permissions = permissions;
    }
} 