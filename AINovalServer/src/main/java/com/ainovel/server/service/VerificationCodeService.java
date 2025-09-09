package com.ainovel.server.service;

import reactor.core.publisher.Mono;

/**
 * 验证码服务接口
 */
public interface VerificationCodeService {
    
    /**
     * 发送手机验证码
     */
    Mono<Boolean> sendPhoneVerificationCode(String phone, String purpose);
    
    /**
     * 发送邮箱验证码
     */
    Mono<Boolean> sendEmailVerificationCode(String email, String purpose);
    
    /**
     * 验证手机验证码
     */
    Mono<Boolean> verifyPhoneCode(String phone, String code, String purpose);
    
    /**
     * 验证邮箱验证码
     */
    Mono<Boolean> verifyEmailCode(String email, String code, String purpose);
    
    /**
     * 生成图片验证码
     */
    Mono<CaptchaResult> generateCaptcha();
    
    /**
     * 验证图片验证码
     */
    Mono<Boolean> verifyCaptcha(String captchaId, String captchaCode);
    
    /**
     * 验证图片验证码
     * @param captchaId 验证码ID
     * @param captchaCode 用户输入的验证码
     * @param consume 是否在验证成功后消费（失效）该验证码
     * @return 验证是否通过
     */
    Mono<Boolean> verifyCaptcha(String captchaId, String captchaCode, boolean consume);
    
    /**
     * 图片验证码结果
     */
    record CaptchaResult(String captchaId, String captchaImage) {}
}