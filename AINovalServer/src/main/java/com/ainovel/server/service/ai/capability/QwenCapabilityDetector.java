package com.ainovel.server.service.ai.capability;

import java.util.ArrayList;
import java.util.List;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import com.ainovel.server.domain.model.ModelInfo;
import com.ainovel.server.domain.model.ModelListingCapability;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * 通义千问能力检测器（DashScope OpenAI兼容端点）
 */
@Slf4j
@Component
public class QwenCapabilityDetector implements ProviderCapabilityDetector {

    private static final String DEFAULT_API_ENDPOINT = "https://dashscope.aliyuncs.com/compatible-mode/v1";

    @Override
    public String getProviderName() {
        return "qwen";
    }

    @Override
    public Mono<ModelListingCapability> detectModelListingCapability() {
        return Mono.just(ModelListingCapability.LISTING_WITH_KEY);
    }

    @Override
    public Flux<ModelInfo> getDefaultModels() {
        List<ModelInfo> models = new ArrayList<>();

        models.add(ModelInfo.builder()
            .id("qwen-max")
            .name("Qwen-Max")
            .description("通义千问 Qwen-Max 通用模型")
            .maxTokens(128000)
            .provider("qwen")
            .build()
            .withUnifiedPrice(0.003));

        models.add(ModelInfo.builder()
            .id("qwen-plus")
            .name("Qwen-Plus")
            .description("通义千问 Qwen-Plus 平衡版")
            .maxTokens(128000)
            .provider("qwen")
            .build()
            .withUnifiedPrice(0.002));

        return Flux.fromIterable(models);
    }

    @Override
    public Mono<Boolean> testApiKey(String apiKey, String apiEndpoint) {
        if (apiKey == null || apiKey.trim().isEmpty()) {
            return Mono.just(false);
        }
        String baseUrl = apiEndpoint != null && !apiEndpoint.trim().isEmpty() ? apiEndpoint : DEFAULT_API_ENDPOINT;
        WebClient webClient = WebClient.builder().baseUrl(baseUrl).build();
        return webClient.get()
            .uri("/models")
            .header("Authorization", "Bearer " + apiKey)
            .accept(MediaType.APPLICATION_JSON)
            .retrieve()
            .bodyToMono(String.class)
            .map(r -> true)
            .onErrorReturn(false);
    }

    @Override
    public String getDefaultApiEndpoint() {
        return DEFAULT_API_ENDPOINT;
    }
}




