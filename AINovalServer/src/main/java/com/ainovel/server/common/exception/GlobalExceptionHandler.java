package com.ainovel.server.common.exception;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.config.MappingExceptionLogger;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mapping.MappingException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.bind.support.WebExchangeBindException;
import reactor.core.publisher.Mono;
import org.springframework.security.authentication.BadCredentialsException;

import java.util.HashMap;
import java.util.Map;

/**
 * 全局异常处理器
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @Autowired
    private MappingExceptionLogger mappingExceptionLogger;
    
    /**
     * 处理验证异常
     */
    @ExceptionHandler(ValidationException.class)
    public Mono<ResponseEntity<ApiResponse<?>>> handleValidationException(ValidationException e) {
        log.warn("验证异常: {}", e.getMessage());
        return Mono.just(ResponseEntity.badRequest()
                .body(ApiResponse.error(e.getMessage(), "VALIDATION_ERROR")));
    }
    
    /**
     * 处理绑定异常（请求参数验证失败）
     */
    @ExceptionHandler(WebExchangeBindException.class)
    public Mono<ResponseEntity<ApiResponse<?>>> handleBindException(WebExchangeBindException e) {
        Map<String, String> errors = new HashMap<>();
        e.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });
        
        String message = "请求参数验证失败";
        if (!errors.isEmpty()) {
            // 获取第一个错误信息作为主要错误提示
            message = errors.values().iterator().next();
        }
        
        log.warn("请求参数验证失败: {}", errors);
        return Mono.just(ResponseEntity.badRequest()
                .body(ApiResponse.error(message, "VALIDATION_ERROR", errors)));
    }
    
    /**
     * 处理认证失败异常（如用户名/密码错误、Token无效等）
     */
    @ExceptionHandler(BadCredentialsException.class)
    public Mono<ResponseEntity<ApiResponse<?>>> handleBadCredentials(BadCredentialsException e) {
        log.warn("认证失败: {}", e.getMessage());
        return Mono.just(ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.error("用户名或密码错误", "INVALID_CREDENTIALS")));
    }
    
    /**
     * 处理积分不足异常
     */
    @ExceptionHandler(InsufficientCreditsException.class)
    public Mono<ResponseEntity<ApiResponse<?>>> handleInsufficientCreditsException(InsufficientCreditsException e) {
        log.warn("积分不足: {}", e.getMessage());
        return Mono.just(ResponseEntity.status(HttpStatus.PAYMENT_REQUIRED)
                .body(ApiResponse.error(e.getMessage(), "INSUFFICIENT_CREDITS")));
    }
    
    /**
     * 专门处理Spring Data MongoDB映射异常
     */
    @ExceptionHandler(MappingException.class)
    public Mono<ResponseEntity<ApiResponse<?>>> handleMappingException(MappingException e) {
        log.error("🚨 MongoDB映射异常被全局异常处理器捕获");
        
        // 使用详细的映射异常记录器
        try {
            // 尝试从异常堆栈和消息中提取更多信息
            Class<?> entityClass = null;
            String documentInfo = "无法获取原始文档 - 异常在映射过程中抛出";
            String operationContext = "未知操作";
            
            log.error("🔍 开始分析MappingException堆栈...");
            
            // 检查异常堆栈，寻找相关的实体类和上下文
            StackTraceElement[] stackTrace = e.getStackTrace();
            for (int i = 0; i < stackTrace.length; i++) {
                StackTraceElement element = stackTrace[i];
                String className = element.getClassName();
                String methodName = element.getMethodName();
                
                log.error("   [{}] 堆栈: {}.{}", i, className, methodName);
                
                // 寻找我们的domain model类
                if (className.contains("com.ainovel.server.domain.model")) {
                    try {
                        entityClass = Class.forName(className);
                        documentInfo = "问题发生在: " + className + "." + methodName;
                        operationContext = "实体类直接操作";
                        log.error("   ✅ 找到domain model类: {}", className);
                        break;
                    } catch (ClassNotFoundException ignored) {
                        // 继续寻找
                    }
                }
                
                // 检查是否是在处理LLMTrace相关的操作
                if (className.contains("LLMTraceService") ||
                    className.contains("LLMObservability")) {
                    documentInfo = "问题发生在LLM观测服务中: " + className + "." + methodName;
                    operationContext = "LLM观测服务操作";
                    // 如果没有找到具体的实体类，默认使用LLMTrace
                    if (entityClass == null) {
                        try {
                            entityClass = Class.forName("com.ainovel.server.domain.model.observability.LLMTrace");
                            log.error("   🎯 LLMTrace操作推断: 设置实体类为LLMTrace");
                        } catch (ClassNotFoundException ignored) {
                            // 忽略
                        }
                    }
                }
                
                // 检查ReactiveMongoTemplate操作
                if (className.contains("ReactiveMongoTemplate")) {
                    operationContext = "MongoDB模板操作: " + methodName;
                    log.error("   📊 MongoDB操作检测: {}.{}", className, methodName);
                }
                
                // 检查MappingMongoConverter
                if (className.contains("MappingMongoConverter")) {
                    operationContext = "MongoDB映射转换: " + methodName;
                    log.error("   🔄 映射转换检测: {}.{}", className, methodName);
                }
                
                // 如果找到了实体类，不要太早退出，继续查找更多上下文
                if (i > 10) break; // 但不要查找太深
            }
            
            log.error("🎯 异常分析结果: entityClass={}, operationContext={}", 
                entityClass != null ? entityClass.getSimpleName() : "null", operationContext);
            
            // 记录详细的映射异常信息
            mappingExceptionLogger.logMappingException(
                entityClass != null ? entityClass : Object.class, 
                documentInfo + " [" + operationContext + "]", 
                e
            );
            
        } catch (Exception logException) {
            log.error("记录映射异常时发生错误", logException);
        }
        
        return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("数据映射错误，请稍后重试", "MAPPING_ERROR")));
    }
    
    /**
     * 处理其他异常
     */
    @ExceptionHandler(Exception.class)
    public Mono<ResponseEntity<ApiResponse<?>>> handleGenericException(Exception e) {
        // 检查是否包含MappingException作为根本原因
        Throwable rootCause = getRootCause(e);
        if (rootCause instanceof MappingException) {
            log.error("🔍 发现包装的MongoDB映射异常");
            return handleMappingException((MappingException) rootCause);
        }
        
        // 检查异常链中是否有MappingException
        Throwable current = e;
        while (current != null) {
            if (current instanceof MappingException) {
                log.error("🔍 在异常链中发现MongoDB映射异常");
                return handleMappingException((MappingException) current);
            }
            current = current.getCause();
        }
        
        log.error("未处理的异常", e);
        return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("服务器内部错误，请稍后重试", "INTERNAL_ERROR")));
    }
    
    /**
     * 获取异常的根本原因
     */
    private Throwable getRootCause(Throwable throwable) {
        Throwable cause = throwable.getCause();
        if (cause == null || cause == throwable) {
            return throwable;
        }
        return getRootCause(cause);
    }
}