package com.ainovel.server.repository;

import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.CreditPack;

import reactor.core.publisher.Flux;

@Repository
public interface CreditPackRepository extends ReactiveMongoRepository<CreditPack, String> {
    Flux<CreditPack> findByActiveTrueOrderByPriceAsc();
}



