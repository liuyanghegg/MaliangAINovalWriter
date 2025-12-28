package com.ainovel.server.web.dto.novelsetting;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 父子关系管理请求DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ParentChildRelationshipRequest {
    
    // 子设定ID
    private String childId;
    
    // 父设定ID
    private String parentId;
    
    // 操作描述（可选）
    private String description;
}