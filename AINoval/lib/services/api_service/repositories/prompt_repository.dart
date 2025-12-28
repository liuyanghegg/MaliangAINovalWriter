import 'package:ainoval/models/prompt_models.dart';

/// 提示词管理接口
abstract class PromptRepository {
  /// 获取所有提示词
  Future<Map<AIFeatureType, PromptData>> getAllPrompts();
  
  /// 获取指定功能类型的提示词
  Future<PromptData> getPrompt(AIFeatureType featureType);
  
  /// 保存提示词
  Future<PromptData> savePrompt(AIFeatureType featureType, String promptText);
  
  /// 删除提示词（恢复为默认）
  Future<PromptData> deletePrompt(AIFeatureType featureType);
  
  /// 获取提示词模板列表
  Future<List<PromptTemplate>> getPromptTemplates();
  
  /// 获取指定功能类型的提示词模板列表
  Future<List<PromptTemplate>> getPromptTemplatesByFeatureType(AIFeatureType featureType);
  
  /// 获取提示词模板详情
  Future<PromptTemplate> getPromptTemplateById(String templateId);
  
  /// 从公共模板复制创建私有模板
  Future<PromptTemplate> copyPublicTemplate(PromptTemplate template);
  
  /// 切换模板收藏状态
  Future<PromptTemplate> toggleTemplateFavorite(PromptTemplate template);
  
  /// 创建提示词模板
  Future<PromptTemplate> createPromptTemplate({
    required String name,
    required String content,
    required AIFeatureType featureType,
    required String authorId,
    String? description,
    List<String>? tags,
  });
  
  /// 更新提示词模板
  Future<PromptTemplate> updatePromptTemplate({
    required String templateId,
    String? name,
    String? content,
  });
  
  /// 删除提示词模板
  Future<void> deletePromptTemplate(String templateId);
  
  /// 流式优化提示词
  void optimizePromptStream(
    String templateId,
    OptimizePromptRequest request, {
    Function(double)? onProgress,
    Function(OptimizationResult)? onResult,
    Function(String)? onError,
  });
  
  /// 取消优化
  void cancelOptimization();
  
  /// 优化提示词
  Future<OptimizationResult> optimizePrompt({
    required String templateId,
    required OptimizePromptRequest request,
  });
  
  /// 生成场景摘要
  Future<String> generateSceneSummary({
    required String novelId,
    required String sceneId,
  });
  
  /// 从摘要生成场景
  Future<String> generateSceneFromSummary({
    required String novelId,
    required String summary,
  });

  // ====================== 统一提示词聚合接口 ======================

  /// 获取功能的完整提示词包
  /// 包含系统默认、用户自定义、公开模板、最近使用等全部信息
  Future<PromptPackage> getCompletePromptPackage(
    AIFeatureType featureType, {
    bool includePublic = true,
  });

  /// 获取用户的提示词概览
  /// 跨功能统计信息，用于用户Dashboard
  Future<UserPromptOverview> getUserPromptOverview();

  /// 批量获取多个功能的提示词包
  /// 用于前端初始化时一次性获取所有需要的数据
  Future<Map<AIFeatureType, PromptPackage>> getBatchPromptPackages({
    List<AIFeatureType>? featureTypes,
    bool includePublic = true,
  });

  /// 预热用户缓存
  /// 系统启动或用户登录时调用，提升后续响应速度
  Future<CacheWarmupResult> warmupCache();

  /// 获取系统缓存统计
  /// 用于系统监控和性能分析
  Future<AggregationCacheStats> getCacheStats();

  /// 获取虚拟线程性能统计
  /// 用于监控占位符解析性能
  Future<PlaceholderPerformanceStats> getPlaceholderPerformanceStats();

  /// 健康检查接口
  /// 检查聚合服务是否正常工作
  Future<SystemHealthStatus> healthCheck();

  // ====================== 增强用户提示词模板管理接口 ======================

  /// 创建增强用户提示词模板
  Future<EnhancedUserPromptTemplate> createEnhancedPromptTemplate(
    CreatePromptTemplateRequest request,
  );

  /// 更新增强用户提示词模板
  Future<EnhancedUserPromptTemplate> updateEnhancedPromptTemplate(
    String templateId,
    UpdatePromptTemplateRequest request,
  );

  /// 删除增强用户提示词模板
  Future<void> deleteEnhancedPromptTemplate(String templateId);

  /// 获取增强用户提示词模板详情
  Future<EnhancedUserPromptTemplate?> getEnhancedPromptTemplate(String templateId);

  /// 获取用户所有增强提示词模板
  Future<List<EnhancedUserPromptTemplate>> getUserEnhancedPromptTemplates({
    AIFeatureType? featureType,
  });

  /// 获取用户收藏的增强模板
  Future<List<EnhancedUserPromptTemplate>> getUserFavoriteEnhancedTemplates();

  /// 获取最近使用的增强模板
  Future<List<EnhancedUserPromptTemplate>> getRecentlyUsedEnhancedTemplates({
    int limit = 10,
  });

  /// 发布模板为公开
  Future<EnhancedUserPromptTemplate> publishEnhancedTemplate(
    String templateId,
    PublishTemplateRequest request,
  );

  /// 通过分享码获取模板
  Future<EnhancedUserPromptTemplate?> getEnhancedTemplateByShareCode(String shareCode);

  /// 复制公开增强模板
  Future<EnhancedUserPromptTemplate> copyPublicEnhancedTemplate(String templateId);

  /// 获取公开增强模板列表
  Future<List<EnhancedUserPromptTemplate>> getPublicEnhancedTemplates(
    AIFeatureType featureType, {
    int page = 0,
    int size = 20,
  });

  /// 收藏增强模板
  Future<void> favoriteEnhancedTemplate(String templateId);

  /// 取消收藏增强模板
  Future<void> unfavoriteEnhancedTemplate(String templateId);

  /// 评分增强模板
  Future<EnhancedUserPromptTemplate> rateEnhancedTemplate(
    String templateId,
    int rating,
  );

  /// 记录增强模板使用
  Future<void> recordEnhancedTemplateUsage(String templateId);

  /// 获取用户所有标签
  Future<List<String>> getUserPromptTags();

  // ==================== 默认模板功能 ====================

  /// 设置默认模板
  Future<EnhancedUserPromptTemplate> setDefaultEnhancedTemplate(String templateId);

  /// 获取默认模板
  Future<EnhancedUserPromptTemplate?> getDefaultEnhancedTemplate(AIFeatureType featureType);
}