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
 * 豆包（火山引擎 Ark）能力检测器 - OpenAI兼容
 */
@Slf4j
@Component
public class DoubaoCapabilityDetector implements ProviderCapabilityDetector {

    private static final String DEFAULT_API_ENDPOINT = "https://ark.cn-beijing.volces.com/api/v3";

    @Override
    public String getProviderName() {
        return "doubao";
    }

    @Override
    public Mono<ModelListingCapability> detectModelListingCapability() {
        return Mono.just(ModelListingCapability.LISTING_WITH_KEY);
    }

    @Override
    public Flux<ModelInfo> getDefaultModels() {
        List<ModelInfo> models = new ArrayList<>();

        models.add(ModelInfo.builder()
            .id("doubao-pro-128k")
            .name("Doubao Pro 128K")
            .description("豆包 Pro 128K，通用推理与创作")
            .maxTokens(128000)
            .provider("doubao")
            .build()
            .withUnifiedPrice(0.003));

        models.add(ModelInfo.builder()
            .id("doubao-lite-128k")
            .name("Doubao Lite 128K")
            .description("豆包 Lite 128K，低延迟低成本版本")
            .maxTokens(128000)
            .provider("doubao")
            .build()
            .withUnifiedPrice(0.0015));

        return Flux.fromIterable(models);
    }

    @Override
    public Mono<Boolean> testApiKey(String apiKey, String apiEndpoint) {
        if (apiKey == null || apiKey.trim().isEmpty()) {
            return Mono.just(false);
        }
        String baseUrl = apiEndpoint != null && !apiEndpoint.trim().isEmpty() ? apiEndpoint : DEFAULT_API_ENDPOINT;
        WebClient webClient = WebClient.builder().baseUrl(baseUrl).build();

        // 优先尝试 OpenAI 兼容的 /models 列表
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




