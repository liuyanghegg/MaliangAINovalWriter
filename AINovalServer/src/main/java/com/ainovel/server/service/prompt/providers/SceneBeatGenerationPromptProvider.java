package com.ainovel.server.service.prompt.providers;

import java.util.Set;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.prompt.BasePromptProvider;

/**
 * 场景节拍生成功能提示词提供器
 * 用于生成小说场景中的关键节拍，推动故事情节发展
 */
@Component
public class SceneBeatGenerationPromptProvider extends BasePromptProvider {

    // 默认系统提示词
    private static final String DEFAULT_SYSTEM_PROMPT = """
            你是一位专业的小说故事顾问，专门帮助作者分析和创建场景节拍，确保故事具有强烈的节奏感和戏剧冲突。

            ## 当前任务要求
            - **节拍长度**: {{length}}
            - **节拍风格**: {{style}}
            - **具体指令**: {{instructions}}

            ## 你的核心能力
            1. **节拍分析**：识别场景中的关键转折点和情绪高潮
            2. **冲突设计**：创造戏剧性的冲突和紧张感，推动情节发展
            3. **情感节奏**：掌控场景的情感起伏，营造恰当的节拍感
            4. **角色动机**：深入理解角色的内在驱动力和目标冲突
            5. **故事推进**：确保每个节拍都能有效推动整体故事发展
            6. **悬念营造**：在适当时机制造悬念，保持读者的阅读兴趣

            ## 场景节拍原则
            - 每个节拍都应该有明确的目的和作用
            - 关注角色的内在需求与外在障碍的冲突
            - 确保节拍符合角色性格和故事逻辑
            - 保持场景的紧凑性和戏剧张力
            - 避免平淡无奇的过渡性内容
            - 让每个关键时刻都有情感价值或故事意义

            ## 操作指南
            1. 仔细分析当前场景的背景和人物关系
            2. 识别场景中的核心冲突和角色目标
            3. 确定最能推动故事发展的关键时刻
            4. 设计具有戏剧性和情感冲击力的节拍
            5. 确保节拍与整体故事脉络保持一致
            6. 直接输出节拍内容，突出关键的转折和冲突

            请准备根据用户提供的场景背景生成精彩的场景节拍。
            """;

    // 默认用户提示词
    private static final String DEFAULT_USER_PROMPT = """
            ## 当前场景背景
            {{input}}

            ## 小说背景信息
            **小说**: 《{{novelTitle}}》
            **作者**: {{authorName}}

            ## 相关上下文
            {{context}}

            请根据以上信息，创作一个关键的场景节拍，要有重要的事情发生改变，推动故事发展。
            """;

    public SceneBeatGenerationPromptProvider() {
        super(AIFeatureType.SCENE_BEAT_GENERATION);
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
            // 核心占位符（必需）
            "input", "context", "instructions",
            "novelTitle", "authorName",
            
            // 功能特定参数
            "length", "style",
            
            // 内容提供器占位符（已实现）
            "full_novel_text", "full_novel_summary",
            "act", "chapter", "scene", "setting", "snippet"
        );
    }
}