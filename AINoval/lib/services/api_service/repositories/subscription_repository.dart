import '../../../models/admin/subscription_models.dart';
import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/utils/logger.dart';

/// 订阅管理仓库接口
abstract interface class SubscriptionRepository {
  /// 获取所有订阅计划
  Future<List<SubscriptionPlan>> getAllPlans();

  /// 获取单个订阅计划
  Future<SubscriptionPlan> getPlanById(String id);

  /// 创建订阅计划
  Future<SubscriptionPlan> createPlan(SubscriptionPlan plan);

  /// 更新订阅计划
  Future<SubscriptionPlan> updatePlan(String id, SubscriptionPlan plan);

  /// 删除订阅计划
  Future<void> deletePlan(String id);

  /// 切换订阅计划状态
  Future<SubscriptionPlan> togglePlanStatus(String id, bool active);

  /// 获取订阅统计信息
  Future<SubscriptionStatistics> getSubscriptionStatistics();

  /// 获取用户订阅历史
  Future<List<UserSubscription>> getUserSubscriptions(String userId);

  /// 获取活跃的用户订阅
  Future<UserSubscription?> getActiveUserSubscription(String userId);
} 

/// 面向用户端的公开计划仓库
class PublicSubscriptionRepository {
  final ApiClient _apiClient;
  static const String _tag = 'PublicSubscriptionRepository';

  PublicSubscriptionRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<SubscriptionPlan>> listActivePlans() async {
    final res = await _apiClient.get('/subscription-plans');
    AppLogger.d(_tag, '订阅计划原始响应类型: ${res.runtimeType}');
    AppLogger.d(_tag, '订阅计划原始响应内容: $res');
    // 兼容两种返回结构：
    // 1) { success, data: [...] }
    // 2) 直接返回数组 [...]
    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(SubscriptionPlan.fromJson)
            .toList();
      }
    } else if (res is List) {
      return res
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPlan.fromJson)
          .toList();
    }
    AppLogger.w(_tag, '订阅计划响应结构非预期，返回空数组');
    // 非预期结构时返回空数组，避免UI崩溃
    return [];
  }

  Future<List<Map<String, dynamic>>> listActiveCreditPacks() async {
    final res = await _apiClient.get('/credit-packs');
    if (res is Map<String, dynamic> && res['data'] is List) {
      return (res['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}