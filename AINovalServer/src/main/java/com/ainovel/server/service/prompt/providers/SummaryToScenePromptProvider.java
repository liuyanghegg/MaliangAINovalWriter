package com.ainovel.server.service.prompt.providers;

import java.util.Set;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.prompt.BasePromptProvider;

/**
 * 摘要生成场景功能提示词提供器
 */
@Component
public class SummaryToScenePromptProvider extends BasePromptProvider {

    // 默认系统提示词
    private static final String DEFAULT_SYSTEM_PROMPT = """
            你是一位富有创造力的小说作家，专门负责将简洁的情节摘要扩展为生动详细的场景描写。

            ## 当前任务要求
            - **场景长度**: {{length}}
            - **写作风格**: {{style}}
            - **具体指令**: {{instructions}}

            ## 你的核心能力
            1. **情节还原**：根据摘要内容准确构建完整的场景情节
            2. **细节创造**：创造丰富的环境描写和氛围营造
            3. **对话设计**：设计自然流畅的人物对话和行为互动
            4. **心理刻画**：添加恰当的心理描写和情感表达
            5. **风格统一**：确保场景风格与小说整体保持一致

            ## 场景扩展原则
            - 严格遵循摘要中的核心情节和关键事件
            - 严格按照指定的长度和风格要求执行
            - 合理扩展细节但不偏离主要故事线
            - 创造符合小说风格和时代背景的描写
            - 确保人物行为和对话符合其性格特征
            - 平衡动作、对话、心理和环境描写

            ## 操作指南
            1. 仔细分析摘要中的核心情节点和关键要素
            2. 结合上下文信息理解故事背景和人物关系
            3. 根据指定的长度和风格要求设计场景结构
            4. 创造生动的细节描写和自然的对话互动
            5. 直接输出完整的场景内容，不需要解释过程

            请准备根据用户提供的摘要内容创作完整场景。
            """;

    // 默认用户提示词
    private static final String DEFAULT_USER_PROMPT = """
            ## 需要扩展为场景的摘要内容
            {{input}}

            ## 小说背景信息
            **小说**: 《{{novelTitle}}》
            **作者**: {{authorName}}

            ## 相关上下文
            {{context}}

            请按照系统要求将以上摘要扩展为完整的场景。
            """;

    public SummaryToScenePromptProvider() {
        super(AIFeatureType.SUMMARY_TO_SCENE);
    }

    @Override
    protected Set<String> initializeSupportedPlaceholders() {
        return Set.of(
            // 核心占位符（必需）
            "input", "context", "instructions",
            "novelTitle", "authorName",
            
            // 功能特定参数
            "length", "style",
            
            // 内容提供器占位符（已实现）
            "full_novel_text", "full_novel_summary",
            "act", "chapter", "scene", "setting", "snippet"
            
            // 🚀 移除：大量未实现的占位符
            // "sceneLength", "currentChapter", "mainCharacters",
            // "narrativeStyle", "writingStyle", "targetLength",
            // "focusElements", "emotionalTone", "sceneType",
            // "characterBackground", "plotContext", "themeElements",
            // "dialogueStyle", "descriptionLevel", "paceRequirements",
            // "characterRelationships", "conflictLevel", "atmosphereType"
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