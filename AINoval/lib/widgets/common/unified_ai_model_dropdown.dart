// import 'package:ainoval/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/unified_ai_model.dart';
import '../../models/user_ai_model_config_model.dart';
// import '../../models/public_model_config.dart';
import '../../models/novel_structure.dart';
import '../../models/novel_setting_item.dart';
import '../../models/setting_group.dart';
import '../../models/novel_snippet.dart';
import '../../blocs/ai_config/ai_config_bloc.dart';
import '../../blocs/public_models/public_models_bloc.dart';
import '../../screens/chat/widgets/chat_settings_dialog.dart';
import '../../config/provider_icons.dart';
import '../../models/ai_request_models.dart';
import '../../screens/editor/managers/editor_layout_manager.dart';
import 'package:provider/provider.dart';
import 'package:ainoval/config/app_config.dart';
import 'package:ainoval/screens/settings/settings_panel.dart';
import 'package:ainoval/screens/editor/managers/editor_state_manager.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

// ==================== 统一 AI 模型下拉菜单 - 尺寸常量定义 ====================

/// 菜单整体尺寸配置
class _MenuDimensions {
  /// 菜单固定宽度
  static const double menuWidth = 320.0;
  
  /// 菜单默认最大高度
  static const double defaultMaxHeight = 900.0;
  
  /// 屏幕边缘的安全边距，防止菜单被状态栏或导航栏遮挡
  static const double screenSafeMargin = 80.0;
  
  /// 菜单最小高度（有设置按钮时）
  static const double minHeightWithSettings = 180.0;
  
  /// 菜单最小高度（无设置按钮时）
  static const double minHeightWithoutSettings = 120.0;
  
  /// 菜单与锚点的垂直间距
  static const double anchorVerticalOffset = 6.0;
  
  /// 菜单水平边距
  static const double horizontalMargin = 16.0;
}

/// 菜单内容区域尺寸配置
class _ContentDimensions {
  /// 供应商分组标题高度
  static const double groupHeaderHeight = 36.0;
  
  /// 单个模型项的高度（包含标签显示空间）
  static const double modelItemHeight = 40.0;
  
  /// 底部操作按钮区域高度
  static const double bottomButtonHeight = 56.0;
  
  /// 菜单内容的上下内边距
  static const double verticalPadding = 6.0;
  
  /// 菜单内容的左右内边距
  static const double horizontalPadding = 4.0;
}

/// 模型项内部尺寸配置
class _ModelItemDimensions {
  /// 模型图标容器大小
  static const double iconContainerSize = 20.0;
  
  /// 模型图标实际大小
  static const double iconSize = 12.0;
  
  /// 模型图标与文字的间距
  static const double iconTextSpacing = 10.0;
  
  /// 选中指示器图标大小
  static const double selectedIconSize = 16.0;
  
  /// 模型项的水平内边距
  static const double itemHorizontalPadding = 12.0;
  
  /// 模型项的垂直内边距
  static const double itemVerticalPadding = 10.0;
  
  /// 模型项的外边距
  static const double itemMargin = 6.0;
  
  /// 模型项的圆角半径
  static const double itemBorderRadius = 8.0;
}

/// 标签样式尺寸配置
class _TagDimensions {
  /// 标签水平内边距
  static const double tagHorizontalPadding = 6.0;
  
  /// 标签垂直内边距
  static const double tagVerticalPadding = 2.0;
  
  /// 标签圆角半径
  static const double tagBorderRadius = 8.0;
  
  /// 标签边框宽度
  static const double tagBorderWidth = 0.5;
  
  /// 标签之间的间距
  static const double tagSpacing = 4.0;
  
  /// 标签行之间的间距
  static const double tagRunSpacing = 2.0;
  
  /// 标签与模型名称的间距
  static const double tagTopSpacing = 2.0;
}

/// 菜单外观样式配置
class _MenuStyling {
  /// 菜单圆角半径
  static const double menuBorderRadius = 16.0;
  
  /// 菜单边框宽度
  static const double menuBorderWidth = 0.8;
  
  /// 分割线高度
  static const double dividerHeight = 8.0;
  
  /// 分割线厚度
  static const double dividerThickness = 0.6;
  
  /// 分割线缩进
  static const double dividerIndent = 16.0;
  
  /// 分割线结束缩进
  static const double dividerEndIndent = 16.0;
  
  /// 菜单阴影高度（暗色主题）
  static const double elevationDark = 12.0;
  
  /// 菜单阴影高度（亮色主题）
  static const double elevationLight = 8.0;
}

/// 底部操作区域尺寸配置
class _BottomActionDimensions {
  /// 底部操作区域内边距
  static const double bottomPadding = 12.0;
  
  /// 按钮垂直内边距
  static const double buttonVerticalPadding = 12.0;
  
  /// 按钮圆角半径
  static const double buttonBorderRadius = 10.0;
  
  /// 按钮边框宽度
  static const double buttonBorderWidth = 0.8;
  
  /// 按钮图标大小
  static const double buttonIconSize = 18.0;

  /// “添加我的私人模型”按钮的高度估算（用于高度计算）
  static const double secondaryButtonHeight = 44.0;
}

/// 空状态显示尺寸配置
class _EmptyStateDimensions {
  /// 空状态容器内边距
  static const double emptyPadding = 24.0;
  
  /// 空状态图标大小
  static const double emptyIconSize = 48.0;
  
  /// 空状态图标与文字的间距
  static const double emptyIconTextSpacing = 12.0;
  
  /// 空状态标题与副标题的间距
  static const double emptyTitleSubtitleSpacing = 8.0;
}

// ==================== 统一 AI 模型下拉菜单组件实现 ====================

/// 统一的AI模型下拉菜单组件，支持显示私有模型和公共模型
/// 通过 [show] 静态方法弹出 Overlay 菜单
class UnifiedAIModelDropdown {
  static OverlayEntry show({
    required BuildContext context,
    LayerLink? layerLink,
    Rect? anchorRect,
    UnifiedAIModel? selectedModel,
    required Function(UnifiedAIModel?) onModelSelected,
    bool showSettingsButton = true,
    bool showAdjustAndGenerate = true,
    double maxHeight = _MenuDimensions.defaultMaxHeight,
    Novel? novel,
    List<NovelSettingItem> settings = const [],
    List<SettingGroup> settingGroups = const [],
    List<NovelSnippet> snippets = const [],
    UniversalAIRequest? chatConfig,
    ValueChanged<UniversalAIRequest>? onConfigChanged,
    VoidCallback? onClose,
  }) {
    assert(layerLink != null || anchorRect != null, '必须提供 layerLink 或 anchorRect');

    late OverlayEntry entry;
    bool _closed = false;

    void safeClose() {
      if (_closed) return;
      _closed = true;
      if (entry.mounted) {
        entry.remove();
      }
      onClose?.call();
    }

    entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // 点击空白处关闭
            Positioned.fill(
              child: GestureDetector(
                onTap: safeClose,
                child: Container(color: Colors.transparent),
              ),
            ),
            if (layerLink != null) ...[
              Positioned(
                width: _MenuDimensions.menuWidth,
                child: CompositedTransformFollower(
                  link: layerLink,
                  showWhenUnlinked: false,
                  targetAnchor: Alignment.bottomCenter,
                  followerAnchor: Alignment.topCenter,
                  offset: const Offset(0, _MenuDimensions.anchorVerticalOffset), // 向下偏移
                  child: BlocBuilder<AiConfigBloc, AiConfigState>(
                    builder: (context, aiState) {
                      return BlocBuilder<PublicModelsBloc, PublicModelsState>(
                        builder: (context, publicState) {
                          final allModels = _combineModels(aiState, publicState);
                          // 结合当前屏幕高度动态限制菜单高度，避免超出屏幕导致无法滚动
                          final screenH = MediaQuery.of(context).size.height;
                          final double maxAllowableHeight = screenH - _MenuDimensions.screenSafeMargin;
                          final menuHeight = _calculateMenuHeight(allModels, showSettingsButton, showAdjustAndGenerate, maxHeight)
                              .clamp(0.0, maxAllowableHeight)
                              .toDouble();
                          return _buildMenuContainer(
                            context, 
                            menuHeight, 
                            allModels, 
                            selectedModel, 
                            onModelSelected, 
                            showSettingsButton, 
                            showAdjustAndGenerate,
                            novel, 
                            settings, 
                            settingGroups, 
                            snippets, 
                            chatConfig, 
                            onConfigChanged, 
                            safeClose
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ] else if (anchorRect != null) ...[
              BlocBuilder<AiConfigBloc, AiConfigState>(
                builder: (context, aiState) {
                  return BlocBuilder<PublicModelsBloc, PublicModelsState>(
                    builder: (context, publicState) {
                      final allModels = _combineModels(aiState, publicState);
                      // 结合当前屏幕高度动态限制菜单高度，避免超出屏幕导致无法滚动
                      final screenH = MediaQuery.of(context).size.height;
                      final double maxAllowableHeight = screenH - _MenuDimensions.screenSafeMargin;
                      final menuHeight = _calculateMenuHeight(allModels, showSettingsButton, showAdjustAndGenerate, maxHeight)
                          .clamp(0.0, maxAllowableHeight)
                          .toDouble();
                      return _buildPositionedMenu(
                        context, 
                        anchorRect, 
                        menuHeight, 
                        allModels, 
                        selectedModel, 
                        onModelSelected, 
                        showSettingsButton, 
                        showAdjustAndGenerate,
                        novel, 
                        settings, 
                        settingGroups, 
                        snippets, 
                        chatConfig, 
                        onConfigChanged, 
                        safeClose
                      );
                    },
                  );
                },
              ),
            ],
          ],
        );
      },
    );

    Overlay.of(context).insert(entry);
    return entry;
  }

  /// 合并私有模型和公共模型
  static List<UnifiedAIModel> _combineModels(AiConfigState aiState, PublicModelsState publicState) {
    final List<UnifiedAIModel> allModels = [];
    
    // 添加已验证的私有模型
    final validatedConfigs = aiState.validatedConfigs;
    for (final config in validatedConfigs) {
      allModels.add(PrivateAIModel(config));
    }
    
    // 添加公共模型
    if (publicState is PublicModelsLoaded) {
      for (final publicModel in publicState.models) {
        allModels.add(PublicAIModel(publicModel));
      }
    }
    
    return allModels;
  }

  /// 按供应商分组模型，系统模型优先
  static Map<String, List<UnifiedAIModel>> _groupModelsByProvider(List<UnifiedAIModel> models) {
    final Map<String, List<UnifiedAIModel>> grouped = {};
    
    for (var model in models) {
      final provider = model.provider;
      grouped.putIfAbsent(provider, () => []);
      grouped[provider]!.add(model);
    }
    
    // 对每个供应商内的模型进行排序
    for (var list in grouped.values) {
      list.sort((a, b) {
        // 系统模型（公共模型）优先
        if (a.isPublic && !b.isPublic) return -1;
        if (!a.isPublic && b.isPublic) return 1;
        
        // 如果都是公共模型，按优先级排序
        if (a.isPublic && b.isPublic) {
          final aPriority = (a as PublicAIModel).publicConfig.priority ?? 0;
          final bPriority = (b as PublicAIModel).publicConfig.priority ?? 0;
          if (aPriority != bPriority) {
            return bPriority.compareTo(aPriority); // 优先级高的在前
          }
        }
        
        // 如果都是私有模型，默认配置在前
        if (!a.isPublic && !b.isPublic) {
          final aIsDefault = (a as PrivateAIModel).userConfig.isDefault;
          final bIsDefault = (b as PrivateAIModel).userConfig.isDefault;
          if (aIsDefault && !bIsDefault) return -1;
          if (!aIsDefault && bIsDefault) return 1;
        }
        
        return a.displayName.compareTo(b.displayName);
      });
    }
    
    return grouped;
  }

  /// 计算菜单高度
  static double _calculateMenuHeight(
    List<UnifiedAIModel> models,
    bool showSettingsButton,
    bool showAdjustAndGenerate,
    double maxHeight,
  ) {
    final grouped = _groupModelsByProvider(models);
    int totalItems = models.length;
    final bool hasPrivateModels = models.any((m) => !m.isPublic);
    final double addButtonHeight = showSettingsButton && !hasPrivateModels
        ? (_BottomActionDimensions.secondaryButtonHeight + 8.0)
        : 0.0;
    final double adjustButtonHeight = showSettingsButton && showAdjustAndGenerate
        ? _ContentDimensions.bottomButtonHeight
        : 0.0;
    final double contentHeight =
        (grouped.length * _ContentDimensions.groupHeaderHeight) +
            (totalItems * _ContentDimensions.modelItemHeight) +
            addButtonHeight +
            adjustButtonHeight +
            (_ContentDimensions.verticalPadding * 2);
    final double minHeight = showSettingsButton 
        ? _MenuDimensions.minHeightWithSettings 
        : _MenuDimensions.minHeightWithoutSettings;
    return contentHeight.clamp(minHeight, maxHeight);
  }

  static Widget _buildMenuContainer(
    BuildContext context,
    double menuHeight,
    List<UnifiedAIModel> models,
    UnifiedAIModel? selectedModel,
    Function(UnifiedAIModel?) onModelSelected,
    bool showSettingsButton,
    bool showAdjustAndGenerate,
    Novel? novel,
    List<NovelSettingItem> settings,
    List<SettingGroup> settingGroups,
    List<NovelSnippet> snippets,
    UniversalAIRequest? chatConfig,
    ValueChanged<UniversalAIRequest>? onConfigChanged,
    VoidCallback onClose,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: isDark ? _MenuStyling.elevationDark : _MenuStyling.elevationLight,
      borderRadius: BorderRadius.circular(_MenuStyling.menuBorderRadius),
      color: isDark 
          ? Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.95)
          : Theme.of(context).colorScheme.surfaceContainer,
      shadowColor: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
      child: Container(
        height: menuHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_MenuStyling.menuBorderRadius),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(isDark ? 0.2 : 0.3),
            width: _MenuStyling.menuBorderWidth,
          ),
        ),
        child: _UnifiedMenuContent(
          models: models,
          selectedModel: selectedModel,
          onModelSelected: onModelSelected,
          onClose: onClose,
          showSettingsButton: showSettingsButton,
          showAdjustAndGenerate: showAdjustAndGenerate,
          novel: novel,
          settings: settings,
          settingGroups: settingGroups,
          snippets: snippets,
          chatConfig: chatConfig,
          onConfigChanged: onConfigChanged,
        ),
      ),
    );
  }

  static Widget _buildPositionedMenu(
    BuildContext context,
    Rect anchorRect,
    double menuHeight,
    List<UnifiedAIModel> models,
    UnifiedAIModel? selectedModel,
    Function(UnifiedAIModel?) onModelSelected,
    bool showSettingsButton,
    bool showAdjustAndGenerate,
    Novel? novel,
    List<NovelSettingItem> settings,
    List<SettingGroup> settingGroups,
    List<NovelSnippet> snippets,
    UniversalAIRequest? chatConfig,
    ValueChanged<UniversalAIRequest>? onConfigChanged,
    VoidCallback onClose,
  ) {
    final screenSize = MediaQuery.of(context).size;
    double left = anchorRect.left;
    if (left + _MenuDimensions.menuWidth > screenSize.width - _MenuDimensions.horizontalMargin) {
      left = screenSize.width - _MenuDimensions.menuWidth - _MenuDimensions.horizontalMargin;
    }

    // 计算垂直放置位置，确保菜单完整显示在屏幕内
    double top = anchorRect.top - menuHeight - _MenuDimensions.anchorVerticalOffset; // 先尝试放在目标组件上方
    final double safeTop = MediaQuery.of(context).padding.top + 10;
    final double safeBottom = screenSize.height - 10;

    // 如果上方空间不足则放到下方
    if (top < safeTop) {
      top = anchorRect.bottom + _MenuDimensions.anchorVerticalOffset;
    }

    // 如果下方还是溢出，则将菜单整体上移
    if (top + menuHeight > safeBottom) {
      top = safeBottom - menuHeight;
      // 仍保证不碰到状态栏
      if (top < safeTop) {
        top = safeTop;
      }
    }

    return Positioned(
      left: left,
      top: top,
      width: _MenuDimensions.menuWidth,
      child: _buildMenuContainer(
        context, 
        menuHeight, 
        models, 
        selectedModel, 
        onModelSelected, 
        showSettingsButton,
        showAdjustAndGenerate, 
        novel, 
        settings, 
        settingGroups, 
        snippets, 
        chatConfig, 
        onConfigChanged, 
        onClose,
      ),
    );
  }
}

// ------------------ 内部菜单内容 ------------------
class _UnifiedMenuContent extends StatelessWidget {
  const _UnifiedMenuContent({
    Key? key,
    required this.models,
    required this.selectedModel,
    required this.onModelSelected,
    required this.onClose,
    required this.showSettingsButton,
    required this.showAdjustAndGenerate,
    this.novel,
    this.settings = const [],
    this.settingGroups = const [],
    this.snippets = const [],
    this.chatConfig,
    this.onConfigChanged,
  }) : super(key: key);

  final List<UnifiedAIModel> models;
  final UnifiedAIModel? selectedModel;
  final Function(UnifiedAIModel?) onModelSelected;
  final VoidCallback onClose;
  final bool showSettingsButton;
  final bool showAdjustAndGenerate;
  final Novel? novel;
  final List<NovelSettingItem> settings;
  final List<SettingGroup> settingGroups;
  final List<NovelSnippet> snippets;
  final UniversalAIRequest? chatConfig;
  final ValueChanged<UniversalAIRequest>? onConfigChanged;

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return _buildEmpty(context);
    }
    
    final grouped = UnifiedAIModelDropdown._groupModelsByProvider(models);
    final providers = grouped.keys.toList();
    
    // 供应商排序：有系统模型的供应商优先
    providers.sort((a, b) {
      final aHasPublic = grouped[a]!.any((m) => m.isPublic);
      final bHasPublic = grouped[b]!.any((m) => m.isPublic);
      if (aHasPublic && !bHasPublic) return -1;
      if (!aHasPublic && bHasPublic) return 1;
      return a.compareTo(b);
    });

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: _ContentDimensions.horizontalPadding, 
              vertical: _ContentDimensions.verticalPadding
            ),
            itemCount: providers.length,
            separatorBuilder: (c, i) => Divider(
              height: _MenuStyling.dividerHeight,
              thickness: _MenuStyling.dividerThickness,
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withOpacity(0.12),
              indent: _MenuStyling.dividerIndent,
              endIndent: _MenuStyling.dividerEndIndent,
            ),
            itemBuilder: (c, index) {
              final provider = providers[index];
              final providerModels = grouped[provider]!;
              return _ProviderGroup(
                provider: provider,
                models: providerModels,
                selectedModel: selectedModel,
                onModelSelected: (m) {
                  onModelSelected(m);
                  onClose();
                },
              );
            },
          ),
        ),
        if (showSettingsButton) _buildBottomActions(context),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_EmptyStateDimensions.emptyPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.model_training_outlined,
                size: _EmptyStateDimensions.emptyIconSize, color: cs.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: _EmptyStateDimensions.emptyIconTextSpacing),
            Text('无可用模型',
                style: Theme.of(context)
                    .textTheme
                                          .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: _EmptyStateDimensions.emptyTitleSubtitleSpacing),
            Text('请先配置AI模型或等待公共模型加载',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(_BottomActionDimensions.bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? cs.surface.withOpacity(0.8) : cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withOpacity(isDark ? 0.15 : 0.2),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!models.any((m) => !m.isPublic)) ...[
            OutlinedButton.icon(
              onPressed: () {
                onClose();
                // 优先尝试编辑器内打开
                try {
                  final layoutManager = Provider.of<EditorLayoutManager>(context, listen: false);
                  layoutManager.toggleSettingsPanel();
                  return;
                } catch (_) {}
                // 回退：列表页等环境直接弹出设置对话框
                final userId = AppConfig.userId;
                if (userId == null || userId.isEmpty) {
                  TopToast.info(context, '请先登录后再添加私人模型');
                  return;
                }
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (dialogContext) {
                    return MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: dialogContext.read<AiConfigBloc>()),
                      ],
                      child: Dialog(
                        insetPadding: const EdgeInsets.all(16),
                        backgroundColor: Colors.transparent,
                        child: SettingsPanel(
                          stateManager: EditorStateManager(),
                          userId: userId,
                          onClose: () => Navigator.of(dialogContext).pop(),
                        ),
                      ),
                    );
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('添加我的私人模型'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                foregroundColor: isDark ? cs.primary.withOpacity(0.9) : cs.primary,
                side: BorderSide(color: cs.primary.withOpacity(isDark ? 0.2 : 0.3), width: _BottomActionDimensions.buttonBorderWidth),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_BottomActionDimensions.buttonBorderRadius)),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (showAdjustAndGenerate)
            SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                onClose(); // 先关闭 Overlay
                // 只有选中私有模型时才能进入设置对话框
                UserAIModelConfigModel? userModel;
                if (selectedModel != null && !selectedModel!.isPublic) {
                  userModel = (selectedModel as PrivateAIModel).userConfig;
                }
                showChatSettingsDialog(
                  context,
                  selectedModel: userModel,
                  onModelChanged: (m) {
                    if (m != null) {
                      onModelSelected(PrivateAIModel(m));
                    }
                  },
                  novel: novel,
                  settings: settings,
                  settingGroups: settingGroups,
                  snippets: snippets,
                  initialChatConfig: chatConfig,
                  onConfigChanged: onConfigChanged,
                  initialContextSelections: null, // 🚀 让ChatSettingsDialog自己构建上下文数据
                );
              },
              icon: const Icon(Icons.tune_rounded, size: _BottomActionDimensions.buttonIconSize),
              label: const Text('调整并生成'),
              style: ElevatedButton.styleFrom(
                foregroundColor: isDark ? cs.primary.withOpacity(0.9) : cs.primary,
                backgroundColor: isDark ? cs.primaryContainer.withOpacity(0.08) : cs.primaryContainer.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: _BottomActionDimensions.buttonVerticalPadding),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_BottomActionDimensions.buttonBorderRadius)),
                elevation: 0,
                side: BorderSide(color: cs.primary.withOpacity(isDark ? 0.2 : 0.3), width: _BottomActionDimensions.buttonBorderWidth),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 供应商分组组件
class _ProviderGroup extends StatelessWidget {
  const _ProviderGroup({
    Key? key,
    required this.provider,
    required this.models,
    required this.selectedModel,
    required this.onModelSelected,
  }) : super(key: key);

  final String provider;
  final List<UnifiedAIModel> models;
  final UnifiedAIModel? selectedModel;
  final Function(UnifiedAIModel?) onModelSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 检查是否有系统模型
    final hasPublicModels = models.any((m) => m.isPublic);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Row(
            children: [
              Icon(
                hasPublicModels ? Icons.public : Icons.person_outline,
                size: 16,
                color: isDark ? cs.primary.withOpacity(0.8) : cs.primary,
              ),
              const SizedBox(width: 6),
              Text(
                provider.toUpperCase(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isDark ? cs.primary.withOpacity(0.9) : cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${models.length}个',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ...models.map((m) => _UnifiedModelItem(
              model: m,
              isSelected: selectedModel?.id == m.id,
              onTap: () => onModelSelected(m),
            )),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _UnifiedModelItem extends StatelessWidget {
  const _UnifiedModelItem({
    Key? key,
    required this.model,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  final UnifiedAIModel model;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_ModelItemDimensions.itemBorderRadius),
      splashColor: cs.primary.withOpacity(0.08),
      highlightColor: cs.primary.withOpacity(0.04),
              child: Container(
          margin: const EdgeInsets.symmetric(horizontal: _ModelItemDimensions.itemMargin, vertical: 1.0),
          padding: const EdgeInsets.symmetric(
            horizontal: _ModelItemDimensions.itemHorizontalPadding, 
            vertical: _ModelItemDimensions.itemVerticalPadding
          ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? cs.primaryContainer.withOpacity(0.2)
                  : cs.primaryContainer.withOpacity(0.15))
              : null,
          borderRadius: BorderRadius.circular(_ModelItemDimensions.itemBorderRadius),
          border: isSelected
              ? Border.all(color: cs.primary.withOpacity(0.2), width: 1.0)
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(2),
              child: _getModelIcon(model.provider, context),
            ),
            const SizedBox(width: _ModelItemDimensions.iconTextSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? cs.primary
                          : (isDark
                              ? cs.onSurface.withOpacity(0.9)
                              : cs.onSurface),
                      fontSize: 13,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 显示所有标签
                  if (model.modelTags.isNotEmpty) ...[
                    const SizedBox(height: _TagDimensions.tagTopSpacing),
                    Wrap(
                      spacing: _TagDimensions.tagSpacing,
                      runSpacing: _TagDimensions.tagRunSpacing,
                      children: model.modelTags.map((tag) => _buildTag(tag, context)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: _ModelItemDimensions.selectedIconSize, color: cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String tag, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color tagColor;
    Color backgroundColor;
    Color borderColor;
    
    if (tag == '私有') {
      tagColor = Colors.blue;
      backgroundColor = isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.withOpacity(0.1);
      borderColor = Colors.blue.withOpacity(isDark ? 0.3 : 0.2);
    } else if (tag == '系统') {
      tagColor = Colors.green;
      backgroundColor = isDark ? Colors.green.withOpacity(0.15) : Colors.green.withOpacity(0.1);
      borderColor = Colors.green.withOpacity(isDark ? 0.3 : 0.2);
    } else if (tag == '推荐') {
      tagColor = Colors.orange;
      backgroundColor = isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.withOpacity(0.1);
      borderColor = Colors.orange.withOpacity(isDark ? 0.3 : 0.2);
    } else if (tag == '免费') {
      tagColor = Colors.purple;
      backgroundColor = isDark ? Colors.purple.withOpacity(0.15) : Colors.purple.withOpacity(0.1);
      borderColor = Colors.purple.withOpacity(isDark ? 0.3 : 0.2);
    } else if (tag.contains('积分')) {
      tagColor = Colors.red;
      backgroundColor = isDark ? Colors.red.withOpacity(0.15) : Colors.red.withOpacity(0.1);
      borderColor = Colors.red.withOpacity(isDark ? 0.3 : 0.2);
    } else {
      tagColor = cs.outline;
      backgroundColor = isDark ? cs.surfaceVariant.withOpacity(0.3) : cs.surfaceVariant.withOpacity(0.5);
      borderColor = cs.outline.withOpacity(isDark ? 0.3 : 0.2);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _TagDimensions.tagHorizontalPadding, 
        vertical: _TagDimensions.tagVerticalPadding
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_TagDimensions.tagBorderRadius),
        border: Border.all(
          color: borderColor,
          width: _TagDimensions.tagBorderWidth,
        ),
      ),
      child: Text(
        tag,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: tagColor.withOpacity(isDark ? 0.9 : 0.8),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _getModelIcon(String provider, BuildContext context) {
    final color = ProviderIcons.getProviderColor(provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: _ModelItemDimensions.iconContainerSize,
      height: _ModelItemDimensions.iconContainerSize,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.9) : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.25),
          width: 0.5,
        ),
      ),
              child: Padding(
          padding: const EdgeInsets.all(2),
          child: ProviderIcons.getProviderIcon(provider, size: _ModelItemDimensions.iconSize, useHighQuality: true),
        ),
    );
  }
} 