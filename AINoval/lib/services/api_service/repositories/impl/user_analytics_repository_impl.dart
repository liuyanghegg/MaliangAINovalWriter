import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/utils/logger.dart';

class UserAnalyticsRepositoryImpl {
  final ApiClient _apiClient;
  final String _tag = 'UserAnalyticsRepository';

  UserAnalyticsRepositoryImpl({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, int>> getMyDailyWords({DateTime? start, DateTime? end}) async {
    try {
      final qp = <String, dynamic>{};
      if (start != null) qp['start'] = start.toIso8601String();
      if (end != null) qp['end'] = end.toIso8601String();
      final res = await _apiClient.getWithParams('/analytics/writing/daily', queryParameters: qp);
      if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
        final data = res['data'] as Map<String, dynamic>;
        final daily = (data['dailyWords'] as Map).map((k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0));
        return daily;
      }
      return {};
    } catch (e) {
      AppLogger.e(_tag, '获取每日写作字数失败', e);
      return {};
    }
  }

  Future<Map<String, dynamic>> getMyWordsBySource({DateTime? start, DateTime? end}) async {
    try {
      final qp = <String, dynamic>{};
      if (start != null) qp['start'] = start.toIso8601String();
      if (end != null) qp['end'] = end.toIso8601String();
      final res = await _apiClient.getWithParams('/analytics/writing/source', queryParameters: qp);
      if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
        return res['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      AppLogger.e(_tag, '获取写作来源统计失败', e);
      return {};
    }
  }

  Future<Map<String, int>> getMyDailyTokens({DateTime? start, DateTime? end}) async {
    try {
      final qp = <String, dynamic>{};
      if (start != null) qp['startTime'] = start.toIso8601String();
      if (end != null) qp['endTime'] = end.toIso8601String();
      final res = await _apiClient.getWithParams('/analytics/llm/daily-tokens', queryParameters: qp);
      if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
        final map = <String, int>{};
        (res['data'] as Map<String, dynamic>).forEach((k, v) {
          map[k] = int.tryParse(v.toString()) ?? 0;
        });
        return map;
      }
      return {};
    } catch (e) {
      AppLogger.e(_tag, '获取每日Token失败', e);
      return {};
    }
  }

  Future<Map<String, dynamic>> getMyFeatureUsage({DateTime? start, DateTime? end}) async {
    try {
      final qp = <String, dynamic>{};
      if (start != null) qp['startTime'] = start.toIso8601String();
      if (end != null) qp['endTime'] = end.toIso8601String();
      final res = await _apiClient.getWithParams('/analytics/llm/features', queryParameters: qp);
      if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
        return res['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      AppLogger.e(_tag, '获取功能使用统计失败', e);
      return {};
    }
  }
}




