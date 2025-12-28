package com.ainovel.server.repository;

import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.PaymentOrder;
import com.ainovel.server.domain.model.PaymentOrder.PayStatus;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Repository
public interface PaymentOrderRepository extends ReactiveMongoRepository<PaymentOrder, String> {

    Mono<PaymentOrder> findByOutTradeNo(String outTradeNo);

    Flux<PaymentOrder> findByUserIdOrderByCreatedAtDesc(String userId);

    Mono<Long> countByUserIdAndStatus(String userId, PayStatus status);
}




