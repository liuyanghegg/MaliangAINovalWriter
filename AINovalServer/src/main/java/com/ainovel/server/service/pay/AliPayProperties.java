package com.ainovel.server.service.pay;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import lombok.Data;

@Component
@ConfigurationProperties(prefix = "payment.alipay")
@Data
public class AliPayProperties {
    private String appId;
    private String merchantPrivateKeyPem;
    private String merchantPublicKeyPem;
    private String alipayPublicKeyPem; // 平台公钥
    private String notifyUrl;
    private Boolean sandbox = false;
}



