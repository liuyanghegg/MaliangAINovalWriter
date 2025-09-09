import 'package:ainoval/models/preset_models.dart';
import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/services/api_service/repositories/preset_aggregation_repository.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:dio/dio.dart';

/// 预设聚合仓储实现
class PresetAggregationRepositoryImpl implements PresetAggregationRepository {
  final ApiClient _apiClient;
  static const String _baseUrl = '/preset-aggregation';
  static const String _tag = 'PresetAggregationRepositoryImpl';

  /// 构造函数
  PresetAggregationRepositoryImpl(this._apiClient);

  @override
  Future<PresetPackage> getCompletePresetPackage(
    String featureType, {
    String? novelId,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'featureType': featureType,
      };
      if (novelId != null) {
        queryParams['novelId'] = novelId;
      }

      // 构建查询字符串
      String url = '$_baseUrl/package';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        url = '$url?$queryString';
      }

      final result = await _apiClient.get(url);

      return PresetPackage.fromJson(result);
    } catch (e) {
      AppLogger.e(_tag, '获取完整预设包失败: featureType=$featureType, novelId=$novelId', e);
      
      // 返回空的预设包作为降级处理
      return PresetPackage(
        featureType: featureType,
        systemPresets: [],
        userPresets: [],
        favoritePresets: [],
        quickAccessPresets: [],
        recentlyUsedPresets: [],
        totalCount: 0,
        cachedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<UserPresetOverview> getUserPresetOverview() async {
    try {
      final result = await _apiClient.get('$_baseUrl/overview');
      return UserPresetOverview.fromJson(result);
    } catch (e) {
      AppLogger.e(_tag, '获取用户预设概览失败', e);
      
      // 返回空的概览作为降级处理
      return UserPresetOverview(
        totalPresets: 0,
        systemPresets: 0,
        userPresets: 0,
        favoritePresets: 0,
        presetsByFeatureType: {},
        recentFeatureTypes: [],
        popularTags: [],
        generatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<Map<String, PresetPackage>> getBatchPresetPackages({
    List<String>? featureTypes,
    String? novelId,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (featureTypes != null && featureTypes.isNotEmpty) {
        queryParams['featureTypes'] = featureTypes.join(',');
      }
      if (novelId != null) {
        queryParams['novelId'] = novelId;
      }

      // 构建查询字符串
      String url = '$_baseUrl/batch';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        url = '$url?$queryString';
      }

      final result = await _apiClient.get(url);

      final Map<String, PresetPackage> packages = {};
      if (result is Map<String, dynamic>) {
        result.forEach((key, value) {
          try {
            packages[key] = PresetPackage.fromJson(value);
          } catch (e) {
            AppLogger.w(_tag, '解析预设包失败: $key', e);
          }
        });
      }

      return packages;
    } catch (e) {
      AppLogger.e(_tag, '批量获取预设包失败: featureTypes=$featureTypes, novelId=$novelId', e);
      return {};
    }
  }

  @override
  Future<CacheWarmupResult> warmupCache() async {
    try {
      final result = await _apiClient.post('$_baseUrl/warmup', data: {});
      return CacheWarmupResult.fromJson(result);
    } catch (e) {
      AppLogger.e(_tag, '预热缓存失败', e);
      
      return CacheWarmupResult(
        success: false,
        warmedFeatureTypes: 0,
        warmedPresets: 0,
        durationMs: 0,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<AggregationCacheStats> getCacheStats() async {
    try {
      final result = await _apiClient.get('$_baseUrl/cache/stats');
      return AggregationCacheStats.fromJson(result);
    } catch (e) {
      AppLogger.e(_tag, '获取缓存统计失败', e);
      
      return AggregationCacheStats(
        hitRate: 0.0,
        cacheEntries: 0,
        cacheSizeBytes: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  @override
  Future<String> clearCache() async {
    try {
      final result = await _apiClient.delete('$_baseUrl/cache');
      if (result is Map<String, dynamic> && result.containsKey('message')) {
        return result['message'] as String;
      }
      return '缓存清除成功';
    } catch (e) {
      AppLogger.e(_tag, '清除缓存失败', e);
      throw Exception('清除缓存失败: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final result = await _apiClient.get('$_baseUrl/health');
      if (result is Map<String, dynamic>) {
        return result;
      }
      return {'status': 'unknown'};
    } catch (e) {
      AppLogger.e(_tag, '聚合服务健康检查失败', e);
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  Future<AllUserPresetData> getAllUserPresetData({String? novelId}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (novelId != null) {
        queryParams['novelId'] = novelId;
      }

      // 构建查询字符串
      String url = '$_baseUrl/all-data';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        url = '$url?$queryString';
      }

      AppLogger.i(_tag, '🚀 请求所有预设聚合数据: url=$url');
      
      final result = await _apiClient.get(url);
      
      // 检查响应格式 - API返回的是标准响应格式 {success, message, data}
      if (result is! Map<String, dynamic>) {
        throw Exception('响应格式错误: 不是JSON对象');
      }
      
      final response = result as Map<String, dynamic>;
      AppLogger.i(_tag, '📋 响应字段: ${response.keys.toList()}');
      
      if (response['success'] != true) {
        throw Exception('请求失败: ${response['message'] ?? '未知错误'}');
      }
      
      final data = response['data'];
      if (data == null) {
        throw Exception('响应数据为空');
      }
      
      AppLogger.i(_tag, '✅ 开始解析聚合数据...');
      final allData = AllUserPresetData.fromJson(data);
      
      AppLogger.i(_tag, '✅ 所有预设聚合数据获取成功');
      AppLogger.i(_tag, '📊 数据统计: 系统预设${allData.systemPresets.length}个, 用户预设分组${allData.userPresetsByFeatureType.length}个, 收藏${allData.favoritePresets.length}个');
      
      return allData;
    } catch (e) {
      AppLogger.e(_tag, '❌ 获取所有预设聚合数据失败: novelId=$novelId', e);
      
      // 返回空的聚合数据作为降级处理
      return AllUserPresetData(
        userId: '',
        overview: UserPresetOverview(
          totalPresets: 0,
          systemPresets: 0,
          userPresets: 0,
          favoritePresets: 0,
          presetsByFeatureType: {},
          recentFeatureTypes: [],
          popularTags: [],
          generatedAt: DateTime.now(),
        ),
        packagesByFeatureType: {},
        systemPresets: [],
        userPresetsByFeatureType: {},
        favoritePresets: [],
        quickAccessPresets: [],
        recentlyUsedPresets: [],
        timestamp: DateTime.now(),
        cacheDuration: 0,
      );
    }
  }
}