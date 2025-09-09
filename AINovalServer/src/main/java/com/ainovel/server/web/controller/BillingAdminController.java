package com.ainovel.server.web.controller;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ainovel.server.domain.model.billing.CreditTransaction;
import com.ainovel.server.repository.CreditTransactionRepository;
import com.ainovel.server.service.billing.ReversalService;

import lombok.Data;
import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/admin/billing")
@RequiredArgsConstructor
public class BillingAdminController {

    private final CreditTransactionRepository txRepo;
    private final ReversalService reversalService;

    @GetMapping(value = "/transactions", produces = MediaType.APPLICATION_JSON_VALUE)
    public Flux<CreditTransaction> listTransactions(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String userId) {
        org.springframework.data.domain.Pageable pageable = org.springframework.data.domain.PageRequest.of(page, size);
        if (status != null && userId != null) {
            return txRepo.findByUserIdAndStatusOrderByCreatedAtDesc(userId, status, pageable);
        } else if (status != null) {
            return txRepo.findByStatusOrderByCreatedAtDesc(status, pageable);
        } else if (userId != null) {
            return txRepo.findByUserIdOrderByCreatedAtDesc(userId, pageable);
        }
        return txRepo.findAllByOrderByCreatedAtDesc(pageable);
    }

    @GetMapping(value = "/transactions/count", produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<Long> countTransactions(@RequestParam(required = false) String status,
                                        @RequestParam(required = false) String userId) {
        if (status != null && userId != null) {
            return txRepo.countByUserIdAndStatus(userId, status);
        } else if (status != null) {
            return txRepo.countByStatus(status);
        } else if (userId != null) {
            return txRepo.countByUserId(userId);
        }
        return txRepo.count();
    }

    @GetMapping(value = "/transactions/{traceId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<CreditTransaction> getTransaction(@PathVariable String traceId) {
        return txRepo.findByTraceId(traceId);
    }

    @PostMapping(value = "/transactions/{traceId}/reverse", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<CreditTransaction> reverse(@PathVariable String traceId, @RequestBody ReverseRequest req) {
        return reversalService.reverseByTraceId(traceId, req.getOperatorUserId(), req.getReason());
    }

    @Data
    public static class ReverseRequest {
        private String operatorUserId;
        private String reason;
    }
}


