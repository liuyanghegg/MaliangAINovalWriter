import 'package:equatable/equatable.dart';
import 'package:ainoval/models/preset_models.dart';

/// 预设管理事件基类
abstract class PresetEvent extends Equatable {
  const PresetEvent();

  @override
  List<Object?> get props => [];
}

/// 加载用户预设概览
class LoadUserPresetOverview extends PresetEvent {
  const LoadUserPresetOverview();
}

/// 加载预设包
class LoadPresetPackage extends PresetEvent {
  final String featureType;
  final String? novelId;

  const LoadPresetPackage({
    required this.featureType,
    this.novelId,
  });

  @override
  List<Object?> get props => [featureType, novelId];
}

/// 加载批量预设包
class LoadBatchPresetPackages extends PresetEvent {
  final List<String>? featureTypes;
  final String? novelId;

  const LoadBatchPresetPackages({
    this.featureTypes,
    this.novelId,
  });

  @override
  List<Object?> get props => [featureTypes, novelId];
}

/// 加载分组预设
class LoadGroupedPresets extends PresetEvent {
  final String? userId;

  const LoadGroupedPresets({this.userId});

  @override
  List<Object?> get props => [userId];
}

/// 选择预设
class SelectPreset extends PresetEvent {
  final String presetId;

  const SelectPreset({required this.presetId});

  @override
  List<Object?> get props => [presetId];
}

/// 创建预设
class CreatePreset extends PresetEvent {
  final CreatePresetRequest request;

  const CreatePreset({required this.request});

  @override
  List<Object?> get props => [request];
}

/// 覆盖更新预设（完整对象）
class OverwritePreset extends PresetEvent {
  final AIPromptPreset preset;

  const OverwritePreset({required this.preset});

  @override
  List<Object?> get props => [preset];
}

/// 更新预设
class UpdatePreset extends PresetEvent {
  final String presetId;
  final UpdatePresetInfoRequest? infoRequest;
  final UpdatePresetPromptsRequest? promptsRequest;

  const UpdatePreset({
    required this.presetId,
    this.infoRequest,
    this.promptsRequest,
  });

  @override
  List<Object?> get props => [presetId, infoRequest, promptsRequest];
}

/// 删除预设
class DeletePreset extends PresetEvent {
  final String presetId;

  const DeletePreset({required this.presetId});

  @override
  List<Object?> get props => [presetId];
}

/// 复制预设
class DuplicatePreset extends PresetEvent {
  final String presetId;
  final DuplicatePresetRequest request;

  const DuplicatePreset({
    required this.presetId,
    required this.request,
  });

  @override
  List<Object?> get props => [presetId, request];
}

/// 切换预设收藏状态
class TogglePresetFavorite extends PresetEvent {
  final String presetId;

  const TogglePresetFavorite({required this.presetId});

  @override
  List<Object?> get props => [presetId];
}

/// 切换预设快捷访问状态
class TogglePresetQuickAccess extends PresetEvent {
  final String presetId;

  const TogglePresetQuickAccess({required this.presetId});

  @override
  List<Object?> get props => [presetId];
}

/// 记录预设使用
class RecordPresetUsage extends PresetEvent {
  final String presetId;

  const RecordPresetUsage({required this.presetId});

  @override
  List<Object?> get props => [presetId];
}

/// 搜索预设
class SearchPresets extends PresetEvent {
  final String query;
  final String? featureType;
  final List<String>? tags;
  final String? sortBy;

  const SearchPresets({
    required this.query,
    this.featureType,
    this.tags,
    this.sortBy,
  });

  @override
  List<Object?> get props => [query, featureType, tags, sortBy];
}

/// 清除预设搜索
class ClearPresetSearch extends PresetEvent {
  const ClearPresetSearch();
}

/// 获取预设统计信息
class LoadPresetStatistics extends PresetEvent {
  const LoadPresetStatistics();
}

/// 获取收藏预设
class LoadFavoritePresets extends PresetEvent {
  final String? novelId;
  final String? featureType;

  const LoadFavoritePresets({
    this.novelId,
    this.featureType,
  });

  @override
  List<Object?> get props => [novelId, featureType];
}

/// 获取最近使用预设
class LoadRecentlyUsedPresets extends PresetEvent {
  final int limit;
  final String? novelId;
  final String? featureType;

  const LoadRecentlyUsedPresets({
    this.limit = 10,
    this.novelId,
    this.featureType,
  });

  @override
  List<Object?> get props => [limit, novelId, featureType];
}

/// 获取快捷访问预设
class LoadQuickAccessPresets extends PresetEvent {
  final String? featureType;
  final String? novelId;

  const LoadQuickAccessPresets({
    this.featureType,
    this.novelId,
  });

  @override
  List<Object?> get props => [featureType, novelId];
}

/// 刷新预设数据
class RefreshPresetData extends PresetEvent {
  const RefreshPresetData();
}

/// 预热缓存
class WarmupPresetCache extends PresetEvent {
  const WarmupPresetCache();
}

/// 获取缓存统计
class LoadCacheStats extends PresetEvent {
  const LoadCacheStats();
}

/// 清除缓存
class ClearPresetCache extends PresetEvent {
  const ClearPresetCache();
}

/// 健康检查
class PresetHealthCheck extends PresetEvent {
  const PresetHealthCheck();
}

/// 🚀 加载所有预设聚合数据
/// 一次性加载用户的所有预设相关数据，避免多次API调用
class LoadAllPresetData extends PresetEvent {
  final String? novelId;

  const LoadAllPresetData({this.novelId});

  @override
  List<Object?> get props => [novelId];
}

/// 🚀 新增预设到本地缓存
/// 创建预设成功后直接添加到本地缓存，避免重新加载
class AddPresetToCache extends PresetEvent {
  final AIPromptPreset preset;

  const AddPresetToCache({required this.preset});

  @override
  List<Object?> get props => [preset];
}