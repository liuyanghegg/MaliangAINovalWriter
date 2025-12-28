package com.ainovel.server.service.setting.generation.tools;

import com.ainovel.server.service.ai.tools.ToolDefinition;
import dev.langchain4j.agent.tool.ToolSpecification;
import dev.langchain4j.model.chat.request.json.JsonObjectSchema;
import dev.langchain4j.model.chat.request.json.JsonStringSchema;
import lombok.extern.slf4j.Slf4j;

import java.util.HashMap;
import java.util.Map;

/**
 * 标记生成完成工具
 */
@Slf4j
public class MarkGenerationCompleteTool implements ToolDefinition {
    
    private final CompletionHandler handler;
    
    public MarkGenerationCompleteTool(CompletionHandler handler) {
        this.handler = handler;
    }
    
    @Override
    public String getName() {
        return "markGenerationComplete";
    }
    
    @Override
    public String getDescription() {
        return "标记当前设定生成任务已完成。";
    }
    
    @Override
    public ToolSpecification getSpecification() {
        JsonObjectSchema parameters = JsonObjectSchema.builder()
            .addProperty("message", JsonStringSchema.builder()
                .description("完成消息")
                .build())
            .build();
        
        return ToolSpecification.builder()
            .name(getName())
            .description(getDescription())
            .parameters(parameters)
            .build();
    }
    
    @Override
    public Object execute(Map<String, Object> parameters) {
        String message = (String) parameters.getOrDefault("message", "Generation completed");
        
        boolean success = handler.handleCompletion(message);
        
        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("message", message);
        
        log.info("Generation marked as complete: {}", message);
        return result;
    }
    
    /**
     * 完成处理器接口
     */
    public interface CompletionHandler {
        boolean handleCompletion(String message);
    }
}