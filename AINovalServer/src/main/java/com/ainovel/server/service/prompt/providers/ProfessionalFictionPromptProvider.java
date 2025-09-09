package com.ainovel.server.service.prompt.providers;

import java.util.Set;

import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.prompt.BasePromptProvider;

/**
 * 专业小说续写功能提示词提供器
 */
@Component
public class ProfessionalFictionPromptProvider extends BasePromptProvider {

    // 默认系统提示词
    private static final String DEFAULT_SYSTEM_PROMPT = 
        "你是一位专业的小说续写专家。你的专长是根据已有内容进行高质量的小说续写。\n\n" +
        "请始终遵循以下续写规则：\n" +
        "- 使用过去时态，采用中文写作规范和表达习惯\n" +
        "- 使用主动语态\n" +
        "- 始终遵循\"展现，而非叙述\"的原则\n" +
        "- 避免使用副词、陈词滥调和过度使用的常见短语。力求新颖独特的描述\n" +
        "- 通过对话来传达事件和故事发展\n" +
        "- 混合使用短句和长句，短句富有冲击力，长句细致描述。省略冗余词汇增加变化\n" +
        "- 省略\"他/她说\"这样的对话标签，通过角色的动作或面部表情来传达说话状态\n" +
        "- 避免过于煽情的对话和描述，对话应始终推进情节，绝不拖沓或添加不必要的冗余。变化描述以避免重复\n" +
        "- 将对话单独成段，与场景和动作分离\n" +
        "- 减少不确定性的表达，如\"试图\"或\"也许\"\n\n" +
        "续写时请特别注意：\n" +
        "- 必须与前文保持高度连贯性，包括人物性格、情节逻辑、写作风格\n" +
        "- 仔细分析前文的语言风格、节奏感和叙述特点，在续写中保持一致\n" +
        "- 绝不要自己结束场景，严格按照续写指示进行\n" +
        "- 绝不要以预示结尾\n" +
        "- 绝不要写超出所提示的内容范围\n" +
        "- 避免想象可能的结局，绝不要偏离续写指示\n" +
        "- 如果续写内容已包含指示中要求的情节点，请适时停止。你不需要填满所有可能的字数\n\n" +
        "对于作者来说，今天是2025年6月11日星期三，他们正在创作小说《{{novelTitle}}》。";

    // 默认用户提示词
    private static final String DEFAULT_USER_PROMPT = 
        "<task>\n" +
        "  <action>请按照专业小说续写标准进行续写</action>\n" +
        "  <previous_content>{{previousContent}}</previous_content>\n" +
        "  <continuation_requirements>{{continuationRequirements}}</continuation_requirements>\n" +
        "  <plot_guidance>{{plotGuidance}}</plot_guidance>\n" +
        "  <style_requirements>{{styleRequirements}}</style_requirements>\n" +
        "  <character_development>{{characterDevelopment}}</character_development>\n" +
        "  <scene_setting>{{sceneSetting}}</scene_setting>\n" +
        "  <emotional_tone>{{emotionalTone}}</emotional_tone>\n" +
        "  <pacing_guidance>{{pacingGuidance}}</pacing_guidance>\n" +
        "  <word_count_target>{{wordCountTarget}}</word_count_target>\n" +
        "  <instructions>\n" +
        "    <item>严格遵循系统提示中的续写规则</item>\n" +
        "    <item>与前文保持高度连贯性，包括人物性格、情节逻辑、写作风格</item>\n" +
        "    <item>展现而非叙述，通过对话和行动推进情节</item>\n" +
        "    <item>使用主动语态和过去时态</item>\n" +
        "    <item>避免陈词滥调，力求新颖独特的表达</item>\n" +
        "    <item>根据续写指示精确创作，不要偏离或添加多余内容</item>\n" +
        "  </instructions>\n" +
        "</task>";

    public ProfessionalFictionPromptProvider() {
        super(AIFeatureType.PROFESSIONAL_FICTION_CONTINUATION);
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
            // 基础续写占位符
            "input", "context", "instructions",
            "novelTitle", "authorName",
            
            // 续写特定参数
            "length", "style",
            
            // 内容提供器占位符（已实现）
            "full_novel_text", "full_novel_summary",
            "act", "chapter", "scene", "setting", "snippet"
            
            // 🚀 移除：大量未实现的占位符 
            // "previousContent", "continuationRequirements", "plotGuidance", 
            // "styleRequirements", "characterDevelopment", "characterInfo", 
            // "characterRelationships", "characterVoice", "characterMotivation", 
            // "characterConflict", "sceneSetting", "sceneAtmosphere", "locationInfo", 
            // "settingInfo", "environmentDetails", "timeOfDay", "weather", "ambiance",
            // "emotionalTone", "moodShift", "tensionLevel", "intimacyLevel",
            // "conflictIntensity", "romanticElement", "dramaticImpact",
            // "pacingGuidance", "wordCountTarget", "sceneLength", "actionPacing",
            // "dialogueRatio", "descriptionLevel", "narrativeSpeed", "full_outline",
            // "acts", "chapters", "scenes", "character", "location", "item", 
            // "lore", "settings", "snippets", "plotInfo", "storyArc", 
            // "nextPlotPoint", "climaxDirection", "conflictResolution", "characterArc", 
            // "themeExploration", "writingStyle", "narrativeVoice", "perspectiveShift", 
            // "genreConventions", "literaryDevices", "symbolism", "foreshadowing", 
            // "callbacks", "prologueElements", "epilogueHints"
        );
    }
} 