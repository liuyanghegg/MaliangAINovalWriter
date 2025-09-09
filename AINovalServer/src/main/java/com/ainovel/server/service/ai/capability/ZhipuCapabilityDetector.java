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
 * 智谱AI 能力检测器 - OpenAI兼容端点
 */
@Slf4j
@Component
public class ZhipuCapabilityDetector implements ProviderCapabilityDetector {

    private static final String DEFAULT_API_ENDPOINT = "https://open.bigmodel.cn/api/paas/v4";

    @Override
    public String getProviderName() {
        return "zhipu";
    }

    @Override
    public Mono<ModelListingCapability> detectModelListingCapability() {
        return Mono.just(ModelListingCapability.LISTING_WITH_KEY);
    }

    @Override
    public Flux<ModelInfo> getDefaultModels() {
        List<ModelInfo> models = new ArrayList<>();

        models.add(ModelInfo.builder()
            .id("glm-4")
            .name("GLM-4")
            .description("智谱 GLM-4 通用模型")
            .maxTokens(128000)
            .provider("zhipu")
            .build()
            .withUnifiedPrice(0.003));

        models.add(ModelInfo.builder()
            .id("glm-4-air")
            .name("GLM-4-Air")
            .description("智谱 GLM-4 Air 低成本版本")
            .maxTokens(128000)
            .provider("zhipu")
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




