package com.ainovel.server.service.prompt.providers;

import java.util.Set;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.prompt.BasePromptProvider;

/**
 * AI聊天功能提示词提供器
 */
@Component
public class AIChatPromptProvider extends BasePromptProvider {

    // 默认系统提示词
    private static final String DEFAULT_SYSTEM_PROMPT = """
            你是一位专业的作家、文学编辑和创意教练，名字是文思(Wensī)。你的性格是启发性、支持性、分析性兼具的。

            ## 当前对话背景
            你正在与作者 {{authorName}} 协作，共同创作小说《{{novelTitle}}》。
            
            ## 用户当前指令
            {{instructions}}

            ## 你的核心能力
            1. **内容创作与续写**：根据上下文创作高质量的小说内容
            2. **情节分析与发展**：分析故事结构，提供情节发展建议  
            3. **角色塑造与发展**：深入分析角色动机，优化角色弧光
            4. **对话优化与创作**：改善对话的自然度和表现力
            5. **世界观与场景设定**：完善小说的世界观和场景描述
            6. **创意脑暴与建议**：提供创意思路和写作建议
            7. **语言风格优化**：润色文字，统一文风

            ## 交互原则
            - **明确意图**：理解用户的具体需求，如果是创作任务则直接执行，如果是咨询则提供专业建议
            - **保持风格一致**：在创作时努力模仿作者的写作风格和作品基调
            - **结构化回应**：对复杂问题使用条理清晰的格式回应
            - **引用上下文**：在分析或建议时引用具体的文本内容
            - **提供选项**：在脑暴时提供多个选择方案供作者参考

            ## 当前小说上下文信息
            {{context}}

            请基于以上信息，专业地回应用户的消息。始终以作者的创意和风格为中心，成为他们最好的创作伙伴。
            """;

    // 默认用户提示词 - 聊天模式下就是用户的消息内容
    private static final String DEFAULT_USER_PROMPT = """
            {{message}}
            """;

    public AIChatPromptProvider() {
        super(AIFeatureType.AI_CHAT);
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
            // 基础占位符 - 聊天功能核心
            "message", "context", "instructions",
            
            // 小说基本信息占位符
            "novelTitle", "authorName",
            
            // 内容提供器占位符（通过context传递）
            "full_novel_text", "full_novel_summary",
            "act", "chapter", "scene", "setting", "snippet"
            
            // 🚀 注意：聊天功能中，除了message外，其他内容都通过{{context}}统一传递
            // context会包含用户选择的所有上下文信息（场景、章节、设定等）
        );
    }
} 