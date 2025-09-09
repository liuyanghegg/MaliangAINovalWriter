package com.ainovel.server.service.ai.langchain4j;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

import com.ainovel.server.config.ProxyConfig;
import com.ainovel.server.domain.model.AIRequest;
import com.ainovel.server.domain.model.ModelInfo;
import com.ainovel.server.service.ai.observability.ChatModelListenerManager;

import dev.langchain4j.model.openai.OpenAiChatModel;
import dev.langchain4j.model.openai.OpenAiStreamingChatModel;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 豆包（字节跳动/火山引擎 Ark）- OpenAI 兼容模式 Provider
 * 说明：豆包官方提供 OpenAI-Compatible API，可通过 OpenAiChatModel 直接接入
 */
@Slf4j
public class DoubaoLangChain4jModelProvider extends LangChain4jModelProvider {

    // Ark OpenAI 兼容 API 基地址
    private static final String DEFAULT_API_ENDPOINT = "https://ark.cn-beijing.volces.com/api/v3";

    // 简单统一价估算（每1K tokens 美元价，供成本估算使用）
    private static final Map<String, Double> TOKEN_PRICES;
    static {
        Map<String, Double> prices = new HashMap<>();
        // 如未知具体价目，使用温和的默认值，避免过高或过低估算
        prices.put("doubao-pro-128k", 0.003);
        prices.put("doubao-lite-128k", 0.0015);
        TOKEN_PRICES = Collections.unmodifiableMap(prices);
    }

    public DoubaoLangChain4jModelProvider(
            String modelName,
            String apiKey,
            String apiEndpoint,
            ProxyConfig proxyConfig,
            ChatModelListenerManager listenerManager
    ) {
        super("doubao", modelName, apiKey, apiEndpoint, proxyConfig, listenerManager);
    }

    @Override
    protected void initModels() {
        try {
            String baseUrl = getApiEndpoint(DEFAULT_API_ENDPOINT);
            if (baseUrl == null || baseUrl.trim().isEmpty()) {
                baseUrl = DEFAULT_API_ENDPOINT;
            }

            // 配置系统代理（如有）
            configureSystemProxy();

            var listeners = getListeners();

            var chatBuilder = OpenAiChatModel.builder()
                    .apiKey(apiKey)
                    .modelName(modelName)
                    .baseUrl(baseUrl)
                    .timeout(Duration.ofSeconds(300))
                    .logRequests(true)
                    .logResponses(true);
            if (!listeners.isEmpty()) {
                chatBuilder.listeners(listeners);
            }
            this.chatModel = chatBuilder.build();

            var streamingBuilder = OpenAiStreamingChatModel.builder()
                    .apiKey(apiKey)
                    .modelName(modelName)
                    .baseUrl(baseUrl)
                    .timeout(Duration.ofSeconds(300))
                    .logRequests(true)
                    .logResponses(true);
            if (!listeners.isEmpty()) {
                streamingBuilder.listeners(listeners);
            }
            this.streamingChatModel = streamingBuilder.build();

            log.info("Doubao(Ark) 模型初始化成功: {} @ {}", modelName, baseUrl);
        } catch (Exception e) {
            log.error("初始化 Doubao(Ark) 模型时出错", e);
            this.chatModel = null;
            this.streamingChatModel = null;
        }
    }

    @Override
    public Mono<Double> estimateCost(AIRequest request) {
        double pricePerThousandTokens = TOKEN_PRICES.getOrDefault(modelName, 0.0015);
        int inputTokens = estimateInputTokens(request);
        int outputTokens = request.getMaxTokens() != null ? request.getMaxTokens() : 1000;
        int totalTokens = inputTokens + outputTokens;
        double costInUSD = (totalTokens / 1000.0) * pricePerThousandTokens;
        double costInCNY = costInUSD * 7.2;
        return Mono.just(costInCNY);
    }

    @Override
    public Flux<String> generateContentStream(AIRequest request) {
        log.info("开始 Doubao 流式生成，模型: {}", modelName);
        final long connectionStartTime = System.currentTimeMillis();
        final AtomicLong firstResponseTime = new AtomicLong(0);
        return super.generateContentStream(request)
                .doOnNext(content -> {
                    if (firstResponseTime.get() == 0 && !"heartbeat".equals(content) && !content.startsWith("错误：")) {
                        firstResponseTime.set(System.currentTimeMillis());
                        log.info("Doubao 首次响应耗时: {}ms, 模型: {}", (firstResponseTime.get() - connectionStartTime), modelName);
                    }
                })
                .doOnError(e -> log.error("Doubao 流式生成出错: {}, 模型: {}", e.getMessage(), modelName, e));
    }

    @Override
    public Flux<ModelInfo> listModelsWithApiKey(String apiKey, String apiEndpoint) {
        if (isApiKeyEmpty(apiKey)) {
            return Flux.error(new RuntimeException("API密钥不能为空"));
        }
        // 豆包官方暂未提供统一的模型枚举 OpenAI 接口，返回一组常见占位或仅返回当前模型
        List<ModelInfo> models = new ArrayList<>();
        models.add(ModelInfo.basic(modelName, modelName, "doubao")
                .withDescription("Doubao (Ark) OpenAI-Compatible 模型")
                .withMaxTokens(128000)
                .withUnifiedPrice(0.0015));
        return Flux.fromIterable(models);
    }
}




