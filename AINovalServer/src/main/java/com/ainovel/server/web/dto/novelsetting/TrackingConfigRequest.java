package com.ainovel.server.web.dto.novelsetting;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 追踪配置请求DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TrackingConfigRequest {
    
    // 设定条目ID
    private String itemId;
    
    // 名称/别名追踪设置
    private String nameAliasTracking;
    
    // AI上下文追踪设置
    private String aiContextTracking;
    
    // 引用更新策略
    private String referenceUpdatePolicy;
}