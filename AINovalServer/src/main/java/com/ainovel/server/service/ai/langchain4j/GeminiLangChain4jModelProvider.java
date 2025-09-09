package com.ainovel.server.service.ai.langchain4j;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.reactive.function.client.WebClient;

import com.ainovel.server.config.ProxyConfig;
import com.ainovel.server.domain.model.AIRequest;
import com.ainovel.server.domain.model.AIResponse;
import com.ainovel.server.domain.model.ModelInfo;
import com.ainovel.server.service.ai.observability.ChatModelListenerManager;

import dev.langchain4j.model.googleai.GoogleAiGeminiChatModel;
import dev.langchain4j.model.googleai.GoogleAiGeminiStreamingChatModel;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * Gemini的LangChain4j实现
 *
 * 注意：Gemini模型与其他模型有不同的配置参数 1. 不支持baseUrl和timeout方法 2.
 * 支持temperature、maxOutputTokens、topK和topP等特有参数 3.
 * 详细文档请参考：https://docs.langchain4j.dev/integrations/language-models/google-ai-gemini/
 */
@Slf4j
public class GeminiLangChain4jModelProvider extends LangChain4jModelProvider {

    private static final String DEFAULT_API_ENDPOINT = "https://generativelanguage.googleapis.com/";
    private static final Map<String, Double> TOKEN_PRICES;




    static {
        Map<String, Double> prices = new HashMap<>();
        prices.put("gemini-pro", 0.0001);
        prices.put("gemini-pro-vision", 0.0001);
        prices.put("gemini-1.5-pro", 0.0007);
        prices.put("gemini-1.5-flash", 0.0001);
        prices.put("gemini-2.0-flash", 0.0001);
        TOKEN_PRICES = Collections.unmodifiableMap(prices);
    }

    /**
     * 构造函数
     *
     * @param modelName 模型名称
     * @param apiKey API密钥
     * @param apiEndpoint API端点
     * @param proxyConfig 代理配置 (由 Spring 注入)
     */
    public GeminiLangChain4jModelProvider(
            String modelName,
            String apiKey,
            String apiEndpoint,
            ProxyConfig proxyConfig,
            ChatModelListenerManager listenerManager
    ) {
        super("gemini", modelName, apiKey, apiEndpoint, proxyConfig, listenerManager);
    }

    @Override
    protected void initModels() {
        try {
            log.info("Gemini Provider (模型: {}): 调用 initModels，将配置系统代理...", modelName);
            // 配置系统代理 (现在会调用上面重写的 configureSystemProxy 方法)
            configureSystemProxy();

            log.info("尝试为Gemini模型 {} 初始化 LangChain4j 客户端...", modelName);
            
            // 获取所有注册的监听器
            List<dev.langchain4j.model.chat.listener.ChatModelListener> listeners = getListeners();

            // 创建非流式模型
            // 注意：Gemini模型不支持baseUrl和timeout方法，但支持其他特有参数
            var chatBuilder = GoogleAiGeminiChatModel.builder()
                    .apiKey(apiKey)
                    .modelName(modelName)
                    .temperature(0.7)
                    .maxOutputTokens(204800)
                    .topK(40)
                    .topP(0.95)
                    .logRequestsAndResponses(true);
            
            if (!listeners.isEmpty()) {
                chatBuilder.listeners(listeners);
            }
            this.chatModel = chatBuilder.build();

            // 创建流式模型
            var streamingBuilder = GoogleAiGeminiStreamingChatModel.builder()
                    .apiKey(apiKey)
                    .modelName(modelName)
                    .temperature(0.7)
                    .maxOutputTokens(204800)
                    .topK(40)
                    .topP(0.95);
            
            if (!listeners.isEmpty()) {
                streamingBuilder.listeners(listeners);
            }
            this.streamingChatModel = streamingBuilder.build();

            log.info("Gemini模型 {} 的 LangChain4j 客户端初始化成功。", modelName);
        } catch (Exception e) {
            log.error("初始化Gemini模型 {} 时出错: {}", modelName, e.getMessage(), e);
            this.chatModel = null;
            this.streamingChatModel = null;
        }
    }

    @Override
    public Mono<Double> estimateCost(AIRequest request) {
        // 获取模型价格（每1000个令牌的美元价格）
        double pricePerThousandTokens = TOKEN_PRICES.getOrDefault(modelName, 0.0001);

        // 估算输入令牌数
        int inputTokens = estimateInputTokens(request);

        // 估算输出令牌数
        int outputTokens = request.getMaxTokens() != null ? request.getMaxTokens() : 1000;

        // 计算总令牌数
        int totalTokens = inputTokens + outputTokens;

        // 计算成本（美元）
        double costInUSD = (totalTokens / 1000.0) * pricePerThousandTokens;

        // 转换为人民币（假设汇率为7.2）
        double costInCNY = costInUSD * 7.2;

        return Mono.just(costInCNY);
    }

    @Override
    public Flux<String> generateContentStream(AIRequest request) {
        log.info("开始Gemini流式生成，模型: {}", modelName);

        return super.generateContentStream(request)
                .doOnSubscribe(subscription -> log.info("Gemini流式生成已订阅"))
                .doOnNext(content -> {
                    if (!"heartbeat".equals(content) && !content.startsWith("错误：")) {
                        //log.debug("Gemini生成内容: {}", content);
                    }
                })
                .doOnComplete(() -> log.info("Gemini流式生成完成"))
                .doOnError(e -> {
                    // 检查是否是 getCandidates() 返回 null 的错误
                    if (e instanceof NullPointerException && 
                        e.getMessage() != null && 
                        e.getMessage().contains("getCandidates()")) {
                        log.error("Gemini API返回了空的candidates响应，可能的原因：1) API配额超限 2) 内容违反策略 3) 服务异常。模型: {}", modelName);
                    } 
                    // 检查是否是"neither with text nor with a function call"错误
                    else if (e instanceof RuntimeException && 
                            e.getMessage() != null && 
                            e.getMessage().contains("has responded neither with text nor with a function call")) {
                        log.error("Gemini API返回了空响应（既没有文本也没有函数调用），可能的原因：1) API瞬时异常 2) 服务过载 3) 内容过滤。模型: {}", modelName);
                    } else {
                        log.error("Gemini流式生成出错", e);
                    }
                })
                .doOnCancel(() -> {
                    log.info("Gemini流式生成被客户端取消 - 模型: {}", modelName);
                })
                // 🚀 新增：针对Gemini特定错误的重试机制
                .retryWhen(reactor.util.retry.Retry.backoff(2, java.time.Duration.ofSeconds(2))
                        .filter(error -> {
                            // 检查是否是需要重试的Gemini特定错误
                            boolean shouldRetry = false;
                            
                            // 1. getCandidates() null错误 - 通常是API瞬时问题
                            if (error instanceof NullPointerException && 
                                error.getMessage() != null && 
                                error.getMessage().contains("getCandidates()")) {
                                shouldRetry = true;
                            }
                            
                            // 2. "neither with text nor with a function call"错误 - LangChain4j解析问题
                            else if (error instanceof RuntimeException && 
                                    error.getMessage() != null && 
                                    error.getMessage().contains("has responded neither with text nor with a function call")) {
                                shouldRetry = true;
                            }
                            
                            // 3. 网络相关错误
                            else if (error instanceof java.net.SocketException ||
                                    error instanceof java.io.IOException ||
                                    error instanceof java.util.concurrent.TimeoutException) {
                                shouldRetry = true;
                            }
                            
                            if (shouldRetry) {
                                log.warn("Gemini流式生成遇到可重试错误，将进行重试。错误: {}", error.getMessage());
                            }
                            
                            return shouldRetry;
                        })
                        .doAfterRetry(retrySignal -> {
                            log.info("Gemini流式生成重试 #{}", retrySignal.totalRetries() + 1);
                        })
                )
                .onErrorResume(e -> {
                    // 对 NullPointerException 和 getCandidates 相关错误进行特殊处理
                    if (e instanceof NullPointerException && 
                        e.getMessage() != null && 
                        e.getMessage().contains("getCandidates()")) {
                        log.warn("检测到Gemini API candidates为null的错误，返回友好错误信息");
                        return Flux.just("错误：Gemini API响应异常，可能的原因包括：1) API配额已用完 2) 请求内容违反了内容策略 3) 服务暂时不可用。请检查API配额和请求内容。");
                    }
                    // 🚀 新增：处理"neither with text nor with a function call"错误
                    else if (e instanceof RuntimeException && 
                            e.getMessage() != null && 
                            e.getMessage().contains("has responded neither with text nor with a function call")) {
                        log.warn("检测到Gemini API空响应错误，返回友好错误信息");
                        return Flux.just("错误：Gemini模型返回了空响应，这通常是API瞬时问题。已进行重试但仍失败，建议：1) 稍后再试 2) 检查网络连接 3) 如果持续出现可尝试其他模型。");
                    }
                    // 其他错误继续向上传播
                    return Flux.error(e);
                });
    }

    @Override
    public Mono<AIResponse> generateContent(AIRequest request) {
        log.info("开始Gemini非流式生成，模型: {}", modelName);

        return super.generateContent(request)
                .doOnSuccess(response -> {
                    if (response != null) {
                        log.debug("Gemini生成响应成功");
                    }
                })
                .doOnError(e -> {
                    // 检查是否是 getCandidates() 返回 null 的错误
                    if (e instanceof NullPointerException && 
                        e.getMessage() != null && 
                        e.getMessage().contains("getCandidates()")) {
                        log.error("Gemini API返回了空的candidates响应，可能的原因：1) API配额超限 2) 内容违反策略 3) 服务异常。模型: {}", modelName);
                    } 
                    // 检查是否是"neither with text nor with a function call"错误
                    else if (e instanceof RuntimeException && 
                            e.getMessage() != null && 
                            e.getMessage().contains("has responded neither with text nor with a function call")) {
                        log.error("Gemini API返回了空响应（既没有文本也没有函数调用），可能的原因：1) API瞬时异常 2) 服务过载 3) 内容过滤。模型: {}", modelName);
                    } else {
                        log.error("Gemini非流式生成出错", e);
                    }
                })
                // 🚀 新增：针对Gemini特定错误的重试机制
                .retryWhen(reactor.util.retry.Retry.backoff(2, java.time.Duration.ofSeconds(2))
                        .filter(error -> {
                            // 检查是否是需要重试的Gemini特定错误
                            boolean shouldRetry = false;
                            
                            // 排除API密钥未配置的错误（继承基类逻辑）
                            if (error instanceof RuntimeException &&
                                error.getMessage() != null &&
                                error.getMessage().contains("API密钥未配置")) {
                                return false;
                            }
                            
                            // 1. getCandidates() null错误 - 通常是API瞬时问题
                            if (error instanceof NullPointerException && 
                                error.getMessage() != null && 
                                error.getMessage().contains("getCandidates()")) {
                                shouldRetry = true;
                            }
                            
                            // 2. "neither with text nor with a function call"错误 - LangChain4j解析问题
                            else if (error instanceof RuntimeException && 
                                    error.getMessage() != null && 
                                    error.getMessage().contains("has responded neither with text nor with a function call")) {
                                shouldRetry = true;
                            }
                            
                            // 3. 网络相关错误
                            else if (error instanceof java.net.SocketException ||
                                    error instanceof java.io.IOException ||
                                    error instanceof java.util.concurrent.TimeoutException) {
                                shouldRetry = true;
                            }
                            
                            if (shouldRetry) {
                                log.warn("Gemini非流式生成遇到可重试错误，将进行重试。错误: {}", error.getMessage());
                            }
                            
                            return shouldRetry;
                        })
                        .doAfterRetry(retrySignal -> {
                            log.info("Gemini非流式生成重试 #{}", retrySignal.totalRetries() + 1);
                        })
                )
                .onErrorResume(e -> {
                    // 🚀 新增：处理"neither with text nor with a function call"错误
                    if (e instanceof RuntimeException && 
                            e.getMessage() != null && 
                            e.getMessage().contains("has responded neither with text nor with a function call")) {
                        log.warn("检测到Gemini API空响应错误，返回友好错误信息");
                        AIResponse errorResponse = new AIResponse();
                        errorResponse.setContent("错误：Gemini模型返回了空响应，这通常是API瞬时问题。已进行重试但仍失败，建议：1) 稍后再试 2) 检查网络连接 3) 如果持续出现可尝试其他模型。");
                        // 设置错误状态
                        try {
                            errorResponse.getClass().getMethod("setStatus", String.class)
                                .invoke(errorResponse, "error");
                        } catch (Exception ex) {
                            log.warn("无法设置AIResponse的status属性", ex);
                        }
                        return Mono.just(errorResponse);
                    }
                    // 其他错误继续向上传播
                    return Mono.error(e);
                });
    }

    /**
     * Gemini需要API密钥才能获取模型列表
     * 覆盖基类的listModelsWithApiKey方法
     *
     * @param apiKey API密钥
     * @param apiEndpoint 可选的API端点
     * @return 模型信息列表
     */
    @Override
    public Flux<ModelInfo> listModelsWithApiKey(String apiKey, String apiEndpoint) {
        if (isApiKeyEmpty(apiKey)) {
            return Flux.error(new RuntimeException("API密钥不能为空"));
        }

        log.info("获取Gemini模型列表");

        // 获取API端点
        String baseUrl = apiEndpoint != null && !apiEndpoint.trim().isEmpty() ?
                apiEndpoint : DEFAULT_API_ENDPOINT;

        // 创建WebClient
        WebClient webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .build();

        // 调用Gemini API获取模型列表
        // Gemini API的路径可能不同，需要根据实际情况调整
        return webClient.get()
                .uri("/v1/models?key=" + apiKey)
                .accept(MediaType.APPLICATION_JSON)
                .retrieve()
                .bodyToMono(String.class)
                .flatMapMany(response -> {
                    try {
                        // 解析响应
                        log.debug("Gemini模型列表响应: {}", response);

                        // 这里应该使用JSON解析库来解析响应
                        // 简化起见，返回预定义的模型列表
                        return Flux.fromIterable(getDefaultGeminiModels());
                    } catch (Exception e) {
                        log.error("解析Gemini模型列表时出错", e);
                        return Flux.fromIterable(getDefaultGeminiModels());
                    }
                })
                .onErrorResume(e -> {
                    log.error("获取Gemini模型列表时出错", e);
                    // 出错时返回预定义的模型列表
                    return Flux.fromIterable(getDefaultGeminiModels());
                });
    }

    /**
     * 获取默认的Gemini模型列表
     *
     * @return 模型信息列表
     */
    private List<ModelInfo> getDefaultGeminiModels() {
        List<ModelInfo> models = new ArrayList<>();

        models.add(ModelInfo.basic("gemini-pro", "Gemini Pro", "gemini")
                .withDescription("Google的Gemini Pro模型 - 强大的文本生成和推理能力")
                .withMaxTokens(32768)
                .withUnifiedPrice(0.0001));

        models.add(ModelInfo.basic("gemini-pro-vision", "Gemini Pro Vision", "gemini")
                .withDescription("Google的Gemini Pro Vision模型 - 支持图像输入")
                .withMaxTokens(32768)
                .withUnifiedPrice(0.0001));

        models.add(ModelInfo.basic("gemini-1.5-pro", "Gemini 1.5 Pro", "gemini")
                .withDescription("Google的Gemini 1.5 Pro模型 - 新一代多模态模型")
                .withMaxTokens(1000000)
                .withUnifiedPrice(0.0007));

        models.add(ModelInfo.basic("gemini-1.5-flash", "Gemini 1.5 Flash", "gemini")
                .withDescription("Google的Gemini 1.5 Flash模型 - 更快速的版本")
                .withMaxTokens(1000000)
                .withUnifiedPrice(0.0001));

        models.add(ModelInfo.basic("gemini-2.0-flash", "Gemini 2.0 Flash", "gemini")
                .withDescription("Google的Gemini 2.0 Flash模型 - 最新版本")
                .withMaxTokens(1000000)
                .withUnifiedPrice(0.0001));

        return models;
    }
}
