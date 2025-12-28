import 'package:ainoval/models/preset_models.dart';
import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/services/api_service/base/api_exception.dart';
import 'package:ainoval/services/api_service/repositories/ai_preset_repository.dart';
import 'package:ainoval/utils/logger.dart';

/// AI预设仓储实现类
class AIPresetRepositoryImpl implements AIPresetRepository {
  final ApiClient apiClient;
  final String _tag = 'AIPresetRepository';

  AIPresetRepositoryImpl({required this.apiClient});

  // 🚀 新增：统一解包 ApiResponse.data
  dynamic _extractData(dynamic response) {
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return response['data'];
    }
    return response;
  }

  @override
  Future<AIPromptPreset> createPreset(CreatePresetRequest request) async {
    try {
      AppLogger.d(_tag, '🔍 创建AI预设: ${request.presetName}');
      
      // 🚀 调用新的AIPromptPresetController接口
      final response = await apiClient.post(
        '/ai/presets',
        data: request.toJson(),
      );
      
      // 🚀 处理ApiResponse包装格式
      final data = _extractData(response);
      final preset = AIPromptPreset.fromJson(data);
      AppLogger.i(_tag, '📘 预设创建成功: ${preset.presetId}');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '❌ 创建预设失败', e);
      rethrow;
    }
  }

  @override
  Future<List<AIPromptPreset>> getUserPresets({String? userId, String featureType = 'AI_CHAT'}) async {
    try {
      AppLogger.d(_tag, '获取用户预设列表: userId=$userId, featureType=$featureType');

      String path = '/ai/presets';
      final List<String> query = [];

      // 必填参数 featureType
      query.add('featureType=${Uri.encodeComponent(featureType)}');

      // 可选 userId
      if (userId != null) {
        query.add('userId=$userId');
      }

      if (query.isNotEmpty) {
        path = '$path?${query.join('&')}';
      }
      
      final response = await apiClient.get(path);
      
      final data = _extractData(response);
      
      if (data is! List) {
        throw ApiException(-1, '响应格式不正确，期望List类型');
      }
      
      final presets = data.map((json) => AIPromptPreset.fromJson(json)).toList();
      AppLogger.i(_tag, '获取到 ${presets.length} 个用户预设');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '获取用户预设列表失败', e);
      rethrow;
    }
  }

  @override
  Future<List<AIPromptPreset>> searchPresets(PresetSearchParams params) async {
    try {
      AppLogger.d(_tag, '搜索预设: ${params.keyword}');
      
      final queryParams = params.toQueryParams();
      String path = '/ai/presets/search';
      
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        path = '$path?$queryString';
      }
      
      final response = await apiClient.get(path);
      
      final data = _extractData(response);
      
      if (data is! List) {
        throw ApiException(-1, '响应格式不正确，期望List类型');
      }
      
      final presets = data.map((json) => AIPromptPreset.fromJson(json)).toList();
      AppLogger.i(_tag, '搜索到 ${presets.length} 个预设');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '搜索预设失败', e);
      rethrow;
    }
  }

  @override
  Future<AIPromptPreset> getPresetById(String presetId) async {
    try {
      AppLogger.d(_tag, '获取预设详情: $presetId');
      
      final response = await apiClient.get('/ai/presets/detail/$presetId');
      
      final data = _extractData(response);
      final preset = AIPromptPreset.fromJson(data);
      AppLogger.i(_tag, '获取预设详情成功: ${preset.presetName}');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '获取预设详情失败: $presetId', e);
      rethrow;
    }
  }

  @override
  Future<AIPromptPreset> overwritePreset(AIPromptPreset preset) async {
    try {
      AppLogger.d(_tag, '覆盖更新预设: ${preset.presetId}');
      
      final response = await apiClient.put(
        '/ai/presets/${preset.presetId}',
        data: preset.toJson(),
      );
      
      final data = _extractData(response);
      final updatedPreset = AIPromptPreset.fromJson(data);
      AppLogger.i(_tag, '预设覆盖更新成功: ${updatedPreset.presetName}');
      return updatedPreset;
    } catch (e) {
      AppLogger.e(_tag, '覆盖更新预设失败: ${preset.presetId}', e);
      rethrow;
    }
  }

  @override
  Future<AIPromptPreset> updatePresetInfo(String presetId, UpdatePresetInfoRequest request) async {
    try {
      AppLogger.d(_tag, '更新预设信息: $presetId');
      
      final response = await apiClient.put(
        '/ai/presets/$presetId/info',
        data: request.toJson(),
      );
      
      final data = _extractData(response);
      final preset = AIPromptPreset.fromJson(data);
      AppLogger.i(_tag, '预设信息更新成功: ${preset.presetName}');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '更新预设信息失败: $presetId', e);
      rethrow;
    }
  }

  @override
  Future<AIPromptPreset> updatePresetPrompts(String presetId, UpdatePresetPromptsRequest request) async {
    try {
      AppLogger.d(_tag, '更新预设提示词: $presetId');
      
      final response = await apiClient.put(
        '/ai/presets/$presetId/prompts',
        data: request.toJson(),
      );
      
      final data = _extractData(response);
      final preset = AIPromptPreset.fromJson(data);
      AppLogger.i(_tag, '预设提示词更新成功');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '更新预设提示词失败: $presetId', e);
      rethrow;
    }
  }

  @override
  Future<void> deletePreset(String presetId) async {
    try {
      AppLogger.d(_tag, '删除预设: $presetId');
      
      await apiClient.delete('/ai/presets/$presetId');
      
      AppLogger.i(_tag, '预设删除成功: $presetId');
    } catch (e) {
      AppLogger.e(_tag, '删除预设失败: $presetId', e);
      rethrow;
    }
  }

  @override
  Future<AIPromptPreset> duplicatePreset(String presetId, DuplicatePresetRequest request) async {
    try {
      AppLogger.d(_tag, '复制预设: $presetId -> ${request.newPresetName}');
      
      final response = await apiClient.post(
        '/ai/presets/$presetId/duplicate',
        data: request.toJson(),
      );
      
      final data = _extractData(response);
      final preset = AIPromptPreset.fromJson(data);
      AppLogger.i(_tag, '预设复制成功: ${preset.presetId}');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '复制预设失败: $presetId', e);
      rethrow;
    }
  }

  @override
  Future<AIPromptPreset> toggleFavorite(String presetId) async {
    try {
      AppLogger.d(_tag, '切换预设收藏状态: $presetId');
      
      final response = await apiClient.post('/ai/presets/$presetId/favorite');
      
      final data = _extractData(response);
      final preset = AIPromptPreset.fromJson(data);
      AppLogger.i(_tag, '预设收藏状态切换成功: ${preset.isFavorite ? "已收藏" : "已取消收藏"}');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '切换预设收藏状态失败: $presetId', e);
      rethrow;
    }
  }

  @override
  Future<void> recordPresetUsage(String presetId) async {
    try {
      AppLogger.d(_tag, '记录预设使用: $presetId');
      
      await apiClient.post('/ai/presets/$presetId/usage');
      
      AppLogger.v(_tag, '预设使用记录成功: $presetId');
    } catch (e) {
      AppLogger.w(_tag, '记录预设使用失败: $presetId', e);
      // 使用记录失败不抛出异常，不影响主要流程
    }
  }

  @override
  Future<PresetStatistics> getPresetStatistics() async {
    try {
      AppLogger.d(_tag, '获取预设统计信息');
      
      final response = await apiClient.get('/ai/presets/statistics');
      
      final data = _extractData(response);
      final statistics = PresetStatistics.fromJson(data);
      AppLogger.i(_tag, '获取预设统计信息成功: 总数 ${statistics.totalPresets}');
      return statistics;
    } catch (e) {
      AppLogger.e(_tag, '获取预设统计信息失败', e);
      rethrow;
    }
  }

  @override
  Future<List<AIPromptPreset>> getFavoritePresets({String? novelId, String? featureType}) async {
    try {
      AppLogger.d(_tag, '获取收藏预设列表: novelId=$novelId, featureType=$featureType');
      
      String path = '/ai/presets/favorites';
      List<String> queryParams = [];
      
      if (novelId != null) {
        queryParams.add('novelId=$novelId');
      }
      if (featureType != null) {
        queryParams.add('featureType=$featureType');
      }
      
      if (queryParams.isNotEmpty) {
        path = '$path?${queryParams.join('&')}';
      }
      
      final response = await apiClient.get(path);
      final data = _extractData(response);
      
      if (data is! List) {
        throw ApiException(-1, '响应格式不正确，期望List类型');
      }
      
      final presets = data.map((json) => AIPromptPreset.fromJson(json)).toList();
      AppLogger.i(_tag, '获取到 ${presets.length} 个收藏预设');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '获取收藏预设列表失败', e);
      rethrow;
    }
  }

  @override
  Future<List<AIPromptPreset>> getRecentlyUsedPresets({int limit = 10, String? novelId, String? featureType}) async {
    try {
      AppLogger.d(_tag, '获取最近使用预设列表: 限制 $limit, novelId=$novelId, featureType=$featureType');
      
      List<String> queryParams = ['limit=$limit'];
      
      if (novelId != null) {
        queryParams.add('novelId=$novelId');
      }
      if (featureType != null) {
        queryParams.add('featureType=$featureType');
      }
      
      String path = '/ai/presets/recent?${queryParams.join('&')}';
      
      final response = await apiClient.get(path);
      final data = _extractData(response);
      
      if (data is! List) {
        throw ApiException(-1, '响应格式不正确，期望List类型');
      }
      
      final presets = data.map((json) => AIPromptPreset.fromJson(json)).toList();
      AppLogger.i(_tag, '获取到 ${presets.length} 个最近使用预设');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '获取最近使用预设列表失败', e);
      rethrow;
    }
  }

  @override
  Future<List<AIPromptPreset>> getPresetsByFeatureType(String featureType) async {
    try {
      AppLogger.d(_tag, '获取指定功能类型预设: $featureType');
      
      final response = await apiClient.get(
        '/ai/presets/feature/$featureType',
      );
      
      final data = _extractData(response);
      
      if (data is! List) {
        throw ApiException(-1, '响应格式不正确，期望List类型');
      }
      
      final presets = data.map((json) => AIPromptPreset.fromJson(json)).toList();
      AppLogger.i(_tag, '获取到 ${presets.length} 个 $featureType 类型预设');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '获取指定功能类型预设失败: $featureType', e);
      rethrow;
    }
  }

  // ============ 新增：系统预设管理接口实现 ============

  @override
  Future<List<AIPromptPreset>> getSystemPresets({String? featureType}) async {
    try {
      AppLogger.d(_tag, '获取系统预设列表: featureType=$featureType');
      
      String path = '/ai/presets/system';
      if (featureType != null) {
        path = '$path?featureType=$featureType';
      }
      
      final response = await apiClient.get(path);
      
      final data = _extractData(response);
      
      if (data is! List) {
        throw ApiException(-1, '响应格式不正确，期望List类型');
      }
      
      final presets = data.map((json) => AIPromptPreset.fromJson(json)).toList();
      AppLogger.i(_tag, '获取到 ${presets.length} 个系统预设');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '获取系统预设列表失败', e);
      rethrow;
    }
  }

  @override
  Future<List<AIPromptPreset>> getQuickAccessPresets({String? featureType, String? novelId}) async {
    try {
      AppLogger.d(_tag, '获取快捷访问预设: featureType=$featureType, novelId=$novelId');
      
      String path = '/ai/presets/quick-access';
      List<String> queryParams = [];
      
      if (featureType != null) {
        queryParams.add('featureType=$featureType');
      }
      if (novelId != null) {
        queryParams.add('novelId=$novelId');
      }
      
      if (queryParams.isNotEmpty) {
        path = '$path?${queryParams.join('&')}';
      }
      
      final response = await apiClient.get(path);
      
      final data = _extractData(response);
      
      if (data is! List) {
        throw ApiException(-1, '响应格式不正确，期望List类型');
      }
      
      final presets = data.map((json) => AIPromptPreset.fromJson(json)).toList();
      AppLogger.i(_tag, '获取到 ${presets.length} 个快捷访问预设');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '获取快捷访问预设失败', e);
      rethrow;
    }
  }

  @override
  Future<AIPromptPreset> toggleQuickAccess(String presetId) async {
    try {
      AppLogger.d(_tag, '切换预设快捷访问状态: $presetId');
      
      final response = await apiClient.post('/ai/presets/$presetId/quick-access');
      
      final data = _extractData(response);
      final preset = AIPromptPreset.fromJson(data);
      AppLogger.i(_tag, '预设快捷访问状态切换成功: ${preset.showInQuickAccess ? "已加入快捷访问" : "已移出快捷访问"}');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '切换预设快捷访问状态失败: $presetId', e);
      rethrow;
    }
  }

  @override
  Future<List<AIPromptPreset>> getPresetsByIds(List<String> presetIds) async {
    try {
      AppLogger.d(_tag, '批量获取预设: ${presetIds.length} 个');
      
      final response = await apiClient.post(
        '/ai/presets/batch',
        data: {'presetIds': presetIds},
      );
      
      final data = _extractData(response);
      
      if (data is! List) {
        throw ApiException(-1, '响应格式不正确，期望List类型');
      }
      
      final presets = data.map((json) => AIPromptPreset.fromJson(json)).toList();
      AppLogger.i(_tag, '批量获取到 ${presets.length} 个预设');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '批量获取预设失败', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, List<AIPromptPreset>>> getUserPresetsByFeatureType({String? userId}) async {
    try {
      AppLogger.d(_tag, '获取用户预设按功能类型分组: userId=$userId');
      
      String path = '/ai/presets/grouped';
      if (userId != null) {
        path = '$path?userId=$userId';
      }
      
      final response = await apiClient.get(path);
      
      final data = _extractData(response);
      
      if (data is! Map<String, dynamic>) {
        throw ApiException(-1, '响应格式不正确，期望Map类型');
      }
      
      final Map<String, List<AIPromptPreset>> groupedPresets = {};
      data.forEach((featureType, presetsJson) {
        try {
          if (presetsJson is List) {
            final presets = presetsJson.map((json) => AIPromptPreset.fromJson(json)).toList();
            groupedPresets[featureType] = presets;
          }
        } catch (e) {
          AppLogger.w(_tag, '解析功能类型预设失败: $featureType', e);
        }
      });
      
      AppLogger.i(_tag, '获取到 ${groupedPresets.length} 个功能类型的分组预设');
      return groupedPresets;
    } catch (e) {
      AppLogger.e(_tag, '获取用户预设按功能类型分组失败', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getFeatureTypePresetManagement(String featureType, {String? novelId}) async {
    try {
      AppLogger.d(_tag, '获取功能类型预设管理信息: featureType=$featureType, novelId=$novelId');
      
      String path = '/ai/presets/management/$featureType';
      if (novelId != null) {
        path = '$path?novelId=$novelId';
      }
      
      final response = await apiClient.get(path);
      
      final data = _extractData(response);
      
      if (data is! Map<String, dynamic>) {
        throw ApiException(-1, '响应格式不正确，期望Map类型');
      }
      
      AppLogger.i(_tag, '获取功能类型预设管理信息成功: $featureType');
      return data;
    } catch (e) {
      AppLogger.e(_tag, '获取功能类型预设管理信息失败: $featureType', e);
      rethrow;
    }
  }

  @override
  Future<PresetListResponse> getFeaturePresetList(String featureType, {String? novelId}) async {
    try {
      AppLogger.d(_tag, '获取功能预设列表: featureType=$featureType, novelId=$novelId');
      
      Map<String, String> queryParams = {
        'featureType': featureType,
      };
      
      if (novelId != null) {
        queryParams['novelId'] = novelId;
      }
      
      final response = await apiClient.get(
        '/ai/presets/feature-list?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}',
      );
      
      final data = _extractData(response);
      
      if (data is! Map<String, dynamic>) {
        throw ApiException(-1, '响应格式不正确，期望Map类型');
      }
      
      final presetListResponse = PresetListResponse.fromJson(data);
      AppLogger.i(_tag, '获取功能预设列表成功: 收藏${presetListResponse.favorites.length}个, '
          '最近使用${presetListResponse.recentUsed.length}个, '
          '推荐${presetListResponse.recommended.length}个');
      return presetListResponse;
    } catch (e) {
      AppLogger.e(_tag, '获取功能预设列表失败: $featureType', e);
      rethrow;
    }
  }
} 