package com.ainovel.server.service.pay;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import lombok.Data;

@Component
@ConfigurationProperties(prefix = "payment.wechat")
@Data
public class WeChatPayProperties {
    private String mchId;
    private String appId;
    private String apiV3Key; // 用于解密平台证书
    private String merchantSerialNo;
    private String merchantPrivateKeyPem; // PEM格式
    private String platformPublicKeyPem; // 可选：直接注入平台公钥
    private String notifyUrl;
    private Boolean sandbox = false;
}



