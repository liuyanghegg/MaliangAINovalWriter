package com.ainovel.server.service.ai.tools.fallback.impl;

import com.ainovel.server.service.ai.tools.fallback.ToolFallbackParser;
import com.ainovel.server.service.ai.tools.fallback.ToolFallbackRegistry;
import lombok.extern.slf4j.Slf4j;

import java.util.*;

/**
 * 默认实现：内置若干解析器并按工具名索引；
 * 使用责任链模式依次尝试解析。
 */
@Slf4j
public class DefaultToolFallbackRegistry implements ToolFallbackRegistry {

    private final Map<String, List<ToolFallbackParser>> toolNameToParsers = new HashMap<>();

    public DefaultToolFallbackRegistry(List<ToolFallbackParser> parsers) {
        if (parsers != null) {
            for (ToolFallbackParser p : parsers) {
                toolNameToParsers.computeIfAbsent(p.getToolName(), k -> new ArrayList<>()).add(p);
            }
        }
    }

    public DefaultToolFallbackRegistry() {
        this(Collections.emptyList());
    }

    public void register(ToolFallbackParser parser) {
        toolNameToParsers.computeIfAbsent(parser.getToolName(), k -> new ArrayList<>()).add(parser);
    }

    @Override
    public List<ToolFallbackParser> getParsers(String toolName) {
        return toolNameToParsers.getOrDefault(toolName, Collections.emptyList());
    }
}


