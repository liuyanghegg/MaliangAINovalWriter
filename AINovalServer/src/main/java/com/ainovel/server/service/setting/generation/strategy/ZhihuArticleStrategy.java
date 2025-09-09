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
 * 知乎短文创作策略
 * 专门针对知乎平台短文创作的结构化设定策略
 */
@Component("zhihu-article")
public class ZhihuArticleStrategy implements SettingGenerationStrategy {
    
    private static final List<ArticleElement> ARTICLE_ELEMENTS = List.of(
        new ArticleElement("引人开头", "hook_opening", SettingType.OTHER, 
            "抓住读者注意力的开头设计，可以是问题、故事或金句", 5),
        new ArticleElement("核心观点", "main_viewpoint", SettingType.OTHER, 
            "文章要表达的核心观点和立场", 5),
        new ArticleElement("逻辑结构", "logical_structure", SettingType.OTHER, 
            "文章的论证逻辑和结构框架", 4),
        new ArticleElement("案例故事", "case_stories", SettingType.EVENT, 
            "支撑观点的具体案例和故事", 4),
        new ArticleElement("干货内容", "practical_content", SettingType.OTHER, 
            "为读者提供实用价值的具体内容", 4),
        new ArticleElement("情感共鸣", "emotional_resonance", SettingType.OTHER, 
            "引起读者情感共鸣的内容设计", 3),
        new ArticleElement("互动设计", "interaction_design", SettingType.OTHER, 
            "促进读者互动的问题和话题设计", 3),
        new ArticleElement("收尾总结", "conclusion", SettingType.OTHER, 
            "总结观点、号召行动或引发思考的结尾", 4)
    );
    
    @SuppressWarnings("unused")
    private static final List<ContentType> CONTENT_TYPES = List.of(
        new ContentType("经验分享", "experience_sharing", "分享个人或他人的经验教训"),
        new ContentType("知识科普", "knowledge_popularization", "普及专业知识或概念"),
        new ContentType("观点评论", "opinion_commentary", "对热点事件或现象的评论"),
        new ContentType("方法论", "methodology", "系统性的方法和技巧分享"),
        new ContentType("深度分析", "deep_analysis", "对复杂问题的深入分析")
    );
    
    @Override
    public String getStrategyId() {
        return "zhihu-article";
    }
    
    @Override
    public String getStrategyName() {
        return "知乎短文创作";
    }
    
    @Override
    public String getDescription() {
        return "专门针对知乎平台的短文创作策略，注重逻辑性、实用性和读者互动";
    }
    
    @Override
    public SettingGenerationConfig createDefaultConfig() {
        List<NodeTemplateConfig> nodeTemplates = new ArrayList<>();
        
        // 为每个文章元素创建节点模板
        for (ArticleElement element : ARTICLE_ELEMENTS) {
            NodeTemplateConfig template = NodeTemplateConfig.builder()
                .id(element.id)
                .name(element.name)
                .type(element.defaultType)
                .description(element.description)
                .isRootTemplate(true)
                .minChildren(element.priority >= 4 ? 2 : 1)
                .maxChildren(element.priority >= 4 ? 6 : 4)
                .minDescriptionLength(40)
                .maxDescriptionLength(element.priority >= 4 ? 120 : 80)
                .priority(element.priority)
                .generationHint(getGenerationHint(element))
                .tags(List.of("知乎", "短文", element.getCategory()))
                .build();
            nodeTemplates.add(template);
        }
        
        // 添加内容类型选择模板
        NodeTemplateConfig contentTypeTemplate = NodeTemplateConfig.builder()
            .id("content_type")
            .name("内容类型")
            .type(SettingType.OTHER)
            .description("确定文章的主要内容类型和定位")
            .isRootTemplate(true)
            .minChildren(1)
            .maxChildren(3)
            .minDescriptionLength(30)
            .maxDescriptionLength(60)
            .priority(5)
            .generationHint("选择最适合的内容类型，可以组合多种类型")
            .tags(List.of("知乎", "内容定位"))
            .build();
        nodeTemplates.add(contentTypeTemplate);
        
        GenerationRules rules = GenerationRules.builder()
            .preferredBatchSize(8)
            .maxBatchSize(12)
            .minDescriptionLength(40)
            .maxDescriptionLength(300)
            .requireInterConnections(true)
            .allowDynamicStructure(true)
            .build();
        
        StrategyMetadata metadata = StrategyMetadata.builder()
            .categories(List.of("内容创作", "社交媒体"))
            .tags(List.of("知乎", "短文", "内容创作", "社交分享"))
            .applicableGenres(List.of("经验分享", "知识科普", "观点评论", "方法论", "深度分析"))
            .difficultyLevel(2)
            .estimatedGenerationTime(10)
            .build();
        
        return SettingGenerationConfig.builder()
            .strategyName(getStrategyName())
            .description(getDescription())
            .nodeTemplates(nodeTemplates)
            .rules(rules)
            .metadata(metadata)
            .expectedRootNodes(9) // 8个文章元素 + 1个内容类型
            .maxDepth(3)
            .isSystemStrategy(true)
            .build();
    }
    
    @Override
    public ValidationResult validateConfig(SettingGenerationConfig config) {
        if (config == null) {
            return ValidationResult.failure("配置不能为空");
        }
        
        if (config.getNodeTemplates().size() < 5) {
            return ValidationResult.failure("知乎短文策略至少需要包含5个核心元素模板");
        }
        
        // 验证必须包含的核心元素
        List<String> requiredElements = List.of("引人开头", "核心观点", "逻辑结构", "收尾总结");
        List<String> configElements = config.getNodeTemplates().stream()
            .map(NodeTemplateConfig::getName)
            .toList();
        
        for (String required : requiredElements) {
            if (!configElements.contains(required)) {
                return ValidationResult.failure("缺少短文创作必需元素：" + required);
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
            // 为根节点添加知乎短文特定的元数据
            if (node.getParentId() == null) {
                ARTICLE_ELEMENTS.stream()
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
                        if (element.name.contains("开头") || element.name.contains("结尾")) {
                            node.getStrategyMetadata().put("isStructuralElement", true);
                        }
                    });
                    
                // 处理内容类型节点
                if ("内容类型".equals(node.getName())) {
                    node.getStrategyMetadata().put("elementType", "content_type");
                    node.getStrategyMetadata().put("isMetaElement", true);
                }
            }
            return node;
        });
    }
    
    @Override
    public List<String> getSupportedNodeTypes() {
        return ARTICLE_ELEMENTS.stream()
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
    
    private String getGenerationHint(ArticleElement element) {
        return switch (element.id) {
            case "hook_opening" -> "设计吸引人的开头，可以用问题、故事、数据或金句";
            case "main_viewpoint" -> "明确表达核心观点，要具体、可论证且有价值";
            case "logical_structure" -> "设计清晰的论证逻辑，如总分总、递进式等";
            case "case_stories" -> "准备具体的案例或故事，增强说服力";
            case "practical_content" -> "提供实用的方法、技巧或知识点";
            case "emotional_resonance" -> "设计引起共鸣的情感点，如痛点、爽点";
            case "interaction_design" -> "设计互动问题或话题，促进评论和讨论";
            case "conclusion" -> "总结观点，给出行动建议或引发思考";
            default -> "详细描述该元素的具体内容和作用";
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
    
    private record ArticleElement(String name, String id, SettingType defaultType, String description, int priority) {
        public String getCategory() {
            return switch (id) {
                case "hook_opening", "conclusion" -> "结构框架";
                case "main_viewpoint", "logical_structure" -> "核心内容";
                case "case_stories", "practical_content" -> "支撑材料";
                case "emotional_resonance", "interaction_design" -> "读者体验";
                default -> "其他";
            };
        }
    }
    
    private record ContentType(String name, String id, String description) {}
}