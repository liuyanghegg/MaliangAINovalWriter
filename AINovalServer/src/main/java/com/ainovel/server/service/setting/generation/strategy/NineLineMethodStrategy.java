package com.ainovel.server.service.setting.generation.strategy;

import com.ainovel.server.domain.model.SettingType;
import com.ainovel.server.domain.model.setting.generation.SettingGenerationSession;
import com.ainovel.server.domain.model.setting.generation.SettingNode;
import com.ainovel.server.domain.model.settinggeneration.SettingGenerationConfig;
import com.ainovel.server.domain.model.settinggeneration.NodeTemplateConfig;
import com.ainovel.server.domain.model.settinggeneration.GenerationRules;
import com.ainovel.server.domain.model.settinggeneration.StrategyMetadata;
import com.ainovel.server.service.setting.generation.SettingGenerationStrategy;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;
import java.util.ArrayList;

/**
 * 九线法设定生成策略
 * 解耦后的九线法策略，专注于核心配置和验证逻辑
 */
@Component("nine-line-method")
public class NineLineMethodStrategy implements SettingGenerationStrategy {
    
    private static final List<LineDefinition> NINE_LINES = List.of(
        new LineDefinition("人物线", SettingType.CHARACTER, 
            "主要角色及其关系网络，包括主角、配角、反派等"),
        new LineDefinition("情感线", SettingType.OTHER, 
            "角色之间的情感纠葛，爱恨情仇的发展脉络"),
        new LineDefinition("事件线", SettingType.EVENT, 
            "推动剧情发展的关键事件和冲突"),
        new LineDefinition("悬念线", SettingType.OTHER, 
            "吸引读者的悬念设置和伏笔"),
        new LineDefinition("金手指线", SettingType.ITEM, 
            "主角的特殊能力、系统或独特优势"),
        new LineDefinition("世界观线", SettingType.OTHER, 
            "小说世界的基本设定和运行规则"),
        new LineDefinition("成长线", SettingType.OTHER, 
            "主角的成长轨迹和能力提升体系"),
        new LineDefinition("势力线", SettingType.FACTION, 
            "各方势力的构成、目标和相互关系"),
        new LineDefinition("主题线", SettingType.OTHER, 
            "小说要表达的核心思想和价值观")
    );
    
    @Override
    public String getStrategyId() {
        return "nine-line-method";
    }
    
    @Override
    public String getStrategyName() {
        return "九线法";
    }
    
    @Override
    public String getDescription() {
        return "基于网文创作九线法理论，系统化地构建小说的核心设定";
    }
    
    @Override
    public SettingGenerationConfig createDefaultConfig() {
        // 创建节点模板
        List<NodeTemplateConfig> nodeTemplates = new ArrayList<>();
        for (LineDefinition line : NINE_LINES) {
            NodeTemplateConfig template = NodeTemplateConfig.builder()
                .id(line.name.toLowerCase().replace("线", "_line"))
                .name(line.name)
                .type(line.defaultType)
                .description(line.description)
                .isRootTemplate(true)
                .minChildren(2)
                .maxChildren(10)
                .minDescriptionLength(50)
                .maxDescriptionLength(80)
                .build();
            nodeTemplates.add(template);
        }
        
        // 创建生成规则
        GenerationRules rules = GenerationRules.builder()
            .preferredBatchSize(10)
            .maxBatchSize(20)
            .minDescriptionLength(50)
            .maxDescriptionLength(500)
            .requireInterConnections(true)
            .allowDynamicStructure(true)
            .build();
        
        // 创建元数据
        StrategyMetadata metadata = StrategyMetadata.builder()
            .categories(List.of("网文创作", "结构化设定"))
            .tags(List.of("九线法", "网文", "系统化"))
            .applicableGenres(List.of("玄幻", "都市", "科幻", "历史", "军事"))
            .difficultyLevel(3)
            .estimatedGenerationTime(15)
            .build();
        
        return SettingGenerationConfig.builder()
            .strategyName(getStrategyName())
            .description(getDescription())
            .nodeTemplates(nodeTemplates)
            .rules(rules)
            .metadata(metadata)
            .expectedRootNodes(9)
            .maxDepth(4)
            .isSystemStrategy(true)
            .build();
    }
    
    @Override
    public ValidationResult validateConfig(SettingGenerationConfig config) {
        if (config == null) {
            return ValidationResult.failure("配置不能为空");
        }
        
        if (config.getNodeTemplates().size() != 9) {
            return ValidationResult.failure("九线法策略必须包含9个根节点模板");
        }
        
        // 验证是否包含所有九线
        List<String> requiredLines = NINE_LINES.stream()
            .map(line -> line.name)
            .toList();
        
        List<String> configLines = config.getNodeTemplates().stream()
            .map(NodeTemplateConfig::getName)
            .toList();
        
        for (String requiredLine : requiredLines) {
            if (!configLines.contains(requiredLine)) {
                return ValidationResult.failure("缺少必需的线：" + requiredLine);
            }
        }
        
        return ValidationResult.success();
    }
    
    @Override
    public ValidationResult validateNode(SettingNode node, SettingGenerationConfig config, SettingGenerationSession session) {
        // 验证节点深度
        int depth = calculateNodeDepth(node, session);
        if (depth > config.getMaxDepth()) {
            return ValidationResult.failure(
                "节点深度超过限制，最大深度为" + config.getMaxDepth());
        }
        
        return ValidationResult.success();
    }
    
    @Override
    public Flux<SettingNode> postProcessNodes(Flux<SettingNode> nodes, SettingGenerationConfig config, SettingGenerationSession session) {
        return nodes.map(node -> {
            // 为根节点添加九线法特定的元数据
            if (node.getParentId() == null) {
                NINE_LINES.stream()
                    .filter(line -> line.name.equals(node.getName()))
                    .findFirst()
                    .ifPresent(line -> {
                        node.getStrategyMetadata().put("lineType", line.name);
                        node.getStrategyMetadata().put("defaultType", line.defaultType.toString());
                    });
            }
            return node;
        });
    }
    
    @Override
    public List<String> getSupportedNodeTypes() {
        return NINE_LINES.stream()
            .map(line -> line.defaultType.toString())
            .distinct()
            .toList();
    }
    
    @Override
    public boolean supportsInheritance() {
        return true;
    }
    
    @Override
    public SettingGenerationConfig createInheritedConfig(SettingGenerationConfig baseConfig, 
                                                       Map<String, Object> modifications) {
        // 克隆基础配置
        SettingGenerationConfig inheritedConfig = SettingGenerationConfig.builder()
            .strategyName((String) modifications.getOrDefault("strategyName", baseConfig.getStrategyName()))
            .description((String) modifications.getOrDefault("description", baseConfig.getDescription()))
            .nodeTemplates(new ArrayList<>(baseConfig.getNodeTemplates()))
            .rules(baseConfig.getRules())
            .metadata(baseConfig.getMetadata())
            .expectedRootNodes(baseConfig.getExpectedRootNodes())
            .maxDepth(baseConfig.getMaxDepth())
            .isSystemStrategy(false) // 继承的配置不是系统策略
            .build();
        
        // 应用修改
        applyModifications(inheritedConfig, modifications);
        
        return inheritedConfig;
    }
    
    private void applyModifications(SettingGenerationConfig config, Map<String, Object> modifications) {
        // 应用节点模板修改
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> nodeModifications = (List<Map<String, Object>>) modifications.get("nodeTemplates");
        if (nodeModifications != null) {
            // 应用节点模板的修改逻辑
            for (Map<String, Object> nodeMod : nodeModifications) {
                String nodeId = (String) nodeMod.get("id");
                String action = (String) nodeMod.get("action");
                
                if ("add".equals(action)) {
                    // 添加新节点模板
                    NodeTemplateConfig newTemplate = buildNodeTemplateFromMap(nodeMod);
                    config.getNodeTemplates().add(newTemplate);
                } else if ("modify".equals(action)) {
                    // 修改现有节点模板
                    config.getNodeTemplates().stream()
                        .filter(template -> nodeId.equals(template.getId()))
                        .findFirst()
                        .ifPresent(template -> modifyNodeTemplate(template, nodeMod));
                } else if ("remove".equals(action)) {
                    // 移除节点模板
                    config.getNodeTemplates().removeIf(template -> nodeId.equals(template.getId()));
                }
            }
        }
    }
    
    private NodeTemplateConfig buildNodeTemplateFromMap(Map<String, Object> nodeMap) {
        return NodeTemplateConfig.builder()
            .id((String) nodeMap.get("id"))
            .name((String) nodeMap.get("name"))
            .type(SettingType.fromValue((String) nodeMap.get("type")))
            .description((String) nodeMap.get("description"))
            .isRootTemplate((Boolean) nodeMap.getOrDefault("isRootTemplate", false))
            .minChildren((Integer) nodeMap.getOrDefault("minChildren", 0))
            .maxChildren((Integer) nodeMap.getOrDefault("maxChildren", -1))
            .minDescriptionLength((Integer) nodeMap.getOrDefault("minDescriptionLength", 50))
            .maxDescriptionLength((Integer) nodeMap.getOrDefault("maxDescriptionLength", 500))
            .build();
    }
    
    private void modifyNodeTemplate(NodeTemplateConfig template, Map<String, Object> modifications) {
        if (modifications.containsKey("name")) {
            template.setName((String) modifications.get("name"));
        }
        if (modifications.containsKey("description")) {
            template.setDescription((String) modifications.get("description"));
        }
        if (modifications.containsKey("minChildren")) {
            template.setMinChildren((Integer) modifications.get("minChildren"));
        }
        if (modifications.containsKey("maxChildren")) {
            template.setMaxChildren((Integer) modifications.get("maxChildren"));
        }
        // 可以继续添加其他字段的修改逻辑
    }
    
    private int calculateNodeDepth(SettingNode node, SettingGenerationSession session) {
        int depth = 0;
        String parentId = node.getParentId();
        while (parentId != null) {
            depth++;
            SettingNode parent = session.getGeneratedNodes().get(parentId);
            if (parent == null) break;
            parentId = parent.getParentId();
        }
        return depth;
    }
    
    private record LineDefinition(String name, SettingType defaultType, String description) {}
}