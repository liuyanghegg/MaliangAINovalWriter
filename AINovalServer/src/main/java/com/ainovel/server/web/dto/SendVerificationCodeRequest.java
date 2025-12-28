package com.ainovel.server.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

/**
 * 发送验证码请求
 */
@Data
public class SendVerificationCodeRequest {
    
    /**
     * 类型：phone 或 email
     */
    @NotBlank(message = "类型不能为空")
    @Pattern(regexp = "^(phone|email)$", message = "类型只能是phone或email")
    private String type;
    
    /**
     * 手机号或邮箱
     */
    @NotBlank(message = "接收方不能为空")
    private String target;
    
    /**
     * 用途：login 或 register
     */
    @NotBlank(message = "用途不能为空")
    @Pattern(regexp = "^(login|register)$", message = "用途只能是login或register")
    private String purpose;
    
    /**
     * 图片验证码ID（注册时必需）
     */
    private String captchaId;
    
    /**
     * 图片验证码（注册时必需）
     */
    private String captchaCode;
}