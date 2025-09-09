package com.ainovel.server.service.setting;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.service.UniversalAIService;
import com.ainovel.server.service.AIService;
import com.ainovel.server.service.NovelAIService;
import com.ainovel.server.service.NovelService;
import com.ainovel.server.service.NovelSettingService;
import com.ainovel.server.service.ai.AIModelProvider;
import com.ainovel.server.service.setting.generation.SettingGenerationService;
import com.ainovel.server.service.setting.generation.InMemorySessionManager;
import com.ainovel.server.service.PublicModelConfigService;
import com.ainovel.server.domain.model.setting.generation.SettingGenerationSession;
import com.ainovel.server.domain.model.setting.generation.SettingNode;
import com.ainovel.server.service.setting.NovelSettingHistoryService.HistoryWithSettings;
import com.ainovel.server.domain.model.Novel;
import com.ainovel.server.domain.model.NovelSettingItem;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import com.ainovel.server.web.dto.response.UniversalAIResponseDto;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;
import dev.langchain4j.data.message.ChatMessage;
import dev.langchain4j.data.message.SystemMessage;
import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.agent.tool.ToolSpecification;

/**
 * 写作编排服务（基于一个 AIFeatureType 实现大纲/章节/组合）
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SettingComposeService {

    private final UniversalAIService universalAIService;
    private final NovelService novelService;
    private final com.ainovel.server.service.SceneService sceneService;
    private final InMemorySessionManager inMemorySessionManager;
    private final SettingConversionService settingConversionService;
    private final NovelSettingService novelSettingService;
    private final com.ainovel.server.service.setting.NovelSettingHistoryService historyService;
    private final SettingGenerationService settingGenerationService;
    private final ObjectMapper objectMapper;
    private final NovelAIService novelAIService;
    private final AIService aiService;
    private final com.ainovel.server.service.ai.tools.ToolExecutionService toolExecutionService;
    private final com.ainovel.server.service.ai.tools.ToolRegistry toolRegistry;
    private final com.ainovel.server.service.prompt.providers.NovelComposePromptProvider composePromptProvider;
    private final PublicModelConfigService publicModelConfigService;
    private final com.ainovel.server.service.ai.tools.fallback.ToolFallbackRegistry toolFallbackRegistry;

    public Flux<UniversalAIResponseDto> streamCompose(UniversalAIRequestDto request) {
        // 归一化 requestType
        request.setRequestType(AIFeatureType.NOVEL_COMPOSE.name());

        // 先确保 novelId（若无则创建草稿），再尝试把设定会话落库
        Mono<UniversalAIRequestDto> prepared = ensureNovelIdIfNeeded(request)
                .flatMap(req -> tryConvertSettingsFromSession(req).thenReturn(req));

        // 提前发送一次绑定信号，保证前端能尽早拿到 novelId / sessionId（最后仍会再发一次最终状态）
        return prepared.flatMapMany(preq -> {
            log.info("[Compose] prepared: userId={}, settingSessionId={}, sessionId={}, novelId={}",
                    preq.getUserId(), preq.getSettingSessionId(), preq.getSessionId(), preq.getNovelId());
            Flux<UniversalAIResponseDto> preBind = bindNovelToSessionAndSignal(preq.getNovelId(), preq.getSettingSessionId())
                    .doOnNext(chunk -> {
                        try {
                            Map<String, Object> m = chunk.getMetadata();
                            Object bind = m != null ? m.get("composeBind") : null;
                            Object status = m != null ? m.get("composeBindStatus") : null;
                            Object ready = m != null ? m.get("composeReady") : null;
                            log.info("[Compose] preBind emitted: bind={}, status={}, ready={}", bind, status, ready);
                        } catch (Exception ignore) {}
                    })
                    .flux();
            return Flux.concat(preBind, streamWithPrepared(preq));
        });
    }

    // ==================== 开始写作编排（无会话可直接从历史恢复） ====================
    public Mono<String> orchestrateStartWriting(String userId, String username, String sessionId, String novelId, String historyId) {
        return ensureNovelIdForStart(userId, username, novelId, sessionId, historyId)
            .flatMap(nid -> performSaveOrRestore(userId, sessionId, historyId, nid)
                .then(markNovelReady(nid))
                .thenReturn(nid)
            );
    }

    private Mono<String> ensureNovelIdForStart(String userId, String username, String providedNovelId, String sessionId, String historyId) {
        if (providedNovelId != null && !providedNovelId.isEmpty()) {
            try { log.info("[开始写作/服务] 使用传入 novelId: {}", providedNovelId); } catch (Exception ignore) {}
            return Mono.just(providedNovelId);
        }
        Mono<String> fromSession = Mono.defer(() -> {
            if (sessionId == null || sessionId.isEmpty()) return Mono.empty();
            return inMemorySessionManager.getSession(sessionId)
                .flatMap(s -> Mono.justOrEmpty(s.getNovelId()))
                .filter(id -> !id.isEmpty());
        });
        Mono<String> createDraft = Mono.defer(() -> {
            try { log.info("[开始写作/服务] 未提供 novelId，准备创建草稿小说"); } catch (Exception ignore) {}
            Novel draft = new Novel();
            draft.setTitle("未命名小说");
            draft.setDescription("自动创建的草稿，用于写作编排");
            Novel.Author author = Novel.Author.builder().id(userId).username(username != null ? username : userId).build();
            draft.setAuthor(author);
            return novelService.createNovel(draft).map(Novel::getId);
        });
        // 历史记录仅提供设定树信息，不再参与 novelId 的确定
        return fromSession.switchIfEmpty(createDraft);
    }

    private Mono<Void> performSaveOrRestore(String userId, String sessionId, String historyId, String novelId) {
        // 优先保存当前会话节点；仅当会话不存在或无节点且显式传入 historyId 时，从历史恢复设定树
        if (sessionId != null && !sessionId.isEmpty()) {
            return inMemorySessionManager.getSession(sessionId)
                    .flatMap(sess -> {
                        boolean hasNodes = false;
                        try {
                            hasNodes = sess.getGeneratedNodes() != null && !sess.getGeneratedNodes().isEmpty();
                        } catch (Exception ignore) {}

                        Mono<Void> opMono;
                        if (hasNodes) {
                            try { log.info("[开始写作/服务] 会话存在且有生成节点，直接保存为小说设定: sessionId={}, novelId={}", sessionId, novelId); } catch (Exception ignore) {}
                            // 直接将会话的生成节点转换并保存到当前 novelId（不依赖会话完成状态）
                            java.util.List<NovelSettingItem> items = settingConversionService.convertSessionToSettingItems(sess, novelId);
                            try { log.info("[开始写作/服务] 将保存设定条目数量: {}", (items != null ? items.size() : 0)); } catch (Exception ignore) {}
                            opMono = novelSettingService.saveAll(items).then();
                        } else if (historyId != null && !historyId.isEmpty()) {
                            try { log.info("[开始写作/服务] 会话无节点，使用显式 historyId 进行历史拷贝: {}", historyId); } catch (Exception ignore) {}
                            opMono = restoreFromHistoryStrict(userId, historyId, novelId);
                        } else {
                            try { log.info("[开始写作/服务] 会话无节点且未提供 historyId，跳过保存/恢复"); } catch (Exception ignore) {}
                            // 无可保存/恢复的数据，直接跳过
                            opMono = Mono.empty();
                        }

                        return opMono.then(
                                inMemorySessionManager.getSession(sessionId)
                                        .flatMap(s -> {
                                            s.setNovelId(novelId);
                                            return inMemorySessionManager.saveSession(s);
                                        })
                                        .onErrorResume(e -> {
                                            log.warn("[Compose] 绑定 novelId 到会话失败: sessionId={}, novelId={}, err={}", sessionId, novelId, e.getMessage());
                                            return Mono.empty();
                                        })
                                        .then()
                        );
                    })
                    .switchIfEmpty(Mono.defer(() -> {
                        // 会话不存在：显式提供 historyId 则恢复；否则尝试将 sessionId 视为 historyId 恢复
                        if (historyId != null && !historyId.isEmpty()) {
                            try { log.info("[开始写作/服务] 无会话，使用显式 historyId 进行历史拷贝: {}", historyId); } catch (Exception ignore) {}
                            return restoreFromHistoryStrict(userId, historyId, novelId);
                        }
                        if (sessionId != null && !sessionId.isEmpty()) {
                            try { log.info("[开始写作/服务] 无会话，尝试将 sessionId 当作 historyId 进行历史拷贝: {}", sessionId); } catch (Exception ignore) {}
                            return restoreFromHistoryStrict(userId, sessionId, novelId);
                        }
                        return Mono.empty();
                    }));
        }
        // 无 sessionId：仅在显式提供 historyId 时进行恢复
        if (historyId != null && !historyId.isEmpty()) {
            try { log.info("[开始写作/服务] 无 sessionId，使用显式 historyId 进行历史拷贝: {}", historyId); } catch (Exception ignore) {}
            return restoreFromHistoryStrict(userId, historyId, novelId);
        }
        return Mono.empty();
    }

    private Mono<Void> restoreFromHistoryStrict(String userId, String historyId, String novelId) {
        if (userId == null || userId.isEmpty()) {
            return Mono.error(new RuntimeException("UNAUTHORIZED"));
        }
        return historyService.getHistoryById(historyId)
            .flatMap(h -> {
                if (!userId.equals(h.getUserId())) {
                    return Mono.error(new RuntimeException("无权限恢复此历史记录"));
                }
                // 使用直接拷贝实现，避免无谓的 SettingNode 往返转换
                try { log.info("[开始写作/服务] 历史拷贝：historyId={} -> novelId={}", historyId, novelId); } catch (Exception ignore) {}
                return historyService.copyHistoryItemsToNovel(historyId, novelId, userId).then();
            });
    }

    private Mono<Void> markNovelReady(String novelId) {
        // 仅更新就绪标记，显式避免携带结构字段，防止触发结构合并
        Novel patch = new Novel();
        patch.setId(novelId);
        patch.setIsReady(true);
        // 显式置空结构，确保不会因为默认builder值而传入空结构
        patch.setStructure(null);
        return novelService.updateNovel(novelId, patch).then();
    }

    public Mono<Map<String, Object>> getStatusLite(String id) {
        return inMemorySessionManager.getSession(id)
            .map(sess -> {
                Map<String, Object> body = new java.util.HashMap<>();
                body.put("type", "session");
                body.put("exists", true);
                body.put("status", sess.getStatus().name());
                return body;
            })
            .switchIfEmpty(
                historyService.getHistoryById(id)
                    .map(h -> {
                        Map<String, Object> body = new java.util.HashMap<>();
                        body.put("type", "history");
                        body.put("exists", true);
                        return body;
                    })
                    .onErrorResume(err -> Mono.fromSupplier(() -> {
                        Map<String, Object> body = new java.util.HashMap<>();
                        body.put("type", "none");
                        body.put("exists", false);
                        return body;
                    }))
            );
    }

    private Flux<UniversalAIResponseDto> streamWithPrepared(UniversalAIRequestDto request) {
        String mode = getParam(request, "mode", "outline");

        if ("outline".equalsIgnoreCase(mode)) {
            Mono<Boolean> isPublicMono = isPublicComposeModel(request);
            return isPublicMono.flatMapMany(isPublic -> {
                Mono<List<String>> blocksMono;
                if (Boolean.TRUE.equals(isPublic)) {
                    // 公共模型：改为文本流路径，触发统一扣费
                    blocksMono = generateOutlinesWithTextPublicModelBlocks(request).cache();
                } else {
                    // 用户模型：沿用工具路径
                    blocksMono = generateOutlinesWithTools(request).map(items -> {
                        List<String> blocks = new ArrayList<>();
                        for (int i = 0; i < items.size(); i++) {
                            var it = items.get(i);
                            String title = it.getTitle() != null ? it.getTitle() : defaultChapterTitle(i + 1);
                            String summary = it.getSummary() != null ? it.getSummary() : "";
                            blocks.add(title + "\n" + summary);
                        }
                        return blocks;
                    }).cache();
                }

                Mono<UniversalAIResponseDto> afterMono = blocksMono.flatMap(blocks -> {
                    String novelId = request.getNovelId();
                    List<Mono<Void>> saves = new ArrayList<>();
                    for (int i = 0; i < blocks.size(); i++) {
                        String block = blocks.get(i);
                        String title = defaultChapterTitle(i + 1);
                        String outlineSummary = block.contains("\n") ? block.substring(block.indexOf("\n") + 1) : block;
                        if (novelId != null && !novelId.isEmpty()) {
                            saves.add(saveChapter(novelId, title, outlineSummary, ""));
                        }
                    }
                    Mono<Void> all = saves.isEmpty() ? Mono.empty() : reactor.core.publisher.Flux.fromIterable(saves).concatMap(m -> m).then();
                    Mono<UniversalAIResponseDto> bindChunk = bindNovelToSessionAndSignal(novelId, request.getSettingSessionId());
                    // 在保存完成后同步刷新字数统计，再发送绑定信号
                    Mono<UniversalAIResponseDto> tail = (novelId != null && !novelId.isEmpty())
                            ? novelService.updateNovelWordCount(novelId).then(bindChunk)
                            : bindChunk;
                    return all.then(tail);
                });

                Flux<UniversalAIResponseDto> outlinesJsonFlux = blocksMono
                        .map(blocks -> buildOutlinesMetadata(blocks))
                        .map(meta -> buildSystemChunkWithMetadata(AIFeatureType.NOVEL_COMPOSE.name(), meta))
                        .flux();

                return Flux.concat(outlinesJsonFlux, afterMono.flux());
            });
        }
        if ("chapters".equalsIgnoreCase(mode)) {
            AtomicReference<StringBuilder> buffer = new AtomicReference<>(new StringBuilder());
            Mono<String> wholeTreeContextMono = maybeBuildWholeSettingTreeContext(request);
            Flux<UniversalAIResponseDto> stream = wholeTreeContextMono.flatMapMany(ctx -> {
                try { log.info("[Compose][Context] Chapters mode ctx.length={}", (ctx != null ? ctx.length() : -1)); } catch (Exception ignore) {}
                UniversalAIRequestDto reqWithCtx = (ctx != null && !ctx.isBlank())
                        ? cloneWithParam(request, Map.of("context", ctx))
                        : request;
                // 若公共模型，确保注入扣费标记（Normalizer 在 buildAIRequest 中也会执行一遍，双保险）
                try {
                    com.ainovel.server.service.billing.PublicModelBillingNormalizer.normalize(
                        reqWithCtx,
                        true,
                        true,
                        AIFeatureType.NOVEL_COMPOSE.name(),
                        resolveModelConfigId(reqWithCtx),
                        null,
                        null,
                        reqWithCtx.getSettingSessionId() != null ? reqWithCtx.getSettingSessionId() : reqWithCtx.getSessionId(),
                        null
                    );
                } catch (Exception ignore) {}
                return universalAIService.processStreamRequest(reqWithCtx)
                        .doOnNext(evt -> {
                            if (evt != null && evt.getContent() != null) {
                                buffer.get().append(evt.getContent());
                            }
                        });
            });

            Mono<UniversalAIResponseDto> postMono = Mono.defer(() -> {
                try {
                    String novelId = request.getNovelId();
                    int expected = getIntParam(request, "chapterCount", 3);
                    List<ChapterPiece> pieces = parseChapters(buffer.get().toString(), expected);
                    List<Mono<Void>> saves = new ArrayList<>();
                    for (int i = 0; i < pieces.size(); i++) {
                        ChapterPiece piece = pieces.get(i);
                        String outlineText = piece.outline != null ? piece.outline : "";
                        String title = piece.title != null && !piece.title.isEmpty() ? piece.title : defaultChapterTitle(i + 1);
                        String content = piece.content != null ? piece.content : "";
                        if (novelId != null && !novelId.isEmpty()) {
                            saves.add(saveChapter(novelId, title, outlineText, content));
                        }
                    }
                    Mono<Void> all = saves.isEmpty() ? Mono.empty() : reactor.core.publisher.Flux.fromIterable(saves).concatMap(m -> m).then();
                    Mono<UniversalAIResponseDto> bindChunk = bindNovelToSessionAndSignal(novelId, request.getSettingSessionId());
                    // 在保存完成后同步刷新字数统计，再发送绑定信号
                    Mono<UniversalAIResponseDto> tail = (novelId != null && !novelId.isEmpty())
                            ? novelService.updateNovelWordCount(novelId).then(bindChunk)
                            : bindChunk;
                    return all.then(tail);
                } catch (Exception e) {
                    log.warn("[Compose] 仅章节模式后处理失败: {}", e.getMessage());
                    return Mono.empty();
                }
            });

            return Flux.concat(stream, postMono.flux());
        }

        if ("outline_plus_chapters".equalsIgnoreCase(mode)) {
            // 1) 先大纲（公共模型→文本流；用户模型→工具）
            UniversalAIRequestDto outlineReq = cloneWithParam(request, Map.of("mode", "outline"));
            Mono<Boolean> isPublicMono = isPublicComposeModel(outlineReq);

            // 转换为字符串块供后续章节生成使用："标题\n摘要"（缓存，防止多订阅）
            Mono<List<String>> outlinesMono = isPublicMono.flatMap(isPublic -> {
                if (Boolean.TRUE.equals(isPublic)) {
                    return generateOutlinesWithTextPublicModelBlocks(outlineReq);
                }
                return generateOutlinesWithTools(outlineReq).map(items -> {
                    List<String> blocks = new ArrayList<>();
                    for (int i = 0; i < items.size(); i++) {
                        var it = items.get(i);
                        String title = it.getTitle() != null ? it.getTitle() : defaultChapterTitle(i + 1);
                        String summary = it.getSummary() != null ? it.getSummary() : "";
                        blocks.add(title + "\n" + summary);
                    }
                    return blocks;
                });
            }).cache();

            // 将大纲块作为结构化元数据发给前端
            Flux<UniversalAIResponseDto> outlinesJsonFlux = outlinesMono
                    .map(outlines -> buildOutlinesMetadata(outlines))
                    .map(meta -> buildSystemChunkWithMetadata(AIFeatureType.NOVEL_COMPOSE.name(), meta))
                    .flux();

            Mono<String> wholeTreeContextMono = maybeBuildWholeSettingTreeContext(request);
            Flux<UniversalAIResponseDto> chaptersFlux = outlinesMono.flatMapMany(outlines -> {
                List<Flux<UniversalAIResponseDto>> perChapter = new ArrayList<>();
                StringBuilder prevSummary = new StringBuilder();
                // 缓存每章正文以便完成后统一入库
                List<StringBuilder> chapterBuffers = new ArrayList<>();
                return wholeTreeContextMono.flatMapMany(ctx -> {
                    try { log.info("[Compose][Context] Outline+Chapters mode ctx.length={}", (ctx != null ? ctx.length() : -1)); } catch (Exception ignore) {}
                    for (int i = 0; i < outlines.size(); i++) {
                        String outlineText = outlines.get(i);
                        int chapterIndex = i + 1;
                        chapterBuffers.add(new StringBuilder());
                        final int currentIndex = i;
                        // 使用 SUMMARY_TO_SCENE 生成章节正文：将单章大纲作为输入
                        UniversalAIRequestDto s2sReq = cloneWithParam(request, Map.of(
                                "chapterIndex", chapterIndex,
                                "outlineText", outlineText,
                                "previousChaptersSummary", prevSummary.toString()
                        ));
                        // 切换功能类型为 SUMMARY_TO_SCENE，并将大纲作为 prompt 传入
                        s2sReq.setRequestType(AIFeatureType.SUMMARY_TO_SCENE.name());
                        s2sReq.setPrompt(outlineText);
                        // 注入整棵设定树上下文
                        if (ctx != null && !ctx.isBlank()) {
                            s2sReq.getParameters().put("context", ctx);
                        }
                        // 若前端传入 s2sTemplateId，则映射为本次 S2S 请求的 promptTemplateId
                        if (request.getParameters() != null && request.getParameters().get("s2sTemplateId") instanceof String) {
                            String s2sTemplateId = (String) request.getParameters().get("s2sTemplateId");
                            if (s2sTemplateId != null && !s2sTemplateId.isEmpty()) {
                                s2sReq.getParameters().put("promptTemplateId", s2sTemplateId);
                            }
                        }

                        // 在章节正文开始前，先向前端输出章节大纲与正文起始的标记，便于前端解析展示
                        Flux<UniversalAIResponseDto> preOutline = Flux.just(
                                buildSystemChunk(AIFeatureType.SUMMARY_TO_SCENE.name(),
                                        "[CHAPTER_" + chapterIndex + "_OUTLINE]\n" + outlineText + "\n"));
                        Flux<UniversalAIResponseDto> preContentStart = Flux.just(
                                buildSystemChunk(AIFeatureType.SUMMARY_TO_SCENE.name(),
                                        "[CHAPTER_" + chapterIndex + "_CONTENT]"));

                        try {
                            com.ainovel.server.service.billing.PublicModelBillingNormalizer.normalize(
                                s2sReq,
                                true,
                                true,
                                AIFeatureType.NOVEL_COMPOSE.name(),
                                resolveModelConfigId(s2sReq),
                                null,
                                null,
                                s2sReq.getSettingSessionId() != null ? s2sReq.getSettingSessionId() : s2sReq.getSessionId(),
                                null
                            );
                        } catch (Exception ignore) {}
                        Flux<UniversalAIResponseDto> chapterStream = universalAIService.processStreamRequest(s2sReq)
                                .doOnNext(evt -> {
                                    if (evt != null && evt.getContent() != null) {
                                        chapterBuffers.get(currentIndex).append(evt.getContent());
                                    }
                                })
                                .doOnComplete(() -> {
                                    // 聚合摘要
                                    prevSummary.append("\n").append(outlineText);
                                });
                        // 顺序：大纲标签 → 正文开始标签 → 正文流
                        perChapter.add(Flux.concat(preOutline, preContentStart, chapterStream));
                    }
                    int concurrency = Math.max(1, getIntParam(request, "concurrency", 3));
                    Flux<UniversalAIResponseDto> merged = (concurrency <= 1)
                            ? Flux.concat(perChapter)
                            : Flux.fromIterable(perChapter).flatMapSequential(stream -> stream, concurrency);
                    // 统一在所有章节流完成后进行保存与绑定
                    Mono<UniversalAIResponseDto> tail = merged.ignoreElements().then(Mono.defer(() -> {
                        String novelId = request.getNovelId();
                        if (novelId != null && !novelId.isEmpty()) {
                            List<Mono<Void>> saves = new ArrayList<>();
                            for (int i = 0; i < outlines.size(); i++) {
                                String outlineText = outlines.get(i);
                                String content = chapterBuffers.get(i).toString();
                                String chapterTitle = defaultChapterTitle(i + 1);
                                saves.add(saveChapter(novelId, chapterTitle, outlineText, content));
                            }
                            Mono<Void> all = saves.isEmpty() ? Mono.empty() : reactor.core.publisher.Flux.fromIterable(saves).concatMap(m -> m).then();
                            // 在保存完成后同步刷新字数统计，再发送绑定信号
                            return all
                                    .then(novelService.updateNovelWordCount(novelId))
                                    .then(bindNovelToSessionAndSignal(novelId, request.getSettingSessionId()));
                        }
                        return bindNovelToSessionAndSignal(null, request.getSettingSessionId());
                    }));
                    return Flux.concat(merged, tail.flux());
                });
            });

            return Flux.concat(outlinesJsonFlux, chaptersFlux);
        }

        // 兜底：按普通流式处理
        return universalAIService.processStreamRequest(request);
    }

    /**
     * 异步保存章节：创建章节并创建一个初始场景，摘要写入summary，正文写入content
     */
    private void saveChapterAsync(String novelId, String chapterTitle, String outlineSummary, String chapterContent) {
        saveChapter(novelId, chapterTitle, outlineSummary, chapterContent).subscribe();
    }

    private Mono<Void> saveChapter(String novelId, String chapterTitle, String outlineSummary, String chapterContent) {
        try {
            return novelService.addChapterWithInitialScene(novelId, chapterTitle, outlineSummary, "场景 1")
                    .flatMap(info -> novelService.updateSceneContent(novelId, info.getChapterId(), info.getSceneId(), chapterContent))
                    .then();
        } catch (Exception e) {
            log.warn("保存章节失败: {}", e.getMessage());
            return Mono.empty();
        }
    }

    private String defaultChapterTitle(int index) { return "第" + index + "章"; }

    private static class ChapterPiece {
        String title;
        String outline;
        String content;
    }

    /**
     * 尝试从带有 [CHAPTER_i_OUTLINE] / [CHAPTER_i_CONTENT] 标签的文本中解析章节块；
     * 若无标签，则按空行分段作为回退。
     */
    private List<ChapterPiece> parseChapters(String text, int expected) {
        List<ChapterPiece> result = new ArrayList<>();
        if (text == null || text.isEmpty()) return result;

        try {
            // 基于标签的解析
            for (int i = 1; i <= expected; i++) {
                String outlineTag = "[CHAPTER_" + i + "_OUTLINE]";
                String contentTag = "[CHAPTER_" + i + "_CONTENT]";
                int outlinePos = text.indexOf(outlineTag);
                int contentPos = text.indexOf(contentTag);
                int nextOutlinePos = text.indexOf("[CHAPTER_" + (i + 1) + "_OUTLINE]");

                if (outlinePos >= 0 && contentPos >= 0) {
                    int outlineStart = outlinePos + outlineTag.length();
                    int outlineEnd = contentPos;
                    int contentStart = contentPos + contentTag.length();
                    int contentEnd = nextOutlinePos > 0 ? nextOutlinePos : text.length();

                    String outlineText = safeTrim(text.substring(outlineStart, Math.max(outlineStart, outlineEnd)));
                    String contentText = safeTrim(text.substring(contentStart, Math.max(contentStart, contentEnd)));

                    ChapterPiece cp = new ChapterPiece();
                    cp.outline = outlineText;
                    cp.content = contentText;
                    cp.title = defaultChapterTitle(i);
                    result.add(cp);
                }
            }
        } catch (Exception ignore) {
        }

        // 回退：按空行拆成 expected 段，每段第一行做标题，余下作为正文
        if (result.isEmpty()) {
            String[] blocks = text.split("\n\n+");
            List<String> clean = new ArrayList<>();
            for (String b : blocks) {
                String t = b.trim();
                if (!t.isEmpty()) clean.add(t);
                if (clean.size() >= expected) break;
            }
            for (int i = 0; i < clean.size() && i < expected; i++) {
                String block = clean.get(i);
                String[] lines = block.split("\n", 2);
                ChapterPiece cp = new ChapterPiece();
                cp.title = safeTrim(lines[0]);
                cp.content = lines.length > 1 ? safeTrim(lines[1]) : "";
                cp.outline = "";
                result.add(cp);
            }
        }

        if (result.size() > expected) return result.subList(0, expected);
        return result;
    }

    private String safeTrim(String s) { return s == null ? "" : s.trim(); }

    private Mono<UniversalAIRequestDto> ensureNovelIdIfNeeded(UniversalAIRequestDto req) {
        boolean isCompose;
        try { isCompose = AIFeatureType.valueOf(req.getRequestType()) == AIFeatureType.NOVEL_COMPOSE; }
        catch (Exception ignore) { isCompose = false; }
        if (!isCompose) {
            return Mono.just(req);
        }

        // 识别 fork / reuseNovel 标志（默认 fork=true：强制新建小说）
        boolean fork = false;
        boolean reuseNovel = false;
        try {
            Object f = req.getParameters() != null ? req.getParameters().get("fork") : null;
            Object r = req.getParameters() != null ? req.getParameters().get("reuseNovel") : null;
            fork = parseBooleanFlag(f).orElse(false); // compose 默认不主动fork，除非前端传入
            reuseNovel = parseBooleanFlag(r).orElse(false);
        } catch (Exception ignore) {}

        Mono<UniversalAIRequestDto> ensureNovelMono;
        if (!fork && req.getNovelId() != null && !req.getNovelId().isEmpty()) {
            ensureNovelMono = Mono.just(req);
        } else {
            // 当 fork=true 或本次未携带 novelId 时，创建草稿
            Novel draft = new Novel();
            draft.setTitle("未命名小说");
            draft.setDescription("自动创建的草稿，用于写作编排");
            Novel.Author author = Novel.Author.builder().id(req.getUserId()).username(req.getUserId()).build();
            draft.setAuthor(author);
            ensureNovelMono = novelService.createNovel(draft)
                    .map(created -> { req.setNovelId(created.getId()); return req; })
                    .onErrorResume(e -> {
                        log.warn("创建草稿小说失败，继续无novelId流程: {}", e.getMessage());
                        return Mono.just(req);
                    });
        }

        // 在编排开始时，将 novelId 绑定到设定会话（优先 settingSessionId，回退使用 sessionId）
        return ensureNovelMono.flatMap(updated -> {
            String settingSessionId = updated.getSettingSessionId();
            String novelId = updated.getNovelId();
            if (novelId == null || novelId.isEmpty()) {
                return Mono.just(updated);
            }
            String sessionIdForBind = (settingSessionId != null && !settingSessionId.isEmpty())
                    ? settingSessionId
                    : updated.getSessionId();
            if (sessionIdForBind == null || sessionIdForBind.isEmpty()) {
                return Mono.just(updated);
            }
            return inMemorySessionManager.getSession(sessionIdForBind)
                    .flatMap(session -> {
                        session.setNovelId(novelId);
                        return inMemorySessionManager.saveSession(session);
                    })
                    .onErrorResume(e -> {
                        log.warn("绑定 novelId 到会话失败: sessionId={}, novelId={}, err={}", sessionIdForBind, novelId, e.getMessage());
                        return Mono.empty();
                    })
                    .thenReturn(updated);
        });
    }

    private java.util.Optional<Boolean> parseBooleanFlag(Object val) {
        if (val == null) return java.util.Optional.empty();
        if (val instanceof Boolean b) return java.util.Optional.of(b);
        if (val instanceof String s) {
            String t = s.trim().toLowerCase();
            if ("true".equals(t) || "1".equals(t) || "yes".equals(t) || "y".equals(t)) return java.util.Optional.of(Boolean.TRUE);
            if ("false".equals(t) || "0".equals(t) || "no".equals(t) || "n".equals(t)) return java.util.Optional.of(Boolean.FALSE);
        }
        return java.util.Optional.empty();
    }

    private Mono<Void> tryConvertSettingsFromSession(UniversalAIRequestDto req) {
        boolean isCompose;
        try { isCompose = AIFeatureType.valueOf(req.getRequestType()) == AIFeatureType.NOVEL_COMPOSE; }
        catch (Exception ignore) { isCompose = false; }
        if (!isCompose) return Mono.empty();
        String novelId = req.getNovelId();
        String sessionId = req.getSettingSessionId();
        if (novelId == null || novelId.isEmpty() || sessionId == null || sessionId.isEmpty()) {
            return Mono.empty();
        }
        return inMemorySessionManager.getSession(sessionId)
                .flatMapMany(session -> {
                    java.util.List<NovelSettingItem> items = settingConversionService.convertSessionToSettingItems(session, novelId);
                    return novelSettingService.saveAll(items);
                })
                .then();
    }

    private String getParam(UniversalAIRequestDto req, String key, String def) {
        if (req.getParameters() != null) {
            Object val = req.getParameters().get(key);
            if (val instanceof String) return (String) val;
        }
        return def;
    }

    private int getIntParam(UniversalAIRequestDto req, String key, int def) {
        if (req.getParameters() != null) {
            Object val = req.getParameters().get(key);
            if (val instanceof Number) return ((Number) val).intValue();
        }
        return def;
    }

    private UniversalAIRequestDto cloneWithParam(UniversalAIRequestDto origin, Map<String, Object> patch) {
        UniversalAIRequestDto clone = UniversalAIRequestDto.builder()
                .requestType(origin.getRequestType())
                .userId(origin.getUserId())
                .sessionId(origin.getSessionId())
                .settingSessionId(origin.getSettingSessionId())
                .novelId(origin.getNovelId())
                .sceneId(origin.getSceneId())
                .chapterId(origin.getChapterId())
                .modelConfigId(origin.getModelConfigId())
                .prompt(origin.getPrompt())
                .instructions(origin.getInstructions())
                .selectedText(origin.getSelectedText())
                .contextSelections(origin.getContextSelections())
                .parameters(origin.getParameters() != null ? new java.util.HashMap<>(origin.getParameters()) : new java.util.HashMap<>())
                .metadata(origin.getMetadata() != null ? new java.util.HashMap<>(origin.getMetadata()) : new java.util.HashMap<>())
                .build();
        clone.getParameters().putAll(patch);
        return clone;
    }

    // =============== 公共模型辅助 ===============
    private Mono<Boolean> isPublicComposeModel(UniversalAIRequestDto req) {
        String modelConfigId = req.getModelConfigId();
        if ((modelConfigId == null || modelConfigId.isEmpty()) && req.getMetadata() != null) {
            Object mid = req.getMetadata().get("modelConfigId");
            if (mid instanceof String s && !s.isEmpty()) {
                modelConfigId = s;
            }
        }
        if (modelConfigId == null || modelConfigId.isEmpty()) return Mono.just(Boolean.FALSE);
        // 直接按ID查公共模型配置，查到即公共
        return publicModelConfigService.findById(modelConfigId)
                .map(cfg -> Boolean.TRUE)
                .defaultIfEmpty(Boolean.FALSE)
                .onErrorReturn(Boolean.FALSE);
    }

    

    private Mono<List<String>> generateOutlinesWithTextPublicModelBlocks(UniversalAIRequestDto request) {
        // 基于通用流式文本生成大纲，并按 "标题\n摘要" 组装
        UniversalAIRequestDto textReq = cloneWithParam(request, Map.of("mode", "outline"));
        try {
            com.ainovel.server.service.billing.PublicModelBillingNormalizer.normalize(
                textReq,
                true,
                true,
                AIFeatureType.NOVEL_COMPOSE.name(),
                resolveModelConfigId(textReq),
                null,
                null,
                textReq.getSettingSessionId() != null ? textReq.getSettingSessionId() : textReq.getSessionId(),
                null
            );
        } catch (Exception ignore) {}
        java.util.concurrent.atomic.AtomicReference<StringBuilder> buf = new java.util.concurrent.atomic.AtomicReference<>(new StringBuilder());
        return universalAIService.processStreamRequest(textReq)
                .doOnNext(evt -> { if (evt != null && evt.getContent() != null) buf.get().append(evt.getContent()); })
                .ignoreElements()
                .then(Mono.fromSupplier(() -> {
                    // 将文本解析成块（简单回退：按空行分段）
                    String all = buf.get().toString();
                    // 优先尝试：通用兜底解析 create_compose_outlines（公共模型也可用）
                    try {
                        String contextId = "compose-outline-" + (request.getSessionId() != null ? request.getSessionId() : java.util.UUID.randomUUID());
                        java.util.List<com.ainovel.server.service.ai.tools.fallback.ToolFallbackParser> parsers = toolFallbackRegistry.getParsers("create_compose_outlines");
                        if (parsers != null && !parsers.isEmpty()) {
                            for (var parser : parsers) {
                                try {
                                    if (parser.canParse(all)) {
                                        java.util.Map<String, Object> params = parser.parseToToolParams(all);
                                        if (params != null && params.get("outlines") instanceof java.util.List<?>) {
                                            // 执行真实工具以保持副作用一致（如事件/日志），并用 handler 捕获结果
                                            var captured = new java.util.ArrayList<com.ainovel.server.service.compose.tools.BatchCreateOutlinesTool.OutlineItem>();
                                            var handler = new com.ainovel.server.service.compose.tools.BatchCreateOutlinesTool.OutlineHandler() {
                                                @Override
                                                public boolean handleOutlines(java.util.List<com.ainovel.server.service.compose.tools.BatchCreateOutlinesTool.OutlineItem> outlines) {
                                                    if (outlines == null || outlines.isEmpty()) return false;
                                                    int chapterCount = getIntParam(request, "chapterCount", 3);
                                                    java.util.List<com.ainovel.server.service.compose.tools.BatchCreateOutlinesTool.OutlineItem> toAdd = outlines;
                                                    if (toAdd.size() > chapterCount) toAdd = toAdd.subList(0, chapterCount);
                                                    captured.clear();
                                                    captured.addAll(toAdd);
                                                    return true;
                                                }
                                            };
                                            var toolCtx = toolExecutionService.createContext(contextId);
                                            try {
                                                toolCtx.registerTool(new com.ainovel.server.service.compose.tools.BatchCreateOutlinesTool(objectMapper, handler));
                                                String argsJson = objectMapper.writeValueAsString(params);
                                                toolExecutionService.invokeTool(contextId, "create_compose_outlines", argsJson);
                                            } finally {
                                                try { toolCtx.close(); } catch (Exception ignore) {}
                                            }
                                            if (!captured.isEmpty()) {
                                                java.util.List<String> blocks = new java.util.ArrayList<>();
                                                for (int i = 0; i < captured.size(); i++) {
                                                    var it = captured.get(i);
                                                    String title = it.getTitle() != null ? it.getTitle() : defaultChapterTitle(i + 1);
                                                    String summary = it.getSummary() != null ? it.getSummary() : "";
                                                    blocks.add(title + "\n" + summary);
                                                }
                                                return blocks;
                                            }
                                        }
                                    }
                                } catch (Exception ignore) {}
                            }
                        }
                    } catch (Exception ignore) {}
                    String[] blocks = all.split("\n\n+");
                    List<String> result = new ArrayList<>();
                    for (String b : blocks) {
                        String t = b.trim();
                        if (!t.isEmpty()) {
                            // 取首行作为标题，剩余作为摘要
                            String[] lines = t.split("\n", 2);
                            String title = lines[0].trim();
                            String summary = lines.length > 1 ? lines[1].trim() : "";
                            result.add((title.isEmpty() ? "大纲" : title) + "\n" + summary);
                        }
                    }
                    if (result.isEmpty()) {
                        // 若无法解析，至少返回一个块，避免后续 NPE
                        result.add("第一章\n");
                    }
                    return result;
                }));
    }

    private String resolveModelConfigId(UniversalAIRequestDto req) {
        String modelConfigId = req.getModelConfigId();
        if ((modelConfigId == null || modelConfigId.isEmpty()) && req.getMetadata() != null) {
            Object mid = req.getMetadata().get("modelConfigId");
            if (mid instanceof String s && !s.isEmpty()) {
                modelConfigId = s;
            }
        }
        return modelConfigId;
    }

    private List<String> parseOutlines(String outlineText, int expected) {
        List<String> items = new ArrayList<>();
        if (outlineText == null || outlineText.isEmpty()) return items;

        // 使用块级解析：一个 [OUTLINE_ITEM ...] 或 [OUTLINE\s*_ITEM ...] 开始，直到下一个同类标记之前的所有内容归为同一大纲块
        java.util.regex.Pattern p = java.util.regex.Pattern.compile("\\[\\s*OUTLINE\\s*_ITEM[^\\]]*\\]");
        java.util.regex.Matcher m = p.matcher(outlineText);

        java.util.List<Integer> starts = new java.util.ArrayList<>();
        while (m.find()) {
            starts.add(m.start());
        }

        if (!starts.isEmpty()) {
            log.debug("[Compose] 解析到大纲标签数量: {}", starts.size());
            for (int i = 0; i < starts.size(); i++) {
                int start = starts.get(i);
                int end = (i + 1 < starts.size()) ? starts.get(i + 1) : outlineText.length();
                String block = outlineText.substring(start, end).trim();
                if (!block.isEmpty()) {
                    items.add(block);
                }
                if (items.size() >= expected) break;
            }
        }

        // 回退：若未匹配到任何带标记的大纲，则按空行分段
        if (items.isEmpty()) {
            String[] blocks = outlineText.split("\n\n+");
            for (String b : blocks) {
                String t = b.trim();
                if (!t.isEmpty()) items.add(t);
                if (items.size() >= expected) break;
            }
        }

        // 截断到期望数量
        if (items.size() > expected) return items.subList(0, expected);
        log.debug("[Compose] 大纲块数量: {} (期望: {}), 首块预览: {}", items.size(), expected, items.isEmpty() ? "<empty>" : items.get(0));

        // 详细日志：逐项打印标题与字数
        try {
            for (int i = 0; i < items.size(); i++) {
                String block = items.get(i);
                String title = defaultChapterTitle(i + 1);
                int charCount = block.codePointCount(0, block.length());
                log.info("[Compose] 解析大纲第{}项：标题=\"{}\"，字数={}", (i + 1), title, charCount);
            }
        } catch (Exception e) {
            log.warn("[Compose] 解析大纲日志打印异常: {}", e.getMessage());
        }
        return items;
    }

    /**
     * 构造一个简易的系统片段，插入到合并流中（例如章节大纲/正文的标记）。
     * 仅用于前端消费展示，不影响计费与追踪。
     */
    private UniversalAIResponseDto buildSystemChunk(String requestType, String content) {
        return UniversalAIResponseDto.builder()
                .id(java.util.UUID.randomUUID().toString())
                .requestType(requestType)
                .content(content)
                .finishReason(null)
                .tokenUsage(null)
                .model(null)
                .createdAt(java.time.LocalDateTime.now())
                .metadata(new java.util.HashMap<>())
                .build();
    }

    // 新增：仅通过 metadata 发送结构化数据的系统片段
    private UniversalAIResponseDto buildSystemChunkWithMetadata(String requestType, java.util.Map<String, Object> metadata) {
        java.util.HashMap<String, Object> meta = new java.util.HashMap<>();
        if (metadata != null) meta.putAll(metadata);
        return UniversalAIResponseDto.builder()
                .id(java.util.UUID.randomUUID().toString())
                .requestType(requestType)
                .content("")
                .finishReason(null)
                .tokenUsage(null)
                .model(null)
                .createdAt(java.time.LocalDateTime.now())
                .metadata(meta)
                .build();
    }

    /**
     * 将分段大纲转换为 JSON：{"outlines":[{"index":1,"title":"...","summary":"..."}, ...]}
     */
    private String buildOutlinesJson(java.util.List<String> outlines) {
        try {
            com.fasterxml.jackson.databind.node.ObjectNode root = objectMapper.createObjectNode();
            com.fasterxml.jackson.databind.node.ArrayNode arr = objectMapper.createArrayNode();
            for (int i = 0; i < outlines.size(); i++) {
                String block = outlines.get(i);
                String title = defaultChapterTitle(i + 1);
                String summary = block;
                com.fasterxml.jackson.databind.node.ObjectNode item = objectMapper.createObjectNode();
                item.put("index", i + 1);
                item.put("title", title);
                item.put("summary", summary);
                arr.add(item);
            }
            root.set("outlines", arr);
            return objectMapper.writeValueAsString(root);
        } catch (Exception e) {
            // 兜底：返回空结构
            return "{\"outlines\":[]}";
        }
    }

    // 新增：将大纲转换为 metadata Map（避免大文本放入content，便于前端通过metadata消费）
    private java.util.Map<String, Object> buildOutlinesMetadata(java.util.List<String> outlines) {
        java.util.HashMap<String, Object> meta = new java.util.HashMap<>();
        java.util.ArrayList<java.util.Map<String, Object>> arr = new java.util.ArrayList<>();
        for (int i = 0; i < outlines.size(); i++) {
            String block = outlines.get(i);
            String title = defaultChapterTitle(i + 1);
            String summary = block;
            java.util.HashMap<String, Object> item = new java.util.HashMap<>();
            item.put("index", i + 1);
            item.put("title", title);
            item.put("summary", summary);
            arr.add(item);
        }
        meta.put("composeOutlines", arr);
        meta.put("composeOutlinesFormat", "json");
        meta.put("composeOutlinesCount", arr.size());
        return meta;
    }

    // 保存完成后，若有settingSessionId则把novelId绑定到会话，并发给前端一个系统片段信号
    private Mono<UniversalAIResponseDto> bindNovelToSessionAndSignal(String novelId, String settingSessionId) {
        if (novelId == null || novelId.isEmpty()) {
            log.info("[Compose] bind: no novelId, settingSessionId={}", settingSessionId);
            java.util.HashMap<String, Object> meta = new java.util.HashMap<>();
            meta.put("composeBind", java.util.Map.of("novelId", "", "sessionId", settingSessionId != null ? settingSessionId : ""));
            meta.put("composeBindStatus", "no_novelId");
            meta.put("composeReady", Boolean.FALSE);
            meta.put("composeReadyReason", "no_novelId");
            return Mono.just(buildSystemChunkWithMetadata(AIFeatureType.NOVEL_COMPOSE.name(), meta));
        }
        if (settingSessionId == null || settingSessionId.isEmpty()) {
            log.info("[Compose] bind: no settingSessionId, novelId={}", novelId);
            java.util.HashMap<String, Object> meta = new java.util.HashMap<>();
            meta.put("composeBind", java.util.Map.of("novelId", novelId, "sessionId", ""));
            meta.put("composeBindStatus", "no_session");
            meta.put("composeReady", Boolean.FALSE);
            meta.put("composeReadyReason", "no_session");
            return Mono.just(buildSystemChunkWithMetadata(AIFeatureType.NOVEL_COMPOSE.name(), meta));
        }
        return inMemorySessionManager.getSession(settingSessionId)
                .flatMap(session -> {
                    session.setNovelId(novelId);
                    return inMemorySessionManager.saveSession(session);
                })
                .onErrorResume(e -> {
                    log.warn("[Compose] bind: failed to save session mapping: sessionId={}, novelId={}, err={}", settingSessionId, novelId, e.getMessage());
                    return Mono.empty();
                })
                .then(Mono.fromSupplier(() -> {
                    java.util.HashMap<String, Object> meta = new java.util.HashMap<>();
                    meta.put("composeBind", java.util.Map.of("novelId", novelId, "sessionId", settingSessionId));
                    meta.put("composeBindStatus", "bound");
                    meta.put("composeReady", Boolean.TRUE);
                    meta.put("composeReadyReason", "ok");
                    UniversalAIResponseDto chunk = buildSystemChunkWithMetadata(AIFeatureType.NOVEL_COMPOSE.name(), meta);
                    try {
                        Map<String, Object> m = chunk.getMetadata();
                        log.info("[Compose] bind: emitted final signal bind={}, status=bound", (m != null ? m.get("composeBind") : null));
                    } catch (Exception ignore) {}
                    return chunk;
                }));
    }

    // ==================== 工具化大纲生成 ====================
    private Mono<List<com.ainovel.server.service.compose.tools.BatchCreateOutlinesTool.OutlineItem>> generateOutlinesWithTools(UniversalAIRequestDto request) {
        String modelConfigId = request.getModelConfigId();
        if ((modelConfigId == null || modelConfigId.isEmpty()) && request.getMetadata() != null) {
            Object mid = request.getMetadata().get("modelConfigId");
            if (mid instanceof String s && !s.isEmpty()) {
                modelConfigId = s;
            }
        }
        int chapterCount = getIntParam(request, "chapterCount", 3);
        String contextId = "compose-outline-" + (request.getSessionId() != null ? request.getSessionId() : java.util.UUID.randomUUID());

        Mono<AIModelProvider> providerMono;
        if (modelConfigId != null && !modelConfigId.isEmpty()) {
            providerMono = novelAIService.getAIModelProviderByConfigId(request.getUserId(), modelConfigId)
                    .onErrorResume(err -> {
                        log.warn("[Compose] 指定模型配置无效或不可用，回退到用户默认模型: {}", err.getMessage());
                        return novelAIService.getAIModelProvider(request.getUserId(), null);
                    });
        } else {
            providerMono = novelAIService.getAIModelProvider(request.getUserId(), null);
        }

        return providerMono
                .flatMap(provider -> {
                    String modelName = provider.getModelName();
                    java.util.Map<String, String> aiConfig = new java.util.HashMap<>();
                    aiConfig.put("apiKey", provider.getApiKey());
                    aiConfig.put("apiEndpoint", provider.getApiEndpoint());
                    aiConfig.put("provider", provider.getProviderName());
                    aiConfig.put("requestType", AIFeatureType.NOVEL_COMPOSE.name());
                    aiConfig.put("correlationId", contextId);
                    // 透传身份信息，供AIRequest写入并被LLMTrace记录
                    if (request.getUserId() != null && !request.getUserId().isEmpty()) {
                        aiConfig.put("userId", request.getUserId());
                    }
                    if (request.getSessionId() != null && !request.getSessionId().isEmpty()) {
                        aiConfig.put("sessionId", request.getSessionId());
                    }

                    com.ainovel.server.service.ai.tools.ToolExecutionService.ToolCallContext toolContext = toolExecutionService.createContext(contextId);

                    java.util.List<com.ainovel.server.service.compose.tools.BatchCreateOutlinesTool.OutlineItem> captured = new java.util.ArrayList<>();
                    com.ainovel.server.service.compose.tools.BatchCreateOutlinesTool.OutlineHandler handler = outlines -> {
                        if (outlines == null || outlines.isEmpty()) return false;
                        // 截断到期望数量
                        java.util.List<com.ainovel.server.service.compose.tools.BatchCreateOutlinesTool.OutlineItem> toAdd = outlines;
                        if (toAdd.size() > chapterCount) {
                            toAdd = toAdd.subList(0, chapterCount);
                        }
                        captured.clear();
                        captured.addAll(toAdd);
                        return true;
                    };
                    toolContext.registerTool(new com.ainovel.server.service.compose.tools.BatchCreateOutlinesTool(objectMapper, handler));

                    java.util.List<ToolSpecification> toolSpecs = toolRegistry.getSpecificationsForContext(contextId);

                    // 构建提示词上下文（支持整棵设定树注入）与历史初始提示（仅当无会话时）
                    Mono<String> wholeTreeContextMono = maybeBuildWholeSettingTreeContext(request);
                    Mono<String> historyInitPromptMono = maybeGetHistoryInitPromptWhenNoSession(request);
                    return reactor.core.publisher.Mono.zip(wholeTreeContextMono, historyInitPromptMono).flatMap(tuple2 -> {
                        String ctx = tuple2.getT1();
                        String historyInitPrompt = tuple2.getT2();
                        try {
                            log.info("[Compose][Context] Outline mode ctx.length={}, historyInitPrompt.length={}",
                                    (ctx != null ? ctx.length() : -1), (historyInitPrompt != null ? historyInitPrompt.length() : -1));
                        } catch (Exception ignore) {}
                        java.util.Map<String, Object> promptParams = new java.util.HashMap<>();
                        if (request.getParameters() != null) promptParams.putAll(request.getParameters());
                        promptParams.put("mode", "outline");
                        promptParams.put("chapterCount", chapterCount);
                        promptParams.put("novelId", request.getNovelId());
                        promptParams.put("userId", request.getUserId());
                        if (ctx != null && !ctx.isBlank()) {
                            promptParams.put("context", ctx);
                        }
                        if (historyInitPrompt != null && !historyInitPrompt.isBlank()) {
                            promptParams.put("historyInitPrompt", historyInitPrompt);
                        }

                        String templateId = null;
                        try {
                            templateId = getParam(request, "promptTemplateId", "");
                            if (templateId != null && templateId.startsWith("public_")) {
                                templateId = templateId.substring("public_".length());
                            }
                        } catch (Exception ignore) {}

                        return composePromptProvider.getSystemPrompt(request.getUserId(), promptParams)
                                .zipWith(composePromptProvider.getUserPrompt(request.getUserId(), templateId, promptParams))
                                .flatMap(tuple -> {
                                    String systemPrompt = tuple.getT1();
                                    String userPrompt = tuple.getT2();
                                    java.util.List<ChatMessage> messages = new java.util.ArrayList<>();
                                    messages.add(new SystemMessage(systemPrompt));
                                    messages.add(new UserMessage(userPrompt));

                                    aiConfig.put("toolContextId", contextId);
                                    return aiService.executeToolCallLoop(
                                            messages,
                                            toolSpecs,
                                            modelName,
                                            aiConfig.get("apiKey"),
                                            aiConfig.get("apiEndpoint"),
                                            aiConfig,
                                            1
                                    ).then(Mono.defer(() -> {
                                        if (captured.isEmpty()) {
                                            // 兜底：返回空列表（显式类型）
                                            return Mono.just(
                                                java.util.Collections.<com.ainovel.server.service.compose.tools.BatchCreateOutlinesTool.OutlineItem>emptyList()
                                            );
                                        }
                                        return Mono.just(captured);
                                    }));
                                })
                                .doFinally(signal -> {
                                    try { toolContext.close(); } catch (Exception ignore) {}
                                });
                    });
                });
    }

    /**
     * 当 includeWholeSettingTree=true 时，构建整棵设定树的可读上下文字符串。
     * 优先从内存会话获取；若不存在，则将 settingSessionId 或 sessionId 当作历史ID从历史记录构建。
     */
    private Mono<String> maybeBuildWholeSettingTreeContext(UniversalAIRequestDto request) {
        boolean includeWholeTree = false;
        try {
            Object flag = request.getParameters() != null ? request.getParameters().get("includeWholeSettingTree") : null;
            includeWholeTree = parseBooleanFlag(flag).orElse(false);
        } catch (Exception ignore) {}
        try { log.info("[Compose][Context] includeWholeSettingTree={} (requestType={})", includeWholeTree, request.getRequestType()); } catch (Exception ignore) {}
        if (!includeWholeTree) {
            return Mono.just("");
        }

        String sid = request.getSettingSessionId() != null && !request.getSettingSessionId().isEmpty()
                ? request.getSettingSessionId()
                : request.getSessionId();
        try { log.info("[Compose][Context] resolve sid for whole-tree: settingSessionId={}, sessionId={}, sid={}", request.getSettingSessionId(), request.getSessionId(), sid); } catch (Exception ignore) {}
        if (sid == null || sid.isEmpty()) {
            return Mono.just("");
        }

        // 优先使用内存会话；失败则回退到历史记录；若会话存在但渲染为空，也回退历史
        return inMemorySessionManager.getSession(sid)
                .flatMap(session -> {
                    try {
                        int nodeCount = session.getGeneratedNodes() != null ? session.getGeneratedNodes().size() : 0;
                        long rootCount = 0;
                        try {
                            rootCount = session.getGeneratedNodes().values().stream()
                                    .filter(n -> n.getParentId() == null)
                                    .count();
                        } catch (Exception ignore) {}
                        log.info("[Compose][Context] Session found for sid={}, nodes={}, roots={}", sid, nodeCount, rootCount);
                    } catch (Exception ignore) {}
                    String ctx = buildReadableSessionTree(session);
                    try { log.info("[Compose][Context] SessionTree length={}", (ctx != null ? ctx.length() : -1)); } catch (Exception ignore) {}
                    if (ctx == null || ctx.isBlank()) {
                        return historyService.getHistoryWithSettings(sid)
                                .map(this::buildReadableHistoryTree)
                                .doOnNext(hctx -> { try { log.info("[Compose][Context] HistoryTree length={}", (hctx != null ? hctx.length() : -1)); } catch (Exception ignore) {} })
                                .defaultIfEmpty("");
                    }
                    return Mono.just(ctx);
                })
                .switchIfEmpty(Mono.defer(() -> {
                    try { log.info("[Compose][Context] Session not found, fallback to history: {}", sid); } catch (Exception ignore) {}
                    return historyService.getHistoryWithSettings(sid)
                            .map(this::buildReadableHistoryTree)
                            .doOnNext(hctx -> { try { log.info("[Compose][Context] HistoryTree length={}", (hctx != null ? hctx.length() : -1)); } catch (Exception ignore) {} })
                            .defaultIfEmpty("");
                }))
                .onErrorResume(err -> { try { log.warn("[Compose][Context] Build whole-tree context failed: {}", err.getMessage(), err); } catch (Exception ignore) {} return Mono.just(""); });
    }

    private String buildReadableSessionTree(SettingGenerationSession session) {
        StringBuilder sb = new StringBuilder();
        // 根节点：parentId == null
        session.getGeneratedNodes().values().stream()
                .filter(n -> n.getParentId() == null)
                .forEach(root -> appendSessionNodeLine(session, root, sb, 0, new java.util.ArrayList<>()))
        ;
        return sb.toString();
    }

    private void appendSessionNodeLine(SettingGenerationSession session, SettingNode node, StringBuilder sb,
                                       int depth, java.util.List<String> ancestors) {
        for (int i = 0; i < depth; i++) sb.append("  ");
        String path = String.join("/", ancestors);
        String oneLineDesc = safeOneLine(node.getDescription(), 140);
        String typeStr = node.getType() != null ? node.getType().name() : "UNKNOWN";
        if (!path.isEmpty()) {
            sb.append("- ").append(path).append("/").append(node.getName())
              .append(" [").append(typeStr).append("]");
        } else {
            sb.append("- ").append(node.getName()).append(" [").append(typeStr).append("]");
        }
        if (!oneLineDesc.isBlank()) {
            sb.append(": ").append(oneLineDesc);
        }
        sb.append("\n");
        // 子节点
        java.util.List<String> childIds = session.getChildrenIds(node.getId());
        if (childIds != null) {
            ancestors.add(node.getName());
            for (String cid : childIds) {
                SettingNode child = session.getGeneratedNodes().get(cid);
                if (child != null) {
                    appendSessionNodeLine(session, child, sb, depth + 1, ancestors);
                }
            }
            ancestors.remove(ancestors.size() - 1);
        }
    }

    private String buildReadableHistoryTree(HistoryWithSettings history) {
        StringBuilder sb = new StringBuilder();
        java.util.List<SettingNode> roots = history.rootNodes();
        for (SettingNode root : roots) {
            appendHistoryNodeLine(root, sb, 0, new java.util.ArrayList<>());
        }
        return sb.toString();
    }

    private void appendHistoryNodeLine(SettingNode node, StringBuilder sb, int depth, java.util.List<String> ancestors) {
        for (int i = 0; i < depth; i++) sb.append("  ");
        String path = String.join("/", ancestors);
        String oneLineDesc = safeOneLine(node.getDescription(), 140);
        String typeStr = node.getType() != null ? node.getType().name() : "UNKNOWN";
        if (!path.isEmpty()) {
            sb.append("- ").append(path).append("/").append(node.getName())
              .append(" [").append(typeStr).append("]");
        } else {
            sb.append("- ").append(node.getName()).append(" [").append(typeStr).append("]");
        }
        if (!oneLineDesc.isBlank()) {
            sb.append(": ").append(oneLineDesc);
        }
        sb.append("\n");
        // 历史的 SettingNode 包含 children 列表
        if (node.getChildren() != null && !node.getChildren().isEmpty()) {
            ancestors.add(node.getName());
            for (SettingNode child : node.getChildren()) {
                appendHistoryNodeLine(child, sb, depth + 1, ancestors);
            }
            ancestors.remove(ancestors.size() - 1);
        }
    }

    private String safeOneLine(String text, int maxLen) {
        if (text == null) return "";
        String t = text.replaceAll("\n|\r", " ").trim();
        if (t.length() <= maxLen) return t;
        return t.substring(0, Math.max(0, maxLen - 1)) + "…";
    }

    /**
     * 当无法解析到有效会话（或会话树渲染为空）时，尝试获取历史记录的 initialPrompt 作为补充提示信息。
     * 仅在 outline 阶段读取，并以参数 historyInitPrompt 注入。
     */
    private Mono<String> maybeGetHistoryInitPromptWhenNoSession(UniversalAIRequestDto request) {
        try {
            // 如果显式有 settingSessionId，优先使用会话；仅当会话不存在或不可用时才考虑历史
            String sid = request.getSettingSessionId();
            if (sid != null && !sid.isEmpty()) {
                return inMemorySessionManager.getSession(sid)
                        .map(sess -> {
                            // 有会话则不需要历史初始提示
                            return "";
                        })
                        .switchIfEmpty(Mono.defer(() -> {
                            try { log.info("[Compose][InitPrompt] sessionId={} 不存在，尝试作为historyId读取initialPrompt", sid); } catch (Exception ignore) {}
                            return historyService.getHistoryById(sid)
                                    .map(h -> {
                                        String ip = h.getInitialPrompt();
                                        try { log.info("[Compose][InitPrompt] 从historyId={} 读取initialPrompt.length={}", sid, (ip != null ? ip.length() : -1)); } catch (Exception ignore) {}
                                        return ip != null ? ip : "";
                                    })
                                    .onErrorResume(err -> Mono.just(""));
                        }))
                        .onErrorResume(err -> Mono.just(""));
            }
        } catch (Exception ignore) {}
        return Mono.just("");
    }
}


