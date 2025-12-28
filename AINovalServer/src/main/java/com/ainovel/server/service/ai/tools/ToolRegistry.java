package com.ainovel.server.service.ai.tools;

import dev.langchain4j.agent.tool.ToolSpecification;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 工具注册中心
 * 管理所有可用的AI工具
 * 修复版本：解决并发问题，实现按上下文隔离的工具存储
 */
@Slf4j
@Component
public class ToolRegistry {
    
    // 全局工具池（用于系统级工具，如果有的话）
    private final Map<String, ToolDefinition> globalTools = new ConcurrentHashMap<>();
    
    // 按上下文隔离的工具存储：contextId -> toolName -> ToolDefinition
    private final Map<String, Map<String, ToolDefinition>> contextScopedTools = new ConcurrentHashMap<>();
    
    /**
     * 注册全局工具（系统级工具）
     */
    public void registerTool(ToolDefinition tool) {
        globalTools.put(tool.getName(), tool);
        log.info("Registered global tool: {}", tool.getName());
    }
    
    /**
     * 注册工具到特定上下文（修复版本：完全隔离上下文）
     */
    public void registerToolForContext(String context, ToolDefinition tool) {
        contextScopedTools.computeIfAbsent(context, unused -> new ConcurrentHashMap<>())
                         .put(tool.getName(), tool);
        log.info("Registered tool {} for context: {}", tool.getName(), context);
    }
    
    /**
     * 获取全局工具
     */
    public Optional<ToolDefinition> getTool(String name) {
        return Optional.ofNullable(globalTools.get(name));
    }
    
    /**
     * 获取特定上下文的工具
     */
    public Optional<ToolDefinition> getToolForContext(String context, String toolName) {
        Map<String, ToolDefinition> contextTools = contextScopedTools.get(context);
        if (contextTools != null) {
            return Optional.ofNullable(contextTools.get(toolName));
        }
        // 回退到全局工具
        return getTool(toolName);
    }
    
    /**
     * 获取所有可用工具名称（全局）
     */
    public Set<String> getAvailableToolNames() {
        return new HashSet<>(globalTools.keySet());
    }
    
    /**
     * 获取特定上下文的工具名称
     */
    public Set<String> getToolNamesForContext(String context) {
        Map<String, ToolDefinition> contextTools = contextScopedTools.get(context);
        if (contextTools != null) {
            return new HashSet<>(contextTools.keySet());
        }
        return Collections.emptySet();
    }
    
    /**
     * 获取所有工具规范（全局）
     */
    public List<ToolSpecification> getAllSpecifications() {
        return globalTools.values().stream()
            .map(ToolDefinition::getSpecification)
            .toList();
    }
    
    /**
     * 获取特定上下文的工具规范（修复版本：不再回退到全局工具）
     */
    public List<ToolSpecification> getSpecificationsForContext(String context) {
        Map<String, ToolDefinition> contextTools = contextScopedTools.get(context);
        if (contextTools == null || contextTools.isEmpty()) {
            log.debug("No tools found for context: {}", context);
            return Collections.emptyList();
        }
        
        List<ToolSpecification> specs = contextTools.values().stream()
            .map(ToolDefinition::getSpecification)
            .filter(Objects::nonNull)
            .toList();
            
        log.debug("Retrieved {} tool specifications for context: {}", specs.size(), context);
        return specs;
    }
    
    /**
     * 清除特定上下文的工具（修复版本：只清除上下文工具，不影响全局工具）
     */
    public void clearContextTools(String context) {
        Map<String, ToolDefinition> removedTools = contextScopedTools.remove(context);
        if (removedTools != null && !removedTools.isEmpty()) {
            log.info("Cleared {} tools for context: {}", removedTools.size(), context);
            for (String toolName : removedTools.keySet()) {
                log.debug("Removed tool: {} from context: {}", toolName, context);
            }
        } else {
            log.debug("No tools to clear for context: {}", context);
        }
    }
    
    /**
     * 获取工具注册状态信息
     */
    public String getRegistryStatus() {
        return String.format("Global tools: %d, Active contexts: %d", 
            globalTools.size(), contextScopedTools.size());
    }
    
    /**
     * 检查上下文是否存在
     */
    public boolean hasContext(String context) {
        return contextScopedTools.containsKey(context);
    }
    
    /**
     * 安全地获取工具并执行（修复版本：支持上下文工具）
     */
    public Object executeTool(String toolName, Map<String, Object> parameters) {
        return executeToolForContext(null, toolName, parameters);
    }
    
    /**
     * 在特定上下文中执行工具
     */
    public Object executeToolForContext(String context, String toolName, Map<String, Object> parameters) {
        log.debug("Attempting to execute tool: {} in context: {} with parameters: {}", toolName, context, parameters);
        
        ToolDefinition tool = null;
        
        // 优先从上下文中查找工具
        if (context != null) {
            Map<String, ToolDefinition> contextTools = contextScopedTools.get(context);
            if (contextTools != null) {
                tool = contextTools.get(toolName);
            }
        }
        
        // 如果上下文中没有，回退到全局工具
        if (tool == null) {
            tool = globalTools.get(toolName);
        }
        
        if (tool == null) {
            Set<String> availableTools = context != null ? getToolNamesForContext(context) : getAvailableToolNames();
            log.error("Tool not found: {} in context: {}. Available tools: {}", toolName, context, availableTools);
            throw new IllegalArgumentException("Unknown tool: " + toolName + " in context: " + context);
        }
        
        // 验证参数
        ToolDefinition.ValidationResult validation = tool.validateParameters(parameters);
        if (!validation.isValid()) {
            log.error("Invalid parameters for tool {}: {}", toolName, validation.errorMessage());
            throw new IllegalArgumentException("Invalid parameters for tool " + toolName + ": " + validation.errorMessage());
        }
        
        // 执行工具
        try {
            log.debug("Executing tool: {} in context: {}", toolName, context);
            Object result = tool.execute(parameters);
            log.debug("Tool {} executed successfully in context: {}", toolName, context);
            return result;
        } catch (Exception e) {
            log.error("Failed to execute tool: {} in context: {}", toolName, context, e);
            throw new RuntimeException("Tool execution failed: " + e.getMessage(), e);
        }
    }
}