package com.ainovel.server.service.ai.langchain4j;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
 * 智谱AI（GLM） - OpenAI 兼容端点接入
 * 参考：智谱 OpenAI 兼容网关
 */
@Slf4j
public class ZhipuLangChain4jModelProvider extends LangChain4jModelProvider {

    private static final String DEFAULT_API_ENDPOINT = "https://open.bigmodel.cn/api/paas/v4";

    private static final Map<String, Double> TOKEN_PRICES;
    static {
        Map<String, Double> prices = new HashMap<>();
        prices.put("glm-4", 0.003);
        prices.put("glm-4-air", 0.0015);
        prices.put("glm-4-plus", 0.004);
        TOKEN_PRICES = Collections.unmodifiableMap(prices);
    }

    public ZhipuLangChain4jModelProvider(String modelName, String apiKey, String apiEndpoint, ProxyConfig proxyConfig,
                                         ChatModelListenerManager listenerManager) {
        super("zhipu", modelName, apiKey, apiEndpoint, proxyConfig, listenerManager);
    }

    @Override
    protected void initModels() {
        try {
            String baseUrl = getApiEndpoint(DEFAULT_API_ENDPOINT);
            if (baseUrl == null || baseUrl.trim().isEmpty()) {
                baseUrl = DEFAULT_API_ENDPOINT;
            }
            configureSystemProxy();

            var listeners = getListeners();

            var chatBuilder = OpenAiChatModel.builder()
                    .apiKey(apiKey)
                    .modelName(modelName)
                    .baseUrl(baseUrl)
                    .timeout(Duration.ofSeconds(300))
                    .logRequests(true)
                    .logResponses(true);
            if (!listeners.isEmpty()) chatBuilder.listeners(listeners);
            this.chatModel = chatBuilder.build();

            var streamingBuilder = OpenAiStreamingChatModel.builder()
                    .apiKey(apiKey)
                    .modelName(modelName)
                    .baseUrl(baseUrl)
                    .timeout(Duration.ofSeconds(300))
                    .logRequests(true)
                    .logResponses(true);
            if (!listeners.isEmpty()) streamingBuilder.listeners(listeners);
            this.streamingChatModel = streamingBuilder.build();

            log.info("Zhipu(GLM) 模型初始化成功: {} @ {}", modelName, baseUrl);
        } catch (Exception e) {
            log.error("初始化 Zhipu(GLM) 模型时出错", e);
            this.chatModel = null;
            this.streamingChatModel = null;
        }
    }

    @Override
    public Mono<Double> estimateCost(AIRequest request) {
        double pricePerThousandTokens = TOKEN_PRICES.getOrDefault(modelName, 0.002);
        int inputTokens = estimateInputTokens(request);
        int outputTokens = request.getMaxTokens() != null ? request.getMaxTokens() : 1000;
        int totalTokens = inputTokens + outputTokens;
        double costInUSD = (totalTokens / 1000.0) * pricePerThousandTokens;
        double costInCNY = costInUSD * 7.2;
        return Mono.just(costInCNY);
    }

    @Override
    public Flux<ModelInfo> listModelsWithApiKey(String apiKey, String apiEndpoint) {
        if (isApiKeyEmpty(apiKey)) {
            return Flux.error(new RuntimeException("API密钥不能为空"));
        }
        List<ModelInfo> models = new ArrayList<>();
        models.add(ModelInfo.basic(modelName, modelName, "zhipu")
                .withDescription("Zhipu GLM OpenAI-Compatible 模型")
                .withMaxTokens(128000)
                .withUnifiedPrice(0.002));
        return Flux.fromIterable(models);
    }
}




