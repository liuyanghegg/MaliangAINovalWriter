import 'package:ainoval/models/preset_models.dart';
import 'package:ainoval/services/api_service/repositories/ai_preset_repository.dart';
import 'package:ainoval/services/api_service/repositories/impl/ai_preset_repository_impl.dart';
import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/utils/logger.dart';

/// AI预设服务
/// 提供预设管理的业务逻辑层
class AIPresetService {
  final AIPresetRepository _repository;
  final String _tag = 'AIPresetService';

  AIPresetService({AIPresetRepository? repository})
      : _repository = repository ?? AIPresetRepositoryImpl(apiClient: ApiClient());

  /// 创建预设
  /// [request] 创建预设请求
  /// 返回创建的预设
  Future<AIPromptPreset> createPreset(CreatePresetRequest request) async {
    try {
      AppLogger.i(_tag, '创建预设: ${request.presetName}');
      
      final preset = await _repository.createPreset(request);
      
      // 记录预设使用（创建后立即记录）
      await _recordUsage(preset.presetId);
      
      AppLogger.i(_tag, '预设创建成功: ${preset.presetId}');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '创建预设失败', e);
      rethrow;
    }
  }

  /// 获取用户的所有预设
  /// [userId] 用户ID，如果为null则获取当前用户的预设
  /// [featureType] 功能类型，默认为AI_CHAT
  /// 返回预设列表
  Future<List<AIPromptPreset>> getUserPresets({String? userId, String featureType = 'AI_CHAT'}) async {
    try {
      AppLogger.d(_tag, '获取用户预设列表: userId=$userId, featureType=$featureType');
      
      final presets = await _repository.getUserPresets(userId: userId, featureType: featureType);
      
      AppLogger.i(_tag, '获取到 ${presets.length} 个用户预设 (featureType=$featureType)');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '获取用户预设列表失败', e);
      rethrow;
    }
  }

  /// 搜索预设
  /// [params] 搜索参数
  /// 返回匹配的预设列表
  Future<List<AIPromptPreset>> searchPresets(PresetSearchParams params) async {
    try {
      AppLogger.d(_tag, '搜索预设: ${params.keyword}');
      
      final presets = await _repository.searchPresets(params);
      
      AppLogger.i(_tag, '搜索到 ${presets.length} 个预设');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '搜索预设失败', e);
      rethrow;
    }
  }

  /// 根据ID获取预设详情
  /// [presetId] 预设ID
  /// 返回预设详情
  Future<AIPromptPreset> getPresetById(String presetId) async {
    try {
      AppLogger.d(_tag, '获取预设详情: $presetId');
      
      final preset = await _repository.getPresetById(presetId);
      
      AppLogger.i(_tag, '获取预设详情成功: ${preset.presetName}');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '获取预设详情失败: $presetId', e);
      rethrow;
    }
  }

  /// 应用预设
  /// [presetId] 预设ID
  /// 返回预设详情并记录使用
  Future<AIPromptPreset> applyPreset(String presetId) async {
    try {
      AppLogger.i(_tag, '应用预设: $presetId');
      
      final preset = await _repository.getPresetById(presetId);
      
      // 记录预设使用
      await _recordUsage(presetId);
      
      AppLogger.i(_tag, '预设应用成功: ${preset.presetName}');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '应用预设失败: $presetId', e);
      rethrow;
    }
  }

  /// 更新预设信息
  /// [presetId] 预设ID
  /// [request] 更新请求
  /// 返回更新后的预设
  Future<AIPromptPreset> updatePresetInfo(String presetId, UpdatePresetInfoRequest request) async {
    try {
      AppLogger.i(_tag, '更新预设信息: $presetId');
      
      final preset = await _repository.updatePresetInfo(presetId, request);
      
      AppLogger.i(_tag, '预设信息更新成功: ${preset.presetName}');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '更新预设信息失败: $presetId', e);
      rethrow;
    }
  }

  /// 更新预设提示词
  /// [presetId] 预设ID
  /// [request] 更新提示词请求
  /// 返回更新后的预设
  Future<AIPromptPreset> updatePresetPrompts(String presetId, UpdatePresetPromptsRequest request) async {
    try {
      AppLogger.i(_tag, '更新预设提示词: $presetId');
      
      final preset = await _repository.updatePresetPrompts(presetId, request);
      
      AppLogger.i(_tag, '预设提示词更新成功');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '更新预设提示词失败: $presetId', e);
      rethrow;
    }
  }

  /// 删除预设
  /// [presetId] 预设ID
  Future<void> deletePreset(String presetId) async {
    try {
      AppLogger.i(_tag, '删除预设: $presetId');
      
      await _repository.deletePreset(presetId);
      
      AppLogger.i(_tag, '预设删除成功: $presetId');
    } catch (e) {
      AppLogger.e(_tag, '删除预设失败: $presetId', e);
      rethrow;
    }
  }

  /// 复制预设
  /// [presetId] 源预设ID
  /// [newName] 新预设名称
  /// 返回新创建的预设
  Future<AIPromptPreset> duplicatePreset(String presetId, String newName) async {
    try {
      AppLogger.i(_tag, '复制预设: $presetId -> $newName');
      
      final request = DuplicatePresetRequest(newPresetName: newName);
      final preset = await _repository.duplicatePreset(presetId, request);
      
      AppLogger.i(_tag, '预设复制成功: ${preset.presetId}');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '复制预设失败: $presetId', e);
      rethrow;
    }
  }

  /// 切换收藏状态
  /// [presetId] 预设ID
  /// 返回更新后的预设
  Future<AIPromptPreset> toggleFavorite(String presetId) async {
    try {
      AppLogger.i(_tag, '切换预设收藏状态: $presetId');
      
      final preset = await _repository.toggleFavorite(presetId);
      
      AppLogger.i(_tag, '预设收藏状态切换成功: ${preset.isFavorite ? "已收藏" : "已取消收藏"}');
      return preset;
    } catch (e) {
      AppLogger.e(_tag, '切换预设收藏状态失败: $presetId', e);
      rethrow;
    }
  }

  /// 获取预设统计信息
  /// 返回统计信息
  Future<PresetStatistics> getStatistics() async {
    try {
      AppLogger.d(_tag, '获取预设统计信息');
      
      final statistics = await _repository.getPresetStatistics();
      
      AppLogger.i(_tag, '获取预设统计信息成功: 总数 ${statistics.totalPresets}');
      return statistics;
    } catch (e) {
      AppLogger.e(_tag, '获取预设统计信息失败', e);
      rethrow;
    }
  }

  /// 获取收藏的预设
  /// [novelId] 小说ID，如果为null则获取全局预设
  /// [featureType] 功能类型，如果指定则只返回该类型的预设
  /// 返回收藏预设列表
  Future<List<AIPromptPreset>> getFavoritePresets({String? novelId, String? featureType}) async {
    try {
      AppLogger.d(_tag, '获取收藏预设列表: novelId=$novelId, featureType=$featureType');
      
      final presets = await _repository.getFavoritePresets(novelId: novelId, featureType: featureType);
      
      AppLogger.i(_tag, '获取到 ${presets.length} 个收藏预设');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '获取收藏预设列表失败', e);
      rethrow;
    }
  }

  /// 获取最近使用的预设
  /// [limit] 返回数量限制，默认10个
  /// [novelId] 小说ID，如果为null则获取全局预设
  /// [featureType] 功能类型，如果指定则只返回该类型的预设
  /// 返回最近使用预设列表
  Future<List<AIPromptPreset>> getRecentlyUsedPresets({int limit = 10, String? novelId, String? featureType}) async {
    try {
      AppLogger.d(_tag, '获取最近使用预设列表: novelId=$novelId, featureType=$featureType');
      
      final presets = await _repository.getRecentlyUsedPresets(limit: limit, novelId: novelId, featureType: featureType);
      
      AppLogger.i(_tag, '获取到 ${presets.length} 个最近使用预设');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '获取最近使用预设列表失败', e);
      rethrow;
    }
  }

  /// 根据功能类型获取预设
  /// [featureType] 功能类型
  /// 返回指定功能类型的预设列表
  Future<List<AIPromptPreset>> getPresetsByFeatureType(String featureType) async {
    try {
      AppLogger.d(_tag, '获取指定功能类型预设: $featureType');
      
      final presets = await _repository.getPresetsByFeatureType(featureType);
      
      AppLogger.i(_tag, '获取到 ${presets.length} 个 $featureType 类型预设');
      return presets;
    } catch (e) {
      AppLogger.e(_tag, '获取指定功能类型预设失败: $featureType', e);
      rethrow;
    }
  }

  /// 获取推荐预设
  /// [featureType] 当前功能类型
  /// [limit] 推荐数量，默认5个
  /// 返回推荐预设列表（基于收藏和使用频率）
  Future<List<AIPromptPreset>> getRecommendedPresets(String featureType, {int limit = 5}) async {
    try {
      AppLogger.d(_tag, '获取推荐预设: $featureType');
      
      // 优先获取同功能类型的收藏预设
      final typedFavorites = await getFavoritePresets(featureType: featureType);
      final limitedFavorites = typedFavorites.take(limit ~/ 2).toList();
      
      // 补充最近使用的预设
      final typedRecent = await getRecentlyUsedPresets(limit: limit, featureType: featureType);
      final filteredRecent = typedRecent
          .where((preset) => !limitedFavorites.any((fav) => fav.presetId == preset.presetId))
          .take(limit - limitedFavorites.length)
          .toList();
      
      final recommended = [...limitedFavorites, ...filteredRecent];
      
      AppLogger.i(_tag, '获取到 ${recommended.length} 个推荐预设');
      return recommended;
    } catch (e) {
      AppLogger.e(_tag, '获取推荐预设失败: $featureType', e);
      rethrow;
    }
  }

  /// 记录预设使用（内部方法）
  Future<void> _recordUsage(String presetId) async {
    try {
      await _repository.recordPresetUsage(presetId);
    } catch (e) {
      // 使用记录失败不影响主要流程
      AppLogger.w(_tag, '记录预设使用失败: $presetId', e);
    }
  }

  /// 获取功能预设列表（收藏、最近使用、推荐）
  /// [featureType] 功能类型
  /// [novelId] 小说ID（可选）
  /// 返回分类的预设列表，包含标签信息
  Future<PresetListResponse> getFeaturePresetList(String featureType, {String? novelId}) async {
    try {
      AppLogger.i(_tag, '获取功能预设列表: $featureType, novelId: $novelId');
      
      final response = await _repository.getFeaturePresetList(featureType, novelId: novelId);
      
      AppLogger.i(_tag, '功能预设列表获取成功: 总共${response.totalCount}个预设');
      return response;
    } catch (e) {
      AppLogger.e(_tag, '获取功能预设列表失败: $featureType', e);
      rethrow;
    }
  }
} 