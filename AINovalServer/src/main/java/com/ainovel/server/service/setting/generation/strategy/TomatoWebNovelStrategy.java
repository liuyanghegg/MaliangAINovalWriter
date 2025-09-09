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
 * 番茄小说网文设定生成策略
 * 专门针对网络小说创作的设定生成策略，注重爽点和节奏
 */
@Component("tomato-web-novel")
public class TomatoWebNovelStrategy implements SettingGenerationStrategy {
    
    private static final List<WebNovelElement> WEB_NOVEL_ELEMENTS = List.of(
        // 核心骨架
        new WebNovelElement("核心卖点", "core_selling_point", SettingType.THEME,
            "一句话高度概括本书的最大吸引力，呈现独到的爆点与读者利益点", 5),
        new WebNovelElement("主角设定", "protagonist_setting", SettingType.CHARACTER, 
            "主角的身份背景、性格与标签、初始困境和阶段性目标", 5),
        new WebNovelElement("金手指系统", "cheat_system", SettingType.GOLDEN_FINGER, 
            "主角的核心外挂/系统/优势，需具成长性、解法性与持续爽点供给", 5),
        new WebNovelElement("世界观框架", "world_framework", SettingType.WORLDVIEW, 
            "小说世界的基本设定、时代背景与底层规则（为爽点与金手指提供舞台）", 4),
        new WebNovelElement("等级/力量体系", "power_system", SettingType.POWER_SYSTEM, 
            "成长与反馈的清晰分层，便于传播的战力体系/门槛/段位", 4),
        
        // 冲突对抗
        new WebNovelElement("反派势力", "antagonist_forces", SettingType.FACTION, 
            "从前期到后期可持续施压的敌对体系，层级递进、动机明确", 4),
        new WebNovelElement("情感线设定", "romance_line", SettingType.CHARACTER, 
            "情感关系发展路径与情绪张力，兼顾读者代入与扩散", 3),
        
        // 爽点与期待
        new WebNovelElement("爽点布局", "satisfaction_points", SettingType.PLEASURE_POINT, 
            "读者爽点的设计与节奏排布：打脸、反差、碾压、奇遇、名利双收等", 5),
        new WebNovelElement("期待感钩子", "anticipation_hooks", SettingType.ANTICIPATION_HOOK, 
            "悬念、伏笔、信息差与预告的系统化设计，串联爽点循环", 5),
        
        // 结构延展
        new WebNovelElement("支线剧情", "sub_plots", SettingType.EVENT, 
            "增强可读性与厚度的副线/任务/阶段目标，服务主线爽点", 3),
        new WebNovelElement("特色设定", "unique_features", SettingType.TROPE, 
            "差异化卖点与母题风格，形成辨识度与话题度", 3)
    );
    
    @Override
    public String getStrategyId() {
        return "tomato-web-novel";
    }
    
    @Override
    public String getStrategyName() {
        return "番茄小说网文设定";
    }
    
    @Override
    public String getDescription() {
        return "专门针对网络小说平台的创作策略，注重读者体验、爽点节奏和商业化考量";
    }
    
    @Override
    public SettingGenerationConfig createDefaultConfig() {
        List<NodeTemplateConfig> nodeTemplates = new ArrayList<>();
        
        // 为每个网文元素创建节点模板
        for (WebNovelElement element : WEB_NOVEL_ELEMENTS) {
            NodeTemplateConfig template = NodeTemplateConfig.builder()
                .id(element.id)
                .name(element.name)
                .type(element.defaultType)
                .description(element.description)
                .isRootTemplate(true)
                .minChildren(element.priority >= 4 ? 3 : 2)
                .maxChildren(element.priority >= 4 ? 12 : 8)
                .minDescriptionLength(element.priority >= 4 ? 90 : 70)
                .maxDescriptionLength(element.priority >= 4 ? 220 : 160)
                .priority(element.priority)
                .generationHint(getGenerationHint(element))
                .tags(List.of("网文", "番茄小说", element.getCategory()))
                .recommendedChildTypes(getRecommendedChildTypes(element))
                .build();
            nodeTemplates.add(template);
        }
        
        GenerationRules rules = GenerationRules.builder()
            .preferredBatchSize(16)
            .maxBatchSize(32)
            .minDescriptionLength(80)
            .maxDescriptionLength(800)
            .requireInterConnections(true)
            .allowDynamicStructure(true)
            .build();
        
        StrategyMetadata metadata = StrategyMetadata.builder()
            .categories(List.of("网络小说", "商业创作"))
            .tags(List.of("网文", "番茄小说", "爽文", "金手指", "期待感", "网感", "商业化"))
            .applicableGenres(List.of("玄幻", "都市", "科幻", "历史", "军事", "游戏", "重生", "言情"))
            .difficultyLevel(3)
            .estimatedGenerationTime(18)
            .build();
        
        return SettingGenerationConfig.builder()
            .strategyName(getStrategyName())
            .description(getDescription())
            .nodeTemplates(nodeTemplates)
            .rules(rules)
            .metadata(metadata)
            .expectedRootNodes(11)
            .maxDepth(4)
            .isSystemStrategy(true)
            .build();
    }
    
    @Override
    public ValidationResult validateConfig(SettingGenerationConfig config) {
        if (config == null) {
            return ValidationResult.failure("配置不能为空");
        }
        
        if (config.getNodeTemplates().size() < 8) {
            return ValidationResult.failure("番茄网文策略至少需要包含8个核心元素模板");
        }
        
        // 验证必须包含的核心元素
        List<String> requiredElements = List.of(
            "核心卖点", "主角设定", "金手指系统", "世界观框架",
            "等级/力量体系", "反派势力", "爽点布局", "期待感钩子"
        );
        List<String> configElements = config.getNodeTemplates().stream()
            .map(NodeTemplateConfig::getName)
            .toList();
        
        for (String required : requiredElements) {
            if (!configElements.contains(required)) {
                return ValidationResult.failure("缺少网文创作必需元素：" + required);
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
            // 为根节点添加网文特定的元数据
            if (node.getParentId() == null) {
                WEB_NOVEL_ELEMENTS.stream()
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
                        if (element.id.equals("satisfaction_points") || element.defaultType == SettingType.PLEASURE_POINT) {
                            node.getStrategyMetadata().put("isPleasurePoint", true);
                        }
                        if (element.id.equals("cheat_system") || element.defaultType == SettingType.GOLDEN_FINGER) {
                            node.getStrategyMetadata().put("isGoldenFinger", true);
                        }
                        if (element.id.equals("anticipation_hooks") || element.defaultType == SettingType.ANTICIPATION_HOOK) {
                            node.getStrategyMetadata().put("isAnticipationHook", true);
                        }
                    });
            }
            return node;
        });
    }
    
    @Override
    public List<String> getSupportedNodeTypes() {
        return WEB_NOVEL_ELEMENTS.stream()
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
    
    private String getGenerationHint(WebNovelElement element) {
        return switch (element.id) {
            case "core_selling_point" -> "用不超过50字的一句话，提炼作品最强卖点和差异化爆点，直击目标读者的情绪需求。";
            case "protagonist_setting" -> "重点描述主角的身份背景、性格特点和初始能力，要让读者有代入感";
            case "cheat_system" -> "设计具成长性和可持续供给爽点的金手指/系统：来源（宿命/奇遇）、底层逻辑（为何存在/如何运作）、升级路径、限制与代价、与世界规则的兼容性。给出1-2个开局即能超预期翻盘的具体用法。";
            case "world_framework" -> "构建与题材匹配的世界观：时代背景、资源与风险、基本规则与禁忌；明确这套规则如何为金手指施展与爽点爆发提供舞台。";
            case "power_system" -> "设计清晰的力量/等级体系：分层命名、获取与提升条件、反馈机制；要便于传播和对比，支撑从弱到强的节奏感与成就感。";
            case "romance_line" -> "安排合理的情感线发展，注意节奏和互动";
            case "antagonist_forces" -> "构造递进式反派体系：门槛-资源-地位-情感阻力多维施压；每阶段都能提供打脸与反差的机会，并与金手指的成长节点相互咬合。";
            case "satisfaction_points" -> "设计前中后期的爽点矩阵：打脸、绝境翻盘、扮猪吃虎、实力碾压、奇遇暴富、名利双收等，明确触发条件与呈现方式，形成‘拉期待—给爽点—再拉期待’循环。";
            case "anticipation_hooks" -> "设置2-3个强钩子：隐藏功能预告、身世线索、强敌将至、时间限制等；要求短句化、传播性强，指向后续大型爽点爆发。";
            case "sub_plots" -> "安排丰富主线的支线情节，增加可读性";
            case "unique_features" -> "沉淀可被记忆与传播的差异化要素：母题/风格/标签化元素，避免同质化。";
            default -> "详细描述该元素的关键特征和作用";
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
    
    private record WebNovelElement(String name, String id, SettingType defaultType, String description, int priority) {
        public String getCategory() {
            return switch (id) {
                case "core_selling_point" -> "商业卖点";
                case "protagonist_setting", "romance_line" -> "角色设定";
                case "antagonist_forces" -> "对抗体系";
                case "cheat_system", "power_system" -> "能力体系";
                case "world_framework", "unique_features" -> "世界构建";
                case "satisfaction_points", "anticipation_hooks", "sub_plots" -> "情节设计";
                default -> "其他";
            };
        }
    }

    private List<SettingType> getRecommendedChildTypes(WebNovelElement element) {
        return switch (element.id) {
            case "core_selling_point" -> List.of(SettingType.PLEASURE_POINT, SettingType.ANTICIPATION_HOOK);
            case "protagonist_setting" -> List.of(SettingType.GOLDEN_FINGER, SettingType.PLEASURE_POINT, SettingType.ANTICIPATION_HOOK, SettingType.TROPE);
            case "cheat_system" -> List.of(SettingType.POWER_SYSTEM, SettingType.PLEASURE_POINT, SettingType.PLOT_DEVICE, SettingType.ANTICIPATION_HOOK);
            case "world_framework" -> List.of(SettingType.WORLDVIEW, SettingType.LORE, SettingType.CONCEPT, SettingType.POLITICS, SettingType.ECONOMY);
            case "power_system" -> List.of(SettingType.POWER_SYSTEM, SettingType.CONCEPT, SettingType.ITEM);
            case "antagonist_forces" -> List.of(SettingType.FACTION, SettingType.CHARACTER, SettingType.EVENT, SettingType.PLEASURE_POINT);
            case "romance_line" -> List.of(SettingType.CHARACTER, SettingType.EVENT, SettingType.PLEASURE_POINT);
            case "satisfaction_points" -> List.of(SettingType.EVENT, SettingType.PLOT_DEVICE, SettingType.ITEM);
            case "anticipation_hooks" -> List.of(SettingType.ANTICIPATION_HOOK, SettingType.EVENT, SettingType.PLOT_DEVICE);
            case "sub_plots" -> List.of(SettingType.EVENT, SettingType.CHARACTER, SettingType.ITEM);
            case "unique_features" -> List.of(SettingType.TROPE, SettingType.STYLE, SettingType.TONE);
            default -> List.of();
        };
    }
}