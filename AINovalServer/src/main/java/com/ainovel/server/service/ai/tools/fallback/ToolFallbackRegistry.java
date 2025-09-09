package com.ainovel.server.service.ai.tools.fallback;

import java.util.List;

/**
 * 工具兜底解析器注册表：按工具名聚合多个解析策略，
 * 以便按顺序尝试（责任链模式）。
 */
public interface ToolFallbackRegistry {

    /**
     * 返回指定工具名的解析器列表（按优先级排序）。
     */
    List<ToolFallbackParser> getParsers(String toolName);
}


