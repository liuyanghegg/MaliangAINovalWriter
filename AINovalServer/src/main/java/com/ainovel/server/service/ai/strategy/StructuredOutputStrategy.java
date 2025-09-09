package com.ainovel.server.service.ai.strategy;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

import com.ainovel.server.domain.model.AIRequest;
import com.ainovel.server.domain.model.NovelSettingItem;
import com.ainovel.server.service.EnhancedUserPromptService;
import com.ainovel.server.service.ai.AIModelProvider;
import com.ainovel.server.service.dto.AiGeneratedSettingData;
import com.ainovel.server.utils.JsonRepairUtils;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.core.JsonProcessingException;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * 结构化输出策略实现类
 * 适用于支持结构化输出的模型，如GPT、Gemini等
 */
@Slf4j
@RequiredArgsConstructor
public class StructuredOutputStrategy implements SettingGenerationStrategy {

    private final EnhancedUserPromptService promptService;
    private final ObjectMapper objectMapper;

    @Override
    public Mono<List<NovelSettingItem>> generateSettings(
            String novelId, 
            String userId, 
            String chapterContext, 
            List<String> validRequestedTypes, 
            int maxSettingsPerType,
            String additionalInstructions,
            AIModelProvider aiModelProvider) {
        
        log.debug("使用结构化输出策略生成设定");
        
        try {
            // 获取设定类型字符串表示
            String settingTypesForPrompt = String.join(", ", validRequestedTypes);
            
            // 获取结构化提示词
            return promptService.getStructuredSettingPrompt(settingTypesForPrompt, maxSettingsPerType, additionalInstructions)
                .flatMap(prompts -> {
                    // 创建请求
                    AIRequest request = new AIRequest();
                    request.setUserId(userId);
                    request.setNovelId(novelId);
                    
                    // 创建系统消息
                    AIRequest.Message systemMessage = new AIRequest.Message();
                    systemMessage.setRole("system");
                    systemMessage.setContent(prompts.get("system"));
                    request.getMessages().add(systemMessage);
                    
                    // 创建用户消息
                    AIRequest.Message userMessage = new AIRequest.Message();
                    userMessage.setRole("user");
                    // 替换上下文占位符
                    String userPrompt = prompts.get("user").replace("{{contextText}}", chapterContext);
                    userMessage.setContent(userPrompt);
                    request.getMessages().add(userMessage);
                    
                    // 使用模型生成内容，若JSON不完整则自动请求 AI 继续
                    return aiModelProvider.generateContent(request)
                        .flatMap(response -> retrieveCompleteJson(aiModelProvider, request, response.getContent(), 3))
                        .flatMap(jsonContent -> {
                            try {
                                // 记录原始JSON内容用于调试
                                log.debug("准备解析的JSON内容长度: {}, novelId: {}", jsonContent.length(), novelId);
                                
                                List<AiGeneratedSettingData> generatedDataList = objectMapper.readValue(
                                        jsonContent,
                                        objectMapper.getTypeFactory().constructCollectionType(List.class, AiGeneratedSettingData.class)
                                );

                                List<NovelSettingItem> novelSettingItems = generatedDataList.stream()
                                        .map(data -> LegacyAISettingGenerationStrategyFactory.convertToNovelSettingItem(data, novelId, userId, validRequestedTypes))
                                        .filter(java.util.Objects::nonNull)
                                        .collect(Collectors.toList());

                                log.info("成功生成 {} 个设定项，novelId: {}", novelSettingItems.size(), novelId);
                                return Mono.just(novelSettingItems);
                            } catch (Exception e) {
                                log.error("解析AI响应为JSON时出错, novelId {}: {}", novelId, e.getMessage(), e);
                                // 尝试修复和降级处理
                                return attemptJsonRepairAndFallback(jsonContent, novelId, userId, validRequestedTypes);
                            }
                        });
                });
                
        } catch (Exception e) {
            log.error("使用结构化输出生成设定时出错, novelId {}: {}", novelId, e.getMessage(), e);
            return Mono.error(new RuntimeException("结构化输出设定生成失败: " + e.getMessage(), e));
        }
    }
    
    /**
     * 尝试修复JSON并提供降级处理
     */
    private Mono<List<NovelSettingItem>> attemptJsonRepairAndFallback(String jsonContent, String novelId, 
                                                                       String userId, List<String> validRequestedTypes) {
        log.info("尝试修复不完整的JSON, novelId: {}", novelId);
        
        try {
            // 使用工具类修复JSON
            String repairedJson = JsonRepairUtils.repairJson(jsonContent);
            if (repairedJson != null) {
                List<AiGeneratedSettingData> generatedDataList = objectMapper.readValue(
                        repairedJson,
                        objectMapper.getTypeFactory().constructCollectionType(List.class, AiGeneratedSettingData.class)
                );

                List<NovelSettingItem> novelSettingItems = generatedDataList.stream()
                        .map(data -> LegacyAISettingGenerationStrategyFactory.convertToNovelSettingItem(data, novelId, userId, validRequestedTypes))
                        .filter(java.util.Objects::nonNull)
                        .collect(Collectors.toList());

                log.info("JSON修复成功，生成 {} 个设定项，novelId: {}", novelSettingItems.size(), novelId);
                return Mono.just(novelSettingItems);
            }
        } catch (Exception repairError) {
            log.warn("JSON修复失败: {}, novelId: {}", repairError.getMessage(), novelId);
        }
        
        // 尝试提取部分有效的JSON对象
        try {
            List<NovelSettingItem> partialItems = extractPartialValidJsonObjects(jsonContent, novelId, userId, validRequestedTypes);
            if (!partialItems.isEmpty()) {
                log.info("部分JSON提取成功，生成 {} 个设定项，novelId: {}", partialItems.size(), novelId);
                return Mono.just(partialItems);
            }
        } catch (Exception partialError) {
            log.warn("部分JSON提取失败: {}, novelId: {}", partialError.getMessage(), novelId);
        }
        
        // 如果所有修复尝试都失败，返回错误
        return Mono.error(new RuntimeException("无法解析AI响应为有效JSON，且修复尝试均失败: " + jsonContent.substring(0, Math.min(500, jsonContent.length()))));
    }

    
    /**
     * 提取部分有效的JSON对象
     */
    private List<NovelSettingItem> extractPartialValidJsonObjects(String jsonContent, String novelId, 
                                                                   String userId, List<String> validRequestedTypes) {
        List<NovelSettingItem> result = new java.util.ArrayList<>();
        
        // 使用正则表达式找到所有完整的JSON对象
        Pattern objectPattern = Pattern.compile("\\{[^{}]*(?:\\{[^{}]*\\}[^{}]*)*\\}");
        Matcher matcher = objectPattern.matcher(jsonContent);
        
        while (matcher.find()) {
            String objectJson = matcher.group();
            try {
                AiGeneratedSettingData data = objectMapper.readValue(objectJson, AiGeneratedSettingData.class);
                NovelSettingItem item = LegacyAISettingGenerationStrategyFactory.convertToNovelSettingItem(data, novelId, userId, validRequestedTypes);
                if (item != null) {
                    result.add(item);
                }
            } catch (Exception e) {
                log.debug("跳过无效的JSON对象: {}", objectJson.substring(0, Math.min(100, objectJson.length())));
            }
        }
        
        return result;
    }
    
    /**
     * 从AI响应中提取JSON
     * 
     * @param response AI响应内容
     * @return 提取的JSON字符串
     */
    private String extractJsonFromResponse(String response) {
        if (response == null || response.isEmpty()) {
            throw new IllegalArgumentException("AI响应为空，无法提取JSON");
        }

        log.debug("开始提取JSON，响应长度: {}", response.length());
        
        // 使用工具类提取JSON
        String extractedJson = JsonRepairUtils.extractJsonFromResponse(response);
        if (extractedJson != null) {
            return extractedJson;
        }

        throw new IllegalArgumentException("无法从响应中提取完整JSON片段，响应前500字符: " + 
                                         response.substring(0, Math.min(500, response.length())));
    }


    /**
     * 递归向 AI 请求直到获取到完整且可解析的 JSON，或达到最大尝试次数。
     */
    private Mono<String> retrieveCompleteJson(AIModelProvider provider, AIRequest baseRequest, String initialContent, int attemptsLeft) {
        return Mono.fromCallable(() -> {
            try {
                return extractJsonFromResponse(initialContent);
            } catch (Exception e) {
                log.debug("JSON提取失败: {}", e.getMessage());
                return null; // 解析失败返回 null
            }
        }).flatMap(json -> {
            if (json != null) {
                // 验证提取的JSON是否真的可以解析
                try {
                    objectMapper.readTree(json);
                    log.debug("JSON提取成功，长度: {}", json.length());
                    
                    // 检查内容是否足够丰富 - 如果JSON太短可能需要继续
                    if (shouldContinueForMoreContent(json, initialContent, attemptsLeft)) {
                        log.info("JSON有效但内容可能不够完整，尝试获取更多内容");
                        // 继续请求更多内容
                    } else {
                        return Mono.just(json);
                    }
                } catch (JsonProcessingException e) {
                    log.warn("提取的JSON无法解析: {}", e.getMessage());
                    // 继续重试流程
                }
            }

            if (attemptsLeft <= 0) {
                log.error("多次尝试后仍无法解析完整JSON，返回原始内容进行修复尝试");
                // 返回原始内容，让上层进行修复尝试
                return Mono.just(initialContent);
            }

            log.info("JSON 未完整，尝试让模型继续输出，剩余尝试次数: {}", attemptsLeft);

            // 构建继续请求
            AIRequest continueReq = new AIRequest();
            continueReq.setUserId(baseRequest.getUserId());
            continueReq.setNovelId(baseRequest.getNovelId());

            AIRequest.Message systemMsg = new AIRequest.Message();
            systemMsg.setRole("system");
            systemMsg.setContent("你之前输出的JSON数组不完整，需要继续输出。\n\n" +
                               "**重要提醒：**\n" +
                               "1. 你的输出被截断了，需要从截断处继续\n" +
                               "2. 不要重复已经输出的内容\n" +
                               "3. 不要添加任何解释文字\n" +
                               "4. 只输出JSON数组的剩余部分\n" +
                               "5. 确保每个对象都完整闭合\n" +
                               "6. 最后必须以 ] 结束数组\n" +
                               "7. 保持JSON语法正确性\n\n" +
                               "请从你被截断的地方直接继续输出JSON内容，确保最终形成一个完整有效的JSON数组。");
            continueReq.getMessages().add(systemMsg);

            // 提供已输出的末尾上下文帮助模型对齐（最多 2000 字符）
            AIRequest.Message assistantMsg = new AIRequest.Message();
            assistantMsg.setRole("assistant");
            String tail = initialContent.length() > 2000 ? 
                initialContent.substring(initialContent.length() - 2000) : initialContent;
            assistantMsg.setContent(tail);
            continueReq.getMessages().add(assistantMsg);

            AIRequest.Message userMsg = new AIRequest.Message();
            userMsg.setRole("user");
            userMsg.setContent("请继续输出JSON数组。从上面assistant消息的末尾直接继续，不要重复内容，确保最终JSON完整有效。");
            continueReq.getMessages().add(userMsg);

            return provider.generateContent(continueReq)
                    .flatMap(resp -> {
                        String combined = initialContent + resp.getContent();
                        log.debug("合并后内容长度: {}", combined.length());
                        return retrieveCompleteJson(provider, baseRequest, combined, attemptsLeft - 1);
                    })
                    .onErrorResume(error -> {
                        log.error("重试请求失败: {}", error.getMessage());
                        // 如果重试请求失败，返回当前内容进行修复尝试
                        return Mono.just(initialContent);
                    });
        });
    }
    
    /**
     * 判断是否应该继续请求更多内容
     */
    private boolean shouldContinueForMoreContent(String extractedJson, String originalContent, int attemptsLeft) {
        // 如果没有剩余重试次数，就不继续了
        if (attemptsLeft <= 0) {
            return false;
        }
        
        // 如果提取的JSON长度相对于原始内容太短，可能需要继续
        double ratio = (double) extractedJson.length() / originalContent.length();
        if (ratio < 0.3) { // 如果提取的内容少于原始内容的30%
            log.debug("JSON长度比例过低 ({:.2f}%)，可能需要更多内容", ratio * 100);
            return true;
        }
        
        // 检查JSON数组中的元素数量是否太少
        try {
            List<?> list = objectMapper.readValue(extractedJson, List.class);
            if (list.size() < 2) { // 如果只有很少的元素
                log.debug("JSON数组元素数量较少 ({}个)，可能需要更多内容", list.size());
                return true;
            }
        } catch (Exception e) {
            // 解析失败就不继续了
            return false;
        }
        
        return false;
    }
} 