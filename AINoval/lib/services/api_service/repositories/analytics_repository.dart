import 'package:ainoval/models/analytics_data.dart';

abstract class AnalyticsRepository {
  /// 获取用户分析概览数据
  Future<AnalyticsData> getAnalyticsOverview();

  /// 获取Token使用趋势数据
  /// [viewMode] 查看模式：daily, monthly, cumulative, range
  /// [startDate] 开始日期（range模式使用）
  /// [endDate] 结束日期（range模式使用）
  Future<List<TokenUsageData>> getTokenUsageTrend({
    required AnalyticsViewMode viewMode,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 获取功能使用统计数据
  /// [viewMode] 查看模式：daily, monthly, range
  /// [startDate] 开始日期（range模式使用）
  /// [endDate] 结束日期（range模式使用）
  Future<List<FunctionUsageData>> getFunctionUsageStats({
    required AnalyticsViewMode viewMode,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 获取大模型使用占比数据（按模型名聚合）
  /// [viewMode] 查看模式：daily, monthly, range
  /// [startDate] 开始日期（range模式使用）
  /// [endDate] 结束日期（range模式使用）
  Future<List<ModelUsageData>> getModelUsageStats({
    required AnalyticsViewMode viewMode,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 获取Token使用记录列表
  /// [limit] 返回记录数量限制
  /// [offset] 偏移量
  Future<List<TokenUsageRecord>> getTokenUsageRecords({
    int limit = 20,
    int offset = 0,
  });

  /// 获取今日Token使用汇总
  Future<Map<String, dynamic>> getTodayTokenSummary();
}

