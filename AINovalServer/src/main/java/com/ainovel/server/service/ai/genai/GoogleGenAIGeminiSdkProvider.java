package com.ainovel.server.service.ai.genai;

import com.ainovel.server.domain.model.AIRequest;
import com.ainovel.server.domain.model.AIResponse;
import com.ainovel.server.service.ai.AbstractAIModelProvider;
import com.google.genai.Client;
import com.google.genai.ResponseStream;
import com.google.genai.types.Content;
import com.google.genai.types.GenerateContentConfig;
import com.google.genai.types.GenerateContentResponse;
import com.google.genai.types.Part;
import com.google.genai.types.ThinkingConfig;
import com.google.genai.types.Tool;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 使用 Google GenAI 官方 Java SDK 的 Gemini Provider
 * 目标：与现有 REST 版完全兼容（签名与行为），可无缝替换
 */
@Slf4j
public class GoogleGenAIGeminiSdkProvider extends AbstractAIModelProvider {

    private Client client;

    public GoogleGenAIGeminiSdkProvider(String modelName, String apiKey, String apiEndpoint) {
        super("gemini", modelName, apiKey, apiEndpoint);
        initClient();
    }

    private void initClient() {
        // 官方 SDK 默认读取环境变量 GOOGLE_API_KEY；我们优先用传入 apiKey 显式设置
        Client.Builder builder = Client.builder();
        if (this.apiKey != null && !this.apiKey.isBlank()) {
            builder.apiKey(this.apiKey);
        }
        // 若有自定义 endpoint，可通过 HttpOptions 配置（SDK 支持）；此处保持默认行为以减少破坏
        this.client = builder.build();
    }

    @Override
    public void setProxy(String host, int port) {
        // SDK 当前未直接暴露代理配置；保持开关状态，回退由工厂/外层控制
        super.setProxy(host, port);
        log.info("GoogleGenAIGeminiSdkProvider: 已记录代理设置 host={}, port={}", host, port);
    }

    @Override
    public void disableProxy() {
        super.disableProxy();
        log.info("GoogleGenAIGeminiSdkProvider: 已关闭代理");
    }

    @Override
    public Mono<AIResponse> generateContent(AIRequest request) {
        if (isApiKeyEmpty()) {
            AIResponse errorResponse = createBaseResponse("API密钥未配置", request);
            errorResponse.setFinishReason("error");
            return Mono.just(errorResponse);
        }

        try {
            Content content = buildContentFromRequest(request);
            GenerateContentConfig config = buildConfigFromRequest(request);

            GenerateContentResponse resp = client.models.generateContent(modelName, content, config);
            AIResponse ai = toAIResponse(resp, request);
            return Mono.just(ai);
        } catch (Throwable e) {
            log.error("Gemini SDK 非流式调用失败: {}", e.getMessage(), e);
            return handleApiException(e, request);
        }
    }

    @Override
    public Flux<String> generateContentStream(AIRequest request) {
        if (isApiKeyEmpty()) {
            return Flux.just("错误：API密钥未配置");
        }

        return Flux.defer(() -> {
            try {
                Content content = buildContentFromRequest(request);
                GenerateContentConfig config = buildConfigFromRequest(request);
                ResponseStream<GenerateContentResponse> stream = client.models.generateContentStream(modelName, content, config);

                return Flux.fromIterable(stream)
                        .map(resp -> {
                            try {
                                String s = resp != null ? resp.text() : "";
                                return s != null ? s : "";
                            } catch (IllegalArgumentException ex) {
                                // 典型场景：工具调用片段或不可直接转文本，忽略即可，返回空串以在下游过滤
                                return "";
                            }
                        })
                        .filter(s -> !s.isEmpty())
                        .doFinally(signal -> {
                            try { stream.close(); } catch (Exception ignore) {}
                        });
            } catch (Throwable e) {
                log.error("Gemini SDK 流式调用失败: {}", e.getMessage(), e);
                return Flux.error(e);
            }
        }).onErrorResume(e -> Flux.just("错误：" + e.getMessage()));
    }

    @Override
    public Mono<Double> estimateCost(AIRequest request) {
        // 与 REST 版保持一致的简易估算逻辑
        double inputPer1k = 0.000125; // 示例值，USD/1K tokens
        double outputPer1k = 0.000375;
        int inputTokens = estimateTokenCountFromRequest(request);
        int outputTokens = request.getMaxTokens() != null ? request.getMaxTokens() : 1000;
        double costUsd = (inputTokens / 1000.0) * inputPer1k + (outputTokens / 1000.0) * outputPer1k;
        double costCny = costUsd * 7.2;
        return Mono.just(costCny);
    }

    @Override
    public Mono<Boolean> validateApiKey() {
        // SDK 无显式校验接口，做一次轻量请求或直接返回存在性
        return Mono.just(!isApiKeyEmpty());
    }

    private Content buildContentFromRequest(AIRequest request) {
        List<Part> parts = new ArrayList<>();

        if (request.getPrompt() != null && !request.getPrompt().isEmpty()) {
            parts.add(Part.fromText(request.getPrompt()));
        }

        // 附件（与 REST 版兼容：parameters.attachments 支持 inlineData/fileUri/text）
        List<Part> attachmentParts = buildAttachmentParts(request);
        parts.addAll(attachmentParts);

        // 多轮消息：将历史消息串接为 text parts（SDK 也支持 Content.fromParts 多 Part）
        if (request.getMessages() != null) {
            request.getMessages().forEach(m -> {
                if (m.getContent() != null && !m.getContent().isEmpty()) {
                    parts.add(Part.fromText(m.getRole() + ": " + m.getContent()));
                }
            });
        }

        if (parts.isEmpty()) {
            parts.add(Part.fromText(""));
        }
        return Content.fromParts(parts.toArray(new Part[0]));
    }

    private List<Part> buildAttachmentParts(AIRequest request) {
        List<Part> result = new ArrayList<>();
        Map<String, Object> params = request.getParameters();
        if (params == null) return result;
        Object att = params.get("attachments");
        if (!(att instanceof List<?> list) || list.isEmpty()) return result;
        for (Object o : list) {
            if (!(o instanceof Map<?, ?> m)) continue;
            String type = asString(m.get("type"));
            String mimeType = asString(m.get("mimeType"));
            if ("image_base64".equalsIgnoreCase(type)) {
                String data = asString(m.get("data"));
                if (data != null) {
                    String mt = mimeType != null ? mimeType : "image/png";
                    String dataUrl = "data:" + mt + ";base64," + data;
                    result.add(Part.fromUri(dataUrl, mt));
                }
            } else if ("file_uri".equalsIgnoreCase(type)) {
                String fileUri = asString(m.get("fileUri"));
                if (fileUri != null) {
                    result.add(Part.fromUri(fileUri, mimeType != null ? mimeType : "application/octet-stream"));
                }
            } else if ("text".equalsIgnoreCase(type)) {
                String text = asString(m.get("text"));
                if (text != null) {
                    result.add(Part.fromText(text));
                }
            }
        }
        return result;
    }

    private GenerateContentConfig buildConfigFromRequest(AIRequest request) {
        GenerateContentConfig.Builder builder = GenerateContentConfig.builder();

        if (request.getMaxTokens() != null) {
            builder.maxOutputTokens(request.getMaxTokens());
        }
        if (request.getTemperature() != null) {
            builder.temperature(request.getTemperature().floatValue());
        }

        // 思考/推理：parameters.reasoning.thinkingBudget = 0 可关闭
        Map<String, Object> params = request.getParameters();
        if (params != null) {
            Object reasoning = params.get("reasoning");
            if (reasoning instanceof Map<?, ?> rmap) {
                Object budget = rmap.get("thinkingBudget");
                if (budget instanceof Number n) {
                    builder.thinkingConfig(ThinkingConfig.builder().thinkingBudget(n.intValue()));
                }
            }

            // systemInstruction
            Object session = params.get("session");
            if (session instanceof Map<?, ?> smap) {
                Object sys = smap.get("systemInstruction");
                if (sys instanceof String s && !s.isEmpty()) {
                    // 先设置外部传入的指令
                    builder.systemInstruction(Content.fromParts(Part.fromText(s)));
                }
            }
        }

        // 工具（函数调用）：强制使用“文本 JSON 工具调用模式”，避免 SDK 自动函数调用导致上层无法解析
        if (request.getToolSpecifications() != null && !request.getToolSpecifications().isEmpty()) {
            String allowed = String.join(", ", collectToolNames(request));
            String enforce = "重要：你现在处于工具调用模式。你必须只输出一个 JSON 对象，且不得输出任何多余文字或标点。" +
                    "格式严格为：{\"name\":\"<函数名>\",\"arguments\":{...}}。" +
                    "其中 <函数名> 必须属于以下允许列表：[" + allowed + "]。" +
                    "不要使用函数调用通道，不要返回自然语言。";
            builder.systemInstruction(Content.fromParts(Part.fromText(enforce)));
            if (request.getTemperature() == null) {
                builder.temperature(0f);
            }
        }

        return builder.build();
    }

    @SuppressWarnings("unused")
    private List<Tool> buildToolsFromRequest(AIRequest request) {
        List<Tool> tools = new ArrayList<>();
        if (request.getToolSpecifications() == null || request.getToolSpecifications().isEmpty()) {
            return tools;
        }
        // SDK 的 Tool.functions 需要 Method 反射；此处先声明空 Tool，允许模型输出函数名+参数，再由上层执行
        // 兼容现有工具循环：SDK 返回的 AFC 历史我们不强依赖，仅解析文本与工具调用内容
        tools.add(Tool.builder().build());
        return tools;
    }

    private List<String> collectToolNames(AIRequest request) {
        List<String> names = new ArrayList<>();
        if (request.getToolSpecifications() == null) return names;
        for (Object spec : request.getToolSpecifications()) {
            try {
                String n = tryGetString(spec, "name", "getName");
                if (n != null && !n.isEmpty()) names.add(n);
            } catch (Exception ignore) {}
        }
        return names;
    }

    private AIResponse toAIResponse(GenerateContentResponse resp, AIRequest request) {
        AIResponse ai = createBaseResponse("", request);
        if (resp == null) return ai;
        boolean toolMode = request.getToolSpecifications() != null && !request.getToolSpecifications().isEmpty();
        String text = null;
        try {
            text = resp.text();
        } catch (IllegalArgumentException ex) {
            // 典型场景：UNEXPECTED_TOOL_CALL（模型尝试使用函数调用通道）
            if (toolMode) {
                // 在工具模式下，容忍该异常，交由上层根据空文本+后续JSON重试策略处理
                text = null;
            } else {
                throw ex;
            }
        }
        if (toolMode) {
            // 优先解析工具调用 JSON
            AIResponse.ToolCall call = tryParseToolJson(text, collectToolNames(request));
            if (call != null) {
                ai.setToolCalls(List.of(call));
                ai.setFinishReason("tool_calls");
                ai.setContent("");
                return ai;
            }
        }
        ai.setContent(text != null ? text : "");
        return ai;
    }

    private AIResponse.ToolCall tryParseToolJson(String text, List<String> allowedNames) {
        if (text == null || text.isEmpty()) return null;
        String s = text.trim();
        // 宽松解析：尝试找到 {"name":..., "arguments": ...}
        try {
            // 简化：用 com.fasterxml.jackson.databind.ObjectMapper 不依赖，避免引入；改为手工查找
            int iName = s.indexOf("\"name\"");
            int iArgs = s.indexOf("\"arguments\"");
            if (iName < 0 || iArgs < 0) return null;
            // 提取 name 值
            int colon = s.indexOf(':', iName);
            if (colon < 0) return null;
            int startQuote = s.indexOf('"', colon + 1);
            int endQuote = s.indexOf('"', startQuote + 1);
            if (startQuote < 0 || endQuote < 0) return null;
            String name = s.substring(startQuote + 1, endQuote);
            if (allowedNames != null && !allowedNames.isEmpty() && !allowedNames.contains(name)) return null;
            // 提取 arguments（从 iArgs 后第一个 '{' 到匹配的 '}'）
            int braceStart = s.indexOf('{', iArgs);
            if (braceStart < 0) return null;
            int depth = 0; int pos = braceStart; int end = -1;
            while (pos < s.length()) {
                char c = s.charAt(pos);
                if (c == '{') depth++;
                else if (c == '}') { depth--; if (depth == 0) { end = pos; break; } }
                pos++;
            }
            if (end < 0) return null;
            String argsJson = s.substring(braceStart, end + 1);
            return AIResponse.ToolCall.builder()
                    .id(name + "-" + System.currentTimeMillis())
                    .type("function")
                    .function(AIResponse.Function.builder().name(name).arguments(argsJson).build())
                    .build();
        } catch (Exception ignore) {
            return null;
        }
    }

    private String tryGetString(Object obj, String... methodNames) {
        for (String m : methodNames) {
            try {
                var method = obj.getClass().getMethod(m);
                Object val = method.invoke(obj);
                if (val != null) return val.toString();
            } catch (Exception ignored) {}
        }
        return null;
    }

    private int estimateTokenCountFromRequest(AIRequest request) {
        int tokenCount = 0;
        if (request.getPrompt() != null && !request.getPrompt().isEmpty()) {
            tokenCount += roughCount(request.getPrompt());
        }
        if (request.getMessages() != null) {
            for (AIRequest.Message m : request.getMessages()) {
                if (m.getContent() != null) tokenCount += roughCount(m.getContent());
            }
        }
        return tokenCount;
    }

    private int roughCount(String text) {
        if (text == null || text.isEmpty()) return 0;
        return (int) (text.split("\\s+").length * 1.3);
    }

    private String asString(Object o) {
        return o == null ? null : o.toString();
    }
}


