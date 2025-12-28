package com.ainovel.server.service.ai.tools;

import dev.langchain4j.agent.tool.ToolSpecification;
import java.util.Map;

/**
 * 工具定义接口
 * 定义AI可调用的工具规范
 */
public interface ToolDefinition {
    
    /**
     * 获取工具名称
     */
    String getName();
    
    /**
     * 获取工具描述
     */
    String getDescription();
    
    /**
     * 获取工具规范
     */
    ToolSpecification getSpecification();
    
    /**
     * 执行工具
     * @param parameters 工具参数
     * @return 执行结果
     */
    Object execute(Map<String, Object> parameters);
    
    /**
     * 验证参数
     * @param parameters 待验证的参数
     * @return 验证结果
     */
    default ValidationResult validateParameters(Map<String, Object> parameters) {
        return ValidationResult.success();
    }
    
    /**
     * 验证结果
     */
    record ValidationResult(boolean isValid, String errorMessage) {
        public static ValidationResult success() {
            return new ValidationResult(true, null);
        }
        
        public static ValidationResult failure(String errorMessage) {
            return new ValidationResult(false, errorMessage);
        }
    }
}