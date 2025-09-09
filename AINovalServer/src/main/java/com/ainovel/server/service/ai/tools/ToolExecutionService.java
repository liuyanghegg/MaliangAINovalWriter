package com.ainovel.server.service.ai.tools;

import com.fasterxml.jackson.databind.ObjectMapper;
import dev.langchain4j.agent.tool.ToolExecutionRequest;
import com.ainovel.server.service.ai.tools.events.ToolEvent;
import reactor.core.publisher.Sinks;
import dev.langchain4j.data.message.AiMessage;
import dev.langchain4j.data.message.ChatMessage;
import dev.langchain4j.data.message.ToolExecutionResultMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * 工具执行服务
 * 处理AI的工具调用请求
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ToolExecutionService {
    
    private final ToolRegistry toolRegistry;
    private final ObjectMapper objectMapper;
    // 按 contextId 维护流式事件通道（仅用于“纯数据工具编排”场景）
    private final Map<String, Sinks.Many<ToolEvent>> contextEventSinks = new HashMap<>();
    private final Map<String, Long> contextSequences = new HashMap<>();
    
    /**
     * 执行AI消息中的工具调用
     */
    public List<ChatMessage> executeToolCalls(AiMessage aiMessage) {
        // 兼容旧入口，默认无上下文
        return executeToolCalls(aiMessage, null);
    }
    
    /**
     * 执行AI消息中的工具调用（支持上下文）
     */
    public List<ChatMessage> executeToolCalls(AiMessage aiMessage, String contextId) {
        List<ChatMessage> results = new ArrayList<>();
        
        if (!aiMessage.hasToolExecutionRequests()) {
            log.debug("No tool execution requests in AI message");
            return results;
        }
        
        log.info("处理工具调用请求: 数量={}", aiMessage.toolExecutionRequests().size());
        
        for (ToolExecutionRequest request : aiMessage.toolExecutionRequests()) {
            log.debug("处理工具调用: id={} 工具={} 上下文={} 参数={} ", 
                request.id(), request.name(), contextId, request.arguments());
            
            try {
                // 事件：收到调用
                emitEvent(contextId, ToolEvent.builder()
                    .contextId(contextId)
                    .eventType("CALL_RECEIVED")
                    .toolName(request.name())
                    .argumentsJson(request.arguments())
                    .timestamp(java.time.LocalDateTime.now())
                    .sequence(nextSequence(contextId))
                    .build());
                String result = executeToolCallInContext(contextId, request.name(), request.arguments());
                results.add(new ToolExecutionResultMessage(
                    request.id(),
                    request.name(),
                    result
                ));
                log.info("工具执行成功: 工具={} 结果长度={}", 
                    request.name(), result.length());
                // 事件：结果
                emitEvent(contextId, ToolEvent.builder()
                    .contextId(contextId)
                    .eventType("CALL_RESULT")
                    .toolName(request.name())
                    .argumentsJson(request.arguments())
                    .resultJson(result)
                    .success(true)
                    .timestamp(java.time.LocalDateTime.now())
                    .sequence(nextSequence(contextId))
                    .build());
            } catch (Exception e) {
                log.error("工具执行失败: 工具={} 参数={}", 
                    request.name(), request.arguments(), e);
                results.add(new ToolExecutionResultMessage(
                    request.id(),
                    request.name(),
                    createErrorResponse(e.getMessage())
                ));
                // 事件：错误
                emitEvent(contextId, ToolEvent.builder()
                    .contextId(contextId)
                    .eventType("CALL_ERROR")
                    .toolName(request.name())
                    .argumentsJson(request.arguments())
                    .errorMessage(e.getMessage())
                    .success(false)
                    .timestamp(java.time.LocalDateTime.now())
                    .sequence(nextSequence(contextId))
                    .build());
            }
        }
        
        return results;
    }
    
    /**
     * 执行单个工具调用（修复版本：支持上下文工具执行）
     */
    private String executeToolCall(String toolName, String argumentsJson) throws Exception {
        return executeToolCallInContext(null, toolName, argumentsJson);
    }
    
    /**
     * 在特定上下文中执行工具调用
     */
    public String invokeTool(String context, String toolName, String argumentsJson) throws Exception {
        return executeToolCallInContext(context, toolName, argumentsJson);
    }

    /**
     * 在特定上下文中执行工具调用（内部实现）
     */
    private String executeToolCallInContext(String context, String toolName, String argumentsJson) throws Exception {
        log.debug("执行工具(解析前): 工具={} 上下文={} 参数原文={}", toolName, context, argumentsJson);
        
        // 尝试直接查找
        Optional<ToolDefinition> toolOpt = context != null ? 
            toolRegistry.getToolForContext(context, toolName) : 
            toolRegistry.getTool(toolName);

        // 如果直接未命中，执行多格式匹配
        if (toolOpt.isEmpty()) {
            String normalizedRequested = normalizeToolName(toolName);
            Set<String> availableToolNames = context != null ? 
                toolRegistry.getToolNamesForContext(context) : 
                toolRegistry.getAvailableToolNames();
                
            for (String registeredName : availableToolNames) {
                if (normalizeToolName(registeredName).equals(normalizedRequested)) {
                    toolOpt = context != null ? 
                        toolRegistry.getToolForContext(context, registeredName) : 
                        toolRegistry.getTool(registeredName);
                    break;
                }
            }
        }

        if (toolOpt.isEmpty()) {
            Set<String> availableTools = context != null ? 
                toolRegistry.getToolNamesForContext(context) : 
                toolRegistry.getAvailableToolNames();
            log.error("未找到工具: {} 上下文={} 可用工具={}", toolName, context, availableTools);
            throw new IllegalArgumentException("Unknown tool: " + toolName + " in context: " + context);
        }

        // 最终解析出的工具名称
        String resolvedToolName = toolOpt.get().getName();
        
        // 解析参数
        Map<String, Object> parameters = parseArguments(argumentsJson);
        log.debug("解析后的参数: 工具={} 上下文={} 参数={} ", resolvedToolName, context, parameters);
        
        // 执行工具
        log.debug("开始执行工具: 工具={} 上下文={}", resolvedToolName, context);
        Object rawResult = toolRegistry.executeToolForContext(context, resolvedToolName, parameters);
        log.debug("工具执行完成: 工具={} 上下文={} 结果类型={}", resolvedToolName, context,
            rawResult != null ? rawResult.getClass().getSimpleName() : "null");

        // 在生成/修改流程中对结果做精简，避免将大体量数据（如 nodeIdMapping、createdNodeIds）回传给模型
        Object resultForModel = compactResultIfNecessary(context, resolvedToolName, rawResult);
        
        // 序列化结果
        String serializedResult = objectMapper.writeValueAsString(resultForModel);
        log.debug("序列化工具结果: 工具={} 上下文={} 内容长度={} 字符", resolvedToolName, context, serializedResult != null ? serializedResult.length() : 0);
        
        return serializedResult;
    }

    // ==================== 事件流（纯数据直通编排使用） ====================
    public reactor.core.publisher.Flux<ToolEvent> subscribeToContext(String contextId) {
        Sinks.Many<ToolEvent> sink = contextEventSinks.computeIfAbsent(contextId, k -> Sinks.many().multicast().onBackpressureBuffer());
        return sink.asFlux();
    }

    public void closeContext(String contextId) {
        Sinks.Many<ToolEvent> sink = contextEventSinks.remove(contextId);
        if (sink != null) {
            try { sink.tryEmitComplete(); } catch (Exception ignore) {}
        }
        contextSequences.remove(contextId);
    }

    private void emitEvent(String contextId, ToolEvent event) {
        if (contextId == null) return; // 非流式直通场景可忽略
        Sinks.Many<ToolEvent> sink = contextEventSinks.get(contextId);
        if (sink != null) {
            sink.tryEmitNext(event);
        }
    }

    private long nextSequence(String contextId) {
        if (contextId == null) return -1L;
        long next = contextSequences.getOrDefault(contextId, 0L) + 1L;
        contextSequences.put(contextId, next);
        return next;
    }

    /**
     * 在特定上下文下精简工具结果，减少回传给大模型的无关或大体量字段
     */
    @SuppressWarnings("unchecked")
    private Object compactResultIfNecessary(String context, String toolName, Object rawResult) {
        if (rawResult == null) {
            return null;
        }
        boolean isGenerationOrModification = context != null && (context.startsWith("generation-") || context.startsWith("modification-"));
        if (!isGenerationOrModification) {
            return rawResult;
        }
        // 仅对创建设定相关工具做压缩
        if (!("create_setting_nodes".equals(toolName) || "create_setting_node".equals(toolName))) {
            return rawResult;
        }
        if (rawResult instanceof Map<?, ?> rawMap) {
            Map<String, Object> compact = new HashMap<>((Map<String, Object>) rawMap);
            // 统计数量并移除大字段
            Object createdList = compact.get("createdNodeIds");
            if (createdList instanceof List<?> list) {
                compact.put("createdCount", list.size());
                compact.remove("createdNodeIds");
            }
            // nodeIdMapping 体量大，模型无需感知
            compact.remove("nodeIdMapping");
            // errors 若存在，仅保留条数
            Object errors = compact.get("errors");
            if (errors instanceof List<?> errList) {
                compact.put("errorCount", errList.size());
                compact.remove("errors");
            }
            // 标记为已压缩，便于追踪
            compact.put("resultCompacted", true);
            return compact;
        }
        return rawResult;
    }
    
    /**
     * 解析工具参数
     */
    @SuppressWarnings("unchecked")
    private Map<String, Object> parseArguments(String argumentsJson) throws Exception {
        log.debug("解析工具参数: 原文长度={}", argumentsJson != null ? argumentsJson.length() : 0);
        
        if (argumentsJson == null || argumentsJson.trim().isEmpty()) {
            log.debug("Empty arguments, returning empty map");
            return new HashMap<>();
        }
        
        try {
            Object parsed = objectMapper.readValue(argumentsJson, Object.class);
            if (parsed instanceof Map) {
                Map<String, Object> result = (Map<String, Object>) parsed;
                log.debug("参数解析成功: 键数={}", result.size());
                return result;
            }
            
            log.error("工具参数不是JSON对象: {}", argumentsJson);
            throw new IllegalArgumentException("Tool arguments must be a JSON object");
        } catch (Exception e) {
            log.error("解析工具参数失败: 原文长度={} 错误={}", argumentsJson != null ? argumentsJson.length() : 0, e.getMessage(), e);
            throw new IllegalArgumentException("Invalid JSON in tool arguments: " + e.getMessage(), e);
        }
    }
    
    /**
     * 创建错误响应
     */
    private String createErrorResponse(String errorMessage) {
        Map<String, Object> error = new HashMap<>();
        error.put("success", false);
        error.put("error", errorMessage);
        error.put("timestamp", System.currentTimeMillis());
        
        try {
            String errorJson = objectMapper.writeValueAsString(error);
            log.debug("已创建错误响应JSON，长度={}", errorJson.length());
            return errorJson;
        } catch (Exception e) {
            log.error("Failed to serialize error response", e);
            return "{\"success\": false, \"error\": \"Failed to serialize error\", \"timestamp\": " + 
                System.currentTimeMillis() + "}";
        }
    }
    
    /**
     * 创建工具调用上下文
     */
    public ToolCallContext createContext(String contextId) {
        log.info("创建工具调用上下文: {}", contextId);
        return new ToolCallContext(contextId, toolRegistry);
    }
    
    /**
     * 工具调用上下文（修复版本：支持上下文感知的工具执行）
     */
    public static class ToolCallContext implements AutoCloseable {
        private final String contextId;
        private final ToolRegistry registry;
        private final Map<String, Object> contextData = new HashMap<>();
        
        public ToolCallContext(String contextId, ToolRegistry registry) {
            this.contextId = contextId;
            this.registry = registry;
            log.debug("已创建工具调用上下文: {}", contextId);
        }
        
        public void registerTool(ToolDefinition tool) {
            log.debug("注册工具到上下文: 工具={} 上下文={}", tool.getName(), contextId);
            registry.registerToolForContext(contextId, tool);
        }
        
        public void setData(String key, Object value) {
            log.debug("设置上下文数据: 上下文={} {}=...", contextId, key);
            contextData.put(key, value);
        }
        
        public Object getData(String key) {
            Object value = contextData.get(key);
            log.debug("读取上下文数据: 上下文={} 键={}", contextId, key);
            return value;
        }
        
        /**
         * 在此上下文中执行工具
         */
        public String executeToolInContext(String toolName, String argumentsJson) throws Exception {
            ToolExecutionService service = new ToolExecutionService(registry, new ObjectMapper());
            return service.executeToolCallInContext(contextId, toolName, argumentsJson);
        }
        
        /**
         * 获取上下文ID
         */
        public String getContextId() {
            return contextId;
        }
        
        @Override
        public void close() {
            log.info("关闭工具调用上下文: {}", contextId);
            try {
                registry.clearContextTools(contextId);
                contextData.clear();
                log.debug("工具调用上下文关闭完成: {}", contextId);
            } catch (Exception e) {
                log.error("关闭工具调用上下文出错: {}", contextId, e);
            }
        }
    }

    /**
     * 将不同风格的工具名称标准化，便于匹配。规则：<br/>
     * 1. 全部转为小写<br/>
     * 2. 去掉下划线、连字符等分隔符<br/>
     */
    private String normalizeToolName(String name) {
        if (name == null) {
            return "";
        }
        String s = name.toLowerCase().replaceAll("[_-]", "");
        // 折叠重复后缀，比如 nodesnodes → nodes
        while (s.endsWith("nodesnodes")) {
            s = s.substring(0, s.length() - "nodes".length());
        }
        while (s.endsWith("nodenode")) {
            s = s.substring(0, s.length() - "node".length());
        }
        return s;
    }
}