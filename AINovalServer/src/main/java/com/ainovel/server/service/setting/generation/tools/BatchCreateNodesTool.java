package com.ainovel.server.service.setting.generation.tools;

import com.ainovel.server.domain.model.SettingType;
import com.ainovel.server.domain.model.setting.generation.SettingNode;
import com.ainovel.server.service.ai.tools.ToolDefinition;
import dev.langchain4j.agent.tool.ToolSpecification;
import dev.langchain4j.model.chat.request.json.JsonObjectSchema;
import dev.langchain4j.model.chat.request.json.JsonArraySchema;
import dev.langchain4j.model.chat.request.json.JsonBooleanSchema;
import dev.langchain4j.model.chat.request.json.JsonStringSchema;


import lombok.extern.slf4j.Slf4j;

import java.util.*;

/**
 * 批量创建节点工具
 */
@Slf4j
public class BatchCreateNodesTool implements ToolDefinition {
    
    private final CreateSettingNodeTool.SettingNodeHandler handler;
    // 改为通过调用方注入的上下文级临时ID映射，避免全局污染
    private final java.util.Map<String, String> crossBatchTempIdMap;
    
    public BatchCreateNodesTool(CreateSettingNodeTool.SettingNodeHandler handler, java.util.Map<String, String> crossBatchTempIdMap) {
        this.handler = handler;
        this.crossBatchTempIdMap = (crossBatchTempIdMap != null) ? crossBatchTempIdMap : new java.util.concurrent.ConcurrentHashMap<>();
    }
    
    @Override
    public String getName() {
        return "create_setting_nodes";
    }
    
    @Override
    public String getDescription() {
        return "批量创建多个设定节点。首选方式，用于一次性创建多个相关设定项，大幅提升效率。强烈建议使用此工具而非 `create_setting_node`。";
    }
    
    @Override
    public ToolSpecification getSpecification() {
        // 定义单个节点的schema
        JsonObjectSchema nodeSchema = JsonObjectSchema.builder()
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
                .description("设定的详细描述，叶子节点的字数要求100-200字，要求具体生动，，父子设定要相互关联，避免简短或占位符文本")
                .build())
            .addProperty("parentId", JsonStringSchema.builder()
                .description("父节点ID，如果是根节点则为null。可以使用tempId引用同批次创建的其他节点")
                .build())
            .addProperty("tempId", JsonStringSchema.builder()
                .description("临时ID，用于在同批次中建立父子关系。推荐使用简洁数字格式，例如：'1','2','3'或'1-1','1-2','1-3'等，后端会自动生成真实UUID")
                .build())
            .addProperty("attributes", JsonObjectSchema.builder()
                .description("额外属性，JSON格式，用于存储特定类型的详细信息")
                .build())
            .required("name", "type", "description")
            .build();
        
        // 定义参数schema
        JsonObjectSchema parameters = JsonObjectSchema.builder()
            .addProperty("nodes", JsonArraySchema.builder()
                .items(nodeSchema)
                .description("要创建的节点列表。推荐一次创建10-20个节点以提高效率。每个节点包含name、type、description、parentId、tempId、attributes字段")
                .build())
            .addProperty("complete", JsonBooleanSchema.builder()
                .description("可选：若为true，表示本次批量创建完成后无需进一步调用，服务端将结束本轮生成循环以节省token")
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
    @SuppressWarnings("unchecked")
    public Object execute(Map<String, Object> parameters) {
        List<Map<String, Object>> nodeList = (List<Map<String, Object>>) parameters.get("nodes");
        if (nodeList == null || nodeList.isEmpty()) {
            // 尝试兼容旧格式：直接传递单节点字段
            if (parameters.containsKey("name") && parameters.containsKey("type") && parameters.containsKey("description")) {
                nodeList = new java.util.ArrayList<>();
                nodeList.add(new java.util.HashMap<>(parameters));
                log.warn("create_setting_nodes 接收到旧格式参数，已自动转换为单节点列表。建议改用 'nodes' 数组格式。");
            } else {
                return createErrorResult("No nodes provided");
            }
        }
        
        Map<String, String> tempIdToRealId = new HashMap<>();
        List<String> createdNodeIds = new ArrayList<>();
        List<String> errors = new ArrayList<>();
        
        for (Map<String, Object> nodeData : nodeList) {
            try {
                // 解析节点数据
                String providedId = (String) nodeData.get("id");
                String name = (String) nodeData.get("name");
                String type = (String) nodeData.get("type");
                String description = (String) nodeData.get("description");
                String parentId = (String) nodeData.get("parentId");
                String tempId = (String) nodeData.get("tempId");
                Map<String, Object> attributes = (Map<String, Object>) nodeData.getOrDefault("attributes", new HashMap<>());
                
                // 处理临时ID映射
                // 1) 先在本批次的临时映射中查找
                if (parentId != null && tempIdToRealId.containsKey(parentId)) {
                    parentId = tempIdToRealId.get(parentId);
                } else if (parentId != null && crossBatchTempIdMap.containsKey(parentId)) {
                    // 2) 如果本批次没有，再回退到上下文级映射
                    parentId = crossBatchTempIdMap.get(parentId);
                }
                
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
                
                // 处理节点
                boolean success = handler.handleNodeCreation(node);
                if (success) {
                    createdNodeIds.add(nodeId);
                    if (tempId != null) {
                        tempIdToRealId.put(tempId, nodeId);
                        // 同时写入上下文级映射，以便后续批次解析
                        crossBatchTempIdMap.put(tempId, nodeId);
                    }
                } else {
                    errors.add(String.format("Failed to create node: %s", name));
                }
                
            } catch (Exception e) {
                errors.add(String.format("Error creating node: %s", e.getMessage()));
                log.error("Failed to create node in batch", e);
            }
        }
        
        // 构建结果
        Map<String, Object> result = new HashMap<>();
        result.put("success", errors.isEmpty());
        result.put("createdNodeIds", createdNodeIds);
        result.put("nodeIdMapping", tempIdToRealId);
        result.put("totalCreated", createdNodeIds.size());
        
        if (!errors.isEmpty()) {
            result.put("errors", errors);
        }
        
        log.info("Batch created {} nodes", createdNodeIds.size());
        return result;
    }
    
    private Map<String, Object> createErrorResult(String message) {
        Map<String, Object> result = new HashMap<>();
        result.put("success", false);
        result.put("message", message);
        result.put("createdNodeIds", Collections.emptyList());
        return result;
    }
}