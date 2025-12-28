package com.ainovel.server.service.impl;

import com.ainovel.server.service.MailTestService;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;

import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;

/**
 * 邮件测试服务实现
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MailTestServiceImpl implements MailTestService {
    
    private final JavaMailSender mailSender;
    private final SecureRandom random = new SecureRandom();
    
    @Value("${spring.mail.host:}")
    private String mailHost;
    
    @Value("${spring.mail.port:0}")
    private int mailPort;
    
    @Value("${spring.mail.username:}")
    private String mailUsername;
    
    @Value("${spring.mail.protocol:smtp}")
    private String mailProtocol;
    
    @Value("${app.name:AINoval}")
    private String appName;
    
    @Value("${ainovel.mail.test-on-startup:false}")
    private boolean testOnStartup;
    
    @Value("${ainovel.mail.test-email:}")
    private String defaultTestEmail;
    
    // 保存最后一次测试结果
    private final AtomicLong lastTestTime = new AtomicLong(0);
    private final AtomicReference<Boolean> lastTestResult = new AtomicReference<>(null);
    
    @PostConstruct
    public void init() {
        if (testOnStartup) {
            log.info("启动时邮件测试已开启，将在应用启动后进行邮件配置测试");
            // 延迟执行，确保应用完全启动
            Mono.delay(java.time.Duration.ofSeconds(5))
                    .then(Mono.fromRunnable(this::testOnStartup))
                    .subscribe();
        }
    }
    
    @Override
    public void testOnStartup() {
        log.info("开始执行启动时邮件配置测试...");
        
        testMailConnection()
                .doOnNext(result -> {
                    if (result.success()) {
                        log.info("✅ 启动时邮件配置测试通过: {}", result.message());
                        
                        // 如果配置了默认测试邮箱，发送测试邮件
                        if (defaultTestEmail != null && !defaultTestEmail.isBlank()) {
                            sendTestMail(defaultTestEmail)
                                    .doOnNext(mailResult -> {
                                        if (mailResult.success()) {
                                            log.info("✅ 测试邮件发送成功: {}", defaultTestEmail);
                                        } else {
                                            log.warn("❌ 测试邮件发送失败: {}", mailResult.message());
                                        }
                                    })
                                    .subscribe();
                        }
                    } else {
                        log.warn("❌ 启动时邮件配置测试失败: {}", result.message());
                        log.warn("邮件功能可能无法正常工作，请检查配置");
                    }
                })
                .doOnError(error -> {
                    log.error("启动时邮件配置测试出现异常", error);
                })
                .subscribe();
    }
    
    @Override
    public Mono<MailTestResult> testMailConnection() {
        return Mono.fromCallable(() -> {
            try {
                log.debug("开始测试邮件服务器连接...");
                
                // 检查基本配置
                if (mailHost == null || mailHost.isBlank()) {
                    return new MailTestResult(false, "邮件服务器未配置", 
                            "spring.mail.host 未设置", null);
                }
                
                if (mailUsername == null || mailUsername.isBlank()) {
                    return new MailTestResult(false, "邮件用户名未配置", 
                            "spring.mail.username 未设置", null);
                }
                
                // 测试连接 - 通过尝试获取会话来验证配置
                if (mailSender instanceof org.springframework.mail.javamail.JavaMailSenderImpl) {
                    ((org.springframework.mail.javamail.JavaMailSenderImpl) mailSender).getSession();
                }
                
                // 记录测试结果
                lastTestTime.set(System.currentTimeMillis());
                lastTestResult.set(true);
                
                String details = String.format("服务器: %s:%d, 用户: %s, 协议: %s", 
                        mailHost, mailPort, mailUsername, mailProtocol);
                
                log.info("邮件服务器连接测试成功: {}", details);
                return new MailTestResult(true, "邮件配置测试通过", details, null);
                
            } catch (Exception e) {
                lastTestTime.set(System.currentTimeMillis());
                lastTestResult.set(false);
                
                String errorMsg = "邮件连接测试失败: " + e.getMessage();
                log.error(errorMsg, e);
                return new MailTestResult(false, errorMsg, e.getClass().getSimpleName(), null);
            }
        })
        .subscribeOn(Schedulers.boundedElastic());
    }
    
    @Override
    public Mono<MailTestResult> sendTestMail(String testEmail) {
        return Mono.fromCallable(() -> {
            try {
                log.debug("向 {} 发送测试邮件...", testEmail);
                
                SimpleMailMessage message = new SimpleMailMessage();
                message.setFrom(mailUsername);
                message.setTo(testEmail);
                message.setSubject(appName + " - 邮件服务测试");
                
                String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
                String content = String.format(
                    "这是一封来自 %s 的测试邮件。\n\n" +
                    "发送时间：%s\n" +
                    "邮件服务器：%s:%d\n" +
                    "发信账号：%s\n\n" +
                    "如果您收到这封邮件，说明邮件服务配置正常。\n\n" +
                    "%s团队",
                    appName, timestamp, mailHost, mailPort, mailUsername, appName
                );
                message.setText(content);
                
                mailSender.send(message);
                
                log.info("测试邮件发送成功: {}", testEmail);
                return new MailTestResult(true, "测试邮件发送成功", 
                        "邮件已发送，请检查收件箱", null);
                
            } catch (Exception e) {
                String errorMsg = "测试邮件发送失败: " + e.getMessage();
                log.error(errorMsg, e);
                return new MailTestResult(false, errorMsg, e.getClass().getSimpleName(), null);
            }
        })
        .subscribeOn(Schedulers.boundedElastic());
    }
    
    @Override
    public Mono<MailTestResult> sendTestVerificationCode(String testEmail) {
        return Mono.fromCallable(() -> {
            try {
                log.debug("向 {} 发送测试验证码...", testEmail);
                
                // 生成6位测试验证码
                String testCode = String.format("%06d", random.nextInt(1000000));
                
                SimpleMailMessage message = new SimpleMailMessage();
                message.setFrom(mailUsername);
                message.setTo(testEmail);
                message.setSubject(appName + " - 测试验证码");
                
                String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
                String content = String.format(
                    "您的测试验证码是：%s\n\n" +
                    "这是一个用于测试邮件服务的验证码。\n" +
                    "发送时间：%s\n" +
                    "此验证码仅用于测试，请勿用于实际业务。\n\n" +
                    "如果这不是您的操作，请忽略此邮件。\n\n" +
                    "%s团队",
                    testCode, timestamp, appName
                );
                message.setText(content);
                
                mailSender.send(message);
                
                log.info("测试验证码发送成功: {} -> {}", testEmail, testCode);
                return new MailTestResult(true, "测试验证码发送成功", 
                        "验证码已发送，请检查收件箱", testCode);
                
            } catch (Exception e) {
                String errorMsg = "测试验证码发送失败: " + e.getMessage();
                log.error(errorMsg, e);
                return new MailTestResult(false, errorMsg, e.getClass().getSimpleName(), null);
            }
        })
        .subscribeOn(Schedulers.boundedElastic());
    }
    
    @Override
    public Mono<MailStatus> getMailStatus() {
        return Mono.fromCallable(() -> {
            boolean configured = mailHost != null && !mailHost.isBlank() 
                    && mailUsername != null && !mailUsername.isBlank();
            
            return new MailStatus(
                    configured,
                    mailHost != null ? mailHost : "",
                    mailPort,
                    mailUsername != null ? mailUsername : "",
                    mailProtocol,
                    lastTestTime.get() > 0 ? lastTestTime.get() : null,
                    lastTestResult.get()
            );
        })
        .subscribeOn(Schedulers.boundedElastic());
    }
}