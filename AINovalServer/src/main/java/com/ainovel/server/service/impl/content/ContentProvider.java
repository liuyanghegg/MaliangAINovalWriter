package com.ainovel.server.service.impl.content;

import reactor.core.publisher.Mono;
import com.ainovel.server.web.dto.request.UniversalAIRequestDto;
import java.util.Map;
import java.util.Set;

/**
 * 内容提供器接口
 * 统一抽象不同类型内容的获取逻辑
 */
public interface ContentProvider {
    /**
     * 获取内容（原有方法）
     * @param id 内容ID
     * @param request 通用AI请求
     * @return 内容结果
     */
    Mono<ContentResult> getContent(String id, UniversalAIRequestDto request);
    
    /**
     * 获取内容（新方法 - 占位符解析专用）
     * @param userId 用户ID
     * @param novelId 小说ID
     * @param contentId 内容ID（可选，某些提供器可能不需要）
     * @param parameters 额外参数
     * @return 内容字符串
     */
    Mono<String> getContentForPlaceholder(String userId, String novelId, String contentId, Map<String, Object> parameters);
    
    /**
     * [新增] 快速获取内容的预估长度
     * 用于积分成本预估，只获取内容长度而不获取完整内容
     * @param contextParameters 从通用AI请求中提取的上下文参数 (如: { "sceneId": "xxx", "chapterId": "xxx" })
     * @return 内容的字符长度。如果内容不存在或不适用，返回 Mono.just(0)
     */
    Mono<Integer> getEstimatedContentLength(Map<String, Object> contextParameters);
    
    /**
     * 获取内容类型
     * @return 内容类型
     */
    String getType();
    
    /**
     * [新增] 获取内容的语义标签
     * 用于智能去重和内容分类，支持多个标签
     * @return 语义标签集合，如: ["character", "setting", "narrative"]
     */
    default Set<String> getSemanticTags() {
        return Set.of(getType());
    }
    
    /**
     * [新增] 检查是否与其他内容类型有重叠
     * 用于智能去重，避免在{{context}}中重复包含已通过专用占位符处理的内容
     * @param otherContentTypes 其他已处理的内容类型
     * @return 如果存在重叠返回true，否则返回false
     */
    default boolean hasOverlapWith(Set<String> otherContentTypes) {
        Set<String> myTags = getSemanticTags();
        return myTags.stream().anyMatch(otherContentTypes::contains);
    }
    
    /**
     * [新增] 获取内容的优先级
     * 数值越小优先级越高，用于解决内容冲突时的决策
     * @return 优先级数值，默认为100
     */
    default int getPriority() {
        return 100;
    }
} 