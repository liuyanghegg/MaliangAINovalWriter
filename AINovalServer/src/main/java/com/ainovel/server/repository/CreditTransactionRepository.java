package com.ainovel.server.repository;

import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.billing.CreditTransaction;

import reactor.core.publisher.Mono;
import reactor.core.publisher.Flux;
import org.springframework.data.domain.Pageable;

@Repository
public interface CreditTransactionRepository extends ReactiveMongoRepository<CreditTransaction, String> {
    Mono<Boolean> existsByTraceId(String traceId);
    Mono<CreditTransaction> findByTraceId(String traceId);

    // 按条件分页查询
    Flux<CreditTransaction> findByStatusOrderByCreatedAtDesc(String status, Pageable pageable);
    Flux<CreditTransaction> findByUserIdOrderByCreatedAtDesc(String userId, Pageable pageable);
    Flux<CreditTransaction> findByUserIdAndStatusOrderByCreatedAtDesc(String userId, String status, Pageable pageable);
    Flux<CreditTransaction> findAllByOrderByCreatedAtDesc(Pageable pageable);
    Mono<Long> countByStatus(String status);
    Mono<Long> countByUserId(String userId);
    Mono<Long> countByUserIdAndStatus(String userId, String status);
}


