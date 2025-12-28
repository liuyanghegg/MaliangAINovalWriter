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
 * 视频短剧创作策略
 * 专门针对短视频剧本创作的设定生成策略，注重节奏和视觉表现
 */
@Component("short-video-script")
public class ShortVideoScriptStrategy implements SettingGenerationStrategy {
    
    private static final List<ScriptElement> SCRIPT_ELEMENTS = List.of(
        new ScriptElement("开场抓手", "opening_hook", SettingType.EVENT, 
            "前3秒抓住观众注意力的开场设计", 5),
        new ScriptElement("核心冲突", "main_conflict", SettingType.EVENT, 
            "推动剧情发展的主要矛盾冲突", 5),
        new ScriptElement("角色设定", "character_setup", SettingType.CHARACTER, 
            "简洁明确的主要角色设定", 4),
        new ScriptElement("情感爆点", "emotional_climax", SettingType.OTHER, 
            "引起强烈情感反应的高潮设计", 4),
        new ScriptElement("反转设计", "plot_twist", SettingType.EVENT, 
            "出人意料的剧情反转", 4),
        new ScriptElement("视觉表现", "visual_presentation", SettingType.OTHER, 
            "适合短视频的视觉呈现方式", 3),
        new ScriptElement("台词金句", "memorable_lines", SettingType.OTHER, 
            "令人印象深刻的台词和金句", 3),
        new ScriptElement("结尾收束", "ending_closure", SettingType.OTHER, 
            "简洁有力的结尾设计", 4)
    );
    
    private static final List<VideoFormat> VIDEO_FORMATS = List.of(
        new VideoFormat("情感故事", "emotional_story", "以情感共鸣为主的故事类短剧"),
        new VideoFormat("悬疑反转", "suspense_twist", "以悬念和反转为核心的剧情"),
        new VideoFormat("喜剧搞笑", "comedy_humor", "以幽默搞笑为主要卖点"),
        new VideoFormat("励志治愈", "inspirational_healing", "传递正能量的励志内容"),
        new VideoFormat("知识科普", "educational_content", "寓教于乐的知识类内容")
    );
    
    private static final List<DurationCategory> DURATION_CATEGORIES = List.of(
        new DurationCategory("超短剧", "ultra_short", "15-30秒", "极致精炼的内容"),
        new DurationCategory("短剧", "short", "30-60秒", "完整小故事"),
        new DurationCategory("中短剧", "medium_short", "1-3分钟", "相对完整的剧情")
    );
    
    @Override
    public String getStrategyId() {
        return "short-video-script";
    }
    
    @Override
    public String getStrategyName() {
        return "视频短剧";
    }
    
    @Override
    public String getDescription() {
        return "专门针对短视频平台的微短剧创作策略，注重快节奏、强冲突和视觉冲击";
    }
    
    @Override
    public SettingGenerationConfig createDefaultConfig() {
        List<NodeTemplateConfig> nodeTemplates = new ArrayList<>();
        
        // 为每个剧本元素创建节点模板
        for (ScriptElement element : SCRIPT_ELEMENTS) {
            NodeTemplateConfig template = NodeTemplateConfig.builder()
                .id(element.id)
                .name(element.name)
                .type(element.defaultType)
                .description(element.description)
                .isRootTemplate(true)
                .minChildren(element.priority >= 4 ? 2 : 1)
                .maxChildren(element.priority >= 4 ? 5 : 3)
                .minDescriptionLength(30)
                .maxDescriptionLength(element.priority >= 4 ? 100 : 80)
                .priority(element.priority)
                .generationHint(getGenerationHint(element))
                .tags(List.of("短视频", "剧本", element.getCategory()))
                .build();
            nodeTemplates.add(template);
        }
        
        // 添加视频格式模板
        NodeTemplateConfig formatTemplate = NodeTemplateConfig.builder()
            .id("video_format")
            .name("视频类型")
            .type(SettingType.OTHER)
            .description("确定短剧的主要类型和风格定位")
            .isRootTemplate(true)
            .minChildren(1)
            .maxChildren(2)
            .minDescriptionLength(20)
            .maxDescriptionLength(50)
            .priority(5)
            .generationHint("选择最适合的视频类型，影响整体创作方向")
            .tags(List.of("短视频", "类型定位"))
            .build();
        nodeTemplates.add(formatTemplate);
        
        // 添加时长规划模板
        NodeTemplateConfig durationTemplate = NodeTemplateConfig.builder()
            .id("duration_planning")
            .name("时长规划")
            .type(SettingType.OTHER)
            .description("短剧的时长规划和节奏安排")
            .isRootTemplate(true)
            .minChildren(1)
            .maxChildren(3)
            .minDescriptionLength(20)
            .maxDescriptionLength(60)
            .priority(4)
            .generationHint("规划各部分的时长分配，确保节奏合理")
            .tags(List.of("短视频", "节奏规划"))
            .build();
        nodeTemplates.add(durationTemplate);
        
        GenerationRules rules = GenerationRules.builder()
            .preferredBatchSize(10)
            .maxBatchSize(15)
            .minDescriptionLength(30)
            .maxDescriptionLength(250)
            .requireInterConnections(true)
            .allowDynamicStructure(true)
            .build();
        
        StrategyMetadata metadata = StrategyMetadata.builder()
            .categories(List.of("视频创作", "短剧剧本"))
            .tags(List.of("短视频", "微短剧", "剧本创作", "视觉叙事"))
            .applicableGenres(List.of("情感故事", "悬疑反转", "喜剧搞笑", "励志治愈", "知识科普"))
            .difficultyLevel(3)
            .estimatedGenerationTime(15)
            .build();
        
        return SettingGenerationConfig.builder()
            .strategyName(getStrategyName())
            .description(getDescription())
            .nodeTemplates(nodeTemplates)
            .rules(rules)
            .metadata(metadata)
            .expectedRootNodes(10) // 8个剧本元素 + 视频类型 + 时长规划
            .maxDepth(3)
            .isSystemStrategy(true)
            .build();
    }
    
    @Override
    public ValidationResult validateConfig(SettingGenerationConfig config) {
        if (config == null) {
            return ValidationResult.failure("配置不能为空");
        }
        
        if (config.getNodeTemplates().size() < 6) {
            return ValidationResult.failure("视频短剧策略至少需要包含6个核心元素模板");
        }
        
        // 验证必须包含的核心元素
        List<String> requiredElements = List.of("开场抓手", "核心冲突", "角色设定", "结尾收束");
        List<String> configElements = config.getNodeTemplates().stream()
            .map(NodeTemplateConfig::getName)
            .toList();
        
        for (String required : requiredElements) {
            if (!configElements.contains(required)) {
                return ValidationResult.failure("缺少短剧创作必需元素：" + required);
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
            // 为根节点添加短剧特定的元数据
            if (node.getParentId() == null) {
                SCRIPT_ELEMENTS.stream()
                    .filter(element -> element.name.equals(node.getName()))
                    .findFirst()
                    .ifPresent(element -> {
                        node.getStrategyMetadata().put("elementType", element.id);
                        node.getStrategyMetadata().put("priority", element.priority);
                        node.getStrategyMetadata().put("category", element.getCategory());
                        
                        // 为关键元素添加额外标记
                        if (element.priority >= 4) {
                            node.getStrategyMetadata().put("isCoreElement", true);
                        }
                        if (element.name.contains("开场") || element.name.contains("结尾")) {
                            node.getStrategyMetadata().put("isStructuralElement", true);
                        }
                        if (element.name.contains("冲突") || element.name.contains("反转")) {
                            node.getStrategyMetadata().put("isDramaticElement", true);
                        }
                    });
                    
                // 处理特殊节点
                if ("视频类型".equals(node.getName())) {
                    node.getStrategyMetadata().put("elementType", "video_format");
                    node.getStrategyMetadata().put("isMetaElement", true);
                }
                if ("时长规划".equals(node.getName())) {
                    node.getStrategyMetadata().put("elementType", "duration_planning");
                    node.getStrategyMetadata().put("isStructuralElement", true);
                }
            }
            return node;
        });
    }
    
    @Override
    public List<String> getSupportedNodeTypes() {
        return SCRIPT_ELEMENTS.stream()
            .map(element -> element.defaultType.toString())
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
    
    private String getGenerationHint(ScriptElement element) {
        return switch (element.id) {
            case "opening_hook" -> "设计前3秒的强力开场，可用悬念、冲突或视觉冲击";
            case "main_conflict" -> "设置明确的主要冲突，推动剧情快速发展";
            case "character_setup" -> "简洁设定主要角色，突出关键特征";
            case "emotional_climax" -> "设计情感爆点，引起观众强烈共鸣";
            case "plot_twist" -> "安排意外反转，增加记忆点和传播性";
            case "visual_presentation" -> "考虑视觉呈现效果，适合短视频平台";
            case "memorable_lines" -> "设计朗朗上口的台词金句";
            case "ending_closure" -> "简洁有力的结尾，留下深刻印象";
            default -> "详细描述该元素的具体内容和视觉效果";
        };
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
    
    private record ScriptElement(String name, String id, SettingType defaultType, String description, int priority) {
        public String getCategory() {
            return switch (id) {
                case "opening_hook", "ending_closure" -> "结构框架";
                case "main_conflict", "plot_twist" -> "剧情推进";
                case "character_setup", "emotional_climax" -> "角色情感";
                case "visual_presentation", "memorable_lines" -> "表现形式";
                default -> "其他";
            };
        }
    }
    
    private record VideoFormat(String name, String id, String description) {}
    private record DurationCategory(String name, String id, String duration, String description) {}
}