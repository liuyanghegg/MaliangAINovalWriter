package com.ainovel.server.web.controller;

import com.ainovel.server.service.setting.SettingComposeService;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.UUID;

/**
 * 写作编排（设定→大纲/章节/组合）专用控制器
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/compose")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class SettingComposeController {

    private final SettingComposeService composeService;
    private final ObjectMapper objectMapper;

    /**
     * 统一流式入口：支持 mode = outline | chapters | outline_plus_chapters
     */
    @PostMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<String>> stream(@Valid @RequestBody UniversalAIRequestDto request) {
        log.info("[Compose] 收到流式请求 - userId={}, mode={}", request.getUserId(),
                request.getParameters() != null ? request.getParameters().get("mode") : null);

        return composeService.streamCompose(request)
                .map(response -> {
                    try {
                        String json = objectMapper.writeValueAsString(response);
                        return ServerSentEvent.<String>builder()
                                .id(UUID.randomUUID().toString())
                                .event("message")
                                .data(json)
                                .build();
                    } catch (Exception e) {
                        log.error("[Compose] 序列化响应失败", e);
                        return ServerSentEvent.<String>builder()
                                .id(UUID.randomUUID().toString())
                                .event("message")
                                .data("{\"error\":\"序列化失败\"}")
                                .build();
                    }
                })
                .delayElements(Duration.ofMillis(40))
                .concatWith(Mono.just(ServerSentEvent.<String>builder()
                        .id(UUID.randomUUID().toString())
                        .event("complete")
                        .data("{\"data\":\"[DONE]\"}")
                        .build()))
                .doOnSubscribe(s -> log.info("[Compose] 开始流式响应"))
                .doOnComplete(() -> log.info("[Compose] 流式响应完成"))
                .doOnError(err -> log.error("[Compose] 流式响应失败: {}", err.getMessage(), err));
    }
}


