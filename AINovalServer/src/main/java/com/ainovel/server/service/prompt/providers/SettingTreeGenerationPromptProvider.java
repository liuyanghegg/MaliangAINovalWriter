package com.ainovel.server.service.prompt.providers;

import java.util.Set;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.prompt.BasePromptProvider;

/**
 * 设定树生成功能提示词提供器
 * 基于 BasePromptProvider 实现设定生成相关的提示词管理
 */
@Component
public class SettingTreeGenerationPromptProvider extends BasePromptProvider {

    // 默认系统提示词
    private static final String DEFAULT_SYSTEM_PROMPT = """
            你是一位专业的小说设定策划师，专门负责根据用户创意生成结构化的小说设定体系。
            
            ## 核心能力
            1. **创意分析**：深入理解用户提供的创意和背景信息
            2. **结构化设计**：按照指定策略组织设定内容的层次结构
            3. **内容生成**：创造详细、生动、逻辑自洽的设定描述
            4. **关联构建**：确保不同设定之间相互呼应、形成有机整体
            5. **质量控制**：遵循描述长度要求和内容质量标准
            
            ## 工作原则
            - **结构清晰**：严格按照策略要求的层次结构组织内容
            - **内容丰富**：叶子节点描述必须100-200字，根节点描述50-80字
            - **逻辑一致**：所有设定必须相互兼容，形成连贯的世界观
            - **具体生动**：避免空洞概念，包含具体的人物、地点、时间、冲突等要素
            
            ## 描述质量要求
            - **根节点**：50-80字的清晰概括，说明该分类的核心内容和重要性
            - **叶子节点**：100-200字的详细描述，包含背景、特征、作用、关联关系等
            - **连贯性**：设定之间要有明确的关联关系，相互呼应
            - **完整性**：每个设定都应该包含足够的信息支撑后续创作
            
            请根据用户提供的策略配置和创意要求，生成高质量的设定内容。
            """;

    // 默认用户提示词
    private static final String DEFAULT_USER_PROMPT = """
            ## 创意内容
            {{input}}
            
            ## 策略配置
            **策略名称**: {{strategyName}}
            **策略描述**: {{strategyDescription}}
            **期望根节点数**: {{expectedRootNodes}}
            **最大深度**: {{maxDepth}}
            
            ## 节点模板要求
            {{nodeTemplatesInfo}}
            
            ## 生成规则
            {{generationRulesInfo}}
            
            ## 上下文信息
            {{context}}
            
            ## 小说背景
            **小说**: 《{{novelTitle}}》
            **作者**: {{authorName}}
            
            请根据以上信息生成设定内容。
            """;

    public SettingTreeGenerationPromptProvider() {
        super(AIFeatureType.SETTING_TREE_GENERATION);
    }

    @Override
    protected Set<String> initializeSupportedPlaceholders() {
        return Set.of(
            // 核心占位符
            "input", "context", "instructions",
            "novelTitle", "authorName",
            
            // 策略配置相关
            "strategyName", "strategyDescription", 
            "expectedRootNodes", "maxDepth",
            "nodeTemplatesInfo", "generationRulesInfo",
            
            // 节点相关
            "nodeId", "nodeName", "nodeType", "nodeDescription",
            "parentNode", "childNodes", "siblingNodes",
            
            // 修改相关
            "modificationPrompt", "originalNode", "targetChanges",
            "originalParentId", "availableParents", "currentNodeId",
            
            // 内容提供器占位符
            "full_novel_text", "full_novel_summary",
            "act", "chapter", "scene", "setting", "snippet"
        );
    }

    @Override
    public String getDefaultSystemPrompt() {
        return DEFAULT_SYSTEM_PROMPT;
    }

    @Override
    public String getDefaultUserPrompt() {
        return DEFAULT_USER_PROMPT;
    }
}