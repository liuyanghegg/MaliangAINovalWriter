package com.ainovel.server.domain.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.annotation.Version;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 支付订单实体
 * 用于订阅计划购买（微信 / 支付宝）
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "payment_orders")
public class PaymentOrder {

    @Id
    private String id;

    /**
     * 业务订单号（对外）
     */
    @Indexed(unique = true)
    private String outTradeNo;

    /**
     * 用户ID
     */
    @Indexed
    private String userId;

    /**
     * 订阅计划ID
     */
    private String planId;

    /**
     * 计划快照信息（防止后续变更影响历史订单展示）
     */
    private String planNameSnapshot;
    private BigDecimal priceSnapshot;
    private String currencySnapshot;
    private SubscriptionPlan.BillingCycle billingCycleSnapshot;

    /**
     * 支付金额/货币
     */
    private BigDecimal amount;
    private String currency;

    /**
     * 支付渠道
     */
    private PayChannel channel;

    /**
     * 订单状态
     */
    private PayStatus status;

    /**
     * 第三方交易号
     */
    private String transactionId;

    /**
     * 支付跳转/二维码URL（仅供前端展示）
     */
    private String paymentUrl;

    /**
     * 通知载荷（便于审计/排障）
     */
    private String notifyPayload;

    /**
     * 时间戳
     */
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime paidAt;
    private LocalDateTime expireAt;

    /**
     * 乐观锁版本
     */
    @Version
    private Long version;

    public enum PayChannel {
        WECHAT,
        ALIPAY
    }

    public enum PayStatus {
        CREATED,
        PENDING,
        SUCCESS,
        FAILED,
        CANCELED,
        EXPIRED
    }

    /**
     * 订单类型（订阅 or 积分包）
     */
    private OrderType orderType;

    public enum OrderType {
        SUBSCRIPTION,
        CREDIT_PACK
    }
}



