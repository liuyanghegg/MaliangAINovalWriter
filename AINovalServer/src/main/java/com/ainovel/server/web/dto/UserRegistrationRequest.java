package com.ainovel.server.web.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 用户注册请求DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserRegistrationRequest {
    
    /**
     * 用户名
     */
    @NotBlank(message = "用户名不能为空")
    @Size(min = 3, max = 20, message = "用户名长度必须在3-20个字符之间")
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "用户名只能包含字母、数字和下划线")
    private String username;
    
    /**
     * 密码
     */
    @NotBlank(message = "密码不能为空")
    @Size(min = 6, max = 50, message = "密码长度必须在6-50个字符之间")
    private String password;
    
    /**
     * 邮箱
     */
    @Email(message = "邮箱格式不正确")
    private String email;
    
    /**
     * 手机号
     */
    @Pattern(regexp = "^$|^1[3-9]\\d{9}$", message = "手机号格式不正确")
    private String phone;
    
    /**
     * 显示名称
     */
    private String displayName;
    
    /**
     * 图片验证码ID
     */
    @NotBlank(message = "验证码ID不能为空")
    private String captchaId;
    
    /**
     * 图片验证码
     */
    @NotBlank(message = "验证码不能为空")
    @Size(min = 4, max = 4, message = "验证码长度必须为4位")
    private String captchaCode;
    
    /**
     * 邮箱验证码（如果通过邮箱注册）
     */
    private String emailVerificationCode;
    
    /**
     * 手机验证码（如果通过手机注册）
     */
    private String phoneVerificationCode;
}