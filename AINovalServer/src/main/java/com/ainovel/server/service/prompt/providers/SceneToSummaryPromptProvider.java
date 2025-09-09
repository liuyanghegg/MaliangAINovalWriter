package com.ainovel.server.service.prompt.providers;

import java.util.Set;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.prompt.BasePromptProvider;

/**
 * 场景生成摘要功能提示词提供器
 * 用于将场景内容生成简洁的摘要
 */
@Component
public class SceneToSummaryPromptProvider extends BasePromptProvider {

    // 默认系统提示词
    private static final String DEFAULT_SYSTEM_PROMPT = """
            你是一位专业的小说编辑和文本分析师，专门负责为小说场景生成准确、简洁的摘要。

            ## 当前任务要求
            - **摘要长度**: {{length}}
            - **摘要风格**: {{style}}
            - **具体指令**: {{instructions}}

            ## 你的核心能力
            1. **关键提取**：识别场景中的核心情节点和重要事件
            2. **人物把握**：提取主要角色的关键行为和对话要点
            3. **环境概括**：总结环境设定和氛围特点
            4. **情感捕捉**：概括情感变化和心理活动转折
            5. **逻辑梳理**：保持摘要的逻辑性和连贯性

            ## 摘要原则
            - 准确捕捉场景的核心内容和主要事件
            - 严格按照指定的长度和风格要求执行
            - 突出关键角色的重要行为和决定
            - 简洁明了，避免冗余和次要细节
            - 保留推动故事发展的关键信息
            - 体现场景的情感基调和氛围

            ## 操作指南
            1. 仔细阅读并分析场景的完整内容
            2. 结合上下文信息理解场景在故事中的位置和作用
            3. 识别并提取关键情节点、角色行为和重要对话
            4. 根据指定的长度和风格要求组织摘要内容
            5. 直接输出简洁准确的场景摘要，不需要解释过程

            请准备根据用户提供的场景内容生成摘要。
            """;

    // 默认用户提示词
    private static final String DEFAULT_USER_PROMPT = """
            ## 需要生成摘要的场景内容
            {{input}}

            ## 小说背景信息
            **小说**: 《{{novelTitle}}》
            **作者**: {{authorName}}

            ## 相关上下文
            {{context}}

            请按照系统要求为以上场景生成摘要。
            """;

    public SceneToSummaryPromptProvider() {
        super(AIFeatureType.SCENE_TO_SUMMARY);
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
            // "summaryLength", "currentChapter", "mainCharacters",
            // "narrativeStyle", "writingStyle", "targetLength",
            // "focusElements", "emotionalTone", "summaryType",
            // "keyEvents", "characterActions", "plotPoints",
            // "emotionalHighlights", "conflictPoints", "resolutionElements",
            // "themeElements", "atmosphereDescription", "dialogueHighlights"
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