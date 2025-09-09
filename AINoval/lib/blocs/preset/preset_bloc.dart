import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/blocs/preset/preset_event.dart';
import 'package:ainoval/blocs/preset/preset_state.dart';
import 'package:ainoval/services/api_service/repositories/preset_aggregation_repository.dart';
import 'package:ainoval/services/api_service/repositories/ai_preset_repository.dart';
import 'package:ainoval/models/preset_models.dart';
import 'package:ainoval/utils/logger.dart';

/// 预设管理BLoC
/// 负责处理预设相关的业务逻辑和状态管理
class PresetBloc extends Bloc<PresetEvent, PresetState> {
  static const String _tag = 'PresetBloc';

  final PresetAggregationRepository _aggregationRepository;
  final AIPresetRepository _presetRepository;

  PresetBloc({
    required PresetAggregationRepository aggregationRepository,
    required AIPresetRepository presetRepository,
  })  : _aggregationRepository = aggregationRepository,
        _presetRepository = presetRepository,
        super(const PresetState.initial()) {
    on<LoadUserPresetOverview>(_onLoadUserPresetOverview);
    on<LoadPresetPackage>(_onLoadPresetPackage);
    on<LoadBatchPresetPackages>(_onLoadBatchPresetPackages);
    on<LoadGroupedPresets>(_onLoadGroupedPresets);
    on<LoadAllPresetData>(_onLoadAllPresetData);
    on<AddPresetToCache>(_onAddPresetToCache);
    on<SelectPreset>(_onSelectPreset);
    on<CreatePreset>(_onCreatePreset);
    on<OverwritePreset>(_onOverwritePreset);
    on<UpdatePreset>(_onUpdatePreset);
    on<DeletePreset>(_onDeletePreset);
    on<DuplicatePreset>(_onDuplicatePreset);
    on<TogglePresetFavorite>(_onTogglePresetFavorite);
    on<TogglePresetQuickAccess>(_onTogglePresetQuickAccess);
    on<SearchPresets>(_onSearchPresets);
    on<ClearPresetSearch>(_onClearPresetSearch);
    on<RefreshPresetData>(_onRefreshPresetData);
    on<WarmupPresetCache>(_onWarmupPresetCache);
  }

  /// 加载用户预设概览
  Future<void> _onLoadUserPresetOverview(
    LoadUserPresetOverview event,
    Emitter<PresetState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      final overview = await _aggregationRepository.getUserPresetOverview();
      
      emit(state.copyWith(
        isLoading: false,
        userOverview: overview,
      ));
      
      AppLogger.i(_tag, '用户预设概览加载成功');
    } catch (e) {
      AppLogger.e(_tag, '加载用户预设概览失败', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '加载用户预设概览失败: ${e.toString()}',
      ));
    }
  }

  /// 加载预设包
  Future<void> _onLoadPresetPackage(
    LoadPresetPackage event,
    Emitter<PresetState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      final package = await _aggregationRepository.getCompletePresetPackage(
        event.featureType,
        novelId: event.novelId,
      );
      
      emit(state.copyWith(
        isLoading: false,
        currentPackage: package,
      ));
      
      AppLogger.i(_tag, '预设包加载成功: ${event.featureType}');
    } catch (e) {
      AppLogger.e(_tag, '加载预设包失败: ${event.featureType}', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '加载预设包失败: ${e.toString()}',
      ));
    }
  }

  /// 加载批量预设包
  Future<void> _onLoadBatchPresetPackages(
    LoadBatchPresetPackages event,
    Emitter<PresetState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      final packages = await _aggregationRepository.getBatchPresetPackages(
        featureTypes: event.featureTypes,
        novelId: event.novelId,
      );
      
      emit(state.copyWith(
        isLoading: false,
        batchPackages: packages,
      ));
      
      AppLogger.i(_tag, '批量预设包加载成功: ${packages.length} 个');
    } catch (e) {
      AppLogger.e(_tag, '加载批量预设包失败', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '加载批量预设包失败: ${e.toString()}',
      ));
    }
  }

  /// 加载分组预设
  Future<void> _onLoadGroupedPresets(
    LoadGroupedPresets event,
    Emitter<PresetState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      final groupedPresets = await _presetRepository.getUserPresetsByFeatureType(
        userId: event.userId,
      );
      
      // 加载系统预设并合并
      final systemPresets = await _presetRepository.getSystemPresets();
      
      // 合并系统预设到分组中
      final mergedGroupedPresets = Map<String, List<AIPromptPreset>>.from(groupedPresets);
      for (final preset in systemPresets) {
        final featureType = preset.aiFeatureType;
        if (!mergedGroupedPresets.containsKey(featureType)) {
          mergedGroupedPresets[featureType] = [];
        }
        mergedGroupedPresets[featureType]!.insert(0, preset);
      }
      
      emit(state.copyWith(
        isLoading: false,
        groupedPresets: mergedGroupedPresets,
      ));
      
      AppLogger.i(_tag, '分组预设加载成功: ${mergedGroupedPresets.length} 个分组');
    } catch (e) {
      AppLogger.e(_tag, '加载分组预设失败', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '加载分组预设失败: ${e.toString()}',
      ));
    }
  }

  /// 选择预设
  Future<void> _onSelectPreset(
    SelectPreset event,
    Emitter<PresetState> emit,
  ) async {
    try {
      // 🚀 修复：优先从已加载的聚合数据中查找预设，避免重复请求后端
      AIPromptPreset? preset;
      
      if (state.allPresetData != null) {
        // 从聚合数据的所有预设中查找
        preset = state.allPresetData!.allPresets
            .where((p) => p.presetId == event.presetId)
            .firstOrNull;
        
        if (preset != null) {
          AppLogger.i(_tag, '✅ 从聚合数据中找到预设: ${event.presetId}');
        }
      }
      
      // 如果聚合数据中没有找到，尝试从分组预设中查找
      if (preset == null && state.groupedPresets.isNotEmpty) {
        for (final presets in state.groupedPresets.values) {
          preset = presets
              .where((p) => p.presetId == event.presetId)
              .firstOrNull;
          if (preset != null) {
            AppLogger.i(_tag, '✅ 从分组预设中找到预设: ${event.presetId}');
            break;
          }
        }
      }
      
      // 最后的回退：如果缓存中都没有，才去后端获取
      if (preset == null) {
        AppLogger.w(_tag, '⚠️ 缓存中未找到预设，从后端获取: ${event.presetId}');
        preset = await _presetRepository.getPresetById(event.presetId);
      }
      
      emit(state.copyWith(
        selectedPreset: preset,
        errorMessage: null,
      ));
      
      AppLogger.i(_tag, '📘 预设选择成功: ${event.presetId}');
    } catch (e) {
      AppLogger.e(_tag, '选择预设失败: ${event.presetId}', e);
      emit(state.copyWith(
        errorMessage: '选择预设失败: ${e.toString()}',
      ));
    }
  }

  /// 创建预设
  Future<void> _onCreatePreset(
    CreatePreset event,
    Emitter<PresetState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      final newPreset = await _presetRepository.createPreset(event.request);
      
      // 🚀 优化：直接更新本地状态，不重新请求API
      final updatedGroupedPresets = Map<String, List<AIPromptPreset>>.from(state.groupedPresets);
      final newFeatureType = newPreset.aiFeatureType;
      
      // 🚀 修复：处理功能类型格式不一致问题
      // 先查找是否存在相同功能类型的其他格式键
      String? existingKey = _findExistingFeatureTypeKey(updatedGroupedPresets, newFeatureType);
      final targetKey = existingKey ?? newFeatureType;
      
      if (updatedGroupedPresets.containsKey(targetKey)) {
        // 将新预设添加到对应功能类型的列表开头
        updatedGroupedPresets[targetKey] = [newPreset, ...updatedGroupedPresets[targetKey]!];
      } else {
        // 如果该功能类型还没有预设，创建新列表
        updatedGroupedPresets[targetKey] = [newPreset];
      }
      
      AppLogger.i(_tag, '📋 预设添加到分组: $targetKey (原始类型: $newFeatureType)');
      
      // 🚀 新增：同时更新聚合数据缓存
      final newAllPresetData = state.allPresetData != null 
          ? _addPresetToAggregatedData(state.allPresetData!, newPreset)
          : null;
      
      emit(state.copyWith(
        isLoading: false,
        selectedPreset: newPreset,
        groupedPresets: updatedGroupedPresets,
        allPresetData: newAllPresetData,
      ));
      
      AppLogger.i(_tag, '📘 预设创建成功: ${newPreset.presetId}');
    } catch (e) {
      AppLogger.e(_tag, '❌ 创建预设失败', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '创建预设失败: ${e.toString()}',
      ));
    }
  }

  /// 覆盖更新预设（完整对象）
  Future<void> _onOverwritePreset(
    OverwritePreset event,
    Emitter<PresetState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      final updatedPreset = await _presetRepository.overwritePreset(event.preset);
      
      // 🚀 直接更新本地缓存
      final updatedGroupedPresets = Map<String, List<AIPromptPreset>>.from(state.groupedPresets);
      final newFeatureType = updatedPreset.aiFeatureType;
      
      String? existingKey = _findExistingFeatureTypeKey(updatedGroupedPresets, newFeatureType);
      final targetKey = existingKey ?? newFeatureType;
      
      if (updatedGroupedPresets.containsKey(targetKey)) {
        final presetList = updatedGroupedPresets[targetKey]!;
        final index = presetList.indexWhere((p) => p.presetId == updatedPreset.presetId);
        if (index != -1) {
          presetList[index] = updatedPreset;
        }
      }
      
      // 🚀 同时更新聚合数据缓存
      final newAllPresetData = _replacePresetInAggregatedData(state.allPresetData, updatedPreset);
      
      emit(state.copyWith(
        isLoading: false,
        selectedPreset: updatedPreset,
        groupedPresets: updatedGroupedPresets,
        allPresetData: newAllPresetData,
      ));
      
      AppLogger.i(_tag, '📘 预设覆盖更新成功: ${updatedPreset.presetId}');
    } catch (e) {
      AppLogger.e(_tag, '❌ 覆盖更新预设失败: ${event.preset.presetId}', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '覆盖更新预设失败: ${e.toString()}',
      ));
    }
  }

  /// 更新预设
  Future<void> _onUpdatePreset(
    UpdatePreset event,
    Emitter<PresetState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      AIPromptPreset updatedPreset;
      if (event.infoRequest != null) {
        updatedPreset = await _presetRepository.updatePresetInfo(
          event.presetId,
          event.infoRequest!,
        );
      } else if (event.promptsRequest != null) {
        updatedPreset = await _presetRepository.updatePresetPrompts(
          event.presetId,
          event.promptsRequest!,
        );
      } else {
        throw Exception('更新请求参数错误');
      }
      
      // 🚀 优化：直接更新本地状态，不重新请求API
      final updatedGroupedPresets = Map<String, List<AIPromptPreset>>.from(state.groupedPresets);
      final newFeatureType = updatedPreset.aiFeatureType;
      
      // 🚀 修复：处理功能类型格式不一致问题
      String? existingKey = _findExistingFeatureTypeKey(updatedGroupedPresets, newFeatureType);
      final targetKey = existingKey ?? newFeatureType;
      
      if (updatedGroupedPresets.containsKey(targetKey)) {
        // 找到并替换对应的预设
        final presetList = updatedGroupedPresets[targetKey]!;
        final index = presetList.indexWhere((p) => p.presetId == event.presetId);
        if (index != -1) {
          presetList[index] = updatedPreset;
          AppLogger.i(_tag, '📋 预设更新在分组: $targetKey');
        }
      } else {
        AppLogger.w(_tag, '⚠️ 未找到预设分组进行更新: $targetKey');
      }
      
      // 🚀 新增：同时更新聚合数据缓存
      final newAllPresetData = _replacePresetInAggregatedData(state.allPresetData, updatedPreset);
      
      emit(state.copyWith(
        isLoading: false,
        selectedPreset: updatedPreset,
        groupedPresets: updatedGroupedPresets,
        allPresetData: newAllPresetData,
      ));
      
      AppLogger.i(_tag, '📘 预设更新成功: ${event.presetId}');
    } catch (e) {
      AppLogger.e(_tag, '❌ 更新预设失败: ${event.presetId}', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '更新预设失败: ${e.toString()}',
      ));
    }
  }

  /// 删除预设
  Future<void> _onDeletePreset(
    DeletePreset event,
    Emitter<PresetState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      await _presetRepository.deletePreset(event.presetId);
      
      // 🚀 优化：直接更新本地状态，不重新请求API
      final updatedGroupedPresets = Map<String, List<AIPromptPreset>>.from(state.groupedPresets);
      
      // 从所有功能类型的列表中移除该预设
      for (final entry in updatedGroupedPresets.entries.toList()) {
        final presetList = entry.value;
        presetList.removeWhere((p) => p.presetId == event.presetId);
        
        // 如果该功能类型的预设列表为空，移除该分组
        if (presetList.isEmpty) {
          updatedGroupedPresets.remove(entry.key);
        }
      }
      
      // 如果删除的是当前选中预设，清除选择
      final selectedPreset = state.selectedPreset?.presetId == event.presetId ? null : state.selectedPreset;
      
      // 🚀 新增：同时更新聚合数据缓存
      final newAllPresetData = _removePresetFromAggregatedData(state.allPresetData, event.presetId);
      
      emit(state.copyWith(
        isLoading: false,
        selectedPreset: selectedPreset,
        groupedPresets: updatedGroupedPresets,
        allPresetData: newAllPresetData,
      ));
      
      AppLogger.i(_tag, '📘 预设删除成功: ${event.presetId}');
    } catch (e) {
      AppLogger.e(_tag, '❌ 删除预设失败: ${event.presetId}', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '删除预设失败: ${e.toString()}',
      ));
    }
  }

  /// 🚀 复制预设
  Future<void> _onDuplicatePreset(
    DuplicatePreset event,
    Emitter<PresetState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      final duplicatedPreset = await _presetRepository.duplicatePreset(event.presetId, event.request);
      
      // 🚀 直接更新本地缓存，类似创建预设的逻辑
      final updatedGroupedPresets = Map<String, List<AIPromptPreset>>.from(state.groupedPresets);
      final featureType = duplicatedPreset.aiFeatureType;
      
      if (updatedGroupedPresets.containsKey(featureType)) {
        // 将复制的预设添加到对应功能类型的列表开头
        updatedGroupedPresets[featureType] = [duplicatedPreset, ...updatedGroupedPresets[featureType]!];
      } else {
        // 如果该功能类型还没有预设，创建新列表
        updatedGroupedPresets[featureType] = [duplicatedPreset];
      }
      
      // 🚀 同时更新聚合数据缓存
      final newAllPresetData = state.allPresetData != null 
          ? _addPresetToAggregatedData(state.allPresetData!, duplicatedPreset)
          : null;
      
      emit(state.copyWith(
        isLoading: false,
        selectedPreset: duplicatedPreset,
        groupedPresets: updatedGroupedPresets,
        allPresetData: newAllPresetData,
      ));
      
      AppLogger.i(_tag, '📘 预设复制成功: ${duplicatedPreset.presetId}');
    } catch (e) {
      AppLogger.e(_tag, '❌ 复制预设失败: ${event.presetId}', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '复制预设失败: ${e.toString()}',
      ));
    }
  }

  /// 切换预设收藏状态
  Future<void> _onTogglePresetFavorite(
    TogglePresetFavorite event,
    Emitter<PresetState> emit,
  ) async {
    try {
      final updatedPreset = await _presetRepository.toggleFavorite(event.presetId);
      
      // 🚀 优化：直接更新本地状态，不重新请求API
      final updatedGroupedPresets = Map<String, List<AIPromptPreset>>.from(state.groupedPresets);
      final newFeatureType = updatedPreset.aiFeatureType;
      
      // 🚀 修复：处理功能类型格式不一致问题
      String? existingKey = _findExistingFeatureTypeKey(updatedGroupedPresets, newFeatureType);
      final targetKey = existingKey ?? newFeatureType;
      
      if (updatedGroupedPresets.containsKey(targetKey)) {
        // 找到并替换对应的预设
        final presetList = updatedGroupedPresets[targetKey]!;
        final index = presetList.indexWhere((p) => p.presetId == event.presetId);
        if (index != -1) {
          presetList[index] = updatedPreset;
          AppLogger.i(_tag, '📋 预设收藏状态更新在分组: $targetKey');
        }
      } else {
        AppLogger.w(_tag, '⚠️ 未找到预设分组进行收藏状态更新: $targetKey');
      }
      
      // 更新选中的预设
      final selectedPreset = state.selectedPreset?.presetId == event.presetId 
          ? updatedPreset 
          : state.selectedPreset;
      
      // 🚀 新增：同时更新聚合数据缓存
      final newAllPresetData = _replacePresetInAggregatedData(state.allPresetData, updatedPreset);
      
      emit(state.copyWith(
        selectedPreset: selectedPreset,
        groupedPresets: updatedGroupedPresets,
        allPresetData: newAllPresetData,
      ));
      
      AppLogger.i(_tag, '📘 预设收藏状态切换成功: ${event.presetId}');
    } catch (e) {
      AppLogger.e(_tag, '❌ 切换预设收藏状态失败: ${event.presetId}', e);
      emit(state.copyWith(
        errorMessage: '切换收藏状态失败: ${e.toString()}',
      ));
    }
  }

  /// 切换预设快捷访问状态
  Future<void> _onTogglePresetQuickAccess(
    TogglePresetQuickAccess event,
    Emitter<PresetState> emit,
  ) async {
    try {
      final updatedPreset = await _presetRepository.toggleQuickAccess(event.presetId);
      
      // 🚀 优化：直接更新本地状态，不重新请求API
      final updatedGroupedPresets = Map<String, List<AIPromptPreset>>.from(state.groupedPresets);
      final newFeatureType = updatedPreset.aiFeatureType;
      
      // 🚀 修复：处理功能类型格式不一致问题
      String? existingKey = _findExistingFeatureTypeKey(updatedGroupedPresets, newFeatureType);
      final targetKey = existingKey ?? newFeatureType;
      
      if (updatedGroupedPresets.containsKey(targetKey)) {
        // 找到并替换对应的预设
        final presetList = updatedGroupedPresets[targetKey]!;
        final index = presetList.indexWhere((p) => p.presetId == event.presetId);
        if (index != -1) {
          presetList[index] = updatedPreset;
          AppLogger.i(_tag, '📋 预设快捷访问状态更新在分组: $targetKey');
        }
      } else {
        AppLogger.w(_tag, '⚠️ 未找到预设分组进行快捷访问状态更新: $targetKey');
      }
      
      // 更新选中的预设
      final selectedPreset = state.selectedPreset?.presetId == event.presetId 
          ? updatedPreset 
          : state.selectedPreset;
      
      // 🚀 新增：同时更新聚合数据缓存
      final newAllPresetData = _replacePresetInAggregatedData(state.allPresetData, updatedPreset);
      
      emit(state.copyWith(
        selectedPreset: selectedPreset,
        groupedPresets: updatedGroupedPresets,
        allPresetData: newAllPresetData,
      ));
      
      AppLogger.i(_tag, '📘 预设快捷访问状态切换成功: ${event.presetId}');
    } catch (e) {
      AppLogger.e(_tag, '❌ 切换预设快捷访问状态失败: ${event.presetId}', e);
      emit(state.copyWith(
        errorMessage: '切换快捷访问状态失败: ${e.toString()}',
      ));
    }
  }

  /// 搜索预设
  Future<void> _onSearchPresets(
    SearchPresets event,
    Emitter<PresetState> emit,
  ) async {
    try {
      final searchParams = PresetSearchParams(
        keyword: event.query,
        featureType: event.featureType,
        tags: event.tags,
        sortBy: event.sortBy ?? 'recent',
      );
      
      final searchResults = await _presetRepository.searchPresets(searchParams);
      
      emit(state.copyWith(
        searchResults: searchResults,
        searchQuery: event.query,
        errorMessage: null,
      ));
      
      AppLogger.i(_tag, '预设搜索完成: ${searchResults.length} 个结果');
    } catch (e) {
      AppLogger.e(_tag, '搜索预设失败', e);
      emit(state.copyWith(
        errorMessage: '搜索预设失败: ${e.toString()}',
      ));
    }
  }

  /// 清除搜索
  Future<void> _onClearPresetSearch(
    ClearPresetSearch event,
    Emitter<PresetState> emit,
  ) async {
    emit(state.copyWith(
      searchResults: [],
      searchQuery: '',
    ));
    
    AppLogger.i(_tag, '预设搜索已清除');
  }

  /// 刷新预设数据
  Future<void> _onRefreshPresetData(
    RefreshPresetData event,
    Emitter<PresetState> emit,
  ) async {
    // 重新加载所有数据
    add(const LoadUserPresetOverview());
    add(const LoadGroupedPresets());
    
    AppLogger.i(_tag, '预设数据刷新中...');
  }

  /// 🚀 查找现有分组中相同功能类型的键（已统一格式，现在只做直接匹配）
  String? _findExistingFeatureTypeKey(Map<String, List<AIPromptPreset>> groupedPresets, String newFeatureType) {
    // 如果直接存在，返回null（使用新的键）
    if (groupedPresets.containsKey(newFeatureType)) {
      return null;
    }
    
    // 🚀 已统一为新格式，不再需要映射，直接使用新的功能类型键
    AppLogger.i(_tag, '📋 使用新的功能类型键: $newFeatureType');
    return null;
  }

  /// 🚀 新增预设到本地缓存
  Future<void> _onAddPresetToCache(
    AddPresetToCache event,
    Emitter<PresetState> emit,
  ) async {
    try {
      final newPreset = event.preset;
      AppLogger.i(_tag, '🚀 添加新预设到本地缓存: ${newPreset.presetName}');
      
      // 🚀 更新聚合数据缓存
      if (state.allPresetData != null) {
        final updatedData = _addPresetToAggregatedData(state.allPresetData!, newPreset);
        
        // 同时更新分组预设以保持兼容性
        final updatedGroupedPresets = Map<String, List<AIPromptPreset>>.from(state.groupedPresets);
        final featureType = newPreset.aiFeatureType;
        
        if (updatedGroupedPresets.containsKey(featureType)) {
          // 将新预设添加到列表开头
          updatedGroupedPresets[featureType] = [newPreset, ...updatedGroupedPresets[featureType]!];
        } else {
          // 创建新的功能类型分组
          updatedGroupedPresets[featureType] = [newPreset];
        }
        
        emit(state.copyWith(
          allPresetData: updatedData,
          groupedPresets: updatedGroupedPresets,
          errorMessage: null,
        ));
        
        AppLogger.i(_tag, '✅ 预设已添加到本地缓存: ${featureType}');
      } else {
        // 如果没有聚合数据，只更新分组预设
        final updatedGroupedPresets = Map<String, List<AIPromptPreset>>.from(state.groupedPresets);
        final featureType = newPreset.aiFeatureType;
        
        if (updatedGroupedPresets.containsKey(featureType)) {
          updatedGroupedPresets[featureType] = [newPreset, ...updatedGroupedPresets[featureType]!];
        } else {
          updatedGroupedPresets[featureType] = [newPreset];
        }
        
        emit(state.copyWith(
          groupedPresets: updatedGroupedPresets,
          errorMessage: null,
        ));
        
        AppLogger.w(_tag, '⚠️ 仅更新分组预设，聚合数据不存在');
      }
      
    } catch (e) {
      AppLogger.e(_tag, '❌ 添加预设到本地缓存失败', e);
      emit(state.copyWith(
        errorMessage: '添加预设到缓存失败: ${e.toString()}',
      ));
    }
  }

  /// 🚀 加载所有预设聚合数据
  Future<void> _onLoadAllPresetData(
    LoadAllPresetData event,
    Emitter<PresetState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      
      AppLogger.i(_tag, '🚀 开始加载所有预设聚合数据: novelId=${event.novelId}');
      
      final allPresetData = await _aggregationRepository.getAllUserPresetData(
        novelId: event.novelId,
      );
      
      emit(state.copyWith(
        isLoading: false,
        allPresetData: allPresetData,
        // 同时更新其他相关字段以保持兼容性
        userOverview: allPresetData.overview,
        groupedPresets: allPresetData.mergedGroupedPresets,
        batchPackages: allPresetData.packagesByFeatureType,
        favoritePresets: allPresetData.favoritePresets,
        quickAccessPresets: allPresetData.quickAccessPresets,
        recentlyUsedPresets: allPresetData.recentlyUsedPresets,
        errorMessage: null,
      ));
      
      AppLogger.i(_tag, '✅ 所有预设聚合数据加载完成');
      AppLogger.i(_tag, '📊 数据统计: 系统预设${allPresetData.systemPresets.length}个, 用户预设分组${allPresetData.userPresetsByFeatureType.length}个');
      AppLogger.i(_tag, '📈 合并分组: ${allPresetData.mergedGroupedPresets.length}个功能类型');
      allPresetData.mergedGroupedPresets.forEach((featureType, presets) {
        AppLogger.i(_tag, '  - $featureType: ${presets.length}个预设');
      });
      
    } catch (e) {
      AppLogger.e(_tag, '❌ 加载所有预设聚合数据失败', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '加载预设数据失败: ${e.toString()}',
      ));
    }
  }

  /// 预热预设缓存
  Future<void> _onWarmupPresetCache(
    WarmupPresetCache event,
    Emitter<PresetState> emit,
  ) async {
    try {
      AppLogger.i(_tag, '开始预热预设缓存...');
      
      final warmupResult = await _aggregationRepository.warmupCache();
      
      emit(state.copyWith(
        warmupResult: warmupResult,
        errorMessage: null,
      ));
      
      AppLogger.i(_tag, '预设缓存预热完成: ${warmupResult.success ? "成功" : "失败"}');
      if (warmupResult.success) {
        AppLogger.i(_tag, '预热了 ${warmupResult.warmedFeatureTypes} 个功能类型，${warmupResult.warmedPresets} 个预设，耗时 ${warmupResult.durationMs}ms');
      }
    } catch (e) {
      AppLogger.e(_tag, '预设缓存预热失败', e);
      emit(state.copyWith(
        errorMessage: '预设缓存预热失败: ${e.toString()}',
      ));
    }
  }

  /// 🚀 向聚合缓存中添加新预设
  AllUserPresetData _addPresetToAggregatedData(AllUserPresetData data, AIPromptPreset newPreset) {
    final featureType = newPreset.aiFeatureType;
    
    // 更新用户预设分组
    final userByFeature = Map<String, List<AIPromptPreset>>.from(data.userPresetsByFeatureType);
    if (userByFeature.containsKey(featureType)) {
      // 添加到现有分组的开头
      userByFeature[featureType] = [newPreset, ...userByFeature[featureType]!];
    } else {
      // 创建新的功能类型分组
      userByFeature[featureType] = [newPreset];
    }
    
    // 更新包分组（如果存在）
    final packages = Map<String, PresetPackage>.from(data.packagesByFeatureType);
    if (packages.containsKey(featureType)) {
      final oldPackage = packages[featureType]!;
      packages[featureType] = PresetPackage(
        featureType: featureType,
        systemPresets: oldPackage.systemPresets,
        userPresets: [newPreset, ...oldPackage.userPresets],
        favoritePresets: oldPackage.favoritePresets,
        quickAccessPresets: oldPackage.quickAccessPresets,
        recentlyUsedPresets: oldPackage.recentlyUsedPresets,
        totalCount: oldPackage.totalCount + 1,
        cachedAt: DateTime.now(),
      );
    }
    
    // 如果新预设是收藏、快捷访问等特殊状态，也需要更新对应列表
    final favoritePresets = newPreset.isFavorite 
        ? [newPreset, ...data.favoritePresets]
        : data.favoritePresets;
    
    final quickAccessPresets = newPreset.showInQuickAccess
        ? [newPreset, ...data.quickAccessPresets]
        : data.quickAccessPresets;
    
    // 添加到最近使用列表的开头
    final recentlyUsedPresets = [newPreset, ...data.recentlyUsedPresets];
    
    // 更新概览统计
    final currentStats = data.overview.presetsByFeatureType[featureType];
    final updatedStats = currentStats != null
        ? PresetTypeStats(
            systemCount: currentStats.systemCount,
            userCount: currentStats.userCount + 1,
            favoriteCount: newPreset.isFavorite ? currentStats.favoriteCount + 1 : currentStats.favoriteCount,
            recentUsageCount: currentStats.recentUsageCount + 1,
          )
        : PresetTypeStats(
            systemCount: 0,
            userCount: 1,
            favoriteCount: newPreset.isFavorite ? 1 : 0,
            recentUsageCount: 1,
          );
    
    final overview = UserPresetOverview(
      totalPresets: data.overview.totalPresets + 1,
      systemPresets: data.overview.systemPresets,
      userPresets: data.overview.userPresets + 1,
      favoritePresets: favoritePresets.length,
      presetsByFeatureType: {
        ...data.overview.presetsByFeatureType,
        featureType: updatedStats,
      },
      recentFeatureTypes: _updateRecentFeatureTypes(data.overview.recentFeatureTypes, featureType),
      popularTags: data.overview.popularTags,
      generatedAt: DateTime.now(),
    );
    
    return AllUserPresetData(
      userId: data.userId,
      overview: overview,
      packagesByFeatureType: packages,
      systemPresets: data.systemPresets,
      userPresetsByFeatureType: userByFeature,
      favoritePresets: favoritePresets,
      quickAccessPresets: quickAccessPresets,
      recentlyUsedPresets: recentlyUsedPresets,
      timestamp: DateTime.now(),
      cacheDuration: data.cacheDuration,
    );
  }

  /// 🚀 更新最近使用的功能类型列表
  List<String> _updateRecentFeatureTypes(List<String> current, String newFeatureType) {
    final updated = [newFeatureType];
    for (final type in current) {
      if (type != newFeatureType && updated.length < 5) {
        updated.add(type);
      }
    }
    return updated;
  }

  /// 🚀 从聚合缓存中删除指定预设
  AllUserPresetData? _removePresetFromAggregatedData(AllUserPresetData? data, String presetId) {
    if (data == null) return null;
    
    bool found = false;

    // 从系统预设列表中移除
    final system = data.systemPresets.where((p) => p.presetId != presetId).toList();
    if (system.length != data.systemPresets.length) found = true;

    // 从用户预设分组中移除
    final userByFeature = <String, List<AIPromptPreset>>{};
    data.userPresetsByFeatureType.forEach((k, list) {
      final filtered = list.where((p) => p.presetId != presetId).toList();
      if (filtered.isNotEmpty) {
        userByFeature[k] = filtered;
      }
      if (filtered.length != list.length) found = true;
    });

    // 从收藏/快捷/最近列表中移除
    final fav = data.favoritePresets.where((p) => p.presetId != presetId).toList();
    final quick = data.quickAccessPresets.where((p) => p.presetId != presetId).toList();
    final recent = data.recentlyUsedPresets.where((p) => p.presetId != presetId).toList();

    if (!found) return data; // 未找到则直接返回原数据

    // 更新包分组
    final packages = Map<String, PresetPackage>.from(data.packagesByFeatureType);
    packages.forEach((featureType, package) {
      final filteredUser = package.userPresets.where((p) => p.presetId != presetId).toList();
      final filteredSystem = package.systemPresets.where((p) => p.presetId != presetId).toList();
      
      if (filteredUser.length != package.userPresets.length || 
          filteredSystem.length != package.systemPresets.length) {
        packages[featureType] = PresetPackage(
          featureType: featureType,
          systemPresets: filteredSystem,
          userPresets: filteredUser,
          favoritePresets: package.favoritePresets.where((p) => p.presetId != presetId).toList(),
          quickAccessPresets: package.quickAccessPresets.where((p) => p.presetId != presetId).toList(),
          recentlyUsedPresets: package.recentlyUsedPresets.where((p) => p.presetId != presetId).toList(),
          totalCount: filteredUser.length + filteredSystem.length,
          cachedAt: DateTime.now(),
        );
      }
    });

    // 更新概览统计
    final overview = UserPresetOverview(
      totalPresets: data.overview.totalPresets - 1,
      systemPresets: system.length,
      userPresets: userByFeature.values.fold(0, (sum, list) => sum + list.length),
      favoritePresets: fav.length,
      presetsByFeatureType: data.overview.presetsByFeatureType, // 保持不变，可选优化
      recentFeatureTypes: data.overview.recentFeatureTypes,
      popularTags: data.overview.popularTags,
      generatedAt: DateTime.now(),
    );

    return AllUserPresetData(
      userId: data.userId,
      overview: overview,
      packagesByFeatureType: packages,
      systemPresets: system,
      userPresetsByFeatureType: userByFeature,
      favoritePresets: fav,
      quickAccessPresets: quick,
      recentlyUsedPresets: recent,
      timestamp: DateTime.now(),
      cacheDuration: data.cacheDuration,
    );
  }

  /// 🚀 在聚合缓存中替换指定预设
  AllUserPresetData? _replacePresetInAggregatedData(AllUserPresetData? data, AIPromptPreset updated) {
    if (data == null) return null;
    
    bool replaced = false;

    // 更新系统预设列表
    List<AIPromptPreset> system = data.systemPresets
        .map((p) => p.presetId == updated.presetId ? updated : p)
        .toList();
    if (!replaced) replaced = system.any((p) => p.presetId == updated.presetId);

    // 更新用户预设分组
    final userByFeature = <String, List<AIPromptPreset>>{};
    data.userPresetsByFeatureType.forEach((k, list) {
      userByFeature[k] = list.map((p) => p.presetId == updated.presetId ? updated : p).toList();
      if (!replaced) {
        replaced = list.any((p) => p.presetId == updated.presetId);
      }
    });

    // 更新收藏/快捷/最近
    List<AIPromptPreset> _mapList(List<AIPromptPreset> src) =>
        src.map((p) => p.presetId == updated.presetId ? updated : p).toList();
    final fav = _mapList(data.favoritePresets);
    final quick = _mapList(data.quickAccessPresets);
    final recent = _mapList(data.recentlyUsedPresets);

    // 如果所有列表都未包含，则根据预设类型追加到正确列表
    if (!replaced) {
      if (updated.isSystem) {
        system.add(updated);
      } else {
        userByFeature.putIfAbsent(updated.aiFeatureType, () => []);
        userByFeature[updated.aiFeatureType]!.add(updated);
      }
      // 快捷访问
      if (updated.showInQuickAccess && !quick.any((p) => p.presetId == updated.presetId)) {
        quick.insert(0, updated);
      }
      // 收藏
      if (updated.isFavorite && !fav.any((p) => p.presetId == updated.presetId)) {
        fav.insert(0, updated);
      }
      // 最近使用无需处理
    }

    return AllUserPresetData(
      userId: data.userId,
      overview: data.overview,
      packagesByFeatureType: data.packagesByFeatureType,
      systemPresets: system,
      userPresetsByFeatureType: userByFeature,
      favoritePresets: fav,
      quickAccessPresets: quick,
      recentlyUsedPresets: recent,
      timestamp: DateTime.now(), // 🔧 修复：更新为当前时间戳
      cacheDuration: data.cacheDuration,
    );
  }
}