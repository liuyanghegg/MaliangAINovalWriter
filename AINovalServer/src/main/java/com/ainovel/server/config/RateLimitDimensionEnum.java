package com.ainovel.server.config;

import lombok.Getter;

/**
 * 限流维度枚举
 * 定义不同粒度的限流控制维度
 */
@Getter
public enum RateLimitDimensionEnum {
    
    /**
     * 全局维度 - 按供应商限流
     * 适用场景：API密钥级别的限流控制
     * 键格式：provider:{providerCode}
     */
    GLOBAL("provider:{providerCode}", "全局供应商限流"),
    
    /**
     * 用户维度 - 按用户+供应商限流
     * 适用场景：用户级别的配额控制
     * 键格式：user:{userId}:provider:{providerCode}
     */
    USER_PROVIDER("user:{userId}:provider:{providerCode}", "用户供应商限流"),
    
    /**
     * 模型维度 - 按供应商+模型限流
     * 适用场景：特定模型的限流控制（如GPT-4限制更严格）
     * 键格式：provider:{providerCode}:model:{modelName}
     */
    PROVIDER_MODEL("provider:{providerCode}:model:{modelName}", "供应商模型限流"),
    
    /**
     * 用户模型维度 - 按用户+供应商+模型限流
     * 适用场景：细粒度的用户级模型限流
     * 键格式：user:{userId}:provider:{providerCode}:model:{modelName}
     */
    USER_PROVIDER_MODEL("user:{userId}:provider:{providerCode}:model:{modelName}", "用户供应商模型限流"),
    
    /**
     * 任务类型维度 - 按任务类型+供应商限流
     * 适用场景：不同任务类型的差异化限流
     * 键格式：task:{taskType}:provider:{providerCode}
     */
    TASK_PROVIDER("task:{taskType}:provider:{providerCode}", "任务供应商限流"),
    
    /**
     * 混合维度 - 按用户+任务类型+供应商+模型限流
     * 适用场景：最细粒度的限流控制
     * 键格式：user:{userId}:task:{taskType}:provider:{providerCode}:model:{modelName}
     */
    HYBRID("user:{userId}:task:{taskType}:provider:{providerCode}:model:{modelName}", "混合维度限流");
    
    private final String keyTemplate;
    private final String description;
    
    RateLimitDimensionEnum(String keyTemplate, String description) {
        this.keyTemplate = keyTemplate;
        this.description = description;
    }
    
    /**
     * 生成限流键
     */
    public String generateKey(RateLimitKeyContext context) {
        String key = keyTemplate;
        
        // 替换占位符
        if (context.getProviderCode() != null) {
            key = key.replace("{providerCode}", context.getProviderCode());
        }
        if (context.getUserId() != null) {
            key = key.replace("{userId}", context.getUserId());
        }
        if (context.getModelName() != null) {
            key = key.replace("{modelName}", context.getModelName());
        }
        if (context.getTaskType() != null) {
            key = key.replace("{taskType}", context.getTaskType());
        }
        
        // 移除未替换的占位符段
        key = removeUnreplacedSegments(key);
        
        return key;
    }
    
    /**
     * 移除未替换的占位符段
     */
    private String removeUnreplacedSegments(String key) {
        // 移除包含大括号的段
        String[] segments = key.split(":");
        StringBuilder result = new StringBuilder();
        
        for (String segment : segments) {
            if (!segment.contains("{") && !segment.contains("}")) {
                if (result.length() > 0) {
                    result.append(":");
                }
                result.append(segment);
            }
        }
        
        return result.toString();
    }
    
    /**
     * 检查是否包含用户维度
     */
    public boolean hasUserDimension() {
        return keyTemplate.contains("{userId}");
    }
    
    /**
     * 检查是否包含模型维度
     */
    public boolean hasModelDimension() {
        return keyTemplate.contains("{modelName}");
    }
    
    /**
     * 检查是否包含任务维度
     */
    public boolean hasTaskDimension() {
        return keyTemplate.contains("{taskType}");
    }
    
    /**
     * 限流键上下文
     */
    @lombok.Data
    @lombok.Builder
    @lombok.AllArgsConstructor
    @lombok.NoArgsConstructor
    public static class RateLimitKeyContext {
        private String providerCode;
        private String userId;
        private String modelName;
        private String taskType;
        
        public static RateLimitKeyContext of(String providerCode, String userId, String modelName) {
            return RateLimitKeyContext.builder()
                    .providerCode(providerCode)
                    .userId(userId)
                    .modelName(modelName)
                    .build();
        }
        
        public static RateLimitKeyContext of(String providerCode, String userId, String modelName, String taskType) {
            return RateLimitKeyContext.builder()
                    .providerCode(providerCode)
                    .userId(userId)
                    .modelName(modelName)
                    .taskType(taskType)
                    .build();
        }
    }
} 