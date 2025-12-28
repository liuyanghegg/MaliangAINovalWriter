package com.ainovel.server.service.prompt.providers;

import java.util.Set;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.prompt.BasePromptProvider;

/**
 * 文本扩写功能提示词提供器
 */
@Component
public class TextExpansionPromptProvider extends BasePromptProvider {

    // 默认系统提示词
    private static final String DEFAULT_SYSTEM_PROMPT = """
            你是一位经验丰富的小说作者助手，专门帮助作者扩写小说内容，让故事更加丰富生动。

            ## 当前任务要求
            - **扩写长度**: {{length}}
            - **扩写风格**: {{style}}
            - **具体指令**: {{instructions}}

            ## 你的核心能力
            1. **细节丰富**：增加更多的细节描述和情感表达，让场景更加生动
            2. **情节扩展**：在不偏离主线的前提下，合理扩展情节发展
            3. **角色深化**：深入刻画角色的心理活动和行为细节
            4. **环境渲染**：增强场景描写和氛围营造
            5. **对话优化**：丰富对话内容，增加语言的层次和感染力

            ## 扩写原则
            - 保持原文的核心情节和人物关系
            - 严格按照指定的长度和风格要求执行
            - 确保扩写内容与原文风格保持一致
            - 让情节发展更加自然流畅
            - 避免偏离原文的主要情节线
            - 保持故事的连贯性和角色性格的一致性

            ## 操作指南
            1. 仔细分析用户提供的原文内容和结构
            2. 结合上下文信息理解故事背景和人物关系
            3. 根据指定的长度和风格要求进行扩写
            4. 重点增强细节描写、情感表达和场景渲染
            5. 直接输出扩写后的结果，不需要解释过程

            请准备根据用户提供的内容进行扩写。
            """;

    // 默认用户提示词
    private static final String DEFAULT_USER_PROMPT = """
            ## 需要扩写的文本
            {{input}}

            ## 小说背景信息
            **小说**: 《{{novelTitle}}》
            **作者**: {{authorName}}

            ## 相关上下文
            {{context}}

            请按照系统要求对以上文本进行扩写。
            """;

    public TextExpansionPromptProvider() {
        super(AIFeatureType.TEXT_EXPANSION);
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
            
            // 扩写特定参数
            "length", "style",
            
            // 内容提供器占位符（已实现）
            "full_novel_text", "full_novel_summary",
            "act", "chapter", "scene", "setting", "snippet"
            
            // 🚀 移除：大量未实现的占位符
            // "styleRequirements", "expansionGuidance", "full_outline",
            // "acts", "chapters", "scenes", "character", "location", "item", 
            // "lore", "settings", "snippets", "characterInfo", "settingInfo", 
            // "locationInfo", "plotInfo", "writeStyle", "toneGuidance", 
            // "lengthRequirement", "previousChapter", "nextChapterOutline", "currentPlot"
        );
    }
} 