package com.ainovel.server.service.prompt;

import java.util.Map;

import reactor.core.publisher.Mono;

/**
 * 内容占位符解析器接口
 * 负责将占位符转换为实际的内容
 */
public interface ContentPlaceholderResolver {

    /**
     * 解析占位符并获取实际内容
     * 
     * @param placeholder 占位符名称（不包含{{}}）
     * @param parameters 参数上下文
     * @param userId 用户ID
     * @param novelId 小说ID
     * @return 解析后的内容
     */
    Mono<String> resolvePlaceholder(String placeholder, Map<String, Object> parameters, 
                                   String userId, String novelId);

    /**
     * 检查是否支持指定的占位符
     * 
     * @param placeholder 占位符名称
     * @return 是否支持
     */
    boolean supports(String placeholder);

    /**
     * 获取占位符的描述信息
     * 
     * @param placeholder 占位符名称
     * @return 描述信息
     */
    String getPlaceholderDescription(String placeholder);

    /**
     * 占位符解析结果
     */
    class ResolveResult {
        private final boolean success;
        private final String content;
        private final String errorMessage;

        public ResolveResult(boolean success, String content, String errorMessage) {
            this.success = success;
            this.content = content;
            this.errorMessage = errorMessage;
        }

        public static ResolveResult success(String content) {
            return new ResolveResult(true, content, null);
        }

        public static ResolveResult error(String errorMessage) {
            return new ResolveResult(false, null, errorMessage);
        }

        public boolean isSuccess() { return success; }
        public String getContent() { return content; }
        public String getErrorMessage() { return errorMessage; }
    }
} 