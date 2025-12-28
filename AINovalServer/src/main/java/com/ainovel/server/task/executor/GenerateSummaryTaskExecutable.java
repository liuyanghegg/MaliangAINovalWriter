package com.ainovel.server.task.executor;

import com.ainovel.server.domain.model.Scene;
import com.ainovel.server.service.NovelAIService;
import com.ainovel.server.service.SceneService;
import com.ainovel.server.service.UserAIModelConfigService;
import com.ainovel.server.task.BackgroundTaskExecutable;
import com.ainovel.server.task.TaskContext;
import com.ainovel.server.task.dto.summarygeneration.GenerateSummaryParameters;
import com.ainovel.server.task.dto.summarygeneration.GenerateSummaryResult;
import com.ainovel.server.task.service.EnhancedRateLimiterService;
import com.ainovel.server.web.dto.SummarizeSceneRequest;
import com.ainovel.server.domain.model.UserAIModelConfig;

import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.data.mongodb.core.ReactiveMongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Component;

import reactor.core.publisher.Mono;

import java.time.Instant;

/**
 * 生成场景摘要任务执行器 (响应式)
 * 使用增强的限流服务进行AI调用控制
 */
@Slf4j
@Component
public class GenerateSummaryTaskExecutable extends BaseAITaskExecutor 
        implements BackgroundTaskExecutable<GenerateSummaryParameters, GenerateSummaryResult> {

    private final SceneService sceneService;
    private final NovelAIService novelAIService;
    private final ReactiveMongoTemplate reactiveMongoTemplate;
    
    public GenerateSummaryTaskExecutable(
            SceneService sceneService,
            NovelAIService novelAIService, 
            UserAIModelConfigService userAIModelConfigService,
            ReactiveMongoTemplate reactiveMongoTemplate,
            EnhancedRateLimiterService rateLimiterService) {
        super(userAIModelConfigService, rateLimiterService);
        this.sceneService = sceneService;
        this.novelAIService = novelAIService;
        this.reactiveMongoTemplate = reactiveMongoTemplate;
    }

    @Override
    public Mono<GenerateSummaryResult> execute(TaskContext<GenerateSummaryParameters> context) {
        GenerateSummaryParameters parameters = context.getParameters();
        String sceneId = parameters.getSceneId();
        boolean useAIEnhancement = parameters.getUseAIEnhancement();
        String userId = context.getUserId();
        String aiConfigId = parameters.getAiConfigId();
        String requestId = context.getTaskId();

        log.info("[任务:{}] 开始为场景 {} 生成摘要，用户ID: {}, 是否使用AI增强: {}, AI配置ID: {}", 
                requestId, sceneId, userId, useAIEnhancement, aiConfigId);

        return sceneService.findSceneById(sceneId)
            .switchIfEmpty(Mono.error(new IllegalStateException("场景不存在: " + sceneId)))
            .flatMap(scene -> {
                int actualVersion = scene.getVersion();
                String content = scene.getContent();

                if (content == null || content.trim().isEmpty()) {
                    log.error("[任务:{}] 场景 {} 内容为空，无法生成摘要", requestId, sceneId);
                    return Mono.error(new IllegalArgumentException("场景内容为空，无法生成摘要"));
                }

                SummarizeSceneRequest summarizeRequest = new SummarizeSceneRequest();
                summarizeRequest.setAiConfigId(aiConfigId);
                log.info("[任务:{}] 调用AI服务生成场景 {} 摘要", requestId, sceneId);
                
                return executeWithRateLimit(userId, useAIEnhancement, aiConfigId, requestId,
                    novelAIService.summarizeScene(userId, sceneId, summarizeRequest)
                        .switchIfEmpty(Mono.error(new RuntimeException("AI服务未返回有效摘要")))
                        .flatMap(response -> {
                            String generatedSummary = response.getSummary();
                            if (generatedSummary == null || generatedSummary.trim().isEmpty()) {
                                log.error("[任务:{}] 生成场景 {} 摘要失败: AI服务返回空摘要", requestId, sceneId);
                                return Mono.error(new RuntimeException("AI服务返回空摘要"));
                            }
                            log.info("[任务:{}] 场景 {} 摘要生成成功，长度: {}", requestId, sceneId, generatedSummary.length());

                            return updateSceneSummaryAtomic(sceneId, actualVersion, generatedSummary)
                                .flatMap(updateSuccess -> {
                                    if (updateSuccess) {
                                        return Mono.just(GenerateSummaryResult.builder()
                                            .sceneId(sceneId)
                                            .summary(generatedSummary)
                                            .processingTimeMs(System.currentTimeMillis())
                                            .completedAt(Instant.now())
                                            .build());
                                    } else {
                                        log.info("[任务:{}] 场景 {} 在生成摘要过程中被修改，将尝试基于最新版本更新", requestId, sceneId);
                                        return sceneService.findSceneById(sceneId)
                                            .switchIfEmpty(Mono.error(new IllegalStateException("场景不存在: " + sceneId)))
                                            .flatMap(latestScene -> 
                                                updateSceneSummaryAtomic(sceneId, latestScene.getVersion(), generatedSummary)
                                                    .flatMap(retrySuccess -> {
                                                        if (retrySuccess) {
                                                            return Mono.just(GenerateSummaryResult.builder()
                                                                .sceneId(sceneId)
                                                                .summary(generatedSummary)
                                                                .processingTimeMs(System.currentTimeMillis())
                                                                .completedAt(Instant.now())
                                                                .build());
                                                        } else {
                                                            return Mono.error(new RuntimeException("场景更新失败，版本冲突"));
                                                        }
                                                    })
                                            );
                                    }
                                });
                        }),
                    parameters);
            });
    }

    private Mono<Boolean> updateSceneSummaryAtomic(String sceneId, int expectedVersion, String summary) {
        Query query = Query.query(Criteria.where("_id").is(sceneId)
                .and("version").is(expectedVersion));
        
        Update update = new Update()
                .set("summary", summary)
                .inc("version", 1);
        
        return reactiveMongoTemplate.updateFirst(query, update, Scene.class)
                .map(updateResult -> updateResult.getModifiedCount() > 0)
                .onErrorResume(OptimisticLockingFailureException.class, e -> {
                    log.warn("原子更新场景 {} 摘要时发生乐观锁冲突 (期望版本: {})", sceneId, expectedVersion);
                    return Mono.just(false);
                })
                .onErrorResume(e -> {
                    log.error("原子更新场景 {} 摘要时发生其他错误", sceneId, e);
                    return Mono.just(false);
                });
    }
    

    


    @Override
    public String getTaskType() {
        return "GENERATE_SUMMARY";
    }
}