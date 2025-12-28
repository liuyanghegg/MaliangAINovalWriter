/// LLM可观测性Repository接口
/// 用于管理后台LLM调用日志的查询和分析

import '../../../../models/admin/llm_observability_models.dart';

abstract class LLMObservabilityRepository {
  // ==================== 日志查询 ====================
  
  /// 获取所有LLM调用日志
  Future<PagedResponse<LLMTrace>> getAllTraces({
    int page = 0,
    int size = 20,
    String sortBy = 'timestamp',
    String sortDir = 'desc',
  });

  /// 根据用户ID获取LLM调用日志
  Future<PagedResponse<LLMTrace>> getTracesByUserId(
    String userId, {
    int page = 0,
    int size = 20,
  });

  /// 根据提供商获取LLM调用日志
  Future<PagedResponse<LLMTrace>> getTracesByProvider(
    String provider, {
    int page = 0,
    int size = 20,
  });

  /// 根据模型名称获取LLM调用日志
  Future<PagedResponse<LLMTrace>> getTracesByModel(
    String modelName, {
    int page = 0,
    int size = 20,
  });

  /// 根据时间范围获取LLM调用日志
  Future<PagedResponse<LLMTrace>> getTracesByTimeRange(
    DateTime startTime,
    DateTime endTime, {
    int page = 0,
    int size = 20,
  });

  /// 搜索LLM调用日志
  Future<PagedResponse<LLMTrace>> searchTraces(
    LLMTraceSearchCriteria criteria, {
    String? businessType,
    String? correlationId,
    String? traceId,
    String? type,
    String? tag,
  });

  /// 游标分页获取LLM调用日志
  Future<CursorPageResponse<LLMTrace>> getTracesByCursor({
    String? cursor,
    int limit = 50,
    String? userId,
    String? provider,
    String? model,
    String? sessionId,
    bool? hasError,
    String? businessType,
    String? correlationId,
    String? traceId,
    String? type,
    String? tag,
    DateTime? startTime,
    DateTime? endTime,
  });

  /// 获取单个LLM调用日志详情
  Future<LLMTrace?> getTraceById(String traceId);

  // ==================== 统计分析 ====================

  /// 获取LLM调用统计概览
  Future<Map<String, dynamic>> getOverviewStatistics({
    DateTime? startTime,
    DateTime? endTime,
  });

  /// 获取提供商统计信息
  Future<List<ProviderStatistics>> getProviderStatistics({
    DateTime? startTime,
    DateTime? endTime,
  });

  /// 获取模型统计信息
  Future<List<ModelStatistics>> getModelStatistics({
    DateTime? startTime,
    DateTime? endTime,
  });

  /// 获取用户统计信息
  Future<List<UserStatistics>> getUserStatistics({
    DateTime? startTime,
    DateTime? endTime,
  });

  /// 获取错误统计信息
  Future<List<ErrorStatistics>> getErrorStatistics({
    DateTime? startTime,
    DateTime? endTime,
  });

  /// 获取性能统计信息
  Future<PerformanceStatistics> getPerformanceStatistics({
    DateTime? startTime,
    DateTime? endTime,
  });

  /// 获取趋势数据（按时间分桶）
  Future<Map<String, dynamic>> getTrends({
    String? metric,
    String? groupBy,
    String? businessType,
    String? model,
    String? provider,
    String interval = 'hour',
    DateTime? startTime,
    DateTime? endTime,
  });

  // ==================== 导出功能 ====================

  /// 导出LLM调用日志
  Future<List<LLMTrace>> exportTraces({
    Map<String, dynamic>? filterCriteria,
  });

  // ==================== 系统管理 ====================

  /// 清理旧日志
  Future<Map<String, dynamic>> cleanupOldTraces(DateTime beforeTime);

  /// 获取系统健康状态
  Future<SystemHealthStatus> getSystemHealth();

  /// 获取数据库状态
  Future<Map<String, dynamic>> getDatabaseStatus();
}