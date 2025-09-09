package com.ainovel.server.web.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.common.security.CurrentUser;
import com.ainovel.server.domain.model.PaymentOrder;
import com.ainovel.server.domain.model.PaymentOrder.PayChannel;
import com.ainovel.server.repository.PaymentOrderRepository;
import com.ainovel.server.service.PaymentService;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;
    private final PaymentOrderRepository paymentOrderRepository;
    private final com.ainovel.server.service.PaymentQueryService paymentQueryService;

    /**
     * 创建订阅计划的支付订单
     */
    @PostMapping("/create/{planId}")
    public Mono<ApiResponse<PaymentOrder>> createPayment(@CurrentUser String userId,
                                                         @PathVariable String planId,
                                                         @RequestParam("channel") PayChannel channel) {
        return paymentService.createOrder(userId, planId, channel)
            .map(ApiResponse::success);
    }

    /**
     * 购买积分补充包（使用订阅计划作为示例来源或单独的creditPackId接口，简化为planId复用）
     */
    @PostMapping("/create-credit-pack/{planId}")
    public Mono<ApiResponse<PaymentOrder>> createCreditPackPayment(@CurrentUser String userId,
                                                                   @PathVariable String planId,
                                                                   @RequestParam("channel") PayChannel channel) {
        return paymentService.createOrder(userId, planId, channel, com.ainovel.server.domain.model.PaymentOrder.OrderType.CREDIT_PACK)
            .map(ApiResponse::success);
    }

    /**
     * 支付回调（统一入口）
     * 注意：生产环境需按微信/支付宝规范提供对应回调签名与响应体
     */
    @PostMapping(value = "/notify/{channel}")
    public Mono<ResponseEntity<String>> notify(@PathVariable("channel") PayChannel channel,
                                               @RequestParam("outTradeNo") String outTradeNo,
                                               @RequestBody(required = false) String payload) {
        return paymentService.handleNotify(channel, outTradeNo, payload)
            .map(ok -> ok ? ResponseEntity.ok("success") : ResponseEntity.badRequest().body("fail"));
    }

    /**
     * 购买积分补充包（与订阅不同，不创建UserSubscription，仅加积分）
     * 这里复用 createOrder 接口，由后续回调在 SubscriptionAssignmentServiceImpl 中加钩子实现。
     * 若需要区分，可在 PaymentOrder 增加 orderType 字段（SUBSCRIPTION/CREDIT_PACK）
     */

    /**
     * 查询我的订单
     */
    @GetMapping("/my-orders")
    public Flux<PaymentOrder> myOrders(@CurrentUser String userId) {
        return paymentOrderRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    /** 查询订单状态（前端主动补偿） */
    @GetMapping("/status")
    public Mono<ApiResponse<PaymentOrder>> queryStatus(@RequestParam("outTradeNo") String outTradeNo) {
        return paymentQueryService.getByOutTradeNo(outTradeNo).map(ApiResponse::success);
    }

    /**
     * 本地联调用：模拟支付完成（开发期）
     */
    @GetMapping("/fake-pay")
    public Mono<ResponseEntity<String>> fakePay(@RequestParam("outTradeNo") String outTradeNo,
                                                @RequestParam("channel") PayChannel channel) {
        return paymentService.handleNotify(channel, outTradeNo, "{\"fake\":true}")
            .map(ok -> ok ? ResponseEntity.ok("PAID") : ResponseEntity.badRequest().body("FAIL"));
    }
}



