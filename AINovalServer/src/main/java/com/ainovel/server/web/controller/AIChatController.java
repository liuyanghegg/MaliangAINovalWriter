package com.ainovel.server.web.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.ainovel.server.domain.model.AIChatMessage;
import com.ainovel.server.domain.model.AIChatSession;
import com.ainovel.server.service.AIChatService;
import com.ainovel.server.web.base.ReactiveBaseController;
import com.ainovel.server.web.dto.ChatMemoryConfigDto;
import com.ainovel.server.web.dto.IdDto;
import com.ainovel.server.web.dto.SessionCreateDto;
import com.ainovel.server.web.dto.SessionMemoryUpdateDto;
import com.ainovel.server.web.dto.SessionMessageDto;
import com.ainovel.server.web.dto.SessionMessageWithMemoryDto;
import com.ainovel.server.web.dto.SessionUpdateDto;
import com.ainovel.server.web.dto.SessionAIConfigDto;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.service.UniversalAIService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ainovel.server.domain.model.AIFeatureType;
import org.springframework.web.server.ResponseStatusException;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import lombok.extern.slf4j.Slf4j; // 🚀 新增

import java.time.Duration;
import java.util.Map;
import java.util.UUID;

/**
 * AI聊天控制器
 */
@Slf4j // 🚀 新增
@RestController
@RequestMapping("/api/v1/ai-chat")
@RequiredArgsConstructor
public class AIChatController extends ReactiveBaseController {

    private final AIChatService aiChatService;
    private final UniversalAIService universalAIService;
    private final ObjectMapper objectMapper;
    private final com.ainovel.server.service.UsageQuotaService usageQuotaService;

    /**
     * 创建聊天会话
     *
     * @param sessionCreateDto 包含用户ID、小说ID、模型名称和元数据的DTO
     * @return 创建的会话
     */
    @PostMapping("/sessions/create")
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<AIChatSession> createSession(@RequestBody SessionCreateDto sessionCreateDto) {
        // 限次：AI聊天/生成会话创建按会员计划次数阈值控制
        return usageQuotaService.isWithinLimit(sessionCreateDto.getUserId(), AIFeatureType.AI_CHAT)
            .flatMap(can -> {
                if (!can) {
                    return Mono.error(new ResponseStatusException(HttpStatus.FORBIDDEN, "今日AI使用次数已达上限"));
                }
                return aiChatService.createSession(
                        sessionCreateDto.getUserId(),
                        sessionCreateDto.getNovelId(),
                        sessionCreateDto.getModelName(),
                        sessionCreateDto.getMetadata()
                ).flatMap(s -> usageQuotaService.incrementUsage(sessionCreateDto.getUserId(), AIFeatureType.AI_CHAT).thenReturn(s));
            });
    }

    /**
     * 获取会话详情（包含AI配置）
     *
     * @param sessionDto 包含用户ID、小说ID和会话ID的DTO
     * @return 包含会话信息和AI配置的响应
     */
    @PostMapping("/sessions/get")
    public Mono<Map<String, Object>> getSession(@RequestBody SessionMessageDto sessionDto) {
        log.info("获取会话详情（含AI配置） - userId: {}, novelId: {}, sessionId: {}", sessionDto.getUserId(), sessionDto.getNovelId(), sessionDto.getSessionId());
        
        // 🚀 使用支持novelId的方法
        return aiChatService.getSession(sessionDto.getUserId(), sessionDto.getNovelId(), sessionDto.getSessionId())
                .flatMap(session -> {
                    // 并行获取AI配置
                    String activePromptPresetId = session.getActivePromptPresetId();
                    Mono<Map<String, Object>> configMono;
                    
                    if (activePromptPresetId != null) {
                        // 通过UniversalAIService获取预设配置
                        configMono = universalAIService.getPromptPresetById(activePromptPresetId)
                                .map(preset -> {
                                    Map<String, Object> configData = new java.util.HashMap<>();
                                    configData.put("config", preset.getRequestData()); // JSON字符串
                                    configData.put("presetId", preset.getPresetId());
                                    log.info("找到会话AI配置 - sessionId: {}, presetId: {}", session.getSessionId(), preset.getPresetId());
                                    return configData;
                                })
                                .switchIfEmpty(Mono.<Map<String, Object>>defer(() -> {
                                    log.warn("会话引用的预设不存在 - sessionId: {}, presetId: {}", session.getSessionId(), activePromptPresetId);
                                    Map<String, Object> emptyConfig = new java.util.HashMap<>();
                                    emptyConfig.put("config", null);
                                    emptyConfig.put("presetId", null);
                                    return Mono.just(emptyConfig);
                                }));
                    } else {
                        log.info("会话暂无AI配置预设 - sessionId: {}", session.getSessionId());
                        Map<String, Object> emptyConfig = new java.util.HashMap<>();
                        emptyConfig.put("config", null);
                        emptyConfig.put("presetId", null);
                        configMono = Mono.just(emptyConfig);
                    }
                    
                    // 合并会话信息和配置信息
                    return configMono.map(configData -> {
                        Map<String, Object> result = new java.util.HashMap<>();
                        result.put("session", session);
                        result.put("aiConfig", configData.get("config"));
                        result.put("presetId", configData.get("presetId"));
                        return result;
                    });
                })
                .onErrorResume(error -> {
                    log.error("获取会话详情（含AI配置）失败", error);
                    return aiChatService.getSession(sessionDto.getUserId(), sessionDto.getNovelId(), sessionDto.getSessionId())
                            .map(session -> {
                                // 如果获取配置失败，至少返回会话信息
                                Map<String, Object> result = new java.util.HashMap<>();
                                result.put("session", session);
                                result.put("aiConfig", null);
                                result.put("presetId", null);
                                result.put("configError", "获取配置失败: " + error.getMessage());
                                return result;
                            })
                            .onErrorReturn(Map.of("error", "获取会话失败: " + error.getMessage()));
                });
    }

    /**
     * 获取用户指定小说的所有会话 (流式 SSE)
     *
     * @param sessionDto 包含用户ID和小说ID的DTO
     * @return 会话列表流
     */
    @PostMapping(value = "/sessions/list", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<AIChatSession> listSessions(@RequestBody SessionMessageDto sessionDto) {
        log.info("获取用户会话列表 - userId: {}, novelId: {}", sessionDto.getUserId(), sessionDto.getNovelId());
        return aiChatService.listUserSessions(sessionDto.getUserId(), sessionDto.getNovelId(), 0, 100);
    }

    /**
     * 更新会话
     *
     * @param sessionUpdateDto 包含用户ID、小说ID、会话ID和更新内容的DTO
     * @return 更新后的会话
     */
    @PostMapping("/sessions/update")
    public Mono<AIChatSession> updateSession(@RequestBody SessionUpdateDto sessionUpdateDto) {
        log.info("更新会话 - userId: {}, novelId: {}, sessionId: {}", sessionUpdateDto.getUserId(), sessionUpdateDto.getNovelId(), sessionUpdateDto.getSessionId());
        return aiChatService.updateSession(
                sessionUpdateDto.getUserId(),
                sessionUpdateDto.getNovelId(),
                sessionUpdateDto.getSessionId(),
                sessionUpdateDto.getUpdates()
        );
    }

    /**
     * 删除会话
     *
     * @param sessionDto 包含用户ID、小说ID和会话ID的DTO
     * @return 操作结果
     */
    @PostMapping("/sessions/delete")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteSession(@RequestBody SessionMessageDto sessionDto) {
        log.info("删除会话 - userId: {}, novelId: {}, sessionId: {}", sessionDto.getUserId(), sessionDto.getNovelId(), sessionDto.getSessionId());
        return aiChatService.deleteSession(sessionDto.getUserId(), sessionDto.getNovelId(), sessionDto.getSessionId());
    }

    /**
     * 发送消息并获取响应
     *
     * @param sessionMessageDto 包含用户ID、小说ID、会话ID、消息内容和元数据的DTO
     * @return AI响应消息
     */
    @PostMapping("/messages/send")
    public Mono<AIChatMessage> sendMessage(@RequestBody SessionMessageDto sessionMessageDto) {
        log.info("发送消息 - userId: {}, novelId: {}, sessionId: {}", sessionMessageDto.getUserId(), sessionMessageDto.getNovelId(), sessionMessageDto.getSessionId());
        
        // 🚀 检查metadata中是否包含AI配置
        UniversalAIRequestDto aiRequest = extractAIConfigFromMetadata(sessionMessageDto.getMetadata());
        
        if (aiRequest != null) {
            // 使用新的配置方法（支持novelId隔离）
            return aiChatService.sendMessage(
                    sessionMessageDto.getUserId(),
                    sessionMessageDto.getNovelId(),
                    sessionMessageDto.getSessionId(),
                    sessionMessageDto.getContent(),
                    aiRequest
            );
        } else {
            // 先验证会话属于指定小说，然后使用原有方法
            return aiChatService.getSession(sessionMessageDto.getUserId(), sessionMessageDto.getNovelId(), sessionMessageDto.getSessionId())
                    .switchIfEmpty(Mono.error(new RuntimeException("会话不存在或不属于指定小说")))
                    .flatMap(session -> aiChatService.sendMessage(
                            sessionMessageDto.getUserId(),
                            sessionMessageDto.getSessionId(),
                            sessionMessageDto.getContent(),
                            sessionMessageDto.getMetadata()
                    ));
        }
    }

    /**
     * 流式发送消息并获取响应
     *
     * @param sessionMessageDto 包含用户ID、小说ID、会话ID、消息内容和元数据的DTO
     * @return 流式AI响应消息 (SSE)
     */
    @PostMapping(value = "/messages/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<AIChatMessage>> streamMessage(@RequestBody SessionMessageDto sessionMessageDto) {
        log.info("流式发送消息请求: userId={}, novelId={}, sessionId={}", 
                sessionMessageDto.getUserId(), sessionMessageDto.getNovelId(), sessionMessageDto.getSessionId());
        
        // 🚀 检查metadata中是否包含AI配置
        UniversalAIRequestDto aiRequest = extractAIConfigFromMetadata(sessionMessageDto.getMetadata());
        
        Flux<AIChatMessage> share;
        if (aiRequest != null) {
            // 使用新的配置方法（支持novelId隔离）
            share = aiChatService.streamMessage(
                    sessionMessageDto.getUserId(),
                    sessionMessageDto.getNovelId(),
                    sessionMessageDto.getSessionId(),
                    sessionMessageDto.getContent(),
                    aiRequest
            ).share();
        } else {
            // 先验证会话属于指定小说，然后使用原有方法
            share = aiChatService.getSession(sessionMessageDto.getUserId(), sessionMessageDto.getNovelId(), sessionMessageDto.getSessionId())
                    .switchIfEmpty(Mono.error(new RuntimeException("会话不存在或不属于指定小说")))
                    .flatMapMany(session -> aiChatService.streamMessage(
                            sessionMessageDto.getUserId(),
                            sessionMessageDto.getSessionId(),
                            sessionMessageDto.getContent(),
                            sessionMessageDto.getMetadata()
                    )).share();
        }
        
        // 🚀 包装为标准SSE格式，参考NextOutlineController的实现
        Flux<ServerSentEvent<AIChatMessage>> eventFlux = share
                .map(message -> ServerSentEvent.<AIChatMessage>builder()
                        .id(message.getId() != null ? message.getId() : UUID.randomUUID().toString())
                        .event("chat-message") // 统一事件名称
                        .data(message)
                        .retry(Duration.ofSeconds(10))
                        .build());

        // 🚀 追加SSE心跳，使用自定义事件名，前端默认按 chat-message 过滤，故心跳将被忽略
        Flux<ServerSentEvent<AIChatMessage>> heartbeatStream = Flux.interval(Duration.ofSeconds(15))
                .map(i -> ServerSentEvent.<AIChatMessage>builder()
                        .id("heartbeat-" + i)
                        .event("heartbeat")
                        .comment("keepalive")
                        .build())
                // 当主流完成时自动停止心跳
                .takeUntilOther(eventFlux.ignoreElements());

        return Flux.merge(eventFlux, heartbeatStream)
                .doOnSubscribe(subscription -> log.info("SSE 连接建立 for chat stream, sessionId: {}", sessionMessageDto.getSessionId()))
                .doOnCancel(() -> log.info("SSE 连接关闭 for chat stream, sessionId: {}", sessionMessageDto.getSessionId()))
                .doOnError(error -> log.error("SSE 流错误 for chat stream, sessionId: {}: {}", sessionMessageDto.getSessionId(), error.getMessage(), error))
                .onErrorResume(error -> {
                    log.error("聊天流式请求发生错误，发送错误事件: sessionId={}, error={} ", sessionMessageDto.getSessionId(), error.getMessage());

                    AIChatMessage errorMessage = AIChatMessage.builder()
                            .sessionId(sessionMessageDto.getSessionId())
                            .role("system")
                            .content("请求失败: " + error.getMessage())
                            .status("ERROR")
                            .messageType("ERROR")
                            .createdAt(java.time.LocalDateTime.now())
                            .build();

                    return Flux.just(ServerSentEvent.<AIChatMessage>builder()
                            .id(UUID.randomUUID().toString())
                            .event("chat-error")
                            .data(errorMessage)
                            .build());
                });
    }

    /**
     * 获取会话消息历史 (流式 SSE)
     *
     * @param sessionDto 包含用户ID、小说ID、会话ID的DTO (以及可选的 limit)
     * @return 消息历史列表流
     */
    @PostMapping(value = "/messages/history", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<AIChatMessage> getMessageHistory(@RequestBody SessionMessageDto sessionDto) {
        log.info("获取消息历史 - userId: {}, novelId: {}, sessionId: {}", sessionDto.getUserId(), sessionDto.getNovelId(), sessionDto.getSessionId());
        int limit = 100;
        return aiChatService.getSessionMessages(sessionDto.getUserId(), sessionDto.getNovelId(), sessionDto.getSessionId(), limit);
    }

    /**
     * 获取特定消息
     *
     * @param messageDto 包含用户ID和消息ID的DTO
     * @return 消息详情
     */
    @PostMapping("/messages/get")
    public Mono<AIChatMessage> getMessage(@RequestBody SessionMessageDto messageDto) {
        return aiChatService.getMessage(messageDto.getUserId(), messageDto.getMessageId());
    }

    /**
     * 删除消息
     *
     * @param messageDto 包含用户ID和消息ID的DTO
     * @return 操作结果
     */
    @PostMapping("/messages/delete")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteMessage(@RequestBody SessionMessageDto messageDto) {
        return aiChatService.deleteMessage(messageDto.getUserId(), messageDto.getMessageId());
    }

    /**
     * 获取会话消息数量
     *
     * @param sessionDto 包含会话ID的DTO
     * @return 消息数量
     */
    @PostMapping("/messages/count")
    public Mono<Long> countSessionMessages(@RequestBody IdDto sessionDto) {
        return aiChatService.countSessionMessages(sessionDto.getId());
    }

    /**
     * 获取用户指定小说的会话数量
     *
     * @param sessionDto 包含用户ID和小说ID的DTO
     * @return 会话数量
     */
    @PostMapping("/sessions/count")
    public Mono<Long> countUserSessions(@RequestBody SessionMessageDto sessionDto) {
        log.info("统计用户会话数量 - userId: {}, novelId: {}", sessionDto.getUserId(), sessionDto.getNovelId());
        return aiChatService.countUserSessions(sessionDto.getUserId(), sessionDto.getNovelId());
    }

    // ==================== 记忆模式API ====================

    /**
     * 发送消息并获取响应（记忆模式）
     *
     * @param sessionMessageDto 包含用户ID、小说ID、会话ID、消息内容和记忆配置的DTO
     * @return AI响应消息
     */
    @PostMapping("/messages/send-with-memory")
    public Mono<AIChatMessage> sendMessageWithMemory(@RequestBody SessionMessageWithMemoryDto sessionMessageDto) {
        log.info("发送消息（记忆模式） - userId: {}, novelId: {}, sessionId: {}", sessionMessageDto.getUserId(), sessionMessageDto.getNovelId(), sessionMessageDto.getSessionId());
        ChatMemoryConfigDto memoryConfigDto = sessionMessageDto.getMemoryConfig();
        return aiChatService.sendMessageWithMemory(
                sessionMessageDto.getUserId(),
                sessionMessageDto.getNovelId(),
                sessionMessageDto.getSessionId(),
                sessionMessageDto.getContent(),
                sessionMessageDto.getMetadata(),
                memoryConfigDto != null ? memoryConfigDto.toModel() : null
        );
    }

    /**
     * 流式发送消息并获取响应（记忆模式）
     *
     * @param sessionMessageDto 包含用户ID、小说ID、会话ID、消息内容和记忆配置的DTO
     * @return 流式AI响应消息 (SSE)
     */
    @PostMapping(value = "/messages/stream-with-memory", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<AIChatMessage>> streamMessageWithMemory(@RequestBody SessionMessageWithMemoryDto sessionMessageDto) {
        log.info("流式发送消息（记忆模式）请求: userId={}, novelId={}, sessionId={}", 
                sessionMessageDto.getUserId(), sessionMessageDto.getNovelId(), sessionMessageDto.getSessionId());
        
        ChatMemoryConfigDto memoryConfigDto = sessionMessageDto.getMemoryConfig();
        Flux<AIChatMessage> messageStream = aiChatService.streamMessageWithMemory(
                sessionMessageDto.getUserId(),
                sessionMessageDto.getNovelId(),
                sessionMessageDto.getSessionId(),
                sessionMessageDto.getContent(),
                sessionMessageDto.getMetadata(),
                memoryConfigDto != null ? memoryConfigDto.toModel() : null
        );
        
        // 🚀 包装为标准SSE格式
        Flux<ServerSentEvent<AIChatMessage>> eventFlux = messageStream
                .map(message -> ServerSentEvent.<AIChatMessage>builder()
                        .id(message.getId() != null ? message.getId() : UUID.randomUUID().toString())
                        .event("chat-message-memory") // 记忆模式使用不同的事件名称
                        .data(message)
                        .retry(Duration.ofSeconds(10))
                        .build());

        Flux<ServerSentEvent<AIChatMessage>> heartbeatStream = Flux.interval(Duration.ofSeconds(15))
                .map(i -> ServerSentEvent.<AIChatMessage>builder()
                        .id("heartbeat-" + i)
                        .event("heartbeat")
                        .comment("keepalive")
                        .build())
                .takeUntilOther(eventFlux.ignoreElements());

        return Flux.merge(eventFlux, heartbeatStream)
                .doOnSubscribe(subscription -> log.info("SSE 连接建立 for memory chat stream, sessionId: {}", sessionMessageDto.getSessionId()))
                .doOnCancel(() -> log.info("SSE 连接关闭 for memory chat stream, sessionId: {}", sessionMessageDto.getSessionId()))
                .doOnError(error -> log.error("SSE 流错误 for memory chat stream, sessionId: {}: {}", sessionMessageDto.getSessionId(), error.getMessage(), error))
                .onErrorResume(error -> {
                    log.error("记忆模式聊天流式请求发生错误，发送错误事件: sessionId={}, error={} ", sessionMessageDto.getSessionId(), error.getMessage());

                    AIChatMessage errorMessage = AIChatMessage.builder()
                            .sessionId(sessionMessageDto.getSessionId())
                            .role("system")
                            .content("请求失败: " + error.getMessage())
                            .status("ERROR")
                            .messageType("ERROR")
                            .createdAt(java.time.LocalDateTime.now())
                            .build();

                    return Flux.just(ServerSentEvent.<AIChatMessage>builder()
                            .id(UUID.randomUUID().toString())
                            .event("chat-error-memory")
                            .data(errorMessage)
                            .build());
                });
    }

    /**
     * 获取会话的记忆消息（流式 SSE）
     *
     * @param sessionMessageDto 包含用户ID、小说ID、会话ID和记忆配置的DTO
     * @return 记忆消息列表流
     */
    @PostMapping(value = "/messages/memory-history", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<AIChatMessage> getSessionMemoryMessages(@RequestBody SessionMessageWithMemoryDto sessionMessageDto) {
        log.info("获取记忆消息历史 - userId: {}, novelId: {}, sessionId: {}", sessionMessageDto.getUserId(), sessionMessageDto.getNovelId(), sessionMessageDto.getSessionId());
        int limit = 100;
        ChatMemoryConfigDto memoryConfigDto = sessionMessageDto.getMemoryConfig();
        return aiChatService.getSessionMemoryMessages(
                sessionMessageDto.getUserId(),
                sessionMessageDto.getNovelId(),
                sessionMessageDto.getSessionId(),
                memoryConfigDto != null ? memoryConfigDto.toModel() : null,
                limit
        );
    }

    /**
     * 更新会话的记忆配置
     *
     * @param sessionMemoryUpdateDto 包含用户ID、小说ID、会话ID和记忆配置的DTO
     * @return 更新后的会话
     */
    @PostMapping("/sessions/update-memory-config")
    public Mono<AIChatSession> updateSessionMemoryConfig(@RequestBody SessionMemoryUpdateDto sessionMemoryUpdateDto) {
        log.info("更新会话记忆配置 - userId: {}, novelId: {}, sessionId: {}", sessionMemoryUpdateDto.getUserId(), sessionMemoryUpdateDto.getNovelId(), sessionMemoryUpdateDto.getSessionId());
        return aiChatService.updateSessionMemoryConfig(
                sessionMemoryUpdateDto.getUserId(),
                sessionMemoryUpdateDto.getNovelId(),
                sessionMemoryUpdateDto.getSessionId(),
                sessionMemoryUpdateDto.getMemoryConfig().toModel()
        );
    }

    /**
     * 清除会话记忆
     *
     * @param sessionDto 包含用户ID、小说ID和会话ID的DTO
     * @return 操作结果
     */
    @PostMapping("/sessions/clear-memory")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> clearSessionMemory(@RequestBody SessionMessageDto sessionDto) {
        log.info("清除会话记忆 - userId: {}, novelId: {}, sessionId: {}", sessionDto.getUserId(), sessionDto.getNovelId(), sessionDto.getSessionId());
        return aiChatService.clearSessionMemory(sessionDto.getUserId(), sessionDto.getNovelId(), sessionDto.getSessionId());
    }

    /**
     * 获取支持的记忆模式列表（流式 SSE）
     *
     * @return 记忆模式列表流
     */
    @PostMapping(value = "/memory/supported-modes", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<String> getSupportedMemoryModes() {
        return aiChatService.getSupportedMemoryModes();
    }

    // ==================== 会话AI配置管理API ====================

    /**
     * 获取会话的AI配置（通过AIPromptPreset）- 已弃用，配置现在通过/sessions/get返回
     *
     * @param sessionDto 包含用户ID、小说ID和会话ID的DTO
     * @return 会话的AI配置
     */
    @PostMapping("/sessions/config/get")
    @Deprecated
    public Mono<Map<String, Object>> getSessionAIConfig(@RequestBody SessionMessageDto sessionDto) {
        log.info("获取会话AI配置 - userId: {}, novelId: {}, sessionId: {}", sessionDto.getUserId(), sessionDto.getNovelId(), sessionDto.getSessionId());
        
        return aiChatService.getSession(sessionDto.getUserId(), sessionDto.getNovelId(), sessionDto.getSessionId())
                .flatMap(session -> {
                    String activePromptPresetId = session.getActivePromptPresetId();
                    if (activePromptPresetId != null) {
                        // 通过UniversalAIService获取预设配置
                        return universalAIService.getPromptPresetById(activePromptPresetId)
                                .map(preset -> {
                                    Map<String, Object> result = new java.util.HashMap<>();
                                    result.put("config", preset.getRequestData()); // JSON字符串
                                    result.put("sessionId", session.getSessionId());
                                    result.put("presetId", preset.getPresetId());
                                    log.info("找到会话AI配置 - sessionId: {}, presetId: {}", session.getSessionId(), preset.getPresetId());
                                    return result;
                                })
                                .switchIfEmpty(Mono.<Map<String, Object>>defer(() -> {
                                    log.warn("会话引用的预设不存在 - sessionId: {}, presetId: {}", session.getSessionId(), activePromptPresetId);
                                    Map<String, Object> result = new java.util.HashMap<>();
                                    result.put("config", null);
                                    result.put("sessionId", session.getSessionId());
                                    return Mono.just(result);
                                }));
                    } else {
                        log.info("会话暂无AI配置预设 - sessionId: {}", session.getSessionId());
                        Map<String, Object> result = new java.util.HashMap<>();
                        result.put("config", null);
                        result.put("sessionId", session.getSessionId());
                        return Mono.just(result);
                    }
                })
                .onErrorResume(error -> {
                    log.error("获取会话AI配置失败", error);
                    Map<String, Object> errorResult = new java.util.HashMap<>();
                    errorResult.put("config", null);
                    errorResult.put("error", "获取配置失败");
                    return Mono.just(errorResult);
                });
    }

    /**
     * 保存会话的AI配置（通过AIPromptPreset）
     * 注意：这个接口主要用于兼容，实际保存逻辑在发送消息时通过UniversalAIService处理
     *
     * @param configDto 包含用户ID、小说ID、会话ID和AI配置的DTO
     * @return 操作结果
     */
    @PostMapping("/sessions/config/save")
    @ResponseStatus(HttpStatus.OK)
    public Mono<Map<String, Object>> saveSessionAIConfig(@RequestBody SessionAIConfigDto configDto) {
        log.info("保存会话AI配置 - userId: {}, novelId: {}, sessionId: {}", configDto.getUserId(), configDto.getNovelId(), configDto.getSessionId());
        
        // 将配置转换为UniversalAIRequestDto
        try {
            ObjectMapper mapper = new ObjectMapper();
            UniversalAIRequestDto aiRequest = mapper.convertValue(configDto.getConfig(), UniversalAIRequestDto.class);
            
            // 通过UniversalAIService生成并存储预设
            return universalAIService.generateAndStorePrompt(aiRequest)
                    .flatMap(promptResult -> {
                        // 更新会话的activePromptPresetId
                        return aiChatService.updateSession(
                                configDto.getUserId(),
                                configDto.getNovelId(),
                                configDto.getSessionId(),
                                Map.of("activePromptPresetId", promptResult.getPresetId())
                        );
                    })
                    .map(updatedSession -> {
                        log.info("会话AI配置保存成功 - sessionId: {}, presetId: {}", 
                                updatedSession.getSessionId(), updatedSession.getActivePromptPresetId());
                        Map<String, Object> result = new java.util.HashMap<>();
                        result.put("success", true);
                        result.put("sessionId", updatedSession.getSessionId());
                        result.put("presetId", updatedSession.getActivePromptPresetId());
                        result.put("message", "配置保存成功");
                        return result;
                    })
                    .onErrorResume(error -> {
                        log.error("保存会话AI配置失败", error);
                        Map<String, Object> errorResult = new java.util.HashMap<>();
                        errorResult.put("success", false);
                        errorResult.put("error", "保存配置失败: " + error.getMessage());
                        return Mono.just(errorResult);
                    });
        } catch (Exception e) {
            log.error("转换AI配置失败", e);
            Map<String, Object> errorResult = new java.util.HashMap<>();
            errorResult.put("success", false);
            errorResult.put("error", "配置格式错误");
            return Mono.just(errorResult);
        }
    }

    // ==================== 🚀 私有辅助方法 ====================

    /**
     * 从metadata中提取AI配置
     */
    private UniversalAIRequestDto extractAIConfigFromMetadata(Map<String, Object> metadata) {
        if (metadata == null || !metadata.containsKey("aiConfig")) {
            return null;
        }
        
        try {
            Object aiConfigObj = metadata.get("aiConfig");
            if (aiConfigObj instanceof Map) {
                @SuppressWarnings("unchecked")
                Map<String, Object> aiConfigMap = (Map<String, Object>) aiConfigObj;
                
                // 🚀 添加详细日志以调试配置解析
                log.info("解析AI配置 - requestType: {}, contextSelections: {}, isPublicModel: {}", 
                         aiConfigMap.get("requestType"),
                         aiConfigMap.get("contextSelections"),
                         aiConfigMap.get("isPublicModel"));
                
                UniversalAIRequestDto config = objectMapper.convertValue(aiConfigMap, UniversalAIRequestDto.class);
                
                // 🚀 手动提取公共模型相关字段到metadata中
                Map<String, Object> configMetadata = config.getMetadata() != null ? 
                        new java.util.HashMap<>(config.getMetadata()) : new java.util.HashMap<>();
                
                // 提取公共模型标识
                if (aiConfigMap.containsKey("isPublicModel")) {
                    configMetadata.put("isPublicModel", aiConfigMap.get("isPublicModel"));
                    log.info("提取isPublicModel字段: {}", aiConfigMap.get("isPublicModel"));
                }
                if (aiConfigMap.containsKey("publicModelId")) {
                    configMetadata.put("publicModelId", aiConfigMap.get("publicModelId"));
                    log.info("提取publicModelId字段: {}", aiConfigMap.get("publicModelId"));
                }
                if (aiConfigMap.containsKey("modelName")) {
                    configMetadata.put("modelName", aiConfigMap.get("modelName"));
                    log.info("提取modelName字段: {}", aiConfigMap.get("modelName"));
                }
                if (aiConfigMap.containsKey("modelProvider")) {
                    configMetadata.put("modelProvider", aiConfigMap.get("modelProvider"));
                    log.info("提取modelProvider字段: {}", aiConfigMap.get("modelProvider"));
                }
                if (aiConfigMap.containsKey("modelConfigId")) {
                    configMetadata.put("modelConfigId", aiConfigMap.get("modelConfigId"));
                    log.info("提取modelConfigId字段: {}", aiConfigMap.get("modelConfigId"));
                }
                
                // 设置metadata
                config.setMetadata(configMetadata);
                
                // 🚀 验证解析结果
                log.info("AI配置解析成功 - userId: {}, requestType: {}, contextSelections数量: {}, isPublicModel: {}", 
                         config.getUserId(), 
                         config.getRequestType(),
                         config.getContextSelections() != null ? config.getContextSelections().size() : 0,
                         configMetadata.get("isPublicModel"));
                
                return config;
            }
            return null;
        } catch (Exception e) {
            // 如果解析失败，记录日志但不抛出异常，降级到原有方法
            log.error("解析metadata中的AI配置失败，降级到原有方法", e);
            return null;
        }
    }
}
