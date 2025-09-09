package com.ainovel.server.controller;

import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ainovel.server.common.response.ApiResponse;
import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.dto.RenderPromptRequest;
import com.ainovel.server.service.UnifiedPromptService;
import com.ainovel.server.service.prompt.AIFeaturePromptProvider;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

/**
 * 统一提示词系统控制器
 * 整合所有提示词相关功能的API入口
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/prompts")
public class UnifiedPromptController {

    @Autowired
    private UnifiedPromptService promptService;

    /**
     * 获取系统提示词
     */
    @PostMapping("/{featureType}/system")
    public Mono<ApiResponse<String>> getSystemPrompt(
            @PathVariable AIFeatureType featureType,
            @RequestBody Map<String, Object> parameters,
            Authentication authentication) {
        
        String userId = authentication.getName();
        log.debug("获取系统提示词: userId={}, featureType={}", userId, featureType);

        return promptService.getSystemPrompt(featureType, userId, parameters)
                .map(ApiResponse::success)
                .onErrorResume(error -> {
                    log.error("获取系统提示词失败: featureType={}, error={}", featureType, error.getMessage());
                    return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
                });
    }

    /**
     * 获取用户提示词
     */
    @PostMapping("/{featureType}/user")
    public Mono<ApiResponse<String>> getUserPrompt(
            @PathVariable AIFeatureType featureType,
            @RequestParam(required = false) String templateId,
            @RequestBody Map<String, Object> parameters,
            Authentication authentication) {
        
        String userId = authentication.getName();
        log.debug("获取用户提示词: userId={}, featureType={}, templateId={}", userId, featureType, templateId);

        return promptService.getUserPrompt(featureType, userId, templateId, parameters)
                .map(ApiResponse::success)
                .onErrorResume(error -> {
                    log.error("获取用户提示词失败: featureType={}, error={}", featureType, error.getMessage());
                    return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
                });
    }

    /**
     * 获取完整的提示词对话
     */
    @PostMapping("/{featureType}/conversation")
    public Mono<ApiResponse<UnifiedPromptService.PromptConversation>> getPromptConversation(
            @PathVariable AIFeatureType featureType,
            @RequestParam(required = false) String templateId,
            @RequestBody Map<String, Object> parameters,
            Authentication authentication) {
        
        String userId = authentication.getName();
        log.debug("获取完整提示词对话: userId={}, featureType={}, templateId={}", userId, featureType, templateId);

        return promptService.getCompletePromptConversation(featureType, userId, templateId, parameters)
                .map(ApiResponse::success)
                .onErrorResume(error -> {
                    log.error("获取完整提示词对话失败: featureType={}, error={}", featureType, error.getMessage());
                    return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
                });
    }

    /**
     * 获取功能类型支持的占位符
     */
    @GetMapping("/{featureType}/placeholders")
    public Mono<ApiResponse<Set<String>>> getSupportedPlaceholders(@PathVariable AIFeatureType featureType) {
        log.debug("获取支持的占位符: featureType={}", featureType);

        try {
            Set<String> placeholders = promptService.getSupportedPlaceholders(featureType);
            return Mono.just(ApiResponse.success(placeholders));
        } catch (Exception error) {
            log.error("获取支持的占位符失败: featureType={}, error={}", featureType, error.getMessage());
            return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
        }
    }

    /**
     * 验证提示词内容中的占位符
     */
    @PostMapping("/{featureType}/validate")
    public Mono<ApiResponse<AIFeaturePromptProvider.ValidationResult>> validatePrompt(
            @PathVariable AIFeatureType featureType,
            @RequestBody RenderPromptRequest request) {
        
        log.debug("验证提示词占位符: featureType={}", featureType);

        try {
            AIFeaturePromptProvider.ValidationResult result = promptService.validatePlaceholders(featureType, request.getContent());
            return Mono.just(ApiResponse.success(result));
        } catch (Exception error) {
            log.error("验证提示词占位符失败: featureType={}, error={}", featureType, error.getMessage());
            return Mono.just(ApiResponse.error("验证失败: " + error.getMessage()));
        }
    }

    /**
     * 获取所有支持的功能类型
     */
    @GetMapping("/feature-types")
    public Mono<ApiResponse<Set<AIFeatureType>>> getSupportedFeatureTypes() {
        log.debug("获取支持的功能类型");

        try {
            Set<AIFeatureType> featureTypes = promptService.getSupportedFeatureTypes();
            return Mono.just(ApiResponse.success(featureTypes));
        } catch (Exception error) {
            log.error("获取支持的功能类型失败: error={}", error.getMessage());
            return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
        }
    }

    /**
     * 检查功能类型是否支持
     */
    @GetMapping("/{featureType}/supported")
    public Mono<ApiResponse<Boolean>> isFeatureTypeSupported(@PathVariable AIFeatureType featureType) {
        log.debug("检查功能类型支持: featureType={}", featureType);

        try {
            boolean supported = promptService.hasPromptProvider(featureType);
            return Mono.just(ApiResponse.success(supported));
        } catch (Exception error) {
            log.error("检查功能类型支持失败: featureType={}, error={}", featureType, error.getMessage());
            return Mono.just(ApiResponse.error("检查失败: " + error.getMessage()));
        }
    }

    /**
     * 获取提示词提供器的默认系统提示词
     */
    @GetMapping("/{featureType}/default/system")
    public Mono<ApiResponse<String>> getDefaultSystemPrompt(@PathVariable AIFeatureType featureType) {
        log.debug("获取默认系统提示词: featureType={}", featureType);

        try {
            AIFeaturePromptProvider provider = promptService.getPromptProvider(featureType);
            if (provider != null) {
                String defaultPrompt = provider.getDefaultSystemPrompt();
                return Mono.just(ApiResponse.success(defaultPrompt));
            } else {
                return Mono.just(ApiResponse.error("不支持的功能类型: " + featureType));
            }
        } catch (Exception error) {
            log.error("获取默认系统提示词失败: featureType={}, error={}", featureType, error.getMessage());
            return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
        }
    }

    /**
     * 获取提示词提供器的默认用户提示词
     */
    @GetMapping("/{featureType}/default/user")
    public Mono<ApiResponse<String>> getDefaultUserPrompt(@PathVariable AIFeatureType featureType) {
        log.debug("获取默认用户提示词: featureType={}", featureType);

        try {
            AIFeaturePromptProvider provider = promptService.getPromptProvider(featureType);
            if (provider != null) {
                String defaultPrompt = provider.getDefaultUserPrompt();
                return Mono.just(ApiResponse.success(defaultPrompt));
            } else {
                return Mono.just(ApiResponse.error("不支持的功能类型: " + featureType));
            }
        } catch (Exception error) {
            log.error("获取默认用户提示词失败: featureType={}, error={}", featureType, error.getMessage());
            return Mono.just(ApiResponse.error("获取失败: " + error.getMessage()));
        }
    }
} 