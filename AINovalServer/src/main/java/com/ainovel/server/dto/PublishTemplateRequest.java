package com.ainovel.server.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 发布模板请求DTO
 */
@Data
public class PublishTemplateRequest {
    
    /**
     * 分享码
     */
    @NotBlank(message = "分享码不能为空")
    @Size(min = 4, max = 20, message = "分享码长度必须在4-20字符之间")
    private String shareCode;
} 