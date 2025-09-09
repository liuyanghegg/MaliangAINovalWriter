package com.ainovel.server.service.ai.observability;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * 可观测性配置开关。
 */
@Component
public class ObservabilityConfig {

    /**
     * 是否在 LLMTrace 中写入请求参数里的 toolSpecifications 明细。
     * 为节省存储空间，可通过配置关闭。
     * 配置键：observability.llmtrace.include-tool-specifications，默认 true
     */
    @Value("${observability.llmtrace.include-tool-specifications:false}")
    private boolean includeToolSpecifications;

    public boolean isIncludeToolSpecifications() {
        return includeToolSpecifications;
    }
}


