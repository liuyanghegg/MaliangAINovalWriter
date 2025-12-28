package com.ainovel.server.service.setting.generation.tools;

import com.ainovel.server.domain.model.SettingType;
import com.ainovel.server.domain.model.setting.generation.SettingNode;
import com.ainovel.server.service.ai.tools.ToolDefinition;
import dev.langchain4j.agent.tool.ToolSpecification;
import dev.langchain4j.model.chat.request.json.JsonObjectSchema;
import dev.langchain4j.model.chat.request.json.JsonBooleanSchema;
import dev.langchain4j.model.chat.request.json.JsonStringSchema;
import lombok.extern.slf4j.Slf4j;

import java.util.*;

/**
 * 创建设定节点工具
 */
@Slf4j
public class CreateSettingNodeTool implements ToolDefinition {
    
    private final SettingNodeHandler handler;
    
    public CreateSettingNodeTool(SettingNodeHandler handler) {
        this.handler = handler;
    }
    
    @Override
    public String getName() {
        return "create_setting_node";
    }
    
    @Override
    public String getDescription() {
        return "创建单个设定节点。辅助工具。优先使用 `create_setting_nodes` 批量创建；仅在需要单独处理特殊设定或补充个别设定时使用。";
    }
    
    @Override
    public ToolSpecification getSpecification() {
        JsonObjectSchema parameters = JsonObjectSchema.builder()
            .addProperty("id", JsonStringSchema.builder()
                .description("节点ID，可选。如果提供则使用指定ID（用于修改现有节点），否则自动生成新UUID")
                .build())
            .addProperty("name", JsonStringSchema.builder()
                .description("设定名称")
                .build())
            .addProperty("type", JsonStringSchema.builder()
                .description("设定类型（必须使用以下枚举之一）：CHARACTER、LOCATION、ITEM、LORE、FACTION、EVENT、CONCEPT、CREATURE、MAGIC_SYSTEM、TECHNOLOGY、CULTURE、HISTORY、ORGANIZATION、WORLDVIEW、PLEASURE_POINT、ANTICIPATION_HOOK、THEME、TONE、STYLE、TROPE、PLOT_DEVICE、POWER_SYSTEM、GOLDEN_FINGER、TIMELINE、RELIGION、POLITICS、ECONOMY、GEOGRAPHY、OTHER")
                .build())
            .addProperty("description", JsonStringSchema.builder()
                .description("设定的详细描述，叶子节点的字数要求100-200字，要求具体生动，父子设定要相互关联，避免简短或占位符文本")
                .build())
            .addProperty("parentId", JsonStringSchema.builder()
                .description("父节点ID，如果是根节点则为null")
                .build())
            .addProperty("attributes", JsonObjectSchema.builder()
                .description("额外属性，JSON格式")
                .build())
            .addProperty("complete", JsonBooleanSchema.builder()
                .description("可选：若为true，表示本次创建完成后无需进一步调用，服务端将结束本轮生成循环以节省token")
                .build())
            .required("name", "type", "description")
            .build();
        
        return ToolSpecification.builder()
            .name(getName())
            .description(getDescription())
            .parameters(parameters)
            .build();
    }

    @Override
    @SuppressWarnings("unchecked")
    public Object execute(Map<String, Object> parameters) {
        String providedId = (String) parameters.get("id");
        String name = (String) parameters.get("name");
        String type = (String) parameters.get("type");
        String description = (String) parameters.get("description");
        String parentId = (String) parameters.get("parentId");
        Map<String, Object> attributes = (Map<String, Object>) parameters.getOrDefault("attributes", new HashMap<>());
        
        // 🔧 支持指定ID：如果提供了ID则使用，否则生成新UUID
        String nodeId = (providedId != null && !providedId.trim().isEmpty()) 
                        ? providedId.trim() 
                        : UUID.randomUUID().toString();
        
        SettingNode node = SettingNode.builder()
            .id(nodeId)
            .parentId(parentId)
            .name(name)
            .type(SettingType.fromValue(type))
            .description(description)
            .attributes(attributes)
            .generationStatus(SettingNode.GenerationStatus.COMPLETED)
            .build();
        
        // 调用处理器
        boolean success = handler.handleNodeCreation(node);
        
        // 返回结果
        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("nodeId", nodeId);
        result.put("message", success ? 
            (providedId != null ? "Node updated successfully" : "Node created successfully") : 
            "Failed to create node");
        
        log.info("{} setting node: {} ({})", 
            providedId != null ? "Updated" : "Created", name, nodeId);
        return result;
    }
    
    @Override
    public ValidationResult validateParameters(Map<String, Object> parameters) {
        if (parameters.get("name") == null || parameters.get("name").toString().trim().isEmpty()) {
            return ValidationResult.failure("Name is required");
        }
        
        if (parameters.get("type") == null) {
            return ValidationResult.failure("Type is required");
        }
        
        // 类型容错：将未知类型映射为 OTHER，避免因大小写或同义词导致报错
        SettingType.fromValue(parameters.get("type").toString());
        
        if (parameters.get("description") == null || parameters.get("description").toString().trim().isEmpty()) {
            return ValidationResult.failure("Description is required");
        }
        
        return ValidationResult.success();
    }
    
    /**
     * 设定节点处理器接口
     */
    public interface SettingNodeHandler {
        boolean handleNodeCreation(SettingNode node);
    }
}