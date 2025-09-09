package com.ainovel.server.service.prompt.impl;

import com.ainovel.server.service.impl.content.ContentProviderFactory;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import jakarta.annotation.PreDestroy;

import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ForkJoinPool;
import java.util.List;
import java.util.ArrayList;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.time.LocalDateTime;

/**
 * 虚拟线程占位符解析器 - 使用Java 21虚拟线程优化并行处理
 * 
 * 使用新的ContentProvider.getContentForPlaceholder方法进行简化调用
 * 
 * 支持占位符格式：
 * - {{full_novel_text}}
 * - {{scene:sceneId}}  
 * - {{chapter:chapterId}}
 * - {{snippet:snippetId}}
 * - {{setting:settingId}}
 * - {{act:actId}}
 * 
 * 性能优化：
 * - 使用虚拟线程处理IO密集型占位符解析
 * - 并行处理多个占位符，避免串行等待
 * - 缓存解析结果，避免重复计算
 * - 性能统计和监控
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class VirtualThreadPlaceholderResolver {

    private final ContentProviderFactory contentProviderFactory;
    
    // 占位符匹配模式：{{type}} 或 {{type:id}}
    private static final Pattern PLACEHOLDER_PATTERN = Pattern.compile("\\{\\{([^:}]+)(?::([^}]+))?\\}\\}");
    
    // 🚀 优化：使用专用的虚拟线程池执行器
    private static final ExecutorService VIRTUAL_EXECUTOR = createVirtualThreadExecutor();
    
    // 解析结果缓存
    private final Map<String, String> placeholderCache = new ConcurrentHashMap<>();
    
    // 性能统计
    private final AtomicLong totalResolveCount = new AtomicLong(0);
    private final AtomicLong parallelResolveCount = new AtomicLong(0);
    private final AtomicLong totalResolveTime = new AtomicLong(0);
    private final AtomicLong cacheHitCount = new AtomicLong(0);
    
    /**
     * 🚀 优化：创建最佳实践的虚拟线程执行器
     * 使用Java 21标准API，提供完整的生命周期管理
     */
    private static ExecutorService createVirtualThreadExecutor() {
        try {
            // 方案1：使用标准的虚拟线程池执行器（推荐）
            try {
                log.info("🚀 使用标准虚拟线程池执行器");
                return Executors.newVirtualThreadPerTaskExecutor();
            } catch (Exception e) {
                log.debug("标准虚拟线程池不可用，尝试手动创建: {}", e.getMessage());
            }
            
            // 方案2：手动创建虚拟线程执行器
            try {
                log.info("🚀 使用自定义虚拟线程执行器");
                var threadFactory = Thread.ofVirtual()
                    .name("virtual-placeholder-", 0)  // 为线程命名便于调试
                    .factory();
                
                return Executors.newThreadPerTaskExecutor(threadFactory);
            } catch (Exception e) {
                log.debug("自定义虚拟线程执行器创建失败: {}", e.getMessage());
            }
            
            // 方案3：反射方式（兼容性后备方案）
            log.warn("⚠️ 使用反射方式创建虚拟线程执行器（不推荐）");
            return createVirtualThreadExecutorByReflection();
            
        } catch (Exception e) {
            log.warn("❌ 虚拟线程完全不可用，回退到ForkJoinPool: {}", e.getMessage());
            return ForkJoinPool.commonPool();
        }
    }
    
    /**
     * 反射方式创建虚拟线程执行器（兼容性后备方案）
     */
    private static ExecutorService createVirtualThreadExecutorByReflection() {
        try {
            Class<?> executorsClass = Executors.class;
            return (ExecutorService) executorsClass.getMethod("newVirtualThreadPerTaskExecutor").invoke(null);
        } catch (Exception e) {
            log.error("反射创建虚拟线程执行器失败，使用ForkJoinPool", e);
            return ForkJoinPool.commonPool();
        }
    }

    public Mono<String> resolvePlaceholders(String template, String userId, String novelId, Map<String, Object> parameters) {
        if (template == null || template.isEmpty()) {
            return Mono.just("");
        }

        long startTime = System.currentTimeMillis();
        totalResolveCount.incrementAndGet();

        log.debug("开始虚拟线程占位符解析: userId={}, novelId={}, template length={}", userId, novelId, template.length());

        // 1. 提取所有占位符
        List<PlaceholderInfo> placeholders = extractPlaceholders(template);
        if (placeholders.isEmpty()) {
            log.debug("未找到内容提供器占位符，直接返回模板");
            return Mono.just(template);
        }

        log.debug("找到 {} 个内容提供器占位符，开始并行解析", placeholders.size());
        
        if (placeholders.size() > 1) {
            parallelResolveCount.incrementAndGet();
        }

        // 2. 并行解析所有占位符
        return resolveAllPlaceholdersParallel(placeholders, userId, novelId, parameters)
                .map(resolvedMap -> {
                    // 3. 批量替换占位符
                    String result = template;
                    for (Map.Entry<String, String> entry : resolvedMap.entrySet()) {
                        result = result.replace(entry.getKey(), entry.getValue());
                    }
                    
                    long duration = System.currentTimeMillis() - startTime;
                    totalResolveTime.addAndGet(duration);
                    
                    log.debug("虚拟线程占位符解析完成，结果长度: {}, 耗时: {}ms", result.length(), duration);
                    return result;
                });
    }

    /**
     * 并行解析所有占位符 - 使用虚拟线程优化IO处理
     */
    private Mono<Map<String, String>> resolveAllPlaceholdersParallel(
            List<PlaceholderInfo> placeholders, 
            String userId, 
            String novelId, 
            Map<String, Object> parameters) {
            
        // 使用虚拟线程并行处理所有占位符
        List<CompletableFuture<Map.Entry<String, String>>> futures = placeholders.stream()
                .map(placeholder -> CompletableFuture
                        .supplyAsync(() -> resolveSinglePlaceholder(placeholder, userId, novelId, parameters), VIRTUAL_EXECUTOR)
                        .exceptionally(throwable -> {
                            log.error("占位符解析失败: {}", placeholder.getFullPlaceholder(), throwable);
                            return Map.entry(placeholder.getFullPlaceholder(), "[内容获取失败]");
                        }))
                .toList();

        // 等待所有占位符解析完成
        CompletableFuture<Map<String, String>> allFutures = CompletableFuture
                .allOf(futures.toArray(new CompletableFuture[0]))
                .thenApply(v -> {
                    Map<String, String> resultMap = new ConcurrentHashMap<>();
                    for (CompletableFuture<Map.Entry<String, String>> future : futures) {
                        try {
                            Map.Entry<String, String> entry = future.get();
                            resultMap.put(entry.getKey(), entry.getValue());
                        } catch (Exception e) {
                            log.error("获取占位符解析结果失败", e);
                        }
                    }
                    return resultMap;
                });

        return Mono.fromFuture(allFutures);
    }

    /**
     * 解析单个占位符 - 使用新的简化方法
     */
    private Map.Entry<String, String> resolveSinglePlaceholder(
            PlaceholderInfo placeholder, 
            String userId, 
            String novelId, 
            Map<String, Object> parameters) {

        String cacheKey = generateCacheKey(placeholder, userId, novelId);
        
        // 检查缓存
        String cached = placeholderCache.get(cacheKey);
        if (cached != null) {
            cacheHitCount.incrementAndGet();
            log.debug("使用缓存的占位符结果: {}", placeholder.getFullPlaceholder());
            return Map.entry(placeholder.getFullPlaceholder(), cached);
        }

        try {
            // 获取内容提供器
            var providerOptional = contentProviderFactory.getProvider(placeholder.getType());
            if (providerOptional.isEmpty()) {
                log.warn("未找到类型为 {} 的内容提供器", placeholder.getType());
                return Map.entry(placeholder.getFullPlaceholder(), "[不支持的内容类型]");
            }

            // 确定内容ID
            String contentId = determineContentId(placeholder, novelId);
            
            // 调用新的简化方法获取内容
            String content = providerOptional.get()
                    .getContentForPlaceholder(userId, novelId, contentId, parameters)
                    .onErrorReturn("[内容获取失败: " + placeholder.getType() + "]")
                    .block(); // 在虚拟线程中阻塞是安全的

            // 缓存结果
            if (content != null && !content.startsWith("[") && !content.endsWith("]")) {
                placeholderCache.put(cacheKey, content);
            }
            
            log.debug("成功解析占位符: {} -> {} 字符", placeholder.getFullPlaceholder(), 
                     content != null ? content.length() : 0);
            
            return Map.entry(placeholder.getFullPlaceholder(), content != null ? content : "");
            
        } catch (Exception e) {
            log.error("解析占位符失败: {}", placeholder.getFullPlaceholder(), e);
            return Map.entry(placeholder.getFullPlaceholder(), "[内容获取异常]");
        }
    }

    /**
     * 确定内容ID
     */
    private String determineContentId(PlaceholderInfo placeholder, String novelId) {
        // 如果占位符包含ID，直接使用
        if (placeholder.getId() != null && !placeholder.getId().isEmpty()) {
            return placeholder.getId();
        }

        // 对于不需要ID的类型，使用novelId或null
        switch (placeholder.getType()) {
            case "full_novel_text":
            case "full_novel_summary":
                return novelId;
            default:
                return null; // 对于需要ID但未提供的情况，让Provider自己处理
        }
    }

    /**
     * 提取模板中的所有占位符
     */
    private List<PlaceholderInfo> extractPlaceholders(String template) {
        List<PlaceholderInfo> placeholders = new ArrayList<>();
        Matcher matcher = PLACEHOLDER_PATTERN.matcher(template);
        
        while (matcher.find()) {
            String type = matcher.group(1);
            String id = matcher.group(2);
            String fullPlaceholder = matcher.group(0);
            
            // 只处理内容提供器类型的占位符
            if (contentProviderFactory.hasProvider(type)) {
                placeholders.add(new PlaceholderInfo(type, id, fullPlaceholder));
            }
        }
        
        return placeholders;
    }

    /**
     * 生成缓存键
     */
    private String generateCacheKey(PlaceholderInfo placeholder, String userId, String novelId) {
        return String.format("%s:%s:%s:%s", 
                placeholder.getType(), 
                placeholder.getId(), 
                userId, 
                novelId);
    }

    /**
     * 预解析模板中的所有占位符（缓存预热）
     */
    public Mono<Void> preResolvePlaceholders(String template, String userId, String novelId, Map<String, Object> parameters) {
        return resolvePlaceholders(template, userId, novelId, parameters)
                .doOnNext(result -> log.debug("预解析完成，缓存已预热"))
                .then();
    }

    /**
     * 清除缓存
     */
    public void clearCache() {
        placeholderCache.clear();
        log.info("占位符缓存已清除");
    }

    /**
     * 获取性能统计
     */
    public Mono<PlaceholderPerformanceStats> getPerformanceStats() {
        return Mono.fromCallable(() -> {
            long totalCount = totalResolveCount.get();
            long totalTime = totalResolveTime.get();
            
            PlaceholderPerformanceStats stats = new PlaceholderPerformanceStats();
            stats.totalResolveCount = totalCount;
            stats.parallelResolveCount = parallelResolveCount.get();
            stats.averageResolveTime = totalCount > 0 ? (double) totalTime / totalCount : 0.0;
            stats.cacheHitCount = cacheHitCount.get();
            stats.cacheSize = placeholderCache.size();
            stats.lastUpdateTime = LocalDateTime.now();
            
            return stats;
        });
    }

    /**
     * 占位符信息
     */
    private static class PlaceholderInfo {
        private final String type;
        private final String id;
        private final String fullPlaceholder;

        public PlaceholderInfo(String type, String id, String fullPlaceholder) {
            this.type = type;
            this.id = id;
            this.fullPlaceholder = fullPlaceholder;
        }

        public String getType() { return type; }
        public String getId() { return id; }
        public String getFullPlaceholder() { return fullPlaceholder; }
    }

    /**
     * 性能统计数据
     */
    public static class PlaceholderPerformanceStats {
        private long totalResolveCount;
        private long parallelResolveCount;
        private double averageResolveTime;
        private long cacheHitCount;
        private int cacheSize;
        private LocalDateTime lastUpdateTime;

        // Getters
        public long getTotalResolveCount() { return totalResolveCount; }
        public long getParallelResolveCount() { return parallelResolveCount; }
        public double getAverageResolveTime() { return averageResolveTime; }
        public long getCacheHitCount() { return cacheHitCount; }
        public int getCacheSize() { return cacheSize; }
        public LocalDateTime getLastUpdateTime() { return lastUpdateTime; }
        
        public double getCacheHitRate() {
            return totalResolveCount > 0 ? (double) cacheHitCount / totalResolveCount * 100 : 0.0;
        }
        
        public double getParallelRate() {
            return totalResolveCount > 0 ? (double) parallelResolveCount / totalResolveCount * 100 : 0.0;
        }
    }
    
    /**
     * 🚀 新增：资源清理 - 应用程序关闭时优雅关闭虚拟线程池
     */
    @PreDestroy
    public void shutdown() {
        if (VIRTUAL_EXECUTOR != null && !VIRTUAL_EXECUTOR.isShutdown()) {
            log.info("正在关闭虚拟线程池执行器...");
            try {
                VIRTUAL_EXECUTOR.shutdown();
                if (!VIRTUAL_EXECUTOR.awaitTermination(30, java.util.concurrent.TimeUnit.SECONDS)) {
                    log.warn("虚拟线程池未在30秒内完成关闭，强制关闭");
                    VIRTUAL_EXECUTOR.shutdownNow();
                }
                log.info("虚拟线程池执行器已成功关闭");
            } catch (InterruptedException e) {
                log.warn("等待虚拟线程池关闭时被中断", e);
                VIRTUAL_EXECUTOR.shutdownNow();
                Thread.currentThread().interrupt();
            } catch (Exception e) {
                log.error("关闭虚拟线程池时发生错误", e);
            }
        }
    }
    
    /**
     * 🚀 新增：获取虚拟线程池状态
     */
    public Mono<VirtualThreadPoolStats> getVirtualThreadPoolStats() {
        return Mono.fromCallable(() -> {
            VirtualThreadPoolStats stats = new VirtualThreadPoolStats();
            stats.isVirtualThreadSupported = !(VIRTUAL_EXECUTOR instanceof ForkJoinPool);
            stats.isShutdown = VIRTUAL_EXECUTOR.isShutdown();
            stats.isTerminated = VIRTUAL_EXECUTOR.isTerminated();
            stats.executorType = VIRTUAL_EXECUTOR.getClass().getSimpleName();
            return stats;
        });
    }
    
    /**
     * 虚拟线程池状态信息
     */
    public static class VirtualThreadPoolStats {
        private boolean isVirtualThreadSupported;
        private boolean isShutdown;
        private boolean isTerminated;
        private String executorType;
        
        // Getters
        public boolean isVirtualThreadSupported() { return isVirtualThreadSupported; }
        public boolean isShutdown() { return isShutdown; }
        public boolean isTerminated() { return isTerminated; }
        public String getExecutorType() { return executorType; }
    }
} 