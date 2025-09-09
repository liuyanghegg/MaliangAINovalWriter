package com.ainovel.server.service.prompt.providers;

import java.util.Set;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.prompt.BasePromptProvider;

/**
 * 文本总结功能提示词提供器
 */
@Component
public class TextSummaryPromptProvider extends BasePromptProvider {

    // 默认系统提示词
    private static final String DEFAULT_SYSTEM_PROMPT = """
            你是一位专业的小说编辑，擅长提炼和总结故事要点。

            ## 当前任务要求
            - **总结长度**: {{length}}
            - **总结风格**: {{style}}
            - **具体指令**: {{instructions}}

            ## 你的核心能力
            1. **内容提炼**：提取关键情节和重要信息，去除冗余细节
            2. **逻辑梳理**：保持总结的准确性和完整性，确保逻辑清晰
            3. **重点突出**：识别并突出重要的故事转折点和角色发展
            4. **主题把握**：概括主要主题和情感线索，保留故事精神内核
            5. **结构优化**：按照要求的详细程度和风格进行总结

            ## 总结原则
            - 准确反映原文的主要内容和情节发展
            - 严格按照指定的长度和风格要求执行
            - 保持逻辑清晰，条理分明
            - 突出关键的情节转折和角色发展
            - 保留重要的情感节点和主题元素
            - 使用简洁明了的语言表达

            ## 操作指南
            1. 仔细阅读并分析用户提供的原文内容
            2. 结合上下文信息理解故事背景和发展脉络
            3. 根据指定的长度和风格要求进行总结
            4. 突出关键情节、角色发展和主题元素
            5. 直接输出总结结果，不需要解释过程

            请准备根据用户提供的内容进行总结。
            """;

    // 默认用户提示词
    private static final String DEFAULT_USER_PROMPT = """
            ## 需要总结的文本
            {{input}}

            ## 小说背景信息
            **小说**: 《{{novelTitle}}》
            **作者**: {{authorName}}

            ## 相关上下文
            {{context}}

            请按照系统要求对以上文本进行总结。
            """;

    public TextSummaryPromptProvider() {
        super(AIFeatureType.TEXT_SUMMARY);
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
            
            // 总结特定参数
            "length", "style",
            
            // 内容提供器占位符（已实现）
            "full_novel_text", "full_novel_summary",
            "act", "chapter", "scene", "setting", "snippet"
            
            // 🚀 移除：大量未实现的占位符
            // "summaryLength", "summaryStyle", "focusPoints", "targetAudience", 
            // "includeCharacters", "includePlotPoints", "detailLevel", "structureType", 
            // "perspective", "keyThemes", "full_outline", "acts", "chapters", "scenes",
            // "character", "location", "item", "lore", "settings", "snippets",
            // "characterInfo", "characterRelationships", "settingInfo", "locationInfo", 
            // "plotInfo", "themeInfo", "conflictInfo", "timelineEvents", "plotStructure", 
            // "storyArcs", "characterArcs", "majorTurningPoints", "climaxPoints", 
            // "resolutionPoints", "previousSummary", "overallPlot", "currentProgress",
            // "futureOutline", "genreElements", "narrativeStyle"
        );
    }
} 