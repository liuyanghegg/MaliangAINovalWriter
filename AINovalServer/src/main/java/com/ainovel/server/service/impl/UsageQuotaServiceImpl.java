package com.ainovel.server.service.impl;

import java.time.LocalDate;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Service;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.SubscriptionPlan;
import com.ainovel.server.domain.model.User;
import com.ainovel.server.repository.SubscriptionPlanRepository;
import com.ainovel.server.repository.UserRepository;
import com.ainovel.server.repository.NovelRepository;
import com.ainovel.server.service.UsageQuotaService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * 简化版配额服务实现：
 * - 从订阅计划 features 中读取阈值
 * - 使用内存级每日计数做演示（生产建议使用Mongo聚合或Redis计数）
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UsageQuotaServiceImpl implements UsageQuotaService {

    private static final String FEATURE_AI_DAILY_CALLS = "ai.daily.calls"; // 每日AI功能调用次数阈值
    private static final String FEATURE_IMPORT_DAILY = "import.daily.limit"; // 每日导入次数
    private static final String FEATURE_NOVEL_MAX = "novel.max.count"; // 用户可创建的最大小说数量

    private final UserRepository userRepository;
    private final SubscriptionPlanRepository subscriptionPlanRepository;
    private final NovelRepository novelRepository;

    // 演示用内存计数：key => userId:date:feature
    private final Map<String, Integer> dailyCounters = new ConcurrentHashMap<>();
    private final Map<String, Integer> importDailyCounters = new ConcurrentHashMap<>();

    @Override
    public Mono<Boolean> isWithinLimit(String userId, AIFeatureType featureType) {
        return getUserPlanFeatureInt(userId, FEATURE_AI_DAILY_CALLS, Integer.MAX_VALUE)
            .map(limit -> {
                String key = dailyKey(userId, featureType.name());
                int used = dailyCounters.getOrDefault(key, 0);
                return used < limit;
            });
    }

    @Override
    public Mono<Void> incrementUsage(String userId, AIFeatureType featureType) {
        return Mono.fromRunnable(() -> {
            String key = dailyKey(userId, featureType.name());
            dailyCounters.merge(key, 1, Integer::sum);
        });
    }

    @Override
    public Mono<Boolean> canCreateMoreNovels(String userId) {
        return getUserPlanFeatureInt(userId, FEATURE_NOVEL_MAX, Integer.MAX_VALUE)
            .flatMap(limit -> novelRepository.countByAuthorId(userId)
                .defaultIfEmpty(0L)
                .map(count -> count < (long) limit));
    }

    @Override
    public Mono<Void> onNovelCreated(String userId) {
        // 实际计数依赖数据库，不需要本地累加；此处为空操作
        return Mono.empty();
    }

    @Override
    public Mono<Boolean> canImportNovel(String userId) {
        return getUserPlanFeatureInt(userId, FEATURE_IMPORT_DAILY, Integer.MAX_VALUE)
            .map(limit -> {
                String key = dailyKey(userId, "IMPORT");
                int used = importDailyCounters.getOrDefault(key, 0);
                return used < limit;
            });
    }

    @Override
    public Mono<Void> onNovelImported(String userId) {
        return Mono.fromRunnable(() -> {
            String key = dailyKey(userId, "IMPORT");
            importDailyCounters.merge(key, 1, Integer::sum);
        });
    }

    private Mono<Integer> getUserPlanFeatureInt(String userId, String featureKey, int defaultValue) {
        return userRepository.findById(userId)
            .flatMap(user -> findUserPlan(user)
                .map(plan -> {
                    Object val = plan.getFeatures() != null ? plan.getFeatures().get(featureKey) : null;
                    if (val instanceof Number n) return n.intValue();
                    if (val instanceof String s) {
                        try { return Integer.parseInt(s); } catch (Exception ignored) {}
                    }
                    return defaultValue;
                })
                .defaultIfEmpty(defaultValue))
            .defaultIfEmpty(defaultValue);
    }

    private Mono<SubscriptionPlan> findUserPlan(User user) {
        String subscriptionId = user.getCurrentSubscriptionId();
        if (subscriptionId == null) {
            return Mono.empty();
        }
        // 简化：根据用户角色优先匹配plan.roleId；或根据currentSubscriptionId进一步查询
        if (user.getRoleIds() != null && !user.getRoleIds().isEmpty()) {
            // 取第一个高优先级角色匹配的计划
            return subscriptionPlanRepository.findByRoleId(user.getRoleIds().get(0)).next();
        }
        return Mono.empty();
    }

    private String dailyKey(String userId, String feature) {
        return userId + ":" + LocalDate.now() + ":" + feature;
    }
}


