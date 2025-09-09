import '../../../../models/admin/subscription_models.dart';
import '../../../../utils/logger.dart';
import '../../base/api_client.dart';
import '../../base/api_exception.dart';
import '../subscription_repository.dart';

/// 订阅管理仓库实现
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final ApiClient _apiClient;
  static const String _tag = 'SubscriptionRepository';

  SubscriptionRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<SubscriptionPlan>> getAllPlans() async {
    try {
      AppLogger.d(_tag, '🔍 获取所有订阅计划');
      final response = await _apiClient.get('/admin/subscription-plans');
      
      // 添加详细的响应调试日志
      AppLogger.d(_tag, '📡 订阅计划原始响应类型: ${response.runtimeType}');
      AppLogger.d(_tag, '📡 订阅计划原始响应内容: $response');
      
      // 解析响应数据
      dynamic rawData;
      if (response is Map<String, dynamic>) {
        AppLogger.d(_tag, '📄 订阅计划响应是Map，包含的键: ${response.keys.toList()}');
        if (response.containsKey('data')) {
          rawData = response['data'];
          AppLogger.d(_tag, '📄 订阅计划data字段类型: ${rawData.runtimeType}');
          AppLogger.d(_tag, '📄 订阅计划data字段内容: $rawData');
        } else if (response.containsKey('success') && response['success'] == true) {
          rawData = response['data'] ?? response;
          AppLogger.d(_tag, '📄 订阅计划success结构，提取的数据类型: ${rawData.runtimeType}');
        } else {
          rawData = response;
          AppLogger.d(_tag, '📄 订阅计划直接使用整个response');
        }
      } else {
        rawData = response;
        AppLogger.d(_tag, '📄 订阅计划响应不是Map，直接使用');
      }
      
      // 检查数据类型并转换为List（兼容 List 与 {data: List} 两种结构）
      List<dynamic> data;
      if (rawData is List) {
        data = rawData;
        AppLogger.d(_tag, '✅ 订阅计划成功获得List，长度: ${data.length}');
      } else if (rawData is Map<String, dynamic>) {
        AppLogger.d(_tag, '📄 订阅计划rawData是Map，包含的键: ${rawData.keys.toList()}');
        if (rawData.containsKey('content')) {
          data = (rawData['content'] as List?) ?? [];
          AppLogger.d(_tag, '✅ 订阅计划从content字段获得List，长度: ${data.length}');
        } else if (rawData.containsKey('data') && rawData['data'] is List) {
          data = (rawData['data'] as List);
          AppLogger.d(_tag, '✅ 订阅计划从data字段获得List，长度: ${data.length}');
        } else {
          // 尝试将 Map 视为单个对象列表（极端兼容）
          AppLogger.w(_tag, '⚠️ 订阅计划Map中未发现content/data列表字段，返回空列表');
          data = [];
        }
      } else {
        AppLogger.e(_tag, '❌ 订阅计划无法识别的数据类型: ${rawData.runtimeType}');
        throw ApiException(-1, '订阅计划数据格式错误: 未知的数据类型 ${rawData.runtimeType}');
      }
      
      AppLogger.d(_tag, '✅ 获取订阅计划成功: count=${data.length}');
      return data.map((json) => SubscriptionPlan.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.e(_tag, '❌ 获取订阅计划失败', e);
      rethrow;
    }
  }

  @override
  Future<SubscriptionPlan> getPlanById(String id) async {
    try {
      AppLogger.d(_tag, '🔍 获取订阅计划详情: id=$id');
      final response = await _apiClient.get('/admin/subscription-plans/$id');
      
      dynamic planData;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        planData = response['data'];
      } else if (response is Map<String, dynamic>) {
        planData = response;
      } else {
        throw ApiException(-1, '订阅计划详情数据格式错误');
      }
      
      AppLogger.d(_tag, '✅ 获取订阅计划详情成功: id=$id');
      return SubscriptionPlan.fromJson(planData as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e(_tag, '❌ 获取订阅计划详情失败', e);
      rethrow;
    }
  }

  @override
  Future<SubscriptionPlan> createPlan(SubscriptionPlan plan) async {
    try {
      AppLogger.d(_tag, '📝 创建订阅计划: ${plan.planName}');
      final response = await _apiClient.post('/admin/subscription-plans', data: plan.toJson());
      
      dynamic planData;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        planData = response['data'];
      } else if (response is Map<String, dynamic>) {
        planData = response;
      } else {
        throw ApiException(-1, '创建订阅计划响应格式错误');
      }
      
      AppLogger.d(_tag, '✅ 创建订阅计划成功: ${plan.planName}');
      return SubscriptionPlan.fromJson(planData as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e(_tag, '❌ 创建订阅计划失败', e);
      rethrow;
    }
  }

  @override
  Future<SubscriptionPlan> updatePlan(String id, SubscriptionPlan plan) async {
    try {
      AppLogger.d(_tag, '📝 更新订阅计划: id=$id');
      final response = await _apiClient.put('/admin/subscription-plans/$id', data: plan.toJson());
      
      dynamic planData;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        planData = response['data'];
      } else if (response is Map<String, dynamic>) {
        planData = response;
      } else {
        throw ApiException(-1, '更新订阅计划响应格式错误');
      }
      
      AppLogger.d(_tag, '✅ 更新订阅计划成功: id=$id');
      return SubscriptionPlan.fromJson(planData as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e(_tag, '❌ 更新订阅计划失败', e);
      rethrow;
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      AppLogger.d(_tag, '🗑️ 删除订阅计划: id=$id');
      await _apiClient.delete('/admin/subscription-plans/$id');
      AppLogger.d(_tag, '✅ 删除订阅计划成功: id=$id');
    } catch (e) {
      AppLogger.e(_tag, '❌ 删除订阅计划失败', e);
      rethrow;
    }
  }

  @override
  Future<SubscriptionPlan> togglePlanStatus(String id, bool active) async {
    try {
      AppLogger.d(_tag, '🔄 切换订阅计划状态: id=$id, active=$active');
      final response = await _apiClient.patch('/admin/subscription-plans/$id/status', data: {
        'active': active,
      });
      
      dynamic planData;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        planData = response['data'];
      } else if (response is Map<String, dynamic>) {
        planData = response;
      } else {
        throw ApiException(-1, '切换订阅计划状态响应格式错误');
      }
      
      AppLogger.d(_tag, '✅ 切换订阅计划状态成功: id=$id, active=$active');
      return SubscriptionPlan.fromJson(planData as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e(_tag, '❌ 切换订阅计划状态失败', e);
      rethrow;
    }
  }

  @override
  Future<SubscriptionStatistics> getSubscriptionStatistics() async {
    try {
      AppLogger.d(_tag, '📊 获取订阅统计信息');
      // TODO: 等后端提供订阅统计接口
      // 临时返回模拟数据
      await Future.delayed(const Duration(milliseconds: 500));
      
      const statistics = SubscriptionStatistics(
        totalPlans: 3,
        activePlans: 2,
        totalSubscriptions: 150,
        activeSubscriptions: 120,
        trialSubscriptions: 25,
        monthlyRevenue: 5000.0,
        yearlyRevenue: 60000.0,
      );
      
      AppLogger.d(_tag, '✅ 获取订阅统计信息成功');
      return statistics;
    } catch (e) {
      AppLogger.e(_tag, '❌ 获取订阅统计信息失败', e);
      rethrow;
    }
  }

  @override
  Future<List<UserSubscription>> getUserSubscriptions(String userId) async {
    try {
      AppLogger.d(_tag, '🔍 获取用户订阅历史: userId=$userId');
      // TODO: 等后端提供用户订阅历史接口
      // 临时返回空列表
      await Future.delayed(const Duration(milliseconds: 300));
      
      AppLogger.d(_tag, '✅ 获取用户订阅历史成功: userId=$userId');
      return [];
    } catch (e) {
      AppLogger.e(_tag, '❌ 获取用户订阅历史失败', e);
      rethrow;
    }
  }

  @override
  Future<UserSubscription?> getActiveUserSubscription(String userId) async {
    try {
      AppLogger.d(_tag, '🔍 获取用户当前订阅: userId=$userId');
      // TODO: 等后端提供当前订阅接口
      // 临时返回null
      await Future.delayed(const Duration(milliseconds: 300));
      
      AppLogger.d(_tag, '✅ 获取用户当前订阅成功: userId=$userId');
      return null;
    } catch (e) {
      AppLogger.e(_tag, '❌ 获取用户当前订阅失败', e);
      rethrow;
    }
  }
} 