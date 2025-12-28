package com.ainovel.server.web.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.domain.model.SubscriptionPlan;
import com.ainovel.server.service.SubscriptionPlanService;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/subscription-plans")
@RequiredArgsConstructor
public class PublicSubscriptionController {

    private final SubscriptionPlanService subscriptionPlanService;

    @GetMapping
    public Mono<ApiResponse<java.util.List<SubscriptionPlan>>> listActivePlans() {
        return subscriptionPlanService.findAll()
            .collectList()
            .map(ApiResponse::success);
    }
}


