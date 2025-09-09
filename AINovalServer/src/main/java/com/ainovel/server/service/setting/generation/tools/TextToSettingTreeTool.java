package com.ainovel.server.service.setting.generation.tools;

import com.ainovel.server.service.ai.tools.ToolDefinition;
import dev.langchain4j.agent.tool.ToolSpecification;
import dev.langchain4j.model.chat.request.json.JsonArraySchema;
import dev.langchain4j.model.chat.request.json.JsonObjectSchema;
import dev.langchain4j.model.chat.request.json.JsonStringSchema;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 纯数据工具：将文本解析为设定树（分层结构），不落库不改会话。
 * 要求模型返回 'tree'：节点包含 name/type/description/tempId/children/sourceSpans 等。
 */
public class TextToSettingTreeTool implements ToolDefinition {

    @Override
    public String getName() {
        return "text_to_setting_tree";
    }

    @Override
    public String getDescription() {
        return "将输入的设定文本解析为分层设定树（纯JSON）。不得修改原文语义，仅结构化并补充必要元数据。";
    }

    @Override
    public ToolSpecification getSpecification() {
        // 定义节点结构
        JsonObjectSchema nodeSchema = JsonObjectSchema.builder()
            .addProperty("name", JsonStringSchema.builder().description("节点名称，来源于原文关键信息").build())
            .addProperty("type", JsonStringSchema.builder().description("节点类型枚举，如 CHARACTER/LOCATION/ITEM/LORE/... ").build())
            .addProperty("description", JsonStringSchema.builder().description("节点描述，来自原文摘录整理，不得杜撰").build())
            .addProperty("tempId", JsonStringSchema.builder().description("临时ID（例如按路径生成，如 R1、R1-1）").build())
            .addProperty("sourceSpans", JsonArraySchema.builder().description("原文区间 [start,end] 或原文片段").items(JsonStringSchema.builder().build()).build())
            .addProperty("children", JsonArraySchema.builder().description("子节点数组").items(JsonObjectSchema.builder().build()).build())
            .required("name", "type", "description")
            .build();

        JsonObjectSchema parameters = JsonObjectSchema.builder()
            .addProperty("source", JsonStringSchema.builder().description("原始设定文本，建议分批 1-4k 字").build())
            .addProperty("rootName", JsonStringSchema.builder().description("可选：根名称，用于聚合树根").build())
            .addProperty("expectedRoots", JsonArraySchema.builder().description("可选：期望的根节点提示").items(JsonStringSchema.builder().build()).build())
            .addProperty("tree", JsonArraySchema.builder().description("模型返回的设定树数组").items(nodeSchema).build())
            .required("source")
            .build();

        return ToolSpecification.builder()
            .name(getName())
            .description(getDescription())
            .parameters(parameters)
            .build();
    }

    @Override
    public Object execute(Map<String, Object> parameters) {
        // 模型应在调用参数中带上 tree；未带时返回占位空树
        Object tree = parameters.get("tree");
        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("tree", (tree instanceof List<?>) ? tree : List.of());
        return result;
    }
}


