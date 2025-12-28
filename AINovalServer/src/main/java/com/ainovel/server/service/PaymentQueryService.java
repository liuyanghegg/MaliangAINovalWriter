package com.ainovel.server.service;

import com.ainovel.server.domain.model.PaymentOrder;

import reactor.core.publisher.Mono;

public interface PaymentQueryService {
    Mono<PaymentOrder> getByOutTradeNo(String outTradeNo);
}



