package com.ainovel.server.service.ai.tools.fallback;

import java.util.Map;

/**
 * 通用工具兜底解析策略接口
 * 当大模型未按函数调用规范返回，而是直接输出文本/JSON时，
 * 实现该接口的策略可将原始文本解析为对应工具的参数对象。
 */
public interface ToolFallbackParser {

    /**
     * 该兜底策略对应的工具名称（如：text_to_settings）。
     */
    String getToolName();

    /**
     * 判断原始文本是否可能由本策略解析。
     */
    boolean canParse(String rawText);

    /**
     * 将原始文本解析为对应工具的参数对象（通常为 Map 结构）。
     * 若无法解析，抛出异常或返回 null 由上层处理。
     */
    Map<String, Object> parseToToolParams(String rawText) throws Exception;
}


