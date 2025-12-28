import 'package:ainoval/models/preset_models.dart';

/// AI预设仓储接口
abstract class AIPresetRepository {
  /// 创建预设
  /// [request] 创建预设请求
  /// 返回创建的预设
  Future<AIPromptPreset> createPreset(CreatePresetRequest request);
  
  /// 获取用户的所有预设
  /// [userId] 用户ID，如果为null则获取当前用户的预设
  /// 返回预设列表
  Future<List<AIPromptPreset>> getUserPresets({String? userId, String featureType = 'AI_CHAT'});
  
  /// 搜索预设
  /// [params] 搜索参数
  /// 返回匹配的预设列表
  Future<List<AIPromptPreset>> searchPresets(PresetSearchParams params);
  
  /// 根据ID获取预设
  /// [presetId] 预设ID
  /// 返回预设详情
  Future<AIPromptPreset> getPresetById(String presetId);
  
  /// 覆盖更新预设（完整对象）
  /// [preset] 完整的预设对象
  /// 返回更新后的预设
  Future<AIPromptPreset> overwritePreset(AIPromptPreset preset);

  /// 更新预设信息
  /// [presetId] 预设ID
  /// [request] 更新请求
  /// 返回更新后的预设
  Future<AIPromptPreset> updatePresetInfo(String presetId, UpdatePresetInfoRequest request);
  
  /// 更新预设提示词
  /// [presetId] 预设ID
  /// [request] 更新提示词请求
  /// 返回更新后的预设
  Future<AIPromptPreset> updatePresetPrompts(String presetId, UpdatePresetPromptsRequest request);
  
  /// 删除预设
  /// [presetId] 预设ID
  Future<void> deletePreset(String presetId);
  
  /// 复制预设
  /// [presetId] 源预设ID
  /// [request] 复制请求
  /// 返回新创建的预设
  Future<AIPromptPreset> duplicatePreset(String presetId, DuplicatePresetRequest request);
  
  /// 切换收藏状态
  /// [presetId] 预设ID
  /// 返回更新后的预设
  Future<AIPromptPreset> toggleFavorite(String presetId);
  
  /// 记录预设使用
  /// [presetId] 预设ID
  Future<void> recordPresetUsage(String presetId);
  
  /// 获取预设统计信息
  /// 返回统计信息
  Future<PresetStatistics> getPresetStatistics();
  
  /// 获取收藏的预设
  /// [novelId] 小说ID，如果为null则获取全局预设
  /// [featureType] 功能类型，如果指定则只返回该类型的预设
  /// 返回收藏预设列表
  Future<List<AIPromptPreset>> getFavoritePresets({String? novelId, String? featureType});
  
  /// 获取最近使用的预设
  /// [limit] 返回数量限制，默认10个
  /// [novelId] 小说ID，如果为null则获取全局预设
  /// [featureType] 功能类型，如果指定则只返回该类型的预设
  /// 返回最近使用预设列表
  Future<List<AIPromptPreset>> getRecentlyUsedPresets({int limit = 10, String? novelId, String? featureType});
  
  /// 根据功能类型获取预设
  /// [featureType] 功能类型
  /// 返回指定功能类型的预设列表
  Future<List<AIPromptPreset>> getPresetsByFeatureType(String featureType);

  // ============ 新增：系统预设管理接口 ============
  
  /// 获取系统预设列表
  /// [featureType] 功能类型，如果指定则只返回该类型的系统预设
  /// 返回系统预设列表
  Future<List<AIPromptPreset>> getSystemPresets({String? featureType});
  
  /// 获取快捷访问预设
  /// [featureType] 功能类型，如果指定则只返回该类型的快捷访问预设
  /// [novelId] 小说ID，如果为null则获取全局快捷访问预设
  /// 返回快捷访问预设列表
  Future<List<AIPromptPreset>> getQuickAccessPresets({String? featureType, String? novelId});
  
  /// 切换预设的快捷访问状态
  /// [presetId] 预设ID
  /// 返回更新后的预设
  Future<AIPromptPreset> toggleQuickAccess(String presetId);
  
  /// 批量获取预设
  /// [presetIds] 预设ID列表
  /// 返回预设列表
  Future<List<AIPromptPreset>> getPresetsByIds(List<String> presetIds);
  
  /// 获取用户预设按功能类型分组
  /// [userId] 用户ID，如果为null则获取当前用户的预设
  /// 返回功能类型到预设列表的映射
  Future<Map<String, List<AIPromptPreset>>> getUserPresetsByFeatureType({String? userId});
  
  /// 获取用户在指定功能类型下的预设管理信息
  /// [featureType] 功能类型
  /// [novelId] 小说ID（可选）
  /// 返回该功能类型下的完整预设管理信息
  Future<Map<String, dynamic>> getFeatureTypePresetManagement(String featureType, {String? novelId});
  
  /// 获取功能预设列表（收藏、最近使用、推荐）
  /// [featureType] 功能类型
  /// [novelId] 小说ID（可选）
  /// 返回分类的预设列表
  Future<PresetListResponse> getFeaturePresetList(String featureType, {String? novelId});
} 