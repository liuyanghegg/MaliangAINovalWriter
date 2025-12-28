package com.ainovel.server.service.prompt.providers;

import java.util.Set;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.prompt.BasePromptProvider;

/**
 * 小说内容生成功能提示词提供器
 */
@Component
public class NovelGenerationPromptProvider extends BasePromptProvider {

    // 默认系统提示词
    private static final String DEFAULT_SYSTEM_PROMPT = 
        "你是一位经验丰富的小说作家，擅长创作各种类型的小说内容。\n\n" +
        "你的核心能力包括：\n" +
        "- 根据给定的设定和要求创作原创小说内容\n" +
        "- 构建引人入胜的情节和冲突\n" +
        "- 塑造立体生动的角色形象\n" +
        "- 创造丰富的世界观和背景设定\n" +
        "- 掌握多种文学风格和叙述技巧\n" +
        "- 平衡故事节奏和情感起伏\n\n" +
        "创作原则：\n" +
        "- 严格遵循提供的设定和创作要求\n" +
        "- 确保故事逻辑清晰，情节发展合理\n" +
        "- 角色行为符合其性格特征和背景\n" +
        "- 语言生动优美，适合目标读者群体\n" +
        "- 保持故事的连贯性和完整性\n" +
        "- 融入适当的文学技巧和修辞手法\n\n" +
        "内容类型适应：\n" +
        "- 支持多种小说类型：{{genreType:现代都市}}\n" +
        "- 适应不同叙述视角：{{narrativePerspective:第三人称}}\n" +
        "- 调整语言风格：{{languageStyle:现代文学}}\n" +
        "- 控制内容长度：{{contentLength:中篇}}\n\n" +
        "当前创作信息：\n" +
        "- 小说标题：{{novelTitle}}\n" +
        "- 目标读者：{{targetAudience:成年读者}}\n" +
        "- 主题风格：{{themeStyle:现实主义}}\n\n" +
        "今天是2025年6月11日星期三。";

    // 默认用户提示词
    private static final String DEFAULT_USER_PROMPT = 
        "请根据以下要求创作小说内容：\n\n" +
        "创作要求：\n" +
        "{{input}}\n\n" +
        "参考设定：\n" +
        "{{context}}\n\n" +
        "具体要求：\n" +
        "- 内容类型：{{contentType:章节}}\n" +
        "- 目标长度：{{targetLength:2000-3000}}字\n" +
        "- 叙述风格：{{narrativeStyle:生动细腻}}\n" +
        "- 情感基调：{{emotionalTone:积极向上}}\n" +
        "- 重点元素：{{focusElements:人物发展和情节推进}}\n\n" +
        "创作规范：\n" +
        "- 确保内容原创且富有创意\n" +
        "- 保持角色性格的一致性\n" +
        "- 情节发展要有逻辑性和连贯性\n" +
        "- 语言表达要符合目标风格\n" +
        "- 适当添加对话、动作和心理描写\n\n" +
        "特殊要求：\n" +
        "{{specialRequirements:无}}\n\n" +
        "请开始创作：";

    public NovelGenerationPromptProvider() {
        super(AIFeatureType.NOVEL_GENERATION);
    }

    @Override
    protected Set<String> initializeSupportedPlaceholders() {
        return Set.of(
            // 基础参数占位符
            "input", "context", "instructions",
            "novelTitle", "authorName",
            
            // 内容创作参数
            "length", "style",
            
            // 内容提供器占位符（已实现）
            "full_novel_text", "full_novel_summary",
            "scene", "chapter", "act", "setting", "snippet"
            
            // 🚀 移除：大量未实现的占位符
            // "contentType", "targetLength", "narrativeStyle", "emotionalTone", 
            // "focusElements", "specialRequirements", "genreType", "narrativePerspective", 
            // "languageStyle", "contentLength", "targetAudience", "themeStyle",
            // "characterDevelopment", "plotStructure", "worldBuilding", "dialogueStyle", 
            // "paceControl", "themeExploration", "conflictDesign", "atmosphereCreation", 
            // "styleAdaptation", "originalityLevel", "complexityLevel", "readabilityLevel",
            // "engagementLevel", "coherenceLevel", "creativityLevel"
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