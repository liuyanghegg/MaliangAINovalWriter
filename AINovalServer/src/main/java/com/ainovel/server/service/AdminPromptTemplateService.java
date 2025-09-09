package com.ainovel.server.service;

import com.ainovel.server.domain.model.AIFeatureType;
import com.ainovel.server.domain.model.EnhancedUserPromptTemplate;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

/**
 * 管理员提示词模板管理服务接口
 * 基于 EnhancedUserPromptTemplate 的统一管理
 */
public interface AdminPromptTemplateService {
    
    // ==================== 公共模板管理 ====================
    
    /**
     * 获取所有公共模板
     * 
     * @return 公共模板列表
     */
    Flux<EnhancedUserPromptTemplate> findAllPublicTemplates();
    
    /**
     * 根据功能类型获取公共模板
     * 
     * @param featureType 功能类型
     * @return 指定功能类型的公共模板列表
     */
    Flux<EnhancedUserPromptTemplate> findPublicTemplatesByFeatureType(AIFeatureType featureType);
    
    /**
     * 获取待审核的模板（非验证的公共模板）
     * 
     * @return 待审核的模板列表
     */
    Flux<EnhancedUserPromptTemplate> findPendingTemplates();
    
    /**
     * 获取已验证的官方模板
     * 
     * @return 官方认证模板列表
     */
    Flux<EnhancedUserPromptTemplate> findVerifiedTemplates();
    
    /**
     * 获取所有用户模板（包括私有和公共）
     * 
     * @param page 页码
     * @param size 每页大小
     * @param search 搜索关键词
     * @return 所有用户模板列表
     */
    Flux<EnhancedUserPromptTemplate> findAllUserTemplates(int page, int size, String search);
    
    // ==================== 模板创建与更新 ====================
    
    /**
     * 创建官方模板
     * 
     * @param template 模板信息
     * @param adminId 管理员ID
     * @return 创建的模板
     */
    Mono<EnhancedUserPromptTemplate> createOfficialTemplate(EnhancedUserPromptTemplate template, String adminId);
    
    /**
     * 更新公共模板
     * 
     * @param templateId 模板ID
     * @param template 更新的模板信息
     * @param adminId 管理员ID
     * @return 更新后的模板
     */
    Mono<EnhancedUserPromptTemplate> updatePublicTemplate(String templateId, EnhancedUserPromptTemplate template, String adminId);
    
    /**
     * 删除公共模板
     * 
     * @param templateId 模板ID
     * @param adminId 管理员ID
     * @return 删除操作结果
     */
    Mono<Void> deletePublicTemplate(String templateId, String adminId);
    
    // ==================== 审核与发布管理 ====================
    
    /**
     * 审核用户提交的模板
     * 
     * @param templateId 模板ID
     * @param approved 是否通过
     * @param adminId 管理员ID
     * @param reviewComment 审核意见
     * @return 审核后的模板
     */
    Mono<EnhancedUserPromptTemplate> reviewUserTemplate(String templateId, boolean approved, String adminId, String reviewComment);
    
    /**
     * 发布模板（设置为公开）
     * 
     * @param templateId 模板ID
     * @param adminId 管理员ID
     * @return 发布后的模板
     */
    Mono<EnhancedUserPromptTemplate> publishTemplate(String templateId, String adminId);
    
    /**
     * 取消发布模板（设置为私有）
     * 
     * @param templateId 模板ID
     * @param adminId 管理员ID
     * @return 取消发布后的模板
     */
    Mono<EnhancedUserPromptTemplate> unpublishTemplate(String templateId, String adminId);
    
    /**
     * 设置模板验证状态（官方认证）
     * 
     * @param templateId 模板ID
     * @param verified 是否验证
     * @param adminId 管理员ID
     * @return 更新后的模板
     */
    Mono<EnhancedUserPromptTemplate> setVerified(String templateId, boolean verified, String adminId);
    
    // ==================== 批量操作 ====================
    
    /**
     * 批量审核模板
     * 
     * @param templateIds 模板ID列表
     * @param approved 是否通过
     * @param adminId 管理员ID
     * @return 批量操作结果
     */
    Mono<Map<String, Object>> batchReviewTemplates(List<String> templateIds, boolean approved, String adminId);
    
    /**
     * 批量设置验证状态
     * 
     * @param templateIds 模板ID列表
     * @param verified 是否验证
     * @param adminId 管理员ID
     * @return 批量操作结果
     */
    Mono<Map<String, Object>> batchSetVerified(List<String> templateIds, boolean verified, String adminId);
    
    /**
     * 批量发布/取消发布
     * 
     * @param templateIds 模板ID列表
     * @param publish 是否发布
     * @param adminId 管理员ID
     * @return 批量操作结果
     */
    Mono<Map<String, Object>> batchPublishTemplates(List<String> templateIds, boolean publish, String adminId);
    
    // ==================== 统计与分析 ====================
    
    /**
     * 获取模板使用统计
     * 
     * @param templateId 模板ID
     * @return 使用统计信息
     */
    Mono<Map<String, Object>> getTemplateUsageStatistics(String templateId);
    
    /**
     * 获取公共模板统计信息
     * 
     * @return 统计信息
     */
    Mono<Map<String, Object>> getPublicTemplatesStatistics();
    
    /**
     * 获取用户模板统计信息
     * 
     * @param userId 用户ID（可选）
     * @return 用户统计信息
     */
    Mono<Map<String, Object>> getUserTemplatesStatistics(String userId);
    
    /**
     * 获取系统整体模板统计
     * 
     * @return 系统统计信息
     */
    Mono<Map<String, Object>> getSystemTemplatesStatistics();
    
    // ==================== 导入导出 ====================
    
    /**
     * 导出公共模板
     * 
     * @param templateIds 模板ID列表（空则导出所有）
     * @param adminId 管理员ID
     * @return 导出的模板列表
     */
    Mono<List<EnhancedUserPromptTemplate>> exportPublicTemplates(List<String> templateIds, String adminId);
    
    /**
     * 导入公共模板
     * 
     * @param templates 模板列表
     * @param adminId 管理员ID
     * @return 导入的模板列表
     */
    Mono<List<EnhancedUserPromptTemplate>> importPublicTemplates(List<EnhancedUserPromptTemplate> templates, String adminId);
    
    // ==================== 搜索与查询 ====================
    
    /**
     * 搜索公共模板
     * 
     * @param keyword 关键词
     * @param featureType 功能类型（可选）
     * @param verified 是否验证（可选）
     * @param page 页码
     * @param size 页大小
     * @return 搜索结果
     */
    Flux<EnhancedUserPromptTemplate> searchPublicTemplates(String keyword, AIFeatureType featureType, Boolean verified, int page, int size);
    
    /**
     * 获取热门公共模板
     * 
     * @param featureType 功能类型（可选）
     * @param limit 数量限制
     * @return 热门模板列表
     */
    Flux<EnhancedUserPromptTemplate> getPopularPublicTemplates(AIFeatureType featureType, int limit);
    
    /**
     * 获取最新公共模板
     * 
     * @param featureType 功能类型（可选）
     * @param limit 数量限制
     * @return 最新模板列表
     */
    Flux<EnhancedUserPromptTemplate> getLatestPublicTemplates(AIFeatureType featureType, int limit);
}