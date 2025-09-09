import 'package:flutter/material.dart';
import 'package:ainoval/models/scene_beat_data.dart';
import 'package:ainoval/models/ai_request_models.dart';
import 'package:ainoval/models/unified_ai_model.dart';
import 'package:ainoval/models/novel_structure.dart';
import 'package:ainoval/models/novel_setting_item.dart';
import 'package:ainoval/models/setting_group.dart';
import 'package:ainoval/models/novel_snippet.dart';
import 'package:ainoval/widgets/editor/overlay_scene_beat_panel.dart';
import 'package:ainoval/utils/logger.dart';
import '../../config/app_config.dart';

// 🚀 新增：导入编辑器状态相关类
import 'package:ainoval/screens/editor/controllers/editor_screen_controller.dart';
import 'package:ainoval/screens/editor/managers/editor_layout_manager.dart';

/// 🚀 重构：纯数据管理器 - 只管理数据，不操作UI
/// 全局单例，负责场景节拍数据的CRUD操作
class SceneBeatDataManager {
  static SceneBeatDataManager? _instance;
  static SceneBeatDataManager get instance => _instance ??= SceneBeatDataManager._();
  
  SceneBeatDataManager._();
  
  // 🚀 核心：场景节拍数据缓存（场景ID -> 数据）
  final Map<String, SceneBeatData> _sceneDataCache = {};
  
  // 🚀 核心：数据变化通知器（场景ID -> 通知器）
  final Map<String, ValueNotifier<SceneBeatData>> _dataNotifiers = {};
  
  /// 获取场景数据的通知器（用于UI监听）
  ValueNotifier<SceneBeatData> getDataNotifier(String sceneId) {
    return _dataNotifiers.putIfAbsent(sceneId, () {
      final data = _sceneDataCache[sceneId] ?? SceneBeatData.createDefault(
        userId: AppConfig.userId ?? 'current-user', // 从AppConfig获取当前用户ID
        novelId: 'unknown', // TODO: 从场景上下文获取
        initialPrompt: '为当前场景生成场景节拍',
      );
      return ValueNotifier<SceneBeatData>(data);
    });
  }
  
  /// 获取场景数据（纯数据访问，不触发UI）
  SceneBeatData getSceneData(String sceneId) {
    final data = _sceneDataCache[sceneId];
    if (data != null) {
      return data;
    }
    
    // 创建默认数据但不立即缓存
    return SceneBeatData.createDefault(
      userId: AppConfig.userId ?? 'current-user', // 从AppConfig获取当前用户ID
      novelId: 'unknown',
      initialPrompt: '为当前场景生成场景节拍',
    );
  }
  
  /// 更新场景数据（纯数据操作）
  void updateSceneData(String sceneId, SceneBeatData newData) {
    // 🚀 优化：检查数据是否真正发生变化
    final currentData = _sceneDataCache[sceneId];
    if (currentData != null && _isDataEqual(currentData, newData)) {
      AppLogger.v('SceneBeatDataManager', '📊 场景数据无变化，跳过更新: $sceneId');
      return;
    }
    
    AppLogger.i('SceneBeatDataManager', '🔄 更新场景数据: $sceneId');
    
    // 更新缓存
    _sceneDataCache[sceneId] = newData;
    
    // 通知UI（如果有监听器的话）
    final notifier = _dataNotifiers[sceneId];
    if (notifier != null) {
      notifier.value = newData;
    }
  }
  
  /// 🚀 判断两个SceneBeatData是否相等（基于关键字段）
  bool _isDataEqual(SceneBeatData data1, SceneBeatData data2) {
    return data1.requestData == data2.requestData &&
           data1.generatedContentDelta == data2.generatedContentDelta &&
           data1.selectedUnifiedModelId == data2.selectedUnifiedModelId &&
           data1.selectedLength == data2.selectedLength &&
           data1.temperature == data2.temperature &&
           data1.topP == data2.topP &&
           data1.enableSmartContext == data2.enableSmartContext &&
           data1.contextSelectionsData == data2.contextSelectionsData &&
           data1.status == data2.status &&
           data1.progress == data2.progress;
  }
  
  /// 🚀 公开方法：判断两个SceneBeatData是否相等
  bool isDataEqual(SceneBeatData data1, SceneBeatData data2) {
    return _isDataEqual(data1, data2);
  }
  
  /// 更新场景状态（便捷方法）
  void updateSceneStatus(String sceneId, SceneBeatStatus status) {
    final currentData = getSceneData(sceneId);
    final updatedData = currentData.updateStatus(status);
    updateSceneData(sceneId, updatedData);
  }
  
  /// 清理场景数据
  void clearSceneData(String sceneId) {
    AppLogger.i('SceneBeatDataManager', '🗑️ 清理场景数据: $sceneId');
    _sceneDataCache.remove(sceneId);
    
    final notifier = _dataNotifiers.remove(sceneId);
    notifier?.dispose();
  }
  
  /// 清理所有数据
  void clearAllData() {
    AppLogger.i('SceneBeatDataManager', '🗑️ 清理所有场景节拍数据');
    _sceneDataCache.clear();
    
    for (final notifier in _dataNotifiers.values) {
      notifier.dispose();
    }
    _dataNotifiers.clear();
  }
}

/// 🚀 重构：UI管理器 - 只管理UI显示/隐藏，不处理数据
/// 全局单例，负责浮动面板的显示状态管理
class OverlaySceneBeatManager {
  static OverlaySceneBeatManager? _instance;
  static OverlaySceneBeatManager get instance => _instance ??= OverlaySceneBeatManager._();
  
  OverlaySceneBeatManager._();
  
  // 🚀 UI状态：当前显示的浮动面板
  OverlayEntry? _currentOverlay;
  
  // 🚀 UI状态：当前场景ID（UI层面的概念）
  final ValueNotifier<String?> _currentSceneIdNotifier = ValueNotifier<String?>(null);
  
  // 🚀 UI状态：显示状态
  bool _isVisible = false;
  
  // 🚀 UI参数缓存（避免重复传递）
  Novel? _cachedNovel;
  List<NovelSettingItem> _cachedSettings = [];
  List<SettingGroup> _cachedSettingGroups = [];
  List<NovelSnippet> _cachedSnippets = [];
  Function(String, UniversalAIRequest, UnifiedAIModel)? _cachedOnGenerate;
  
  // 🚀 新增：编辑器状态监听
  EditorScreenController? _editorController;
  EditorLayoutManager? _layoutManager;
  VoidCallback? _editorControllerListener;
  VoidCallback? _layoutManagerListener;
  
  /// 获取当前场景ID通知器（UI监听用）
  ValueNotifier<String?> get currentSceneIdNotifier => _currentSceneIdNotifier;
  
  /// 获取当前场景ID
  String? get currentSceneId => _currentSceneIdNotifier.value;
  
  /// 是否显示中
  bool get isVisible => _isVisible;
  
  /// 🚀 新增：绑定编辑器状态监听
  void bindEditorState({
    EditorScreenController? editorController,
    EditorLayoutManager? layoutManager,
  }) {
    AppLogger.i('OverlaySceneBeatManager', '🔗 绑定编辑器状态监听');
    
    // 清理之前的监听器
    unbindEditorState();
    
    _editorController = editorController;
    _layoutManager = layoutManager;
    
    // 监听编辑器状态变化
    if (_editorController != null) {
      _editorControllerListener = () {
        _onEditorStateChanged();
      };
      _editorController!.addListener(_editorControllerListener!);
    }
    
    // 监听布局管理器状态变化
    if (_layoutManager != null) {
      _layoutManagerListener = () {
        _onLayoutStateChanged();
      };
      _layoutManager!.addListener(_layoutManagerListener!);
    }
  }
  
  /// 🚀 新增：解绑编辑器状态监听
  void unbindEditorState() {
    if (_editorController != null && _editorControllerListener != null) {
      _editorController!.removeListener(_editorControllerListener!);
      _editorController = null;
      _editorControllerListener = null;
    }
    
    if (_layoutManager != null && _layoutManagerListener != null) {
      _layoutManager!.removeListener(_layoutManagerListener!);
      _layoutManager = null;
      _layoutManagerListener = null;
    }
  }
  
  /// 🚀 新增：处理编辑器状态变化
  void _onEditorStateChanged() {
    if (_editorController == null || !_isVisible) return;
    
    // 检查是否切换到了其他视图
    final bool isInMainEditMode = !_editorController!.isPlanViewActive && 
                                  !_editorController!.isNextOutlineViewActive && 
                                  !_editorController!.isPromptViewActive;
    
    if (!isInMainEditMode) {
      AppLogger.i('OverlaySceneBeatManager', '📺 检测到视图切换，隐藏场景节拍面板');
      hide();
    }
  }
  
  /// 🚀 新增：处理布局状态变化
  void _onLayoutStateChanged() {
    if (_layoutManager == null || !_isVisible) return;
    
    // 检查是否有设置面板显示
    if (_layoutManager!.isSettingsPanelVisible) {
      AppLogger.i('OverlaySceneBeatManager', '⚙️ 检测到设置面板显示，隐藏场景节拍面板');
      hide();
    }
    
    // 检查是否有其他重要对话框显示
    if (_layoutManager!.isNovelSettingsVisible) {
      AppLogger.i('OverlaySceneBeatManager', '📖 检测到小说设置显示，隐藏场景节拍面板');
      hide();
    }
  }
  
  /// 🚀 显示浮动面板（只处理UI显示，不管理数据）
  void show({
    required BuildContext context,
    required String sceneId,
    Novel? novel,
    List<NovelSettingItem> settings = const [],
    List<SettingGroup> settingGroups = const [],
    List<NovelSnippet> snippets = const [],
    Function(String, UniversalAIRequest, UnifiedAIModel)? onGenerate,
    // 🚀 新增：可选的编辑器状态参数
    EditorScreenController? editorController,
    EditorLayoutManager? layoutManager,
  }) {
    AppLogger.i('OverlaySceneBeatManager', '🎯 显示场景节拍面板: $sceneId');
    
    // 🚀 绑定编辑器状态监听
    bindEditorState(
      editorController: editorController,
      layoutManager: layoutManager,
    );
    
    // 🚀 检查当前是否在主编辑模式
    if (editorController != null) {
      final bool isInMainEditMode = !editorController.isPlanViewActive && 
                                    !editorController.isNextOutlineViewActive && 
                                    !editorController.isPromptViewActive;
      
      if (!isInMainEditMode) {
        AppLogger.w('OverlaySceneBeatManager', '⚠️ 当前不在主编辑模式，跳过显示场景节拍面板');
        return;
      }
    }
    
    // 🚀 检查是否有设置面板显示
    if (layoutManager != null && layoutManager.isSettingsPanelVisible) {
      AppLogger.w('OverlaySceneBeatManager', '⚠️ 设置面板正在显示，跳过显示场景节拍面板');
      return;
    }
    
    // 缓存参数
    _cachedNovel = novel;
    _cachedSettings = settings;
    _cachedSettingGroups = settingGroups;
    _cachedSnippets = snippets;
    _cachedOnGenerate = onGenerate;
    
    // 如果已经显示，只切换场景
    if (_isVisible && _currentOverlay != null) {
      switchScene(sceneId);
      return;
    }
    
    // 创建新的浮动面板
    _currentOverlay = _createOverlayEntry(context, sceneId);
    
    // 插入到Overlay中
    Overlay.of(context).insert(_currentOverlay!);
    
    // 更新状态
    _isVisible = true;
    _currentSceneIdNotifier.value = sceneId;
    
    AppLogger.i('OverlaySceneBeatManager', '✅ 场景节拍面板已显示');
  }
  
  /// 🚀 切换场景（只更新场景ID，面板自动响应）
  void switchScene(String sceneId) {
    if (_currentSceneIdNotifier.value == sceneId) {
      AppLogger.v('OverlaySceneBeatManager', '场景ID相同，跳过切换: $sceneId');
      return;
    }
    
    AppLogger.i('OverlaySceneBeatManager', '🔄 切换场景: ${_currentSceneIdNotifier.value} -> $sceneId');
    
    // 只更新场景ID，UI会自动响应
    _currentSceneIdNotifier.value = sceneId;
  }
  
  /// 🚀 隐藏面板（只处理UI隐藏）
  void hide() {
    if (!_isVisible || _currentOverlay == null) {
      return;
    }
    
    AppLogger.i('OverlaySceneBeatManager', '🫥 隐藏场景节拍面板');
    
    // 移除浮动面板
    _currentOverlay!.remove();
    _currentOverlay = null;
    
    // 更新状态
    _isVisible = false;
    _currentSceneIdNotifier.value = null;
    
    AppLogger.i('OverlaySceneBeatManager', '✅ 场景节拍面板已隐藏');
  }
  
  /// 🚀 切换显示状态
  void toggle({
    required BuildContext context,
    required String sceneId,
    Novel? novel,
    List<NovelSettingItem> settings = const [],
    List<SettingGroup> settingGroups = const [],
    List<NovelSnippet> snippets = const [],
    Function(String, UniversalAIRequest, UnifiedAIModel)? onGenerate,
    // 🚀 新增：可选的编辑器状态参数
    EditorScreenController? editorController,
    EditorLayoutManager? layoutManager,
  }) {
    if (_isVisible) {
      hide();
    } else {
      show(
        context: context,
        sceneId: sceneId,
        novel: novel,
        settings: settings,
        settingGroups: settingGroups,
        snippets: snippets,
        onGenerate: onGenerate,
        editorController: editorController,
        layoutManager: layoutManager,
      );
    }
  }
  
  /// 🚀 创建浮动面板UI（新架构：UI独立管理）
  OverlayEntry _createOverlayEntry(BuildContext context, String initialSceneId) {
    return OverlayEntry(
      builder: (overlayContext) => ValueListenableBuilder<String?>(
        valueListenable: _currentSceneIdNotifier,
        builder: (context, currentSceneId, child) {
          if (currentSceneId == null) {
            return const SizedBox.shrink();
          }
          
          return SceneBeatFloatingPanel(
            sceneId: currentSceneId,
            novel: _cachedNovel,
            settings: _cachedSettings,
            settingGroups: _cachedSettingGroups,
            snippets: _cachedSnippets,
            onClose: hide,
            onGenerate: _cachedOnGenerate,
          );
        },
      ),
    );
  }
  
  /// 🚀 修改：增强的释放资源方法
  void dispose() {
    AppLogger.i('OverlaySceneBeatManager', '🗑️ 开始释放UI管理器资源');
    
    // 隐藏面板
    hide();
    
    // 解绑编辑器状态监听
    unbindEditorState();
    
    // 释放通知器
    _currentSceneIdNotifier.dispose();
    
    // 清理缓存
    _cachedNovel = null;
    _cachedSettings = [];
    _cachedSettingGroups = [];
    _cachedSnippets = [];
    _cachedOnGenerate = null;
    
    AppLogger.i('OverlaySceneBeatManager', '✅ UI管理器资源已释放');
  }
}

/// 🚀 新增：场景节拍浮动面板UI组件
/// 职责：纯UI展示，通过监听数据管理器获取数据变化
class SceneBeatFloatingPanel extends StatefulWidget {
  const SceneBeatFloatingPanel({
    super.key,
    required this.sceneId,
    this.novel,
    this.settings = const [],
    this.settingGroups = const [],
    this.snippets = const [],
    this.onClose,
    this.onGenerate,
  });
  
  final String sceneId;
  final Novel? novel;
  final List<NovelSettingItem> settings;
  final List<SettingGroup> settingGroups;
  final List<NovelSnippet> snippets;
  final VoidCallback? onClose;
  final Function(String, UniversalAIRequest, UnifiedAIModel)? onGenerate;

  @override
  State<SceneBeatFloatingPanel> createState() => _SceneBeatFloatingPanelState();
}

class _SceneBeatFloatingPanelState extends State<SceneBeatFloatingPanel> {
  // 🚀 数据监听器（只监听当前场景的数据变化）
  late ValueNotifier<SceneBeatData> _dataNotifier;
  
  @override
  void initState() {
    super.initState();
    _setupDataListener();
  }
  
  @override
  void didUpdateWidget(SceneBeatFloatingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 🚀 只有场景ID变化时才重新设置监听器
    if (oldWidget.sceneId != widget.sceneId) {
      AppLogger.i('SceneBeatFloatingPanel', '🔄 场景切换，重新设置数据监听: ${oldWidget.sceneId} -> ${widget.sceneId}');
      _setupDataListener();
    }
  }
  
  /// 🚀 设置数据监听器（核心：数据和UI分离）
  void _setupDataListener() {
    // 获取当前场景的数据通知器
    _dataNotifier = SceneBeatDataManager.instance.getDataNotifier(widget.sceneId);
    
    AppLogger.i('SceneBeatFloatingPanel', '📡 设置场景数据监听: ${widget.sceneId}');
  }
  
  @override
  Widget build(BuildContext context) {
    // 🚀 核心：优化重建策略，减少不必要的重建
    return ValueListenableBuilder<SceneBeatData>(
      valueListenable: _dataNotifier,
      // 🚀 使用 child 参数缓存不需要重建的部分
      child: _buildStaticContent(),
      builder: (context, sceneBeatData, child) {
        // 🚀 直接返回面板，避免ParentData冲突
        return OverlaySceneBeatPanel(
          sceneId: widget.sceneId,
          data: sceneBeatData,
          novel: widget.novel,
          settings: widget.settings,
          settingGroups: widget.settingGroups,
          snippets: widget.snippets,
          onClose: widget.onClose,
          onGenerate: widget.onGenerate != null 
            ? (request, model) => widget.onGenerate!(widget.sceneId, request, model)
            : null,
          onDataChanged: (newData) {
            // 🚀 避免无谓的更新：只在数据真正改变时才更新
            if (_shouldUpdateData(sceneBeatData, newData)) {
              SceneBeatDataManager.instance.updateSceneData(widget.sceneId, newData);
            }
          },
        );
      },
    );
  }
  
  /// 🚀 构建静态内容（不需要监听数据变化的部分）
  Widget _buildStaticContent() {
    // 这里可以放置不依赖于数据的静态组件
    return const SizedBox.shrink();
  }
  
  /// 🚀 判断是否需要更新数据（避免无意义的更新）
  bool _shouldUpdateData(SceneBeatData oldData, SceneBeatData newData) {
    // 🚀 简化：利用数据管理器的公开相等性检查方法
    return !SceneBeatDataManager.instance.isDataEqual(oldData, newData);
  }
  
  @override
  void dispose() {
    // 🚀 不需要手动dispose _dataNotifier，由数据管理器统一管理
    super.dispose();
  }
} 