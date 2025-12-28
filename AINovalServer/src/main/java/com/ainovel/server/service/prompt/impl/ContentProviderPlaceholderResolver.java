package com.ainovel.server.service.prompt.impl;

import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.ainovel.server.service.impl.content.ContentProviderFactory;
import com.ainovel.server.service.impl.content.ContentProvider;
import com.ainovel.server.service.impl.content.providers.NovelBasicInfoProvider;
import com.ainovel.server.service.prompt.ContentPlaceholderResolver;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * 基于内容提供器的占位符解析器实现 - 简化版
 * 直接使用ContentProvider的新方法getContentForPlaceholder
 */
@Slf4j
@Component
public class ContentProviderPlaceholderResolver implements ContentPlaceholderResolver {

    @Autowired
    private ContentProviderFactory contentProviderFactory;
    
    @Autowired
    private VirtualThreadPlaceholderResolver virtualThreadResolver;

    @Autowired
    private NovelBasicInfoProvider novelBasicInfoProvider;

    // 占位符匹配模式：{{type}} 或 {{type:id}}
    private static final Pattern PLACEHOLDER_PATTERN = Pattern.compile("\\{\\{([^:}]+)(?::([^}]+))?\\}\\}");

    // 占位符到内容提供器类型的映射
    private static final Map<String, String> PLACEHOLDER_TO_PROVIDER_MAP = Map.ofEntries(
        // 小说相关
        Map.entry("full_novel_text", "full_novel_text"),
        Map.entry("full_novel_summary", "full_novel_summary"),
        
        // 🚀 新增：基本信息和前五章相关占位符
        Map.entry("novel_basic_info", "novel_basic_info"),
        Map.entry("recent_chapters_content", "recent_chapters_content"),
        Map.entry("recent_chapters_summary", "recent_chapters_summary"),
        // 新增固定类型映射
        Map.entry("current_chapter_content", "current_chapter_content"),
        Map.entry("current_scene_content", "current_scene_content"),
        Map.entry("current_chapter_summary", "current_chapter_summary"),
        Map.entry("current_scene_summary", "current_scene_summary"),
        Map.entry("previous_chapters_content", "previous_chapters_content"),
        Map.entry("previous_chapters_summary", "previous_chapters_summary"),
        
        // 结构相关
        Map.entry("act", "act"),
        Map.entry("act_content", "act"), // act_content 映射到 act 提供器
        Map.entry("chapter", "chapter"),
        Map.entry("scene", "scene"),
        
        // 设定相关
        Map.entry("setting", "setting"),
        Map.entry("setting_groups", "setting"),
        Map.entry("settings_by_type", "setting"),
        
        // 片段相关
        Map.entry("snippet", "snippet")
    );

    // 支持的占位符集合
    private static final Set<String> SUPPORTED_PLACEHOLDERS = PLACEHOLDER_TO_PROVIDER_MAP.keySet();

    @Override
    public Mono<String> resolvePlaceholder(String placeholder, Map<String, Object> parameters, 
                                          String userId, String novelId) {
        log.debug("解析占位符: placeholder={}, userId={}, novelId={}", placeholder, userId, novelId);

        // 首先检查是否是小说基本信息相关的占位符
        if (isNovelBasicInfoPlaceholder(placeholder)) {
            return resolveBasicInfoPlaceholder(placeholder, userId, novelId, parameters);
        }

        // 兼容别名：历史模板中的 {{message}} 等同于 {{input}}
        if ("message".equals(placeholder)) {
            Object value = parameters.get("input");
            return Mono.just(value != null ? value.toString() : "");
        }

        // 解析占位符格式 {{type}} 或 {{type:id}}
        Matcher matcher = PLACEHOLDER_PATTERN.matcher("{{" + placeholder + "}}");
        if (!matcher.matches()) {
            // 不是内容提供器占位符格式，直接从parameters中获取
            Object value = parameters.get(placeholder);
            return Mono.just(value != null ? value.toString() : "");
        }

        String type = matcher.group(1);
        String id = matcher.group(2);

        // 检查是否是内容提供器相关的占位符
        if (!PLACEHOLDER_TO_PROVIDER_MAP.containsKey(type)) {
            // 不是内容提供器占位符，直接从parameters中获取
            Object value = parameters.get(placeholder);
            return Mono.just(value != null ? value.toString() : "");
        }

        // 从内容提供器获取内容
        String providerType = PLACEHOLDER_TO_PROVIDER_MAP.get(type);
        return getContentFromProvider(providerType, id, userId, novelId, parameters)
                .onErrorResume(error -> {
                    log.warn("获取占位符内容失败: placeholder={}, error={}", placeholder, error.getMessage());
                    return Mono.just("[内容获取失败: " + placeholder + "]");
                });
    }
    
    /**
     * 解析包含多个占位符的模板 - 使用虚拟线程并行处理
     */
    public Mono<String> resolveTemplate(String template, Map<String, Object> parameters, 
                                       String userId, String novelId) {
        log.debug("使用虚拟线程解析模板: template length={}, userId={}, novelId={}", 
                 template.length(), userId, novelId);
        
        // 委托给VirtualThreadPlaceholderResolver进行并行处理
        return virtualThreadResolver.resolvePlaceholders(template, userId, novelId, parameters);
    }

    @Override
    public boolean supports(String placeholder) {
        // 解析占位符获取类型
        Matcher matcher = PLACEHOLDER_PATTERN.matcher("{{" + placeholder + "}}");
        if (matcher.matches()) {
            String type = matcher.group(1);
            return SUPPORTED_PLACEHOLDERS.contains(type);
        }
        
        // 或者是参数占位符
        return isParameterPlaceholder(placeholder);
    }

    @Override
    public String getPlaceholderDescription(String placeholder) {
        // 解析占位符获取类型
        Matcher matcher = PLACEHOLDER_PATTERN.matcher("{{" + placeholder + "}}");
        if (matcher.matches()) {
            String type = matcher.group(1);
            return switch (type) {
                case "full_novel_text" -> "完整小说文本内容";
                case "full_novel_summary" -> "完整小说摘要";
                case "act" -> "指定幕的内容";
                case "act_content" -> "当前幕的内容";
                case "chapter" -> "指定章节的内容";
                case "scene" -> "指定场景的内容";
                case "setting" -> "小说设定信息";
                case "snippet" -> "指定片段内容";
                default -> "未知占位符: " + placeholder;
            };
        }
        
        return switch (placeholder) {
            case "input" -> "用户输入的内容";
            case "context" -> "上下文信息";
            case "novelTitle" -> "小说标题";
            case "authorName" -> "作者名称";
            case "user_act" -> "用户具体指令和行动";
            default -> "未知占位符: " + placeholder;
        };
    }

    /**
     * 从内容提供器获取内容 - 使用新的简化方法
     */
    private Mono<String> getContentFromProvider(String providerType, String contentId, 
                                               String userId, String novelId, Map<String, Object> parameters) {
        log.debug("从内容提供器获取内容: providerType={}, contentId={}, userId={}, novelId={}",
                 providerType, contentId, userId, novelId);

        // 🔒 过滤逻辑：仅当用户在 contextSelections 中显式选择了该类型时才解析
        @SuppressWarnings("unchecked")
        Set<String> selectedProviderTypes = (Set<String>) parameters.get("selectedProviderTypes");
        if (selectedProviderTypes != null && !selectedProviderTypes.isEmpty()) {
            if (!selectedProviderTypes.contains(providerType.toLowerCase())) {
                log.info("跳过占位符解析，用户未选择此类型: {}", providerType);
                return Mono.just("");
            }
        }

        // 检查内容提供器是否已注册
        if (!contentProviderFactory.hasProvider(providerType)) {
            log.warn("内容提供器未实现: providerType={}", providerType);
            return Mono.just("[内容提供器未实现: " + providerType + "]");
        }

        try {
            // 获取内容提供器
            var providerOptional = contentProviderFactory.getProvider(providerType);
            if (providerOptional.isEmpty()) {
                log.warn("内容提供器获取失败: providerType={}", providerType);
                return Mono.just("[内容提供器不可用: " + providerType + "]");
            }

            ContentProvider provider = providerOptional.get();
            
            // 调用新的简化方法
            return provider.getContentForPlaceholder(userId, novelId, contentId, parameters)
                    .doOnNext(content -> 
                        log.debug("成功获取内容: providerType={}, contentLength={}", providerType, content.length())
                    )
                    .onErrorResume(error -> {
                        log.error("内容提供器执行失败: providerType={}, error={}", providerType, error.getMessage());
                        return Mono.just("[内容获取失败: " + error.getMessage() + "]");
                    });

        } catch (Exception e) {
            log.error("内容提供器调用失败: providerType={}, error={}", providerType, e.getMessage(), e);
            return Mono.just("[内容获取错误: " + e.getMessage() + "]");
        }
    }

    public Set<String> getAvailablePlaceholders() {
        return Set.of(
            // 内容提供器占位符
            "full_novel_text", "full_novel_summary",
            "act", "act_content", "chapter", "scene", "setting", "snippet",
            
            // 基本信息占位符
            "novelTitle", "authorName", "user_act",
            
            // 参数占位符
            "input", "context", 
            "chapterId", "sceneId", "actId", "settingId", "snippetId"
        );
    }

    /**
     * 检查是否是参数占位符
     */
    private boolean isParameterPlaceholder(String placeholder) {
        return Set.of("input", "context", "novelTitle", "authorName", 
                     "chapterId", "sceneId", "actId", "settingId", "snippetId")
                  .contains(placeholder);
    }

    /**
     * 检查是否是小说基本信息占位符
     */
    private boolean isNovelBasicInfoPlaceholder(String placeholder) {
        return Set.of("novelTitle", "authorName", "user_act")
                  .contains(placeholder);
    }

    /**
     * 解析小说基本信息占位符
     */
    private Mono<String> resolveBasicInfoPlaceholder(String placeholder, String userId, 
                                                    String novelId, Map<String, Object> parameters) {
        log.debug("解析基本信息占位符: placeholder={}, userId={}, novelId={}", placeholder, userId, novelId);
        
        if (novelId == null || novelId.isEmpty()) {
            log.warn("novelId为空，无法解析基本信息占位符: {}", placeholder);
            return Mono.just("");
        }

        return switch (placeholder) {
            case "novelTitle" -> novelBasicInfoProvider.getFieldValue(novelId, "title");
            case "authorName" -> novelBasicInfoProvider.getFieldValue(novelId, "author");
            case "user_act" -> {
                // user_act 是用户的具体指令，通常从 parameters 中获取
                Object userAct = parameters.get("user_act");
                yield Mono.just(userAct != null ? userAct.toString() : "");
            }
            default -> {
                log.warn("未知的基本信息占位符: {}", placeholder);
                yield Mono.just("");
            }
        };
    }
} 