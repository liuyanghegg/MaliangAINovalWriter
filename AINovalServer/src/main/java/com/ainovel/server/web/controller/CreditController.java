package com.ainovel.server.web.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.security.CurrentUser;
import com.ainovel.server.service.CreditService;
import com.ainovel.server.web.dto.response.UserCreditResponseDto;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * 用户积分控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/credits")
@Tag(name = "Credit", description = "用户积分API")
public class CreditController {

    @Autowired
    private CreditService creditService;

    /**
     * 获取当前用户的积分余额
     * 
     * @param currentUser 当前登录用户
     * @return 用户积分信息
     */
    @GetMapping("/balance")
    @Operation(summary = "获取用户积分余额", description = "查询当前登录用户的积分余额信息")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public Mono<ResponseEntity<ApiResponse<UserCreditResponseDto>>> getUserCredits(
            @AuthenticationPrincipal CurrentUser currentUser) {
        
        String userId = currentUser.getId();
        log.info("获取用户积分余额请求: userId={}", userId);
        
        return creditService.getUserCredits(userId)
                .map(credits -> {
                    UserCreditResponseDto response = UserCreditResponseDto.builder()
                            .userId(userId)
                            .credits(credits)
                            .build();
                    
                    log.info("返回用户积分余额: userId={}, credits={}", userId, credits);
                    return ResponseEntity.ok(ApiResponse.success(response));
                })
                .doOnError(error -> log.error("获取用户积分余额失败: userId={}", userId, error))
                .onErrorResume(error -> {
                    log.error("获取用户积分余额时发生错误: userId={}, error={}", userId, error.getMessage());
                    return Mono.just(ResponseEntity.internalServerError()
                            .body(ApiResponse.error("获取积分余额失败: " + error.getMessage())));
                });
    }
} 