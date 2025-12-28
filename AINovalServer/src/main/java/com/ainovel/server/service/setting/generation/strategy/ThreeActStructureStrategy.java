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
 * 三幕剧结构设定生成策略
 * 基于经典的三幕剧结构理论构建故事设定
 */
@Component("three-act-structure")
public class ThreeActStructureStrategy implements SettingGenerationStrategy {
    
    private static final List<ActDefinition> THREE_ACTS = List.of(
        new ActDefinition("第一幕：建立", "setup", SettingType.OTHER, 
            "建立故事世界、介绍主要角色、提出核心冲突", 25),
        new ActDefinition("第二幕：对抗", "confrontation", SettingType.OTHER, 
            "发展冲突、角色成长、面临挫折和挑战", 50),
        new ActDefinition("第三幕：解决", "resolution", SettingType.OTHER, 
            "故事高潮、冲突解决、角色命运归宿", 25)
    );
    
    private static final List<ElementDefinition> STORY_ELEMENTS = List.of(
        new ElementDefinition("主角设定", "protagonist", SettingType.CHARACTER, 
            "故事的主要角色，推动情节发展的核心人物"),
        new ElementDefinition("冲突核心", "conflict", SettingType.EVENT, 
            "驱动整个故事的主要矛盾和冲突"),
        new ElementDefinition("故事世界", "world", SettingType.OTHER, 
            "故事发生的背景环境和世界设定"),
        new ElementDefinition("主题表达", "theme", SettingType.OTHER, 
            "故事要传达的核心思想和价值观"),
        new ElementDefinition("情节转折", "plot_points", SettingType.EVENT, 
            "推动故事发展的关键情节点")
    );
    
    @Override
    public String getStrategyId() {
        return "three-act-structure";
    }
    
    @Override
    public String getStrategyName() {
        return "三幕剧结构";
    }
    
    @Override
    public String getDescription() {
        return "基于经典的三幕剧结构理论，系统化地构建故事的核心设定，适用于各类戏剧和影视创作";
    }
    
    @Override
    public SettingGenerationConfig createDefaultConfig() {
        List<NodeTemplateConfig> nodeTemplates = new ArrayList<>();
        
        // 添加三幕结构根节点
        for (ActDefinition act : THREE_ACTS) {
            NodeTemplateConfig actTemplate = NodeTemplateConfig.builder()
                .id(act.id)
                .name(act.name)
                .type(act.defaultType)
                .description(act.description)
                .isRootTemplate(true)
                .minChildren(3)
                .maxChildren(8)
                .minDescriptionLength(80)
                .maxDescriptionLength(150)
                .priority(act.name.contains("第一幕") ? 3 : act.name.contains("第二幕") ? 2 : 1)
                .generationHint("重点描述该幕次的核心任务和主要情节发展，占全剧约" + act.percentage + "%的篇幅")
                .tags(List.of("三幕剧", "戏剧结构", act.id))
                .build();
            nodeTemplates.add(actTemplate);
        }
        
        // 添加核心故事元素节点模板
        for (ElementDefinition element : STORY_ELEMENTS) {
            NodeTemplateConfig elementTemplate = NodeTemplateConfig.builder()
                .id(element.id)
                .name(element.name)
                .type(element.defaultType)
                .description(element.description)
                .isRootTemplate(true)
                .minChildren(2)
                .maxChildren(6)
                .minDescriptionLength(60)
                .maxDescriptionLength(120)
                .priority(element.name.equals("主角设定") ? 5 : 
                         element.name.equals("冲突核心") ? 4 : 2)
                .generationHint("详细描述" + element.name + "的关键特征和作用")
                .tags(List.of("故事元素", element.id))
                .build();
            nodeTemplates.add(elementTemplate);
        }
        
        GenerationRules rules = GenerationRules.builder()
            .preferredBatchSize(8)
            .maxBatchSize(15)
            .minDescriptionLength(60)
            .maxDescriptionLength(400)
            .requireInterConnections(true)
            .allowDynamicStructure(true)
            .build();
        
        StrategyMetadata metadata = StrategyMetadata.builder()
            .categories(List.of("戏剧创作", "故事结构"))
            .tags(List.of("三幕剧", "戏剧", "故事结构", "经典理论"))
            .applicableGenres(List.of("戏剧", "电影", "电视剧", "话剧", "舞台剧"))
            .difficultyLevel(2)
            .estimatedGenerationTime(12)
            .build();
        
        return SettingGenerationConfig.builder()
            .strategyName(getStrategyName())
            .description(getDescription())
            .nodeTemplates(nodeTemplates)
            .rules(rules)
            .metadata(metadata)
            .expectedRootNodes(8) // 3个幕次 + 5个核心元素
            .maxDepth(3)
            .isSystemStrategy(true)
            .build();
    }
    
    @Override
    public ValidationResult validateConfig(SettingGenerationConfig config) {
        if (config == null) {
            return ValidationResult.failure("配置不能为空");
        }
        
        if (config.getNodeTemplates().size() < 3) {
            return ValidationResult.failure("三幕剧策略至少需要包含3个幕次模板");
        }
        
        // 验证是否包含三个基本幕次
        List<String> requiredActs = THREE_ACTS.stream()
            .map(act -> act.name)
            .toList();
        
        List<String> configActs = config.getNodeTemplates().stream()
            .map(NodeTemplateConfig::getName)
            .filter(name -> name.contains("第") && name.contains("幕"))
            .toList();
        
        for (String requiredAct : requiredActs) {
            if (!configActs.contains(requiredAct)) {
                return ValidationResult.failure("缺少必需的幕次：" + requiredAct);
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
            // 为根节点添加三幕剧特定的元数据
            if (node.getParentId() == null) {
                THREE_ACTS.stream()
                    .filter(act -> act.name.equals(node.getName()))
                    .findFirst()
                    .ifPresent(act -> {
                        node.getStrategyMetadata().put("actType", act.id);
                        node.getStrategyMetadata().put("percentage", act.percentage);
                        node.getStrategyMetadata().put("structureLevel", "act");
                    });
                    
                STORY_ELEMENTS.stream()
                    .filter(element -> element.name.equals(node.getName()))
                    .findFirst()
                    .ifPresent(element -> {
                        node.getStrategyMetadata().put("elementType", element.id);
                        node.getStrategyMetadata().put("structureLevel", "element");
                    });
            }
            return node;
        });
    }
    
    @Override
    public List<String> getSupportedNodeTypes() {
        List<String> types = new ArrayList<>();
        types.addAll(THREE_ACTS.stream().map(act -> act.defaultType.toString()).toList());
        types.addAll(STORY_ELEMENTS.stream().map(element -> element.defaultType.toString()).toList());
        return types.stream().distinct().toList();
    }
    
    @Override
    public boolean supportsInheritance() {
        return true;
    }
    
    @Override
    public SettingGenerationConfig createInheritedConfig(SettingGenerationConfig baseConfig, 
                                                       Map<String, Object> modifications) {
        return SettingGenerationConfig.builder()
            .strategyName((String) modifications.getOrDefault("strategyName", baseConfig.getStrategyName()))
            .description((String) modifications.getOrDefault("description", baseConfig.getDescription()))
            .nodeTemplates(new ArrayList<>(baseConfig.getNodeTemplates()))
            .rules(baseConfig.getRules())
            .metadata(baseConfig.getMetadata())
            .expectedRootNodes(baseConfig.getExpectedRootNodes())
            .maxDepth(baseConfig.getMaxDepth())
            .isSystemStrategy(false)
            .build();
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
    
    private record ActDefinition(String name, String id, SettingType defaultType, String description, int percentage) {}
    private record ElementDefinition(String name, String id, SettingType defaultType, String description) {}
}