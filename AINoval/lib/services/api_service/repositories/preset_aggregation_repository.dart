import 'package:ainoval/models/preset_models.dart';

/// 预设聚合仓储接口
/// 提供一站式的预设获取和缓存接口
abstract class PresetAggregationRepository {
  /// 获取功能的完整预设包
  /// [featureType] 功能类型
  /// [novelId] 小说ID（可选）
  /// 返回完整预设包，包含系统预设、用户预设、快捷访问预设等全部信息
  Future<PresetPackage> getCompletePresetPackage(
    String featureType, {
    String? novelId,
  });

  /// 获取用户的预设概览
  /// 返回跨功能统计信息，用于用户Dashboard
  Future<UserPresetOverview> getUserPresetOverview();

  /// 批量获取多个功能的预设包
  /// [featureTypes] 功能类型列表，如果为null则获取所有类型
  /// [novelId] 小说ID（可选）
  /// 返回功能类型到预设包的映射，用于前端初始化时一次性获取所有需要的数据
  Future<Map<String, PresetPackage>> getBatchPresetPackages({
    List<String>? featureTypes,
    String? novelId,
  });

  /// 预热用户缓存
  /// 系统启动或用户登录时调用，提升后续响应速度
  /// 返回缓存预热结果
  Future<CacheWarmupResult> warmupCache();

  /// 获取系统缓存统计
  /// 用于系统监控和性能分析
  /// 返回聚合服务的缓存统计信息
  Future<AggregationCacheStats> getCacheStats();

  /// 清除预设聚合缓存
  /// 用于调试和强制刷新缓存
  /// 返回清除结果消息
  Future<String> clearCache();

  /// 聚合服务健康检查
  /// 检查预设聚合服务的健康状态
  /// 返回健康状态信息
  Future<Map<String, dynamic>> healthCheck();

  /// 🚀 获取用户的所有预设聚合数据
  /// 一次性返回用户的所有预设相关数据，避免多次API调用
  /// [novelId] 小说ID（可选）
  /// 返回完整的用户预设聚合数据
  Future<AllUserPresetData> getAllUserPresetData({String? novelId});
}