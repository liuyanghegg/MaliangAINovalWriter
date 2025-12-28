package com.ainovel.server.service.impl;

import com.ainovel.server.service.VerificationCodeService;
import com.aliyun.dysmsapi20170525.Client;
import com.aliyun.dysmsapi20170525.models.SendSmsRequest;
import com.aliyun.dysmsapi20170525.models.SendSmsResponse;
import com.aliyun.teaopenapi.models.Config;
import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.google.code.kaptcha.impl.DefaultKaptcha;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Properties;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * 验证码服务实现
 */
@Slf4j
@Service
public class VerificationCodeServiceImpl implements VerificationCodeService {
    
    private final JavaMailSender mailSender;
    private Client smsClient;
    private final DefaultKaptcha kaptcha;
    private final SecureRandom random = new SecureRandom();
    
    // 使用Caffeine作为内存缓存
    private final Cache<String, String> verificationCodeCache = Caffeine.newBuilder()
            .expireAfterWrite(5, TimeUnit.MINUTES)
            .maximumSize(10000)
            .build();
    
    // 发送频率限制缓存（1分钟过期）
    private final Cache<String, String> rateLimitCache = Caffeine.newBuilder()
            .expireAfterWrite(1, TimeUnit.MINUTES)
            .maximumSize(10000)
            .build();
    
    private final Cache<String, String> captchaCache = Caffeine.newBuilder()
            .expireAfterWrite(5, TimeUnit.MINUTES)
            .maximumSize(1000)
            .build();
    
    @Value("${aliyun.sms.access-key-id}")
    private String accessKeyId;
    
    @Value("${aliyun.sms.access-key-secret}")
    private String accessKeySecret;
    
    @Value("${aliyun.sms.sign-name}")
    private String signName;
    
    @Value("${aliyun.sms.template-code}")
    private String templateCode;
    
    @Value("${spring.mail.username}")
    private String fromEmail;
    
    @Value("${app.name:AINoval}")
    private String appName;
    
    public VerificationCodeServiceImpl(JavaMailSender mailSender) {
        this.mailSender = mailSender;
        
        // 初始化Kaptcha
        this.kaptcha = new DefaultKaptcha();
        Properties properties = new Properties();
        properties.setProperty("kaptcha.border", "yes");
        properties.setProperty("kaptcha.border.color", "105,179,90");
        properties.setProperty("kaptcha.textproducer.font.color", "blue");
        properties.setProperty("kaptcha.image.width", "125");
        properties.setProperty("kaptcha.image.height", "45");
        properties.setProperty("kaptcha.textproducer.font.size", "35");
        properties.setProperty("kaptcha.textproducer.char.length", "4");
        properties.setProperty("kaptcha.textproducer.font.names", "宋体,楷体,微软雅黑");
        com.google.code.kaptcha.util.Config kaptchaConfig = new com.google.code.kaptcha.util.Config(properties);
        kaptcha.setConfig(kaptchaConfig);
        
        // 初始化阿里云短信客户端将在第一次使用时进行
        this.smsClient = null;
    }
    
    private synchronized Client getSmsClient() throws Exception {
        if (smsClient == null) {
            Config config = new Config()
                    .setAccessKeyId(accessKeyId)
                    .setAccessKeySecret(accessKeySecret)
                    .setEndpoint("dysmsapi.aliyuncs.com");
            smsClient = new Client(config);
        }
        return smsClient;
    }
    
    @Override
    public Mono<Boolean> sendPhoneVerificationCode(String phone, String purpose) {
        log.info("开始执行手机验证码发送，phone: {}, purpose: {}", phone, purpose);
        return Mono.fromCallable(() -> {
            // 生成6位验证码
            String code = generateNumericCode(6);
            String cacheKey = buildCacheKey("phone", phone, purpose);
            
            // 检查是否频繁发送（1分钟限制）
            String rateLimitKey = "rate_limit:phone:" + phone + ":" + purpose;
            if (rateLimitCache.getIfPresent(rateLimitKey) != null) {
                log.warn("验证码发送过于频繁: {}", phone);
                return false;
            }
            
            // 发送短信
            SendSmsRequest request = new SendSmsRequest()
                    .setPhoneNumbers(phone)
                    .setSignName(signName)
                    .setTemplateCode(templateCode)
                    .setTemplateParam("{\"code\":\"" + code + "\"}");
            
            SendSmsResponse response = getSmsClient().sendSms(request);
            
            if ("OK".equals(response.getBody().getCode())) {
                // 存储验证码
                verificationCodeCache.put(cacheKey, code);
                // 设置1分钟发送锁
                rateLimitCache.put(rateLimitKey, "1");
                
                log.info("手机验证码发送成功: {}", phone);
                return true;
            } else {
                log.error("手机验证码发送失败: {}, 错误: {}", phone, response.getBody().getMessage());
                return false;
            }
        })
        .subscribeOn(Schedulers.boundedElastic())
        .onErrorResume(throwable -> {
            log.error("手机验证码发送过程中发生异常: {}, phone: {}", throwable.getMessage(), phone, throwable);
            return Mono.just(false);
        });
    }
    
    @Override
    public Mono<Boolean> sendEmailVerificationCode(String email, String purpose) {
        log.info("开始执行邮箱验证码发送，email: {}, purpose: {}", email, purpose);
        return Mono.fromCallable(() -> {
            // 生成6位验证码
            String code = generateNumericCode(6);
            String cacheKey = buildCacheKey("email", email, purpose);
            log.info("生成邮箱验证码，email: {}, purpose: {}, code: {}, cacheKey: {}", 
                    email, purpose, code, cacheKey);
            
            // 检查是否频繁发送（1分钟限制）
            String rateLimitKey = "rate_limit:email:" + email + ":" + purpose;
            if (rateLimitCache.getIfPresent(rateLimitKey) != null) {
                log.warn("验证码发送过于频繁，email: {}, purpose: {}", email, purpose);
                return false;
            }
            
            // 发送邮件
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(email);
            message.setSubject(appName + " - 验证码");
            
            String emailContent = String.format(
                "您的验证码是：%s\n\n" +
                "此验证码5分钟内有效，请勿泄露给他人。\n\n" +
                "如果这不是您的操作，请忽略此邮件。\n\n" +
                "%s团队",
                code, appName
            );
            message.setText(emailContent);
            
            mailSender.send(message);
            
            // 存储验证码
            verificationCodeCache.put(cacheKey, code);
            // 设置1分钟发送锁
            rateLimitCache.put(rateLimitKey, "1");
            
            log.info("邮箱验证码发送成功，email: {}, purpose: {}, cacheKey: {}", 
                    email, purpose, cacheKey);
            return true;
        })
        .subscribeOn(Schedulers.boundedElastic())
        .onErrorResume(throwable -> {
            log.error("邮箱验证码发送过程中发生异常，email: {}, purpose: {}, 错误: {}", 
                    email, purpose, throwable.getMessage(), throwable);
            return Mono.just(false);
        });
    }
    
    @Override
    public Mono<Boolean> verifyPhoneCode(String phone, String code, String purpose) {
        return Mono.fromCallable(() -> {
            String cacheKey = buildCacheKey("phone", phone, purpose);
            String storedCode = verificationCodeCache.getIfPresent(cacheKey);
            
            if (storedCode != null && storedCode.equals(code)) {
                // 验证成功，删除验证码和频率限制
                verificationCodeCache.invalidate(cacheKey);
                String rateLimitKey = "rate_limit:phone:" + phone + ":" + purpose;
                rateLimitCache.invalidate(rateLimitKey);
                return true;
            }
            
            return false;
        });
    }
    
    @Override
    public Mono<Boolean> verifyEmailCode(String email, String code, String purpose) {
        return Mono.fromCallable(() -> {
            String cacheKey = buildCacheKey("email", email, purpose);
            log.info("开始验证邮箱验证码，email: {}, purpose: {}, code: {}, cacheKey: {}", 
                    email, purpose, code, cacheKey);
            
            String storedCode = verificationCodeCache.getIfPresent(cacheKey);
            
            if (storedCode == null) {
                log.warn("邮箱验证码不存在或已过期，email: {}, purpose: {}, cacheKey: {}", 
                        email, purpose, cacheKey);
                return false;
            }
            
            log.info("找到存储的验证码，email: {}, purpose: {}, 存储的code: {}, 输入的code: {}", 
                    email, purpose, storedCode, code);
            
            if (storedCode.equals(code)) {
                // 验证成功，删除验证码和频率限制
                verificationCodeCache.invalidate(cacheKey);
                String rateLimitKey = "rate_limit:email:" + email + ":" + purpose;
                rateLimitCache.invalidate(rateLimitKey);
                log.info("邮箱验证码验证成功，email: {}, purpose: {}", email, purpose);
                return true;
            } else {
                log.warn("邮箱验证码不匹配，email: {}, purpose: {}, 期望: {}, 实际: {}", 
                        email, purpose, storedCode, code);
                return false;
            }
        });
    }
    
    @Override
    public Mono<CaptchaResult> generateCaptcha() {
        return Mono.fromCallable(() -> {
            // 生成验证码文本和图片
            String captchaText = kaptcha.createText();
            BufferedImage captchaImage = kaptcha.createImage(captchaText);
            
            // 生成唯一ID
            String captchaId = UUID.randomUUID().toString();
            
            // 存储验证码
            captchaCache.put(captchaId, captchaText);
            
            // 将图片转换为Base64
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            ImageIO.write(captchaImage, "png", outputStream);
            String base64Image = "data:image/png;base64," + 
                    Base64.getEncoder().encodeToString(outputStream.toByteArray());
            
            return new CaptchaResult(captchaId, base64Image);
        })
        .subscribeOn(Schedulers.boundedElastic());
    }
    
    @Override
    public Mono<Boolean> verifyCaptcha(String captchaId, String captchaCode) {
        // 保持向后兼容，默认消费
        return verifyCaptcha(captchaId, captchaCode, true);
    }

    @Override
    public Mono<Boolean> verifyCaptcha(String captchaId, String captchaCode, boolean consume) {
        return Mono.fromCallable(() -> {
            log.info("开始验证图片验证码，captchaId: {}, 输入的code: {}, consume: {}", captchaId, captchaCode, consume);
            
            if (captchaId == null || captchaId.trim().isEmpty()) {
                log.warn("图片验证码ID为空");
                return false;
            }
            
            if (captchaCode == null || captchaCode.trim().isEmpty()) {
                log.warn("图片验证码内容为空");
                return false;
            }
            
            String storedCaptcha = captchaCache.getIfPresent(captchaId);
            
            if (storedCaptcha == null) {
                log.warn("图片验证码已过期或不存在，captchaId: {}", captchaId);
                return false;
            }
            
            log.info("存储的验证码: {}, 输入的验证码: {}", storedCaptcha, captchaCode);
            
            if (storedCaptcha.equalsIgnoreCase(captchaCode)) {
                if (consume) {
                    // 验证成功且需要消费，删除验证码
                    captchaCache.invalidate(captchaId);
                }
                log.info("图片验证码验证成功，captchaId: {}, consume: {}", captchaId, consume);
                return true;
            } else {
                log.warn("图片验证码错误，captchaId: {}, 期望: {}, 实际: {}", captchaId, storedCaptcha, captchaCode);
                return false;
            }
        }).subscribeOn(Schedulers.boundedElastic());
    }
    
    /**
     * 生成数字验证码
     */
    private String generateNumericCode(int length) {
        StringBuilder code = new StringBuilder();
        for (int i = 0; i < length; i++) {
            code.append(random.nextInt(10));
        }
        return code.toString();
    }
    
    /**
     * 构建缓存key
     */
    private String buildCacheKey(String type, String target, String purpose) {
        return String.format("verification:%s:%s:%s", type, target, purpose);
    }
}