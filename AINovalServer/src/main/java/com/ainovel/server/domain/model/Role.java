package com.ainovel.server.domain.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 角色实体类
 * 用于定义用户角色和权限管理
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "roles")
public class Role {
    
    @Id
    private String id;
    
    /**
     * 角色名称（内部标识符，如 ROLE_FREE, ROLE_PRO, ROLE_ADMIN）
     */
    @Indexed(unique = true)
    private String roleName;
    
    /**
     * 显示名称（用于UI显示，如 "免费用户", "专业版会员", "管理员"）
     */
    private String displayName;
    
    /**
     * 角色描述
     */
    private String description;
    
    /**
     * 该角色拥有的权限列表
     */
    @Builder.Default
    private List<String> permissions = new ArrayList<>();
    
    /**
     * 角色是否启用
     */
    @Builder.Default
    private Boolean enabled = true;
    
    /**
     * 角色优先级（数值越高，优先级越高）
     */
    @Builder.Default
    private Integer priority = 0;
    
    /**
     * 创建时间
     */
    private LocalDateTime createdAt;
    
    /**
     * 更新时间
     */
    private LocalDateTime updatedAt;
    
    /**
     * 检查角色是否拥有指定权限
     * 
     * @param permission 权限标识符
     * @return 是否拥有该权限
     */
    public boolean hasPermission(String permission) {
        return permissions != null && permissions.contains(permission);
    }
    
    /**
     * 添加权限
     * 
     * @param permission 权限标识符
     */
    public void addPermission(String permission) {
        if (permissions == null) {
            permissions = new ArrayList<>();
        }
        if (!permissions.contains(permission)) {
            permissions.add(permission);
        }
    }
    
    /**
     * 移除权限
     * 
     * @param permission 权限标识符
     */
    public void removePermission(String permission) {
        if (permissions != null) {
            permissions.remove(permission);
        }
    }
}