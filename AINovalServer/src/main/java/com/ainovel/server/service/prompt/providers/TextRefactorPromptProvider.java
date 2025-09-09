package com.ainovel.server.service.prompt.providers;

import java.util.Set;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.prompt.BasePromptProvider;

/**
 * 文本重构功能提示词提供器
 */
@Component
public class TextRefactorPromptProvider extends BasePromptProvider {

    // 默认系统提示词
    private static final String DEFAULT_SYSTEM_PROMPT ="""
            你是一位经验丰富的小说编辑和文字工作者，专门负责优化和重构小说文本。

            ## 当前任务要求
            - **重构方式**: {{style}}
            - **长度要求**: {{length}}
            - **具体指令**: {{instructions}}

            ## 你的核心能力
            1. **文字优化**：改善表达方式，使文字更加流畅、生动、准确
            2. **风格调整**：根据要求调整文本的语言风格、叙述角度、情感色调
            3. **结构重组**：优化句式结构，改善段落组织，提升阅读体验
            4. **细节完善**：补充必要的细节描写，删减冗余内容

            ## 重构原则
            - 保持原文的核心内容、情节发展和人物性格
            - 确保与小说整体风格和背景设定保持一致
            - 根据上下文信息调整表达方式，保证连贯性
            - 尊重作者的创作意图，在此基础上进行优化
            - 严格按照指定的重构方式和长度要求执行

            ## 操作指南
            1. 仔细分析用户提供的原文内容
            2. 结合上下文信息理解文本背景
            3. 根据指定的重构方式进行文本优化
            4. 确保重构后的内容符合长度要求
            5. 直接输出重构后的结果，不需要解释过程

            请准备根据用户提供的内容进行重构。
            """;

    // 默认用户提示词
    private static final String DEFAULT_USER_PROMPT = 
        """
            ## 需要重构的文本
            {{input}}

            ## 小说背景信息
            **小说**: 《{{novelTitle}}》
            **作者**: {{authorName}}

            ## 相关上下文
            {{context}}

            请按照系统要求对以上文本进行重构。
            """;

    public TextRefactorPromptProvider() {
        super(AIFeatureType.TEXT_REFACTOR);
    }

    @Override
    public String getDefaultSystemPrompt() {
        return DEFAULT_SYSTEM_PROMPT;
    }

    @Override
    public String getDefaultUserPrompt() {
        return DEFAULT_USER_PROMPT;
    }

    @Override
    protected Set<String> initializeSupportedPlaceholders() {
        return Set.of(
            // 基础占位符
            "input", "context", "instructions",
            "novelTitle", "authorName",
            
            // 重构特定参数
            "style", "length",
            
            // 内容提供器占位符（已实现）
            "full_novel_text", "full_novel_summary",
            "act", "chapter", "scene", "setting", "snippet"
            
            // 🚀 移除：大量未实现的占位符
            // "refactorStyle", "refactorRequirements", "targetTone", "characterVoice", 
            // "writingStyle", "sceneAtmosphere", "genreStyle", "narrativeVoice", 
            // "dialogueStyle", "full_outline", "acts", "chapters", "scenes",
            // "character", "location", "item", "lore", "settings", "snippets",
            // "characterInfo", "characterRelationships", "settingInfo", "locationInfo", 
            // "plotInfo", "themeInfo", "originalStyle", "targetStyle", "intensityLevel", 
            // "emotionalTone", "paceAdjustment", "detailLevel", "perspectiveShift",
            // "previousChapter", "nextChapterOutline", "currentPlot", "storyArc", 
            // "characterDevelopment", "conflictLevel"
        );
    }
} 