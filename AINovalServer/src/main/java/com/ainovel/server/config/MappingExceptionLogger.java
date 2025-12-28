package com.ainovel.server.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.stereotype.Component;
import org.bson.Document;

/**
 * MongoDB映射异常监听器
 * 用于捕获和详细记录映射过程中的异常信息，帮助排查复杂嵌套对象的映射问题
 */
@Component
public class MappingExceptionLogger {
    
    private static final Logger logger = LoggerFactory.getLogger(MappingExceptionLogger.class);
    
    /**
     * 记录映射异常的详细信息
     * 
     * @param entity 出问题的实体类
     * @param document 原始MongoDB文档
     * @param exception 映射异常
     */
    public void logMappingException(Class<?> entity, Object document, Throwable exception) {
        logger.error("🚨🚨🚨 MongoDB映射失败详情 🚨🚨🚨");
        logger.error("═══════════════════════════════════════");
        
        // 增强的实体类分析
        Class<?> actualProblemClass = analyzeActualProblemClass(entity, exception);
        
        logger.error("📋 基本信息:");
        logger.error("   ├─ 报告实体类: {}", entity.getName());
        if (!actualProblemClass.equals(entity)) {
            logger.error("   ├─ 🎯 实际问题类: {}", actualProblemClass.getName());
            logger.error("   ├─ 🔍 问题类型: {}", getClassType(actualProblemClass));
        }
        logger.error("   ├─ 异常类型: {}", exception.getClass().getSimpleName());
        logger.error("   └─ 异常消息: {}", exception.getMessage());
        
        logger.error("═══════════════════════════════════════");
        logger.error("📄 文档信息:");
        if (document instanceof Document doc) {
            logger.error("   ├─ 文档字段: {}", doc.keySet());
            logger.error("   └─ 文档大小: {} 个字段", doc.size());
            // 不打印完整文档内容，避免日志过长
        } else {
            logger.error("   └─ 原始数据类型: {}", document != null ? document.getClass().getSimpleName() : "null");
        }
        
        logger.error("═══════════════════════════════════════");
        logger.error("🔍 堆栈分析:");
        analyzeStackTrace(exception);
        
        // 如果是参数名缺失异常，提供更多上下文
        if (exception.getMessage() != null && exception.getMessage().contains("does not have a name")) {
            logger.error("═══════════════════════════════════════");
            logger.error("💡 参数名缺失问题诊断:");
            logger.error("   ├─ 问题类型: 构造函数参数无法解析");
            
            // LLMTrace特定的诊断信息
            if (isLLMTraceRelated(actualProblemClass)) {
                analyzeLLMTraceSpecificIssues(actualProblemClass);
            } else {
                logger.error("   ├─ 可能原因:");
                logger.error("   │  ├─ 1. 构造函数参数缺少 @JsonProperty 注解");
                logger.error("   │  ├─ 2. 编译时未启用 -parameters 选项");
                logger.error("   │  ├─ 3. @NoArgsConstructor 访问级别为 PRIVATE");
                logger.error("   │  └─ 4. Lombok 生成的构造函数缺少必要注解");
                logger.error("   └─ 建议修复:");
                logger.error("      ├─ 检查 {} 类的所有嵌套类", actualProblemClass.getSimpleName());
                logger.error("      ├─ 确保所有 @NoArgsConstructor 都是 public");
                logger.error("      └─ 为复杂构造函数添加 @JsonCreator + @JsonProperty");
            }
        }
        
        logger.error("═══════════════════════════════════════");
        logger.error("📚 完整异常堆栈:");
        logger.error("", exception);
        logger.error("🚨🚨🚨 映射异常分析结束 🚨🚨🚨");
    }
    
    /**
     * 分析实际出问题的类
     */
    private Class<?> analyzeActualProblemClass(Class<?> reportedEntity, Throwable exception) {
        // 如果报告的实体类就是Object，说明需要深度分析
        if (reportedEntity == Object.class) {
            Class<?> foundClass = searchForLLMTraceInnerClass(exception);
            if (foundClass != null) {
                return foundClass;
            }
            
            // 尝试从异常消息中提取类信息
            String message = exception.getMessage();
            if (message != null && message.contains("Parameter")) {
                // 尝试从异常堆栈中查找创建实例的相关信息
                foundClass = searchForClassInStackTrace(exception);
                if (foundClass != null) {
                    return foundClass;
                }
            }
        }
        
        return reportedEntity;
    }
    
    /**
     * 在异常堆栈中搜索LLMTrace内嵌类
     */
    private Class<?> searchForLLMTraceInnerClass(Throwable exception) {
        StackTraceElement[] stackTrace = exception.getStackTrace();
        
        // 常见的LLMTrace内嵌类列表
        String[] innerClasses = {
            "Request", "Response", "MessageInfo", "ToolCallInfo", 
            "Parameters", "ToolSpecification", "Metadata", 
            "TokenUsageInfo", "Error", "Performance"
        };
        
        boolean isLLMTraceOperation = false;
        
        for (StackTraceElement element : stackTrace) {
            String className = element.getClassName();
            String methodName = element.getMethodName();
            
            // 检查是否在处理LLMTrace相关的操作
            if (className.contains("LLMTraceService") || 
                className.contains("LLMObservability") ||
                className.contains("LLMTrace")) {
                isLLMTraceOperation = true;
                logger.error("   🎯 [LLMTrace操作检测] 在 {}.{} 中发现LLMTrace相关操作", 
                    className.substring(className.lastIndexOf('.') + 1), methodName);
                
                // 尝试从方法名或上下文推断内嵌类
                for (String innerClass : innerClasses) {
                    if (methodName.toLowerCase().contains(innerClass.toLowerCase()) ||
                        className.contains("$" + innerClass)) {
                        try {
                            Class<?> innerClazz = Class.forName("com.ainovel.server.domain.model.observability.LLMTrace$" + innerClass);
                            logger.error("   ✅ [内嵌类识别] 找到问题类: {}", innerClazz.getName());
                            return innerClazz;
                        } catch (ClassNotFoundException e) {
                            // 继续查找
                        }
                    }
                }
            }
            
            // 检查Spring Data MongoDB的相关操作
            if (className.contains("MappingMongoConverter") && 
                methodName.contains("readValue")) {
                logger.error("   🔍 [映射上下文] 在 {}.{} 中发现映射操作", 
                    className.substring(className.lastIndexOf('.') + 1), methodName);
            }
            
            // 检查ReactiveMongoTemplate的find操作
            if (className.contains("ReactiveMongoTemplate") && 
                (methodName.contains("find") || methodName.contains("execute"))) {
                logger.error("   📊 [MongoDB操作] 在 {}.{} 中执行查询操作", 
                    className.substring(className.lastIndexOf('.') + 1), methodName);
            }
        }
        
        // 如果检测到是LLMTrace相关操作，但找不到具体内嵌类，返回LLMTrace主类
        if (isLLMTraceOperation) {
            try {
                Class<?> mainClazz = Class.forName("com.ainovel.server.domain.model.observability.LLMTrace");
                logger.error("   📋 [默认识别] 无法确定具体内嵌类，返回LLMTrace主类");
                return mainClazz;
            } catch (ClassNotFoundException e) {
                logger.error("   ❌ [错误] 无法找到LLMTrace主类");
            }
        }
        
        return null;
    }
    
    /**
     * 在异常堆栈中搜索类信息
     */
    private Class<?> searchForClassInStackTrace(Throwable exception) {
        StackTraceElement[] stackTrace = exception.getStackTrace();
        
        for (StackTraceElement element : stackTrace) {
            String className = element.getClassName();
            
            // 查找我们的domain model类
            if (className.contains("com.ainovel.server.domain.model")) {
                try {
                    return Class.forName(className);
                } catch (ClassNotFoundException e) {
                    // 继续搜索
                }
            }
        }
        
        return null;
    }
    
    /**
     * 获取类类型描述
     */
    private String getClassType(Class<?> clazz) {
        if (clazz.isEnum()) {
            return "枚举类";
        } else if (clazz.isMemberClass()) {
            return "内嵌类";
        } else if (clazz.isLocalClass()) {
            return "局部类";
        } else if (clazz.isAnonymousClass()) {
            return "匿名类";
        } else {
            return "普通类";
        }
    }
    
    /**
     * 检查是否与LLMTrace相关
     */
    private boolean isLLMTraceRelated(Class<?> clazz) {
        return clazz.getName().contains("LLMTrace");
    }
    
    /**
     * 分析LLMTrace特定的问题
     */
    private void analyzeLLMTraceSpecificIssues(Class<?> problemClass) {
        logger.error("   ├─ 🎯 LLMTrace映射问题专项分析:");
        logger.error("   │  ├─ 目标类: {}", problemClass.getSimpleName());
        
        // 分析具体的内嵌类问题
        if (problemClass.getName().contains("$")) {
            String innerClassName = problemClass.getSimpleName();
            logger.error("   │  ├─ 内嵌类: {}", innerClassName);
            logger.error("   │  └─ 问题分析:");
            
            switch (innerClassName) {
                case "Request":
                    logger.error("   │     ├─ Request类有@JsonCreator构造函数");
                    logger.error("   │     ├─ 检查messages和parameters字段初始化");
                    logger.error("   │     └─ 确认所有@JsonProperty注解正确");
                    break;
                case "Parameters":
                    logger.error("   │     ├─ Parameters类包含复杂的providerSpecific字段");
                    logger.error("   │     ├─ 检查safeConvertToMap方法调用");
                    logger.error("   │     └─ 确认Map<String, Object>类型转换");
                    break;
                case "MessageInfo":
                    logger.error("   │     ├─ MessageInfo类有toolCalls集合");
                    logger.error("   │     ├─ 检查List<ToolCallInfo>初始化");
                    logger.error("   │     └─ 确认嵌套对象映射");
                    break;
                case "ToolSpecification":
                    logger.error("   │     ├─ ToolSpecification包含parameters Map");
                    logger.error("   │     ├─ 检查safeConvertToMap转换");
                    logger.error("   │     └─ 可能是convertToolParameters方法问题");
                    break;
                default:
                    logger.error("   │     ├─ 通用内嵌类映射问题");
                    logger.error("   │     └─ 检查@JsonCreator和@JsonProperty注解");
            }
        } else {
            logger.error("   │  └─ LLMTrace主类映射问题，检查内嵌类实例化");
        }
        
        logger.error("   └─ 🔧 LLMTrace修复建议:");
        logger.error("      ├─ 1. 检查所有@NoArgsConstructor是否为public");
        logger.error("      ├─ 2. 确认@JsonCreator构造函数参数都有@JsonProperty");
        logger.error("      ├─ 3. 检查safeConvertToMap方法的Map转换逻辑");
        logger.error("      ├─ 4. 验证Builder.Default字段的初始化");
        logger.error("      └─ 5. 考虑添加@PersistenceCreator注解");
    }
    
    /**
     * 分析异常堆栈，找出具体的问题类
     */
    private void analyzeStackTrace(Throwable exception) {
        StackTraceElement[] stackTrace = exception.getStackTrace();
        for (int i = 0; i < Math.min(stackTrace.length, 10); i++) {
            StackTraceElement element = stackTrace[i];
            String className = element.getClassName();
            String methodName = element.getMethodName();
            
            if (className.contains("com.ainovel.server.domain.model")) {
                logger.error("   ├─ [{}] 问题实体: {}.{}", i, className, methodName);
            } else if (className.contains("MappingMongoConverter") || 
                      className.contains("BasicPersistentEntity") ||
                      className.contains("PersistentEntityParameterValueProvider")) {
                logger.error("   ├─ [{}] 映射组件: {}.{}", i, className.substring(className.lastIndexOf('.') + 1), methodName);
            }
        }
    }
    
    /**
     * 记录实体映射开始信息（调试用）
     */
    public void logMappingStart(Class<?> entity, Object document) {
        if (logger.isTraceEnabled()) {
            logger.trace("🔄 开始映射实体: {} <- {}", entity.getSimpleName(), 
                document instanceof Document ? ((Document) document).keySet() : "Unknown");
        }
    }
    
    /**
     * 记录实体映射成功信息（调试用）
     */
    public void logMappingSuccess(Class<?> entity) {
        if (logger.isTraceEnabled()) {
            logger.trace("✅ 映射成功: {}", entity.getSimpleName());
        }
    }
}