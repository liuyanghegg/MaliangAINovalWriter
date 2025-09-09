package com.ainovel.server.web.dto;

/**
 * 管理员认证请求DTO
 */
public class AdminAuthRequest {
    private String username;
    private String password;
    
    public AdminAuthRequest() {
    }
    
    public AdminAuthRequest(String username, String password) {
        this.username = username;
        this.password = password;
    }
    
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getPassword() {
        return password;
    }
    
    public void setPassword(String password) {
        this.password = password;
    }
} 