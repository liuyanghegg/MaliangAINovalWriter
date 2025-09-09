package com.ainovel.server.service;

import reactor.core.publisher.Mono;

/**
 * 邮件测试服务接口
 */
public interface MailTestService {
    
    /**
     * 测试邮件连接
     * @return 测试结果
     */
    Mono<MailTestResult> testMailConnection();
    
    /**
     * 发送测试邮件
     * @param testEmail 测试邮箱
     * @return 发送结果
     */
    Mono<MailTestResult> sendTestMail(String testEmail);
    
    /**
     * 发送测试验证码
     * @param testEmail 测试邮箱
     * @return 发送结果（包含验证码）
     */
    Mono<MailTestResult> sendTestVerificationCode(String testEmail);
    
    /**
     * 获取邮件服务状态
     * @return 邮件服务状态
     */
    Mono<MailStatus> getMailStatus();
    
    /**
     * 在应用启动时测试邮件配置
     */
    void testOnStartup();
    
    /**
     * 邮件测试结果
     */
    record MailTestResult(
            boolean success,
            String message,
            String details,
            String verificationCode
    ) {}
    
    /**
     * 邮件服务状态
     */
    record MailStatus(
            boolean configured,
            String host,
            int port,
            String username,
            String protocol,
            Long lastTestTime,
            Boolean lastTestResult
    ) {}
}