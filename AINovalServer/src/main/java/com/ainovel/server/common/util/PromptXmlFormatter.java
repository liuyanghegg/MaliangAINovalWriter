package com.ainovel.server.common.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.dataformat.xml.XmlMapper;
import com.fasterxml.jackson.dataformat.xml.ser.ToXmlGenerator;
import com.ainovel.server.domain.model.Scene;
import com.ainovel.server.domain.model.NovelSettingItem;
import com.ainovel.server.domain.model.NovelSnippet;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;
import java.util.Map;
import java.util.LinkedHashMap;
import java.util.stream.Collectors;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.Comparator;

/**
 * 提示词XML格式化工具类
 * 使用Jackson XML进行正确的XML序列化
 */
@Slf4j
@Component
public class PromptXmlFormatter {

    private final XmlMapper xmlMapper;

    public PromptXmlFormatter() {
        this.xmlMapper = XmlMapper.builder()
                .enable(SerializationFeature.INDENT_OUTPUT)
                .disable(ToXmlGenerator.Feature.WRITE_XML_DECLARATION)
                // 配置序列化规则：不包含null、空字符串、空集合等
                .serializationInclusion(JsonInclude.Include.NON_EMPTY)
                .build();
    }

    /**
     * 公共方法，确保文本内容被换行符包裹，用于XML格式化。
     * 如果文本不为空，此方法会移除其首尾的空白字符，然后在前后各添加一个换行符。
     * @param text 要处理的文本。
     * @return 如果文本为null或仅包含空白，则返回原始文本；否则返回处理后的文本。
     */
    public static String ensureTextIsWrappedWithNewlines(String text) {
        if (text == null || text.trim().isEmpty()) {
            return text;
        }
        // 先trim清除首尾空白，然后包裹换行符
        return "\n" + text.trim() + "\n";
    }

    /**
     * 格式化系统提示词
     */
    public String formatSystemPrompt(String role, String instructions, String context, 
                                   String length, String style, Map<String, Object> parameters) {
        try {
            // 🚀 检查context是否包含XML内容，如果包含则直接构建XML避免转义
            if (context != null && !context.isEmpty() && isXmlContent(context)) {
                return buildSystemPromptXmlDirectly(role, instructions, context, length, style, parameters);
            }
            
            PromptTemplateModel.SystemPrompt.SystemPromptBuilder builder = PromptTemplateModel.SystemPrompt.builder()
                    .role(role)
                    .instructions(ensureTextIsWrappedWithNewlines(instructions));

            // 只在聊天类型时添加上下文到系统提示词
            if (context != null && !context.isEmpty()) {
                builder.context(ensureTextIsWrappedWithNewlines(context));
            }

            if (length != null && !length.isEmpty()) {
                builder.length(length);
            }

            if (style != null && !style.isEmpty()) {
                builder.style(style);
            }

            // 添加参数信息
            if (parameters != null && !parameters.isEmpty()) {
                PromptTemplateModel.SystemPrompt.Parameters.ParametersBuilder paramBuilder = 
                        PromptTemplateModel.SystemPrompt.Parameters.builder();
                
                boolean hasValidParam = false;
                
                if (parameters.containsKey("temperature")) {
                    Object tempValue = parameters.get("temperature");
                    if (tempValue instanceof Number) {
                        paramBuilder.temperature(((Number) tempValue).doubleValue());
                        hasValidParam = true;
                    }
                }
                if (parameters.containsKey("maxTokens")) {
                    Object maxTokensValue = parameters.get("maxTokens");
                    if (maxTokensValue instanceof Number) {
                        paramBuilder.maxTokens(((Number) maxTokensValue).intValue());
                        hasValidParam = true;
                    }
                }
                if (parameters.containsKey("topP")) {
                    Object topPValue = parameters.get("topP");
                    if (topPValue instanceof Number) {
                        paramBuilder.topP(((Number) topPValue).doubleValue());
                        hasValidParam = true;
                    }
                }
                
                // 只有存在有效参数时才设置parameters
                if (hasValidParam) {
                    builder.parameters(paramBuilder.build());
                }
            }

            PromptTemplateModel.SystemPrompt systemPrompt = builder.build();
            String result = xmlMapper.writeValueAsString(systemPrompt);
            
            // 直接返回结果，不做额外处理
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化系统提示词失败: {}", e.getMessage(), e);
            return "";
        }
    }

    /**
     * 格式化用户提示词（任务类型）
     */
    public String formatUserPrompt(String action, String input, String context, 
                                 String length, String style, String tone) {
        try {
            // 🚀 检查context是否包含XML内容，如果包含则直接构建XML避免转义
            if (context != null && !context.isEmpty() && isXmlContent(context)) {
                return buildUserPromptXmlDirectly(action, input, context, length, style, tone);
            }
            
            PromptTemplateModel.UserPrompt.UserPromptBuilder builder = PromptTemplateModel.UserPrompt.builder()
                    .action(action)
                    .input(ensureTextIsWrappedWithNewlines(input));

            // 非聊天类型添加上下文到用户提示词
            if (context != null && !context.isEmpty()) {
                builder.context(ensureTextIsWrappedWithNewlines(context));
            }

            // 添加要求信息
            if ((length != null && !length.isEmpty()) || 
                (style != null && !style.isEmpty()) || 
                (tone != null && !tone.isEmpty())) {
                
                PromptTemplateModel.UserPrompt.Requirements requirements = 
                        PromptTemplateModel.UserPrompt.Requirements.builder()
                                .length(length)
                                .style(style)
                                .tone(tone)
                                .build();
                builder.requirements(requirements);
            }

            PromptTemplateModel.UserPrompt userPrompt = builder.build();
            String result = xmlMapper.writeValueAsString(userPrompt);
            
            // 直接返回结果，不做额外处理
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化用户提示词失败: {}", e.getMessage(), e);
            return "";
        }
    }

    /**
     * 格式化聊天消息
     */
    public String formatChatMessage(String message, String context) {
        try {
            PromptTemplateModel.ChatMessage chatMessage = PromptTemplateModel.ChatMessage.builder()
                    .content(ensureTextIsWrappedWithNewlines(message))
                    .context(ensureTextIsWrappedWithNewlines(context))
                    .build();
            String result = xmlMapper.writeValueAsString(chatMessage);
            
            // 直接返回结果，不做额外处理
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化聊天消息失败: {}", e.getMessage(), e);
            return "";
        }
    }

    /**
     * 格式化小说大纲
     */
    public String formatNovelOutline(String title, String description, List<Scene> scenes) {
        try {
            log.info("开始格式化小说大纲 - 标题: {}, 原始场景数量: {}", title, scenes != null ? scenes.size() : 0);
            
            // 过滤并验证场景数据
            List<Scene> validScenes = (scenes == null ? java.util.List.<Scene>of() : scenes).stream()
                    .filter(scene -> scene != null && 
                                   scene.getId() != null && !scene.getId().trim().isEmpty() &&
                                   scene.getChapterId() != null && !scene.getChapterId().trim().isEmpty())
                    .collect(Collectors.toList());
            
            log.info("过滤后的有效场景数量: {}", validScenes.size());
            
            if (validScenes.isEmpty()) {
                log.warn("没有有效的场景数据，使用回退方案");
                return "";
            }

            // 按章节分组，并保持顺序
            Map<String, List<Scene>> chapterGroups = validScenes.stream()
                    .collect(Collectors.groupingBy(Scene::getChapterId, LinkedHashMap::new, Collectors.toList()));

            log.info("按章节分组后的章节数量: {}", chapterGroups.size());
            for (Map.Entry<String, List<Scene>> entry : chapterGroups.entrySet()) {
                log.debug("章节 {} 包含 {} 个场景", entry.getKey(), entry.getValue().size());
            }

            // 🚀 使用AtomicInteger来为章节分配顺序号
            AtomicInteger chapterNumber = new AtomicInteger(1);
            
            List<PromptTemplateModel.NovelOutline.Chapter> chapters = chapterGroups.entrySet().stream()
                    .map(entry -> {
                        String chapterId = entry.getKey();
                        List<Scene> chapterScenes = entry.getValue();
                        
                        log.debug("处理章节 {} 的 {} 个场景", chapterId, chapterScenes.size());
                        
                        // 🚀 对章节内的场景按sequence排序，然后重新分配顺序号
                        List<Scene> sortedScenes = chapterScenes.stream()
                                .sorted(Comparator.comparing(Scene::getSequence, Comparator.nullsLast(Integer::compareTo)))
                                .collect(Collectors.toList());
                        
                        AtomicInteger sceneNumber = new AtomicInteger(1);
                        List<PromptTemplateModel.NovelOutline.Scene> xmlScenes = sortedScenes.stream()
                                .map(scene -> {
                                    String content = scene.getContent() != null ? 
                                            RichTextUtil.deltaJsonToPlainText(scene.getContent()) : null;
                                    log.debug("场景 {} - 标题: {}, 内容长度: {}", 
                                             scene.getId(), scene.getTitle(), 
                                             content != null ? content.length() : 0);
                                    
                                    return PromptTemplateModel.NovelOutline.Scene.builder()
                                            .title(scene.getTitle())
                                            .number(sceneNumber.getAndIncrement()) // 🚀 使用章节内的顺序号
                                            .id(scene.getId())
                                            .summary(ensureTextIsWrappedWithNewlines(scene.getSummary()))
                                            .content(ensureTextIsWrappedWithNewlines(content))
                                            .build();
                                })
                                .collect(Collectors.toList());

                        return PromptTemplateModel.NovelOutline.Chapter.builder()
                                .id(chapterId)
                                .number(chapterNumber.getAndIncrement()) // 🚀 使用章节顺序号，而不是硬编码的1
                                .scenes(xmlScenes)
                                .build();
                    })
                    .collect(Collectors.toList());

            // 创建一个默认的Act（如果没有Act概念，可以都放在Act 1中）
            PromptTemplateModel.NovelOutline.Act act = PromptTemplateModel.NovelOutline.Act.builder()
                    .number(1)
                    .chapters(chapters)
                    .build();

            PromptTemplateModel.NovelOutline outline = PromptTemplateModel.NovelOutline.builder()
                    .title(title)
                    .description(ensureTextIsWrappedWithNewlines(description))
                    .acts(List.of(act))
                    .build();

            String result = xmlMapper.writeValueAsString(outline);
            log.info("小说大纲格式化完成，最终XML长度: {}", result.length());
                        
            // 直接返回结果，不做额外处理
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化小说大纲失败: {}", e.getMessage(), e);
            return "";
        }
    }

    /**
     * 格式化小说摘要
     */
    public String formatNovelSummary(String title, String description, List<Scene> scenes) {
        try {
            // 过滤并验证场景数据 - 🚀 只保留有摘要的场景以节省token
            List<Scene> validScenes = (scenes == null ? java.util.List.<Scene>of() : scenes).stream()
                    .filter(scene -> scene != null && 
                                   scene.getId() != null && !scene.getId().trim().isEmpty() &&
                                   scene.getChapterId() != null && !scene.getChapterId().trim().isEmpty() &&
                                   scene.getSummary() != null && !scene.getSummary().trim().isEmpty())
                    .collect(Collectors.toList());
            
            if (validScenes.isEmpty()) {
                log.warn("没有有效的场景摘要数据，使用回退方案");
                return "";
            }

            // 按章节分组，并保持顺序
            Map<String, List<Scene>> chapterGroups = validScenes.stream()
                    .collect(Collectors.groupingBy(Scene::getChapterId, LinkedHashMap::new, Collectors.toList()));

            // 🚀 使用AtomicInteger来为章节分配顺序号
            AtomicInteger chapterNumber = new AtomicInteger(1);
            
            List<PromptTemplateModel.NovelSummary.ChapterSummary> chapterSummaries = chapterGroups.entrySet().stream()
                    .map(entry -> {
                        String chapterId = entry.getKey();
                        List<Scene> chapterScenes = entry.getValue();
                        
                        // 🚀 对章节内的场景按sequence排序，然后重新分配顺序号
                        List<Scene> sortedScenes = chapterScenes.stream()
                                .sorted(Comparator.comparing(Scene::getSequence, Comparator.nullsLast(Integer::compareTo)))
                                .collect(Collectors.toList());
                        
                        AtomicInteger sceneNumber = new AtomicInteger(1);
                        List<PromptTemplateModel.NovelSummary.SceneSummary> sceneSummaries = sortedScenes.stream()
                                .map(scene -> PromptTemplateModel.NovelSummary.SceneSummary.builder()
                                        .title(scene.getTitle())
                                        .number(sceneNumber.getAndIncrement()) // 🚀 使用章节内的顺序号
                                        .id(scene.getId())
                                        .content(ensureTextIsWrappedWithNewlines(scene.getSummary()))
                                        .build())
                                .collect(Collectors.toList());

                        return PromptTemplateModel.NovelSummary.ChapterSummary.builder()
                                .id(chapterId)
                                .number(chapterNumber.getAndIncrement()) // 🚀 使用章节顺序号，而不是硬编码的1
                                .scenes(sceneSummaries)
                                .build();
                    })
                    .collect(Collectors.toList());

            PromptTemplateModel.NovelSummary novelSummary = PromptTemplateModel.NovelSummary.builder()
                    .title(title)
                    .description(ensureTextIsWrappedWithNewlines(description))
                    .chapters(chapterSummaries)
                    .build();

            String result = xmlMapper.writeValueAsString(novelSummary);
            
            // 直接返回结果，不做额外处理
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化小说摘要失败: {}", e.getMessage(), e);
            return "";
        }
    }

    /**
     * 格式化章节
     */
    public String formatChapter(String chapterId, Integer chapterNumber, List<Scene> scenes) {
        try {
            // 🚀 过滤有效场景 - 只保留有内容或摘要的场景以节省token
            List<Scene> validScenes = (scenes == null ? java.util.List.<Scene>of() : scenes).stream()
                    .filter(scene -> scene != null && 
                                   scene.getId() != null && !scene.getId().trim().isEmpty() &&
                                   scene.getChapterId() != null && !scene.getChapterId().trim().isEmpty() &&
                                   ((scene.getContent() != null && !scene.getContent().trim().isEmpty()) ||
                                    (scene.getSummary() != null && !scene.getSummary().trim().isEmpty())))
                    .toList();
            
            if (validScenes.isEmpty()) {
                log.warn("章节 {} 没有有效的场景内容", chapterId);
                return "";
            }
            
            // 🚀 对场景按sequence排序，然后重新分配顺序号
            List<Scene> sortedScenes = validScenes.stream()
                    .sorted(Comparator.comparing(Scene::getSequence, Comparator.nullsLast(Integer::compareTo)))
                    .collect(Collectors.toList());
            
            AtomicInteger sceneNumber = new AtomicInteger(1);
            List<PromptTemplateModel.NovelOutline.Scene> xmlScenes = sortedScenes.stream()
                    .map(scene -> PromptTemplateModel.NovelOutline.Scene.builder()
                            .title(scene.getTitle())
                            .number(sceneNumber.getAndIncrement()) // 🚀 使用章节内的顺序号
                            .id(scene.getId())
                            .summary(ensureTextIsWrappedWithNewlines(scene.getSummary() != null ?
                                    RichTextUtil.deltaJsonToPlainText(scene.getSummary()) : null))
                            .content(ensureTextIsWrappedWithNewlines(scene.getContent() != null ? 
                                    RichTextUtil.deltaJsonToPlainText(scene.getContent()) : null))
                            .build())
                    .collect(Collectors.toList());

            PromptTemplateModel.NovelOutline.Chapter chapter = PromptTemplateModel.NovelOutline.Chapter.builder()
                    .id(chapterId)
                    .number(chapterNumber) // 🚀 使用传入的章节号
                    .scenes(xmlScenes)
                    .build();

            String result = xmlMapper.writeValueAsString(chapter);
            
            // 直接返回结果，不做额外处理
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化章节失败: {}", e.getMessage(), e);
            return "";
        }
    }

    /**
     * 格式化场景
     */
    public String formatScene(Scene scene) {
        try {
            // 🚀 检查场景是否有效内容 - 如果既无内容又无摘要，返回空字符串以节省token
            if (scene == null || 
                scene.getId() == null || scene.getId().trim().isEmpty() ||
                ((scene.getContent() == null || scene.getContent().trim().isEmpty()) &&
                 (scene.getSummary() == null || scene.getSummary().trim().isEmpty()))) {
                log.warn("场景无效或无内容，跳过格式化: {}", scene != null ? scene.getId() : "null");
                return "";
            }
            
            PromptTemplateModel.NovelOutline.Scene xmlScene = PromptTemplateModel.NovelOutline.Scene.builder()
                    .title(scene.getTitle())
                    .number(scene.getSequence() != null ? scene.getSequence() : 1) // 🚀 保持原有sequence或使用默认值1
                    .id(scene.getId())
                    .summary(ensureTextIsWrappedWithNewlines(scene.getSummary() != null ?
                            RichTextUtil.deltaJsonToPlainText(scene.getSummary()) : null))
                    .content(ensureTextIsWrappedWithNewlines(scene.getContent() != null ? 
                            RichTextUtil.deltaJsonToPlainText(scene.getContent()) : null))
                    .build();

            String result = xmlMapper.writeValueAsString(xmlScene);
            
            // 直接返回结果，不做额外处理
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化场景失败: {}", e.getMessage(), e);
            return "";
        }
    }

    /**
     * 格式化设定项目
     */
    public String formatSetting(NovelSettingItem setting) {
        try {
            String attributesStr = "";
            String tagsStr = "";
            
            if (setting.getAttributes() != null && !setting.getAttributes().isEmpty()) {
                attributesStr = setting.getAttributes().entrySet().stream()
                        .map(entry -> entry.getKey() + ": " + entry.getValue())
                        .collect(Collectors.joining(", "));
            }
            
            if (setting.getTags() != null && !setting.getTags().isEmpty()) {
                tagsStr = String.join(", ", setting.getTags());
            }

            PromptTemplateModel.SelectedContext.Setting xmlSetting = 
                    PromptTemplateModel.SelectedContext.Setting.builder()
                            .type(setting.getType())
                            .id(setting.getId())
                            .name(setting.getName())
                            .description(ensureTextIsWrappedWithNewlines(setting.getDescription()))
                            .attributes(attributesStr)
                            .tags(tagsStr)
                            .build();

            String result = xmlMapper.writeValueAsString(xmlSetting);
            
            // 直接返回结果，不做额外处理
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化设定失败: {}", e.getMessage(), e);
            return "";
        }
    }

    /**
     * 格式化设定项目（不包含ID属性）
     * 用于设定组/设定类型上下文下隐藏UUID
     */
    public String formatSettingWithoutId(NovelSettingItem setting) {
        try {
            String attributesStr = "";
            String tagsStr = "";
            
            if (setting.getAttributes() != null && !setting.getAttributes().isEmpty()) {
                attributesStr = setting.getAttributes().entrySet().stream()
                        .map(entry -> entry.getKey() + ": " + entry.getValue())
                        .collect(Collectors.joining(", "));
            }
            
            if (setting.getTags() != null && !setting.getTags().isEmpty()) {
                tagsStr = String.join(", ", setting.getTags());
            }

            PromptTemplateModel.SelectedContext.Setting xmlSetting = 
                    PromptTemplateModel.SelectedContext.Setting.builder()
                            .type(setting.getType())
                            // 不设置ID
                            .name(setting.getName())
                            .description(ensureTextIsWrappedWithNewlines(setting.getDescription()))
                            .attributes(attributesStr)
                            .tags(tagsStr)
                            .build();

            String result = xmlMapper.writeValueAsString(xmlSetting);
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化设定(隐藏ID)失败: {}", e.getMessage(), e);
            return "";
        }
    }

    /**
     * 格式化选择的上下文
     */
    public String formatSelectedContext(PromptTemplateModel.SelectedContext context) {
        try {
            String result = xmlMapper.writeValueAsString(context);
            
            // 直接返回结果，不做额外处理
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化选择上下文失败: {}", e.getMessage(), e);
            return "<selected_context>\n  <error>格式化失败</error>\n</selected_context>";
        }
    }

    /**
     * 格式化片段
     */
    public String formatSnippet(NovelSnippet snippet) {
        try {
            String tagsStr = "";
            
            if (snippet.getTags() != null && !snippet.getTags().isEmpty()) {
                tagsStr = String.join(", ", snippet.getTags());
            }

            PromptTemplateModel.Snippet xmlSnippet = PromptTemplateModel.Snippet.builder()
                    .id(snippet.getId())
                    .title(snippet.getTitle())
                    .notes(ensureTextIsWrappedWithNewlines(snippet.getNotes()))
                    .content(ensureTextIsWrappedWithNewlines(snippet.getContent()))
                    .category(snippet.getCategory())
                    .tags(tagsStr)
                    .build();

            String result = xmlMapper.writeValueAsString(xmlSnippet);
            
            // 直接返回结果，不做额外处理
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化片段失败: {}", e.getMessage(), e);
            return "";
        }
    }

    /**
     * 🚀 新增：格式化完整小说文本（包含所有场景的实际内容）
     */
    public String formatFullNovelText(String title, String description, List<Scene> scenes) {
        try {
            log.info("开始格式化完整小说文本 - 标题: {}, 原始场景数量: {}", title, scenes != null ? scenes.size() : 0);
            
            // 过滤有效场景（必须有实际内容） - 🚀 只保留有内容的场景以节省token
            List<Scene> validScenes = (scenes == null ? java.util.List.<Scene>of() : scenes).stream()
                    .filter(scene -> scene != null && 
                                   scene.getId() != null && !scene.getId().trim().isEmpty() &&
                                   scene.getChapterId() != null && !scene.getChapterId().trim().isEmpty() &&
                                   scene.getContent() != null && !scene.getContent().trim().isEmpty())
                    .collect(Collectors.toList());
            
            log.info("过滤后有内容的场景数量: {}", validScenes.size());
            
            if (validScenes.isEmpty()) {
                log.warn("没有有效的场景内容数据");
                return "";
            }

            // 按章节分组，并保持顺序
            Map<String, List<Scene>> chapterGroups = validScenes.stream()
                    .collect(Collectors.groupingBy(Scene::getChapterId, LinkedHashMap::new, Collectors.toList()));

            log.info("按章节分组后的章节数量: {}", chapterGroups.size());

            // 🚀 使用AtomicInteger来为章节分配顺序号
            AtomicInteger chapterNumber = new AtomicInteger(1);
            
            List<PromptTemplateModel.FullNovelText.ChapterContent> chapters = chapterGroups.entrySet().stream()
                    .map(entry -> {
                        String chapterId = entry.getKey();
                        List<Scene> chapterScenes = entry.getValue();
                        
                        log.debug("处理章节 {} 的 {} 个场景", chapterId, chapterScenes.size());
                        
                        // 🚀 对章节内的场景按sequence排序，然后重新分配顺序号
                        List<Scene> sortedScenes = chapterScenes.stream()
                                .sorted(Comparator.comparing(Scene::getSequence, Comparator.nullsLast(Integer::compareTo)))
                                .collect(Collectors.toList());
                        
                        AtomicInteger sceneNumber = new AtomicInteger(1);
                        List<PromptTemplateModel.FullNovelText.SceneContent> xmlScenes = sortedScenes.stream()
                                .map(scene -> {
                                    String content = RichTextUtil.deltaJsonToPlainText(scene.getContent());
                                    log.debug("场景 {} - 标题: {}, 内容长度: {}", 
                                             scene.getId(), scene.getTitle(), 
                                             content != null ? content.length() : 0);
                                    
                                    return PromptTemplateModel.FullNovelText.SceneContent.builder()
                                            .title(scene.getTitle())
                                            .number(sceneNumber.getAndIncrement()) // 🚀 使用章节内的顺序号
                                            .id(scene.getId())
                                            .content(content)
                                            .build();
                                })
                                .collect(Collectors.toList());

                        int currentChapterNumber = chapterNumber.getAndIncrement();
                        return PromptTemplateModel.FullNovelText.ChapterContent.builder()
                                .id(chapterId)
                                .number(currentChapterNumber) // 🚀 使用章节顺序号，而不是硬编码的1
                                .title("第" + currentChapterNumber + "章") // 🚀 动态生成章节标题
                                .scenes(xmlScenes)
                                .build();
                    })
                    .collect(Collectors.toList());

            // 创建一个默认的Act（如果没有Act概念，可以都放在Act 1中）
            PromptTemplateModel.FullNovelText.ActContent act = PromptTemplateModel.FullNovelText.ActContent.builder()
                    .number(1)
                    .title("第一幕")
                    .chapters(chapters)
                    .build();

            PromptTemplateModel.FullNovelText fullNovelText = PromptTemplateModel.FullNovelText.builder()
                    .title(title)
                    .description(description)
                    .acts(List.of(act))
                    .build();

            String result = xmlMapper.writeValueAsString(fullNovelText);
            log.info("完整小说文本格式化完成，最终XML长度: {}", result.length());
                        
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化完整小说文本失败: {}", e.getMessage(), e);
            return "";
        }
    }

    /**
     * 🚀 新增：使用章节顺序映射格式化完整小说文本
     * - 若映射中存在章节顺序，则优先使用映射中的值；否则回退到自增顺序
     * - 场景的 number 仍为章节内自增
     */
    public String formatFullNovelTextUsingChapterOrderMap(String title, String description,
                                                          java.util.List<Scene> scenes,
                                                          java.util.Map<String, Integer> chapterOrderMap,
                                                          boolean includeIds) {
        try {
            log.info("开始格式化完整小说文本(带章节顺序映射) - 标题: {}, 原始场景数量: {}", title, scenes != null ? scenes.size() : 0);

            java.util.List<Scene> validScenes = (scenes == null ? java.util.List.<Scene>of() : scenes).stream()
                    .filter(scene -> scene != null &&
                                   scene.getId() != null && !scene.getId().trim().isEmpty() &&
                                   scene.getChapterId() != null && !scene.getChapterId().trim().isEmpty() &&
                                   scene.getContent() != null && !scene.getContent().trim().isEmpty())
                    .collect(java.util.stream.Collectors.toList());

            if (validScenes.isEmpty()) {
                log.warn("没有有效的场景内容数据");
                return "";
            }

            java.util.Map<String, java.util.List<Scene>> chapterGroups = validScenes.stream()
                    .collect(java.util.stream.Collectors.groupingBy(Scene::getChapterId, java.util.LinkedHashMap::new, java.util.stream.Collectors.toList()));

            java.util.concurrent.atomic.AtomicInteger fallbackChapterNumber = new java.util.concurrent.atomic.AtomicInteger(1);

            java.util.List<com.ainovel.server.common.util.PromptTemplateModel.FullNovelText.ChapterContent> chapters = chapterGroups.entrySet().stream()
                    .map(entry -> {
                        String chapterId = entry.getKey();
                        java.util.List<Scene> chapterScenes = entry.getValue();

                        java.util.List<Scene> sortedScenes = chapterScenes.stream()
                                .sorted(java.util.Comparator.comparing(Scene::getSequence, java.util.Comparator.nullsLast(Integer::compareTo)))
                                .collect(java.util.stream.Collectors.toList());

                        java.util.concurrent.atomic.AtomicInteger sceneNumber = new java.util.concurrent.atomic.AtomicInteger(1);
                        java.util.List<com.ainovel.server.common.util.PromptTemplateModel.FullNovelText.SceneContent> xmlScenes = sortedScenes.stream()
                                .map(scene -> {
                                    String content = RichTextUtil.deltaJsonToPlainText(scene.getContent());
                                    com.ainovel.server.common.util.PromptTemplateModel.FullNovelText.SceneContent.SceneContentBuilder builder =
                                            com.ainovel.server.common.util.PromptTemplateModel.FullNovelText.SceneContent.builder()
                                                    .title(scene.getTitle())
                                                    .number(sceneNumber.getAndIncrement())
                                                    .content(content);
                                    if (includeIds) {
                                        builder.id(scene.getId());
                                    }
                                    return builder.build();
                                })
                                .collect(java.util.stream.Collectors.toList());

                        int mappedOrder = chapterOrderMap != null && chapterOrderMap.containsKey(chapterId)
                                ? chapterOrderMap.get(chapterId)
                                : fallbackChapterNumber.getAndIncrement();

                        com.ainovel.server.common.util.PromptTemplateModel.FullNovelText.ChapterContent.ChapterContentBuilder chapterBuilder =
                                com.ainovel.server.common.util.PromptTemplateModel.FullNovelText.ChapterContent.builder()
                                        .number(mappedOrder)
                                        .title("第" + mappedOrder + "章")
                                        .scenes(xmlScenes);
                        if (includeIds) {
                            chapterBuilder.id(chapterId);
                        }
                        return chapterBuilder.build();
                    })
                    .collect(java.util.stream.Collectors.toList());

            com.ainovel.server.common.util.PromptTemplateModel.FullNovelText.ActContent act = com.ainovel.server.common.util.PromptTemplateModel.FullNovelText.ActContent.builder()
                    .number(1)
                    .title("第一幕")
                    .chapters(chapters)
                    .build();

            com.ainovel.server.common.util.PromptTemplateModel.FullNovelText fullNovelText = com.ainovel.server.common.util.PromptTemplateModel.FullNovelText.builder()
                    .title(title)
                    .description(description)
                    .acts(java.util.List.of(act))
                    .build();

            String result = xmlMapper.writeValueAsString(fullNovelText);
            log.info("完整小说文本(带章节顺序映射)格式化完成，最终XML长度: {}", result.length());
            return result;
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            log.error("格式化完整小说文本(带章节顺序映射)失败: {}", e.getMessage(), e);
            return "";
        }
    }

    /**
     * 🚀 检查字符串是否包含XML内容
     */
    private boolean isXmlContent(String content) {
        if (content == null || content.isEmpty()) {
            return false;
        }
        // 检查是否包含XML标签
        return content.contains("<") && content.contains(">") && 
               (content.contains("</") || content.matches(".*<\\w+[^>]*>.*"));
    }

    /**
     * 🚀 直接构建用户提示词XML，避免context内容被转义
     */
    private String buildUserPromptXmlDirectly(String action, String input, String context, 
                                            String length, String style, String tone) {
        StringBuilder xml = new StringBuilder();
        xml.append("<task>\n");
        
        if (action != null && !action.isEmpty()) {
            xml.append("  <action>\n").append(escapeXmlContent(action)).append("\n  </action>\n");
        }
        
        if (input != null && !input.isEmpty()) {
            xml.append("  <input>\n").append(escapeXmlContent(input)).append("\n  </input>\n");
        }
        
        // 🚀 关键：context内容直接插入，不进行转义
        if (context != null && !context.isEmpty()) {
            xml.append("  <context>\n").append(context).append("\n  </context>\n");
        }
        
        // 添加要求信息
        if ((length != null && !length.isEmpty()) || 
            (style != null && !style.isEmpty()) || 
            (tone != null && !tone.isEmpty())) {
            
            xml.append("  <requirements>\n");
            
            if (length != null && !length.isEmpty()) {
                xml.append("    <length>").append(escapeXmlContent(length)).append("</length>\n");
            }
            
            if (style != null && !style.isEmpty()) {
                xml.append("    <style>").append(escapeXmlContent(style)).append("</style>\n");
            }
            
            if (tone != null && !tone.isEmpty()) {
                xml.append("    <tone>").append(escapeXmlContent(tone)).append("</tone>\n");
            }
            
            xml.append("  </requirements>\n");
        }
        
        xml.append("</task>");
        return xml.toString();
    }

    /**
     * 🚀 直接构建系统提示词XML，避免context内容被转义
     */
    private String buildSystemPromptXmlDirectly(String role, String instructions, String context, 
                                              String length, String style, Map<String, Object> parameters) {
        StringBuilder xml = new StringBuilder();
        xml.append("<system>\n");
        
        if (role != null && !role.isEmpty()) {
            xml.append("  <role>\n").append(escapeXmlContent(role)).append("\n  </role>\n");
        }
        
        if (instructions != null && !instructions.isEmpty()) {
            xml.append("  <instructions>\n").append(escapeXmlContent(instructions)).append("\n  </instructions>\n");
        }
        
        // 🚀 关键：context内容直接插入，不进行转义
        if (context != null && !context.isEmpty()) {
            xml.append("  <context>\n").append(context).append("\n  </context>\n");
        }
        
        if (length != null && !length.isEmpty()) {
            xml.append("  <length>").append(escapeXmlContent(length)).append("</length>\n");
        }
        
        if (style != null && !style.isEmpty()) {
            xml.append("  <style>").append(escapeXmlContent(style)).append("</style>\n");
        }
        
        // 添加参数信息
        if (parameters != null && !parameters.isEmpty()) {
            boolean hasValidParam = false;
            StringBuilder paramXml = new StringBuilder();
            paramXml.append("  <parameters>\n");
            
            if (parameters.containsKey("temperature")) {
                Object tempValue = parameters.get("temperature");
                if (tempValue instanceof Number) {
                    paramXml.append("    <temperature>").append(tempValue).append("</temperature>\n");
                    hasValidParam = true;
                }
            }
            if (parameters.containsKey("maxTokens")) {
                Object maxTokensValue = parameters.get("maxTokens");
                if (maxTokensValue instanceof Number) {
                    paramXml.append("    <max_tokens>").append(maxTokensValue).append("</max_tokens>\n");
                    hasValidParam = true;
                }
            }
            if (parameters.containsKey("topP")) {
                Object topPValue = parameters.get("topP");
                if (topPValue instanceof Number) {
                    paramXml.append("    <top_p>").append(topPValue).append("</top_p>\n");
                    hasValidParam = true;
                }
            }
            
            paramXml.append("  </parameters>\n");
            
            // 只有存在有效参数时才添加parameters
            if (hasValidParam) {
                xml.append(paramXml);
            }
        }
        
        xml.append("</system>");
        return xml.toString();
    }

    /**
     * 🚀 转义XML内容中的特殊字符（除了context字段）
     */
    private String escapeXmlContent(String content) {
        if (content == null) {
            return "";
        }
        return content.replace("&", "&amp;")
                     .replace("<", "&lt;")
                     .replace(">", "&gt;")
                     .replace("\"", "&quot;")
                     .replace("'", "&apos;");
    }

    /**
     * 🚀 新增：格式化Act结构
     */
    public String formatAct(Integer actNumber, String actTitle, String actDescription, List<Scene> scenes) {
        try {
            log.info("开始格式化Act {} - 标题: {}, 原始场景数量: {}", actNumber, actTitle, scenes != null ? scenes.size() : 0);
            
            // 过滤有效场景（必须有实际内容） - 🚀 只保留有内容的场景以节省token
            List<Scene> validScenes = (scenes == null ? java.util.List.<Scene>of() : scenes).stream()
                    .filter(scene -> scene != null && 
                                   scene.getId() != null && !scene.getId().trim().isEmpty() &&
                                   scene.getChapterId() != null && !scene.getChapterId().trim().isEmpty() &&
                                   scene.getContent() != null && !scene.getContent().trim().isEmpty())
                    .collect(Collectors.toList());
            
            log.info("Act {} 过滤后有内容的场景数量: {}", actNumber, validScenes.size());
            
            if (validScenes.isEmpty()) {
                log.warn("Act {} 没有有效的场景内容数据", actNumber);
                return "";
            }

            // 按章节分组，并保持顺序
            Map<String, List<Scene>> chapterGroups = validScenes.stream()
                    .collect(Collectors.groupingBy(Scene::getChapterId, LinkedHashMap::new, Collectors.toList()));

            // 🚀 使用AtomicInteger来为章节分配顺序号
            AtomicInteger chapterNumber = new AtomicInteger(1);
            
            List<PromptTemplateModel.FullNovelText.ChapterContent> chapters = chapterGroups.entrySet().stream()
                    .map(entry -> {
                        String chapterId = entry.getKey();
                        List<Scene> chapterScenes = entry.getValue();
                        
                        // 🚀 对章节内的场景按sequence排序，然后重新分配顺序号
                        List<Scene> sortedScenes = chapterScenes.stream()
                                .sorted(Comparator.comparing(Scene::getSequence, Comparator.nullsLast(Integer::compareTo)))
                                .collect(Collectors.toList());
                        
                        AtomicInteger sceneNumber = new AtomicInteger(1);
                        List<PromptTemplateModel.FullNovelText.SceneContent> xmlScenes = sortedScenes.stream()
                                .map(scene -> {
                                    String content = RichTextUtil.deltaJsonToPlainText(scene.getContent());
                                    
                                    return PromptTemplateModel.FullNovelText.SceneContent.builder()
                                            .title(scene.getTitle())
                                            .number(sceneNumber.getAndIncrement()) // 🚀 使用章节内的顺序号
                                            .id(scene.getId())
                                            .content(content)
                                            .build();
                                })
                                .collect(Collectors.toList());

                        int currentChapterNumber = chapterNumber.getAndIncrement();
                        return PromptTemplateModel.FullNovelText.ChapterContent.builder()
                                .id(chapterId)
                                .number(currentChapterNumber) // 🚀 使用章节顺序号，而不是硬编码的1
                                .title("第" + currentChapterNumber + "章") // 🚀 动态生成章节标题
                                .scenes(xmlScenes)
                                .build();
                    })
                    .collect(Collectors.toList());

            PromptTemplateModel.ActStructure actStructure = PromptTemplateModel.ActStructure.builder()
                    .number(actNumber)
                    .title(actTitle)
                    .description(actDescription)
                    .chapters(chapters)
                    .build();

            String result = xmlMapper.writeValueAsString(actStructure);
            log.info("Act {} 格式化完成，最终XML长度: {}", actNumber, result.length());
                        
            return result;
        } catch (JsonProcessingException e) {
            log.error("格式化Act {}失败: {}", actNumber, e.getMessage(), e);
            return "";
        }
    }

} 