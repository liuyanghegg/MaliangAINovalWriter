package com.ainovel.server.service;

import com.ainovel.server.domain.model.AIFeatureType;

import reactor.core.publisher.Mono;

/**
 * 用量/配额服务：支持按会员计划的特性阈值控制
 */
public interface UsageQuotaService {

    /**
     * 检查用户在指定功能上的用量是否达到限额（例如AI生成次数、导入次数、小说数量等）
     */
    Mono<Boolean> isWithinLimit(String userId, AIFeatureType featureType);

    /**
     * 增加一次功能使用计数
     */
    Mono<Void> incrementUsage(String userId, AIFeatureType featureType);

    /**
     * 检查用户小说总数是否在限额内
     */
    Mono<Boolean> canCreateMoreNovels(String userId);

    /**
     * 在创建小说后登记计数
     */
    Mono<Void> onNovelCreated(String userId);

    /**
     * 检查导入次数是否在限额内
     */
    Mono<Boolean> canImportNovel(String userId);

    /**
     * 导入成功后登记计数
     */
    Mono<Void> onNovelImported(String userId);
}




