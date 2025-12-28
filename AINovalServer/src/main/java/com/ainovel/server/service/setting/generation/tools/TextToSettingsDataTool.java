package com.ainovel.server.service.setting.generation.tools;

import com.ainovel.server.service.ai.tools.ToolDefinition;
import dev.langchain4j.agent.tool.ToolSpecification;
import dev.langchain4j.model.chat.request.json.JsonArraySchema;
import dev.langchain4j.model.chat.request.json.JsonObjectSchema;
import dev.langchain4j.model.chat.request.json.JsonStringSchema;
import dev.langchain4j.model.chat.request.json.JsonBooleanSchema;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 纯数据工具：将文本解析为设定数据（JSON结构），不修改任何会话/数据库。
 * 输出为通用JSON对象，业务层可直接消费。
 */
public class TextToSettingsDataTool implements ToolDefinition {

    @Override
    public String getName() {
        return "text_to_settings";
    }

    @Override
    public String getDescription() {
        return "将输入的设定文本解析为结构化设定数据（纯JSON，不落库不改会话）。";
    }

    @Override
    public ToolSpecification getSpecification() {
        // 对齐 BatchCreateNodesTool：要求直接产出可创建的节点列表
        JsonObjectSchema nodeSchema = JsonObjectSchema.builder()
            .addProperty("id", JsonStringSchema.builder()
                .description("节点ID，可选；提供则更新该节点，否则由后端生成新ID")
                .build())
            .addProperty("name", JsonStringSchema.builder()
                .description("设定名称")
                .build())
            .addProperty("type", JsonStringSchema.builder()
                .description("设定类型（使用与批量创建一致的枚举，例如：CHARACTER、LOCATION、ITEM、LORE、FACTION、EVENT、CONCEPT、CREATURE、MAGIC_SYSTEM、TECHNOLOGY、CULTURE、HISTORY、ORGANIZATION、WORLDVIEW、PLEASURE_POINT、ANTICIPATION_HOOK、THEME、TONE、STYLE、TROPE、PLOT_DEVICE、POWER_SYSTEM、GOLDEN_FINGER、TIMELINE、RELIGION、POLITICS、ECONOMY、GEOGRAPHY、OTHER")
                .build())
            .addProperty("description", JsonStringSchema.builder()
                .description("设定的详细描述，叶子节点建议100-200字，具体生动；父子设定需相互关联，避免占位符文本")
                .build())
            .addProperty("parentId", JsonStringSchema.builder()
                .description("父节点ID；根节点为null。允许使用tempId在同批次内引用父节点")
                .build())
            .addProperty("tempId", JsonStringSchema.builder()
                .description("临时ID，用于在本批次中建立父子关系。如 '1','1-1' 等；后端将映射为真实ID")
                .build())
            .addProperty("attributes", JsonObjectSchema.builder()
                .description("可选：额外属性，JSON对象")
                .build())
            .build();

        JsonObjectSchema parameters = JsonObjectSchema.builder()
            .addProperty("nodes", JsonArraySchema.builder()
                .items(nodeSchema)
                .description("要创建/更新的设定节点列表；建议每批10-20条")
                .build())
            .addProperty("complete", JsonBooleanSchema.builder()
                .description("可选：若为true，表示本批完成，可结束本轮工具调用")
                .build())
            .required("nodes")
            .build();

        return ToolSpecification.builder()
            .name(getName())
            .description(getDescription())
            .parameters(parameters)
            .build();
    }

    @Override
    public Object execute(Map<String, Object> parameters) {
        // 纯数据工具：不落库，仅回显 nodes；若缺失则返回空列表占位
        Object nodes = parameters.get("nodes");
        if (nodes instanceof List<?> || nodes instanceof Map<?, ?>) {
            Map<String, Object> ok = new HashMap<>();
            ok.put("success", true);
            ok.put("nodes", nodes);
            // 透传complete标志，便于上游决定是否结束循环
            Object complete = parameters.get("complete");
            if (complete instanceof Boolean) ok.put("complete", complete);
            return ok;
        }
        Map<String, Object> fallback = new HashMap<>();
        fallback.put("success", true);
        fallback.put("message", "Model should provide 'nodes' array. Returning empty list as fallback.");
        fallback.put("nodes", List.of());
        return fallback;
    }
}


