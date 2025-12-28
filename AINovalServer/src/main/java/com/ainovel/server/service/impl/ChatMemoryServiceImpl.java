package com.ainovel.server.service.impl;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.ainovel.server.domain.model.AIChatMessage;
import com.ainovel.server.domain.model.ChatMemoryConfig;
import com.ainovel.server.domain.model.ChatMemoryMode;
import com.ainovel.server.repository.AIChatMessageRepository;
import com.ainovel.server.service.AIService;
import com.ainovel.server.service.ChatMemoryService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 聊天记忆服务实现
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ChatMemoryServiceImpl implements ChatMemoryService {

    private final AIChatMessageRepository messageRepository;
    private final AIService aiService;

    @Override
    public Flux<AIChatMessage> getMemoryMessages(String sessionId, ChatMemoryConfig config, int limit) {
        log.debug("获取会话记忆消息: sessionId={}, mode={}, limit={}", sessionId, config.getMode(), limit);
        
        return messageRepository.findBySessionIdOrderByCreatedAtDesc(sessionId, limit)
                .collectList()
                .flatMapMany(messages -> {
                    // 按时间正序排列
                    messages.sort(Comparator.comparing(AIChatMessage::getCreatedAt));
                    
                    switch (config.getMode()) {
                        case HISTORY:
                            return Flux.fromIterable(messages);
                        case MESSAGE_WINDOW:
                            return Flux.fromIterable(applyMessageWindowStrategy(messages, config.getMaxMessages(), config.getPreserveSystemMessages()));
                        case TOKEN_WINDOW:
                            return applyTokenWindowStrategy(messages, config.getMaxTokens(), config.getPreserveSystemMessages(), getModelNameFromMessages(messages))
                                    .flatMapMany(Flux::fromIterable);
                        case SUMMARY:
                            return applySummaryStrategy(messages, config.getSummaryThreshold(), config.getSummaryRetainCount(), getModelNameFromMessages(messages))
                                    .flatMapMany(Flux::fromIterable);
                        default:
                            return Flux.fromIterable(messages);
                    }
                });
    }

    @Override
    public Mono<Void> addMessage(String sessionId, AIChatMessage message, ChatMemoryConfig config) {
        log.debug("添加消息到记忆: sessionId={}, messageId={}, mode={}", sessionId, message.getId(), config.getMode());
        
        // 对于记忆模式，我们可能需要在添加新消息后进行清理
        return messageRepository.save(message)
                .then(performMemoryCleanup(sessionId, config));
    }

    @Override
    public Mono<Void> clearMemory(String sessionId) {
        log.info("清除会话记忆: sessionId={}", sessionId);
        return messageRepository.deleteBySessionId(sessionId);
    }

    @Override
    public Mono<Integer> calculateTokens(List<AIChatMessage> messages, String modelName) {
        // 简单的令牌估算：每个字符约0.25个令牌（针对中文），英文单词约1-1.5个令牌
        int totalTokens = messages.stream()
                .mapToInt(msg -> estimateTokens(msg.getContent()))
                .sum();
        
        log.debug("估算令牌数: messages={}, tokens={}, model={}", messages.size(), totalTokens, modelName);
        return Mono.just(totalTokens);
    }

    @Override
    public Flux<String> getSupportedMemoryModes() {
        return Flux.fromArray(ChatMemoryMode.values())
                .map(ChatMemoryMode::getCode);
    }

    @Override
    public Mono<Boolean> validateMemoryConfig(ChatMemoryConfig config) {
        if (config == null) {
            return Mono.just(false);
        }
        
        boolean valid = true;
        
        if (config.getMode() == ChatMemoryMode.MESSAGE_WINDOW && config.getMaxMessages() <= 0) {
            valid = false;
        }
        
        if (config.getMode() == ChatMemoryMode.TOKEN_WINDOW && config.getMaxTokens() <= 0) {
            valid = false;
        }
        
        if (config.getMode() == ChatMemoryMode.SUMMARY) {
            if (config.getSummaryThreshold() <= 0 || config.getSummaryRetainCount() <= 0) {
                valid = false;
            }
        }
        
        return Mono.just(valid);
    }

    @Override
    public List<AIChatMessage> applyMessageWindowStrategy(List<AIChatMessage> messages, int maxMessages, boolean preserveSystemMessages) {
        log.debug("应用消息窗口策略: messages={}, maxMessages={}, preserveSystem={}", messages.size(), maxMessages, preserveSystemMessages);
        
        if (messages.size() <= maxMessages) {
            return new ArrayList<>(messages);
        }
        
        List<AIChatMessage> result = new ArrayList<>();
        List<AIChatMessage> systemMessages = new ArrayList<>();
        List<AIChatMessage> nonSystemMessages = new ArrayList<>();
        
        // 分离系统消息和非系统消息
        for (AIChatMessage message : messages) {
            if ("system".equals(message.getRole()) && preserveSystemMessages) {
                systemMessages.add(message);
            } else {
                nonSystemMessages.add(message);
            }
        }
        
        // 添加系统消息
        result.addAll(systemMessages);
        
        // 从非系统消息中保留最后的N条
        int remainingSlots = maxMessages - systemMessages.size();
        if (remainingSlots > 0 && !nonSystemMessages.isEmpty()) {
            int startIndex = Math.max(0, nonSystemMessages.size() - remainingSlots);
            result.addAll(nonSystemMessages.subList(startIndex, nonSystemMessages.size()));
        }
        
        // 按时间排序
        result.sort(Comparator.comparing(AIChatMessage::getCreatedAt));
        
        log.debug("消息窗口策略结果: 原始={}, 结果={}", messages.size(), result.size());
        return result;
    }

    @Override
    public Mono<List<AIChatMessage>> applyTokenWindowStrategy(List<AIChatMessage> messages, int maxTokens, boolean preserveSystemMessages, String modelName) {
        log.debug("应用令牌窗口策略: messages={}, maxTokens={}, preserveSystem={}, model={}", messages.size(), maxTokens, preserveSystemMessages, modelName);
        
        return calculateTokens(messages, modelName)
                .map(totalTokens -> {
                    if (totalTokens <= maxTokens) {
                        return new ArrayList<>(messages);
                    }
                    
                    List<AIChatMessage> result = new ArrayList<>();
                    List<AIChatMessage> systemMessages = new ArrayList<>();
                    List<AIChatMessage> nonSystemMessages = new ArrayList<>();
                    
                    // 分离系统消息和非系统消息
                    for (AIChatMessage message : messages) {
                        if ("system".equals(message.getRole()) && preserveSystemMessages) {
                            systemMessages.add(message);
                        } else {
                            nonSystemMessages.add(message);
                        }
                    }
                    
                    // 添加系统消息
                    result.addAll(systemMessages);
                    int usedTokens = systemMessages.stream()
                            .mapToInt(msg -> estimateTokens(msg.getContent()))
                            .sum();
                    
                    // 从后向前添加非系统消息，直到达到令牌限制
                    for (int i = nonSystemMessages.size() - 1; i >= 0; i--) {
                        AIChatMessage message = nonSystemMessages.get(i);
                        int messageTokens = estimateTokens(message.getContent());
                        
                        if (usedTokens + messageTokens <= maxTokens) {
                            result.add(0, message); // 插入到开头保持时间顺序
                            usedTokens += messageTokens;
                        } else {
                            break;
                        }
                    }
                    
                    // 重新排序
                    result.sort(Comparator.comparing(AIChatMessage::getCreatedAt));
                    
                    log.debug("令牌窗口策略结果: 原始={}, 结果={}, 使用令牌={}", messages.size(), result.size(), usedTokens);
                    return result;
                });
    }

    @Override
    public Mono<List<AIChatMessage>> applySummaryStrategy(List<AIChatMessage> messages, int threshold, int retainCount, String modelName) {
        log.debug("应用总结策略: messages={}, threshold={}, retainCount={}, model={}", messages.size(), threshold, retainCount, modelName);
        
        if (messages.size() <= threshold) {
            return Mono.just(new ArrayList<>(messages));
        }
        
        // 保留最后的retainCount条消息
        List<AIChatMessage> recentMessages = messages.subList(Math.max(0, messages.size() - retainCount), messages.size());
        
        // 需要总结的消息
        List<AIChatMessage> messagesToSummarize = messages.subList(0, Math.max(0, messages.size() - retainCount));
        
        if (messagesToSummarize.isEmpty()) {
            return Mono.just(new ArrayList<>(recentMessages));
        }
        
        // 生成总结（这里简化处理，实际应该调用AI服务）
        return generateSummary(messagesToSummarize, modelName)
                .map(summary -> {
                    List<AIChatMessage> result = new ArrayList<>();
                    
                    // 添加总结消息
                    AIChatMessage summaryMessage = AIChatMessage.builder()
                            .sessionId(messages.get(0).getSessionId())
                            .userId(messages.get(0).getUserId())
                            .role("system")
                            .content("【对话总结】" + summary)
                            .modelName(modelName)
                            .metadata(Map.of("type", "summary", "originalMessageCount", messagesToSummarize.size()))
                            .status("GENERATED")
                            .messageType("SUMMARY")
                            .createdAt(LocalDateTime.now())
                            .build();
                    
                    result.add(summaryMessage);
                    result.addAll(recentMessages);
                    
                    log.debug("总结策略结果: 原始={}, 总结={}, 保留={}, 结果={}", messages.size(), messagesToSummarize.size(), recentMessages.size(), result.size());
                    return result;
                });
    }

    /**
     * 执行记忆清理
     */
    private Mono<Void> performMemoryCleanup(String sessionId, ChatMemoryConfig config) {
        if (config.getMode() == ChatMemoryMode.HISTORY) {
            return Mono.empty(); // 历史模式不需要清理
        }
        
        // 对于其他模式，可以在这里实现定期清理逻辑
        // 例如：当消息数量超过某个阈值时，删除旧消息
        return Mono.empty();
    }

    /**
     * 估算文本的令牌数量
     */
    private int estimateTokens(String text) {
        if (text == null || text.isEmpty()) {
            return 0;
        }
        
        // 简单估算：中文字符按0.5个令牌计算，英文单词按1个令牌计算
        int chineseChars = 0;
        int englishWords = 0;
        
        for (char c : text.toCharArray()) {
            if (Character.toString(c).matches("[\\u4e00-\\u9fa5]")) {
                chineseChars++;
            }
        }
        
        // 估算英文单词数
        String[] words = text.replaceAll("[\\u4e00-\\u9fa5]", " ").split("\\s+");
        englishWords = words.length;
        
        return (int) (chineseChars * 0.5 + englishWords);
    }

    /**
     * 从消息列表中获取模型名称
     */
    private String getModelNameFromMessages(List<AIChatMessage> messages) {
        return messages.stream()
                .filter(msg -> msg.getModelName() != null)
                .findFirst()
                .map(AIChatMessage::getModelName)
                .orElse("gpt-3.5-turbo");
    }

    /**
     * 生成对话总结
     */
    private Mono<String> generateSummary(List<AIChatMessage> messages, String modelName) {
        // 这里简化处理，返回简单的总结
        // 实际应该调用AI服务生成智能总结
        String conversationText = messages.stream()
                .map(msg -> msg.getRole() + ": " + msg.getContent())
                .collect(Collectors.joining("\n"));
        
        String summary = String.format("这段对话包含了%d条消息，涵盖了用户与AI助手的交互。", messages.size());
        
        // TODO: 实际实现应该调用AI服务生成更智能的总结
        // return aiService.generateSummary(conversationText, modelName);
        
        return Mono.just(summary);
    }
} 