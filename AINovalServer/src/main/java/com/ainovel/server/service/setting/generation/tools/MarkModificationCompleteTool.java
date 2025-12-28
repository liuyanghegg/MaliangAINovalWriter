package com.ainovel.server.service.setting.generation.tools;

import com.ainovel.server.service.ai.tools.ToolDefinition;
import dev.langchain4j.agent.tool.ToolSpecification;
import dev.langchain4j.model.chat.request.json.JsonObjectSchema;
import dev.langchain4j.model.chat.request.json.JsonStringSchema;
import lombok.extern.slf4j.Slf4j;

import java.util.Collections;
import java.util.Map;

/**
 * 标记修改完成工具
 * 用于在节点修改流程中，由AI明确告知系统修改操作已完成。
 */
@Slf4j
public class MarkModificationCompleteTool implements ToolDefinition {

    private final CompletionHandler handler;

    public MarkModificationCompleteTool(CompletionHandler handler) {
        this.handler = handler;
    }

    @Override
    public String getName() {
        return "markModificationComplete";
    }

    @Override
    public String getDescription() {
        return "当对一个或多个设定节点的修改和创建操作全部完成后，调用此工具来结束当前修改流程。";
    }

    @Override
    public ToolSpecification getSpecification() {
        return ToolSpecification.builder()
                .name(getName())
                .description(getDescription())
                .parameters(JsonObjectSchema.builder()
                        .addProperty("message", JsonStringSchema.builder()
                                .description("一条简短的完成信息，说明修改已完成。")
                                .build())
                        .build())
                .build();
    }

    @Override
    public Object execute(Map<String, Object> parameters) {
        String message = (String) parameters.getOrDefault("message", "Modification completed successfully.");
        log.info("Executing MarkModificationCompleteTool with message: {}", message);
        boolean result = handler.handleCompletion(message);
        return Collections.singletonMap("success", result);
    }

    /**
     * 完成处理器接口
     */
    public interface CompletionHandler {
        boolean handleCompletion(String message);
    }
} 