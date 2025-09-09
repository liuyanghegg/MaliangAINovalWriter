package com.ainovel.server.service.prompt;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.UnifiedPromptService;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * 提示词系统使用示例
 * 展示如何使用新的提示词系统进行占位符解析和内容获取
 */
@Slf4j
@Component
public class PromptSystemExample {

    @Autowired
    private UnifiedPromptService unifiedPromptService;

    /**
     * 示例：获取文本扩写的完整提示词对话
     */
    public Mono<String> getTextExpansionExample(String userId, String novelId) {
        log.info("=== 提示词系统使用示例：文本扩写 ===");

        // 1. 构建参数映射
        Map<String, Object> parameters = Map.ofEntries(
            // 基础参数
            Map.entry("novelId", novelId),
            Map.entry("input", "主角走进了神秘的森林。"),
            Map.entry("context", "这是一个关于冒险的奇幻小说，主角是一位年轻的法师。"),
            Map.entry("novelTitle", "魔法师的冒险"),
            Map.entry("authorName", "测试作者"),
            
            // 功能特定参数
            Map.entry("styleRequirements", "文笔优美，充满想象力"),
            Map.entry("targetTone", "神秘而充满期待"),
            Map.entry("characterVoice", "年轻、好奇、勇敢"),
            
            // 内容提供器相关参数（这些会被解析为实际内容）
            Map.entry("character", "主角信息"),  // 将被解析为实际的角色设定
            Map.entry("scene", "当前场景"),      // 将被解析为实际的场景描述
            Map.entry("snippet", "相关片段")     // 将被解析为相关的文本片段
        );

        // 2. 获取完整的提示词对话
        return unifiedPromptService.getCompletePromptConversation(
                AIFeatureType.TEXT_EXPANSION,
                userId,
                null, // 使用默认模板，也可以指定用户自定义模板ID
                parameters
        ).map(conversation -> {
            StringBuilder example = new StringBuilder();
            example.append("=== 文本扩写提示词对话示例 ===\n\n");
            example.append("📋 输入参数:\n");
            parameters.forEach((key, value) -> 
                example.append(String.format("  %s: %s\n", key, value))
            );
            
            example.append("\n🤖 系统提示词:\n");
            example.append(conversation.getSystemMessage());
            example.append("\n\n👤 用户提示词:\n");
            example.append(conversation.getUserMessage());
            
            example.append("\n\n✅ 占位符解析说明:\n");
            example.append("- {{input}} → 用户输入的文本\n");
            example.append("- {{character}} → 通过内容提供器获取的角色设定\n");
            example.append("- {{scene}} → 通过内容提供器获取的场景描述\n");
            example.append("- {{novelTitle}} → 小说标题\n");
            example.append("- {{styleRequirements}} → 风格要求\n");
            
            return example.toString();
        });
    }

    /**
     * 示例：验证提示词中的占位符
     */
    public String validatePlaceholdersExample() {
        log.info("=== 提示词系统使用示例：占位符验证 ===");

        String testPrompt = """
            请扩写以下内容：{{input}}
            
            小说信息：
            - 标题：{{novelTitle}}
            - 角色：{{character}}
            - 场景：{{scene}}
            
            风格要求：{{styleRequirements}}
            无效占位符：{{invalidPlaceholder}}
            """;

        // 验证占位符
        AIFeaturePromptProvider.ValidationResult result = 
            unifiedPromptService.validatePlaceholders(AIFeatureType.TEXT_EXPANSION, testPrompt);

        StringBuilder example = new StringBuilder();
        example.append("=== 占位符验证示例 ===\n\n");
        example.append("📝 测试提示词:\n");
        example.append(testPrompt);
        example.append("\n🔍 验证结果:\n");
        example.append(String.format("- 验证通过: %s\n", result.isValid() ? "是" : "否"));
        example.append(String.format("- 验证消息: %s\n", result.getMessage()));
        
        if (!result.getUnsupportedPlaceholders().isEmpty()) {
            example.append("- 不支持的占位符: ");
            example.append(String.join(", ", result.getUnsupportedPlaceholders()));
            example.append("\n");
        }

        return example.toString();
    }

    /**
     * 示例：获取功能支持的占位符
     */
    public String getSupportedPlaceholdersExample() {
        log.info("=== 提示词系统使用示例：支持的占位符 ===");

        StringBuilder example = new StringBuilder();
        example.append("=== 各功能支持的占位符 ===\n\n");

        // 遍历所有支持的功能类型
        for (AIFeatureType featureType : unifiedPromptService.getSupportedFeatureTypes()) {
            example.append(String.format("🎯 %s:\n", featureType.name()));
            var placeholders = unifiedPromptService.getSupportedPlaceholders(featureType);
            placeholders.forEach(placeholder -> 
                example.append(String.format("  - {{%s}}\n", placeholder))
            );
            example.append("\n");
        }

        example.append("💡 占位符分类说明:\n");
        example.append("- 内容提供器占位符: full_novel_text, character, scene 等\n");
        example.append("- 参数占位符: input, context, novelTitle 等\n");
        example.append("- 功能特定占位符: styleRequirements, refactorStyle 等\n");

        return example.toString();
    }
} 