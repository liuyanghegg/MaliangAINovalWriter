package com.ainovel.server.service.setting.generation;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.EnhancedUserPromptTemplate;
import com.ainovel.server.domain.model.settinggeneration.ReviewStatus;
import com.ainovel.server.domain.model.settinggeneration.SettingGenerationConfig;
import com.ainovel.server.repository.EnhancedUserPromptTemplateRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * 策略管理服务
 * 负责自定义策略的创建、修改、审核和分享
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class StrategyManagementService {
    
    private final EnhancedUserPromptTemplateRepository templateRepository;
    private final SettingGenerationStrategyFactory strategyFactory;
    
    /**
     * 创建用户自定义策略
     */
    public Mono<EnhancedUserPromptTemplate> createUserStrategy(String userId, CreateStrategyRequest request) {
        log.info("Creating user strategy for user: {}, name: {}", userId, request.getName());
        
        // 验证基础策略（如果指定）
        if (request.getBaseStrategyId() != null) {
            if (!strategyFactory.hasStrategy(request.getBaseStrategyId())) {
                return Mono.error(new IllegalArgumentException("Base strategy not found: " + request.getBaseStrategyId()));
            }
        }
        
        // 创建设定生成配置
        SettingGenerationConfig config = buildGenerationConfig(request);
        
        // 创建模板
        EnhancedUserPromptTemplate template = EnhancedUserPromptTemplate.builder()
            .userId(userId)
            .featureType(AIFeatureType.SETTING_TREE_GENERATION)
            .name(request.getName())
            .description(request.getDescription())
            .systemPrompt(request.getSystemPrompt())
            .userPrompt(request.getUserPrompt())
            .settingGenerationConfig(config)
            .isPublic(false) // 默认不公开
            .isDefault(false)
            .authorId(userId)
            .version(1)
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();
        
        return templateRepository.save(template)
            .doOnSuccess(savedTemplate -> 
                log.info("User strategy created successfully: {}", savedTemplate.getId()));
    }
    
    /**
     * 基于现有策略创建新策略
     */
    public Mono<EnhancedUserPromptTemplate> createStrategyFromBase(String userId, String baseTemplateId, 
                                                                 CreateFromBaseRequest request) {
        log.info("Creating strategy from base template: {}", baseTemplateId);
        
        return templateRepository.findById(baseTemplateId)
            .switchIfEmpty(Mono.error(new IllegalArgumentException("Base template not found: " + baseTemplateId)))
            .flatMap(baseTemplate -> {
                // 检查权限
                if (!baseTemplate.getIsPublic() && !baseTemplate.getUserId().equals(userId)) {
                    return Mono.error(new IllegalArgumentException("No permission to use base template"));
                }
                
                if (!baseTemplate.isSettingGenerationTemplate()) {
                    return Mono.error(new IllegalArgumentException("Base template is not for setting generation"));
                }
                
                // 克隆并修改配置
                SettingGenerationConfig baseConfig = baseTemplate.getSettingGenerationConfig();
                SettingGenerationConfig newConfig = applyModifications(baseConfig, request.getModifications());
                
                // 创建新模板
                EnhancedUserPromptTemplate newTemplate = EnhancedUserPromptTemplate.builder()
                    .userId(userId)
                    .featureType(AIFeatureType.SETTING_TREE_GENERATION)
                    .name(request.getName())
                    .description(request.getDescription())
                    .systemPrompt(request.getSystemPrompt() != null ? request.getSystemPrompt() : baseTemplate.getSystemPrompt())
                    .userPrompt(request.getUserPrompt() != null ? request.getUserPrompt() : baseTemplate.getUserPrompt())
                    .settingGenerationConfig(newConfig)
                    .sourceTemplateId(baseTemplateId)
                    .isPublic(false)
                    .isDefault(false)
                    .authorId(userId)
                    .version(1)
                    .createdAt(LocalDateTime.now())
                    .updatedAt(LocalDateTime.now())
                    .build();
                
                return templateRepository.save(newTemplate);
            });
    }
    
    /**
     * 提交策略审核
     */
    public Mono<EnhancedUserPromptTemplate> submitForReview(String templateId, String userId) {
        log.info("Submitting strategy for review: {}", templateId);
        
        return templateRepository.findByIdAndUserId(templateId, userId)
            .switchIfEmpty(Mono.error(new IllegalArgumentException("Template not found or no permission")))
            .flatMap(template -> {
                if (!template.isSettingGenerationTemplate()) {
                    return Mono.error(new IllegalArgumentException("Template is not for setting generation"));
                }
                
                ReviewStatus reviewStatus = template.getSettingGenerationConfig().getReviewStatus();
                if (!"DRAFT".equals(reviewStatus.getStatus()) && !"REJECTED".equals(reviewStatus.getStatus())) {
                    return Mono.error(new IllegalStateException("Strategy cannot be submitted for review in current state"));
                }
                
                // 更新审核状态
                reviewStatus.setStatus(ReviewStatus.Status.PENDING);
                reviewStatus.setSubmittedAt(LocalDateTime.now());
                template.setUpdatedAt(LocalDateTime.now());
                
                return templateRepository.save(template)
                    .doOnSuccess(savedTemplate -> 
                        log.info("Strategy submitted for review: {}", savedTemplate.getId()));
            });
    }
    
    /**
     * 审核策略
     */
    public Mono<EnhancedUserPromptTemplate> reviewStrategy(String templateId, String reviewerId, 
                                                         ReviewDecision decision) {
        log.info("Reviewing strategy: {}, decision: {}", templateId, decision.getAction());
        
        return templateRepository.findById(templateId)
            .switchIfEmpty(Mono.error(new IllegalArgumentException("Template not found")))
            .flatMap(template -> {
                if (!template.isSettingGenerationTemplate()) {
                    return Mono.error(new IllegalArgumentException("Template is not for setting generation"));
                }
                
                ReviewStatus reviewStatus = template.getSettingGenerationConfig().getReviewStatus();
                if (!ReviewStatus.Status.PENDING.equals(reviewStatus.getStatus())) {
                    return Mono.error(new IllegalStateException("Strategy is not pending review"));
                }
                
                // 更新审核状态
                reviewStatus.setStatus(decision.getStatus());
                reviewStatus.setReviewerId(reviewerId);
                reviewStatus.setReviewComment(decision.getComment());
                reviewStatus.setReviewedAt(LocalDateTime.now());
                
                if (decision.getRejectionReasons() != null) {
                    reviewStatus.setRejectionReasons(decision.getRejectionReasons());
                }
                
                if (decision.getImprovementSuggestions() != null) {
                    reviewStatus.setImprovementSuggestions(decision.getImprovementSuggestions());
                }
                
                // 如果审核通过，设置为公开
                if (ReviewStatus.Status.APPROVED.equals(decision.getStatus())) {
                    template.setIsPublic(true);
                }
                
                template.setUpdatedAt(LocalDateTime.now());
                
                return templateRepository.save(template)
                    .doOnSuccess(savedTemplate -> 
                        log.info("Strategy review completed: {}", savedTemplate.getId()));
            });
    }
    
    /**
     * 获取用户的策略列表
     */
    public Flux<EnhancedUserPromptTemplate> getUserStrategies(String userId, Pageable pageable) {
        return templateRepository.findByUserIdAndFeatureType(userId, AIFeatureType.SETTING_TREE_GENERATION)
            .skip(pageable.getOffset())
            .take(pageable.getPageSize());
    }
    
    /**
     * 获取公开的策略列表
     */
    public Flux<EnhancedUserPromptTemplate> getPublicStrategies(String category, Pageable pageable) {
        Flux<EnhancedUserPromptTemplate> baseQuery = templateRepository.findByFeatureTypeAndIsPublicTrue(
            AIFeatureType.SETTING_TREE_GENERATION
        );
        
        if (category != null && !category.isEmpty()) {
            baseQuery = baseQuery.filter(template -> 
                template.getCategories().contains(category)
            );
        }
        
        return baseQuery
            .skip(pageable.getOffset())
            .take(pageable.getPageSize());
    }
    
    /**
     * 获取待审核的策略列表
     */
    public Flux<EnhancedUserPromptTemplate> getPendingReviews(Pageable pageable) {
        return templateRepository.findByFeatureType(AIFeatureType.SETTING_TREE_GENERATION)
            .filter(template -> {
                SettingGenerationConfig config = template.getSettingGenerationConfig();
                return config != null && 
                       ReviewStatus.Status.PENDING.equals(config.getReviewStatus().getStatus());
            })
            .skip(pageable.getOffset())
            .take(pageable.getPageSize());
    }
    
    private SettingGenerationConfig buildGenerationConfig(CreateStrategyRequest request) {
        return SettingGenerationConfig.builder()
            .strategyName(request.getName())
            .description(request.getDescription())
            .nodeTemplates(request.getNodeTemplates())
            .expectedRootNodes(request.getExpectedRootNodes())
            .maxDepth(request.getMaxDepth())
            .baseStrategyId(request.getBaseStrategyId())
            .reviewStatus(ReviewStatus.builder()
                .status(ReviewStatus.Status.DRAFT)
                .build())
            .isSystemStrategy(false)
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();
    }
    
    private SettingGenerationConfig applyModifications(SettingGenerationConfig baseConfig, 
                                                     Map<String, Object> modifications) {
        // 这里可以实现复杂的配置修改逻辑
        // 为了简化，现在只做基本的字段更新
        SettingGenerationConfig.SettingGenerationConfigBuilder builder = SettingGenerationConfig.builder()
            .nodeTemplates(baseConfig.getNodeTemplates())
            .rules(baseConfig.getRules())
            .metadata(baseConfig.getMetadata())
            .expectedRootNodes(baseConfig.getExpectedRootNodes())
            .maxDepth(baseConfig.getMaxDepth())
            .baseStrategyId(baseConfig.getBaseStrategyId())
            .isSystemStrategy(false)
            .updatedAt(LocalDateTime.now());
        
        // 应用修改
        if (modifications.containsKey("strategyName")) {
            builder.strategyName((String) modifications.get("strategyName"));
        } else {
            builder.strategyName(baseConfig.getStrategyName());
        }
        
        if (modifications.containsKey("description")) {
            builder.description((String) modifications.get("description"));
        } else {
            builder.description(baseConfig.getDescription());
        }
        
        // 设置审核状态为草稿
        builder.reviewStatus(ReviewStatus.builder()
            .status(ReviewStatus.Status.DRAFT)
            .build());
        
        return builder.build();
    }
}

// DTO类
class CreateStrategyRequest {
    private String name;
    private String description;
    private String systemPrompt;
    private String userPrompt;
    private java.util.List<com.ainovel.server.domain.model.settinggeneration.NodeTemplateConfig> nodeTemplates;
    private Integer expectedRootNodes;
    private Integer maxDepth;
    private String baseStrategyId;
    
    // getters and setters
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getSystemPrompt() { return systemPrompt; }
    public void setSystemPrompt(String systemPrompt) { this.systemPrompt = systemPrompt; }
    public String getUserPrompt() { return userPrompt; }
    public void setUserPrompt(String userPrompt) { this.userPrompt = userPrompt; }
    public java.util.List<com.ainovel.server.domain.model.settinggeneration.NodeTemplateConfig> getNodeTemplates() { return nodeTemplates; }
    public void setNodeTemplates(java.util.List<com.ainovel.server.domain.model.settinggeneration.NodeTemplateConfig> nodeTemplates) { this.nodeTemplates = nodeTemplates; }
    public Integer getExpectedRootNodes() { return expectedRootNodes; }
    public void setExpectedRootNodes(Integer expectedRootNodes) { this.expectedRootNodes = expectedRootNodes; }
    public Integer getMaxDepth() { return maxDepth; }
    public void setMaxDepth(Integer maxDepth) { this.maxDepth = maxDepth; }
    public String getBaseStrategyId() { return baseStrategyId; }
    public void setBaseStrategyId(String baseStrategyId) { this.baseStrategyId = baseStrategyId; }
}

class CreateFromBaseRequest {
    private String name;
    private String description;
    private String systemPrompt;
    private String userPrompt;
    private Map<String, Object> modifications;
    
    // getters and setters
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getSystemPrompt() { return systemPrompt; }
    public void setSystemPrompt(String systemPrompt) { this.systemPrompt = systemPrompt; }
    public String getUserPrompt() { return userPrompt; }
    public void setUserPrompt(String userPrompt) { this.userPrompt = userPrompt; }
    public Map<String, Object> getModifications() { return modifications; }
    public void setModifications(Map<String, Object> modifications) { this.modifications = modifications; }
}

class ReviewDecision {
    private ReviewStatus.Status status;
    private String comment;
    private java.util.List<String> rejectionReasons;
    private java.util.List<String> improvementSuggestions;
    
    public String getAction() { return status.name(); }
    
    // getters and setters
    public ReviewStatus.Status getStatus() { return status; }
    public void setStatus(ReviewStatus.Status status) { this.status = status; }
    public String getComment() { return comment; }
    public void setComment(String comment) { this.comment = comment; }
    public java.util.List<String> getRejectionReasons() { return rejectionReasons; }
    public void setRejectionReasons(java.util.List<String> rejectionReasons) { this.rejectionReasons = rejectionReasons; }
    public java.util.List<String> getImprovementSuggestions() { return improvementSuggestions; }
    public void setImprovementSuggestions(java.util.List<String> improvementSuggestions) { this.improvementSuggestions = improvementSuggestions; }
}