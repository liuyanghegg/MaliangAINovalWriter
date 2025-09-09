package com.ainovel.server.service.impl;

import org.springframework.stereotype.Service;

import com.ainovel.server.domain.model.PaymentOrder;
import com.ainovel.server.repository.PaymentOrderRepository;
import com.ainovel.server.service.PaymentQueryService;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Mono;

@Service
@RequiredArgsConstructor
public class PaymentQueryServiceImpl implements PaymentQueryService {

    private final PaymentOrderRepository paymentOrderRepository;

    @Override
    public Mono<PaymentOrder> getByOutTradeNo(String outTradeNo) {
        return paymentOrderRepository.findByOutTradeNo(outTradeNo);
    }
}



