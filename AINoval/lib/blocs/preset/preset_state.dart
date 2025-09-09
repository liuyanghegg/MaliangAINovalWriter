import 'package:equatable/equatable.dart';
import 'package:ainoval/models/preset_models.dart';

/// 预设管理状态
class PresetState extends Equatable {
  /// 是否正在加载
  final bool isLoading;
  
  /// 错误信息
  final String? errorMessage;
  
  /// 用户预设概览
  final UserPresetOverview? userOverview;
  
  /// 当前预设包
  final PresetPackage? currentPackage;
  
  /// 批量预设包
  final Map<String, PresetPackage> batchPackages;
  
  /// 按功能类型分组的预设
  final Map<String, List<AIPromptPreset>> groupedPresets;
  
  /// 当前选中的预设
  final AIPromptPreset? selectedPreset;
  
  /// 搜索结果
  final List<AIPromptPreset> searchResults;
  
  /// 搜索查询
  final String searchQuery;
  
  /// 预设统计信息
  final PresetStatistics? statistics;
  
  /// 收藏预设列表
  final List<AIPromptPreset> favoritePresets;
  
  /// 最近使用预设列表
  final List<AIPromptPreset> recentlyUsedPresets;
  
  /// 快捷访问预设列表
  final List<AIPromptPreset> quickAccessPresets;
  
  /// 缓存预热结果
  final CacheWarmupResult? warmupResult;
  
  /// 缓存统计信息
  final AggregationCacheStats? cacheStats;
  
  /// 健康检查结果
  final Map<String, dynamic>? healthStatus;

  /// 🚀 所有预设聚合数据
  final AllUserPresetData? allPresetData;

  const PresetState({
    this.isLoading = false,
    this.errorMessage,
    this.userOverview,
    this.currentPackage,
    this.batchPackages = const {},
    this.groupedPresets = const {},
    this.selectedPreset,
    this.searchResults = const [],
    this.searchQuery = '',
    this.statistics,
    this.favoritePresets = const [],
    this.recentlyUsedPresets = const [],
    this.quickAccessPresets = const [],
    this.warmupResult,
    this.cacheStats,
    this.healthStatus,
    this.allPresetData,
  });

  /// 初始状态
  const PresetState.initial() : this();

  /// 加载状态
  PresetState.loading() : this(isLoading: true);

  /// 错误状态
  PresetState.error(String message) : this(errorMessage: message);

  /// 复制状态并更新指定字段
  PresetState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserPresetOverview? userOverview,
    PresetPackage? currentPackage,
    Map<String, PresetPackage>? batchPackages,
    Map<String, List<AIPromptPreset>>? groupedPresets,
    AIPromptPreset? selectedPreset,
    List<AIPromptPreset>? searchResults,
    String? searchQuery,
    PresetStatistics? statistics,
    List<AIPromptPreset>? favoritePresets,
    List<AIPromptPreset>? recentlyUsedPresets,
    List<AIPromptPreset>? quickAccessPresets,
    CacheWarmupResult? warmupResult,
    AggregationCacheStats? cacheStats,
    Map<String, dynamic>? healthStatus,
    AllUserPresetData? allPresetData,
  }) {
    return PresetState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userOverview: userOverview ?? this.userOverview,
      currentPackage: currentPackage ?? this.currentPackage,
      batchPackages: batchPackages ?? this.batchPackages,
      groupedPresets: groupedPresets ?? this.groupedPresets,
      selectedPreset: selectedPreset,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      statistics: statistics ?? this.statistics,
      favoritePresets: favoritePresets ?? this.favoritePresets,
      recentlyUsedPresets: recentlyUsedPresets ?? this.recentlyUsedPresets,
      quickAccessPresets: quickAccessPresets ?? this.quickAccessPresets,
      warmupResult: warmupResult ?? this.warmupResult,
      cacheStats: cacheStats ?? this.cacheStats,
      healthStatus: healthStatus ?? this.healthStatus,
      allPresetData: allPresetData ?? this.allPresetData,
    );
  }

  /// 是否有数据
  bool get hasData {
    return userOverview != null ||
           currentPackage != null ||
           batchPackages.isNotEmpty ||
           groupedPresets.isNotEmpty ||
           searchResults.isNotEmpty;
  }

  /// 是否有错误
  bool get hasError => errorMessage != null;

  /// 是否有选中的预设
  bool get hasSelectedPreset => selectedPreset != null;

  /// 是否正在搜索
  bool get isSearching => searchQuery.isNotEmpty;

  /// 获取所有预设的总数
  int get totalPresetCount {
    return groupedPresets.values.fold(0, (sum, presets) => sum + presets.length);
  }

  /// 获取用户预设数量
  int get userPresetCount {
    return groupedPresets.values
        .expand((presets) => presets)
        .where((preset) => !preset.isSystem)
        .length;
  }

  /// 获取系统预设数量
  int get systemPresetCount {
    return groupedPresets.values
        .expand((presets) => presets)
        .where((preset) => preset.isSystem)
        .length;
  }

  /// 获取收藏预设数量
  int get favoritePresetCount {
    return groupedPresets.values
        .expand((presets) => presets)
        .where((preset) => preset.isFavorite)
        .length;
  }

  /// 获取快捷访问预设数量
  int get quickAccessPresetCount {
    return groupedPresets.values
        .expand((presets) => presets)
        .where((preset) => preset.showInQuickAccess)
        .length;
  }

  /// 获取指定功能类型的预设列表
  List<AIPromptPreset> getPresetsByFeatureType(String featureType) {
    return groupedPresets[featureType] ?? [];
  }

  /// 获取所有预设的平铺列表
  List<AIPromptPreset> get allPresets {
    return groupedPresets.values.expand((presets) => presets).toList();
  }

  /// 🚀 获取合并后的分组预设（系统预设+用户预设，按功能分组）
  /// 优先使用allPresetData中的合并数据，如果没有则使用旧的groupedPresets
  Map<String, List<AIPromptPreset>> get mergedGroupedPresets {
    if (allPresetData != null) {
      return allPresetData!.mergedGroupedPresets;
    }
    return groupedPresets;
  }

  /// 是否已加载聚合数据
  bool get hasAllPresetData => allPresetData != null;

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        userOverview,
        currentPackage,
        batchPackages,
        groupedPresets,
        selectedPreset,
        searchResults,
        searchQuery,
        statistics,
        favoritePresets,
        recentlyUsedPresets,
        quickAccessPresets,
        warmupResult,
        cacheStats,
        healthStatus,
        allPresetData,
      ];

  @override
  String toString() {
    return '''PresetState(
      isLoading: $isLoading,
      hasError: $hasError,
      hasData: $hasData,
      totalPresets: $totalPresetCount,
      userPresets: $userPresetCount,
      systemPresets: $systemPresetCount,
      favoritePresets: $favoritePresetCount,
      quickAccessPresets: $quickAccessPresetCount,
      selectedPreset: ${selectedPreset?.presetName ?? 'null'},
      searchQuery: '$searchQuery',
    )''';
  }
}