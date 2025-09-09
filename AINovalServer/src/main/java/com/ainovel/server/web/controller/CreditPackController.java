package com.ainovel.server.web.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.domain.model.CreditPack;
import com.ainovel.server.repository.CreditPackRepository;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/credit-packs")
@RequiredArgsConstructor
public class CreditPackController {

    private final CreditPackRepository creditPackRepository;

    @GetMapping
    public Mono<ApiResponse<java.util.List<CreditPack>>> listActivePacks() {
        return creditPackRepository.findByActiveTrueOrderByPriceAsc().collectList().map(ApiResponse::success);
    }
}



