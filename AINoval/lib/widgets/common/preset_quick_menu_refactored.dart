import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/models/preset_models.dart';
import 'package:ainoval/models/ai_request_models.dart';
import 'package:ainoval/models/user_ai_model_config_model.dart';
import 'package:ainoval/models/novel_structure.dart';
import 'package:ainoval/models/novel_setting_item.dart';
import 'package:ainoval/models/setting_group.dart';
import 'package:ainoval/models/novel_snippet.dart';
import 'package:ainoval/blocs/preset/preset_bloc.dart';
import 'package:ainoval/blocs/preset/preset_state.dart';
import 'package:ainoval/blocs/ai_config/ai_config_bloc.dart';
import 'package:ainoval/blocs/public_models/public_models_bloc.dart';
import 'package:ainoval/blocs/universal_ai/universal_ai_bloc.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:ainoval/config/provider_icons.dart';
import 'package:ainoval/config/app_config.dart';
import 'package:ainoval/models/unified_ai_model.dart';

import 'package:ainoval/models/context_selection_models.dart';
import 'package:ainoval/screens/editor/components/ai_dialog_common_logic.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

/// 基于MenuAnchor的预设快捷菜单组件（重构版本）
/// 使用Flutter官方推荐的MenuAnchor组件实现级联菜单功能
class PresetQuickMenuRefactored extends StatefulWidget {
  const PresetQuickMenuRefactored({
    super.key,
    required this.requestType,
    required this.selectedText,
    this.defaultModel,
    required this.onPresetSelected,
    required this.onAdjustAndGenerate,
    this.onPresetWithModelSelected,
    this.onStreamingGenerate,
    this.onMenuClosed,
    this.novel,
    this.settings = const [],
    this.settingGroups = const [],
    this.snippets = const [],
  });

  final AIRequestType requestType;
  final String selectedText;
  final UserAIModelConfigModel? defaultModel;
  final Function(AIPromptPreset preset) onPresetSelected;
  final Function() onAdjustAndGenerate;
  final Function(AIPromptPreset preset, UnifiedAIModel model)? onPresetWithModelSelected;
  final Function(UniversalAIRequest, UnifiedAIModel)? onStreamingGenerate;
  final VoidCallback? onMenuClosed;
  final Novel? novel;
  final List<NovelSettingItem> settings;
  final List<SettingGroup> settingGroups;
  final List<NovelSnippet> snippets;

  @override
  State<PresetQuickMenuRefactored> createState() => _PresetQuickMenuRefactoredState();
}

class _PresetQuickMenuRefactoredState extends State<PresetQuickMenuRefactored> with AIDialogCommonLogic {
  static const String _tag = 'PresetQuickMenuRefactored';
  final MenuController _menuController = MenuController();
  
  // 级联菜单管理
  OverlayEntry? _cascadeMenuOverlay;
  AIPromptPreset? _currentHoveredPreset;
  bool _isHoveringCascadeMenu = false;
  Timer? _cascadeHideTimer;
  Timer? _cascadeShowTimer;
  double _cascadeMenuMaxHeight = 300.0;
  
  // 🚀 移除缓存机制 - 缓存会导致数据更新后仍显示旧数据
  // 预设分类计算成本不高，但数据一致性更重要

  @override
  void dispose() {
    _removeCascadeMenu();
    super.dispose();
  }

  /// 移除级联菜单
  void _removeCascadeMenu() {
    _cascadeHideTimer?.cancel();
    _cascadeHideTimer = null;
    _cascadeShowTimer?.cancel();
    _cascadeShowTimer = null;
    _cascadeMenuOverlay?.remove();
    _cascadeMenuOverlay = null;
    _currentHoveredPreset = null;
    _isHoveringCascadeMenu = false;
  }

  /// 延迟移除级联菜单（允许鼠标移到级联菜单上）
  void _scheduleCascadeMenuRemoval() {
    _cascadeHideTimer?.cancel();
    _cascadeHideTimer = Timer(const Duration(milliseconds: 420), () {
      if (mounted && !_isHoveringCascadeMenu) {
        _removeCascadeMenu();
      }
    });
  }

  /// 请求显示级联菜单（防抖，避免闪烁）
  void _requestShowCascadeMenu(BuildContext context, AIPromptPreset preset, GlobalKey presetKey) {
    // 若已显示相同预设的子菜单，只需取消隐藏定时器
    if (_currentHoveredPreset == preset && _cascadeMenuOverlay != null) {
      _cascadeHideTimer?.cancel();
      return;
    }
    _cascadeShowTimer?.cancel();
    _cascadeHideTimer?.cancel();
    _cascadeShowTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _showCascadeMenu(context, preset, presetKey);
    });
  }

  /// 显示级联菜单
  void _showCascadeMenu(BuildContext context, AIPromptPreset preset, GlobalKey presetKey) {
    // 如果是同一个预设，不重复显示
    if (_currentHoveredPreset == preset) return;
    
    // 移除现有的级联菜单
    _removeCascadeMenu();
    _currentHoveredPreset = preset;

    // 获取预设项的位置
    final RenderBox? presetBox = presetKey.currentContext?.findRenderObject() as RenderBox?;
    if (presetBox == null) return;

    final presetPosition = presetBox.localToGlobal(Offset.zero);
    final presetSize = presetBox.size;

    // 计算屏幕可用高度，尽可能显示更多内容
    final double screenHeight = MediaQuery.of(context).size.height;
    final double overlayTop = (presetPosition.dy - 4).clamp(8.0, screenHeight - 100.0);
    final double availableBelow = (screenHeight - overlayTop - 8).clamp(100.0, screenHeight);
    _cascadeMenuMaxHeight = availableBelow;

    // 创建级联菜单
    _cascadeMenuOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: presetPosition.dx + presetSize.width + 8, // 在预设项右侧
        top: overlayTop, // 稍微向上对齐，并根据屏幕高度约束
        child: MouseRegion(
          onEnter: (_) {
            // 鼠标进入级联菜单，保持显示
            _isHoveringCascadeMenu = true;
            _cascadeHideTimer?.cancel();
          },
          onExit: (_) {
            // 鼠标离开级联菜单，延迟移除
            _isHoveringCascadeMenu = false;
            _scheduleCascadeMenuRemoval();
          },
          child: _buildCascadeModelMenu(context, preset),
        ),
      ),
    );

    Overlay.of(context).insert(_cascadeMenuOverlay!);
  }

  /// 构建级联模型菜单
  Widget _buildCascadeModelMenu(BuildContext context, AIPromptPreset preset) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 阻止所有滚动通知传播
        return true;
      },
      child: Listener(
        // 阻止滚动事件传播到父组件
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            // 完全阻止滚动事件传播到父组件
            return;
          }
        },
        child: Material(
          elevation: isDark ? 16.0 : 12.0,
          shadowColor: Colors.black.withOpacity(isDark ? 0.4 : 0.2),
          borderRadius: BorderRadius.circular(8),
          color: isDark ? cs.surface.withOpacity(0.98) : cs.surface,
          child: Container(
          width: 220,
          constraints: BoxConstraints(
            maxHeight: _cascadeMenuMaxHeight,
            minHeight: 100,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(isDark ? 0.3 : 0.4),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.memory, size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '选择模型',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 模型列表
              Flexible(
                child: BlocBuilder<AiConfigBloc, AiConfigState>(
                  builder: (context, state) {
                    return _buildCascadeModelList(context, preset, state);
                  },
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  /// 构建级联模型列表
  Widget _buildCascadeModelList(BuildContext context, AIPromptPreset preset, AiConfigState state) {
    return BlocBuilder<PublicModelsBloc, PublicModelsState>(
      builder: (context, publicState) {
        final allModels = _combineModels(state, publicState);
        
        if (allModels.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text('无可用模型')),
          );
        }

        // 按提供商分组模型
        final grouped = _groupUnifiedModelsByProvider(allModels);
        final providers = grouped.keys.toList();
        
        // 供应商排序：有系统模型的供应商优先
        providers.sort((a, b) {
          final aHasPublic = grouped[a]!.any((m) => m.isPublic);
          final bHasPublic = grouped[b]!.any((m) => m.isPublic);
          if (aHasPublic && !bHasPublic) return -1;
          if (!aHasPublic && bHasPublic) return 1;
          return a.compareTo(b);
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          shrinkWrap: true,
          itemCount: providers.length,
          itemBuilder: (context, providerIndex) {
            final provider = providers[providerIndex];
            final models = grouped[provider]!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 提供商标题
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      _getProviderIcon(context, provider),
                      const SizedBox(width: 6),
                      Text(
                        provider.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // 该提供商下的模型
                ...models.map((model) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        _removeCascadeMenu();
                        // 也关闭主菜单
                        widget.onMenuClosed?.call();
                        _handleModelSelected(preset, model);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            _getModelIcon(context, model.provider),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                model.displayName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ..._buildModelTags(context, model),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                if (providerIndex < providers.length - 1)
                  const Divider(height: 4, thickness: 0.3),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 确保有UniversalAIBloc可用于积分预估
    return BlocProvider<UniversalAIBloc>.value(
      value: context.read<UniversalAIBloc>(),
      child: _buildDirectMenu(context),
    );
  }

  /// 直接构建菜单，不使用MenuAnchor避免ParentDataWidget冲突
  Widget _buildDirectMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 阻止所有滚动通知传播
        return true;
      },
      child: Listener(
        // 阻止滚动事件传播到父组件
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            // 完全阻止滚动事件传播到父组件
            return;
          }
        },
        child: Material(
          elevation: isDark ? 16.0 : 12.0,
          shadowColor: Colors.black.withOpacity(isDark ? 0.4 : 0.2),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? cs.surface.withOpacity(0.98) : cs.surface,
          child: Container(
          width: 260,
          constraints: const BoxConstraints(
            maxHeight: 600,
            minHeight: 180,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(isDark ? 0.3 : 0.4),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 预设列表
              Flexible(
                child: BlocBuilder<PresetBloc, PresetState>(
                  builder: (context, state) {
                    return _buildPresetList(context, state);
                  },
                ),
              ),
              // 底部按钮（始终可见）
              _buildBottomSection(context),
            ],
          ),
        ),
        ),
      ),
    );
  }

  /// 构建菜单标题 - 已移除
  Widget _buildMenuHeader(BuildContext context) {
    // 移除预设头，直接返回空容器
    return const SizedBox.shrink();
  }

  /// 构建预设列表
  Widget _buildPresetList(BuildContext context, PresetState state) {
    if (state.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.errorMessage != null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            '加载失败: ${state.errorMessage}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    // 按优先级分类预设
    final categorizedPresets = _categorizePresets(state, widget.requestType.value);
    
    if (categorizedPresets.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('暂无可用预设')),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 480),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        shrinkWrap: true,
        children: _buildPresetItems(context, categorizedPresets),
      ),
    );
  }

  /// 构建预设项列表
  List<Widget> _buildPresetItems(BuildContext context, Map<String, List<AIPromptPreset>> categorizedPresets) {
    final List<Widget> items = [];
    final categoryOrder = ['quick', 'system', 'public', 'user'];
    final categoryLabels = {
      'quick': '快捷预设',
      'system': '系统预设', 
      'public': '公共预设',
      'user': '用户预设',
    };

    bool needsDivider = false;

    for (final category in categoryOrder) {
      if (categorizedPresets.containsKey(category)) {
        final presets = categorizedPresets[category]!;
        
        // 添加分隔线（除了第一个分类）
        if (needsDivider) {
          items.add(const Divider(height: 1, thickness: 0.3, indent: 12, endIndent: 12));
        }
        
        // 添加分类标题（如果有多个分类）
        if (categorizedPresets.length > 1) {
          items.add(_buildCategoryHeader(context, categoryLabels[category]!));
        }
        
        // 添加该分类下的预设项
        for (final preset in presets) {
          final isQuickAccess = category == 'quick';
          items.add(_buildPresetItem(context, preset, isQuickAccess));
        }
        
        needsDivider = true;
      }
    }

    return items;
  }

  /// 构建分类标题
  Widget _buildCategoryHeader(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// 构建预设项 - 优化布局，移除图标，减少高度
  Widget _buildPresetItem(BuildContext context, AIPromptPreset preset, bool isQuickAccess) {
    final cs = Theme.of(context).colorScheme;
    final GlobalKey presetKey = GlobalKey();
    
    return Container(
      key: presetKey,
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.transparent,
        child: MouseRegion(
          onEnter: (_) {
            if (widget.onPresetWithModelSelected != null) {
              _requestShowCascadeMenu(context, preset, presetKey);
            }
          },
          onExit: (_) {
            if (widget.onPresetWithModelSelected != null) {
              _scheduleCascadeMenuRemoval();
            }
          },
          child: InkWell(
            onTap: () {
              if (widget.onPresetWithModelSelected != null) {
                _showModelSelectionDialog(context, preset);
              } else {
                widget.onPresetSelected(preset);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // 预设信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.displayName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (preset.presetDescription != null && preset.presetDescription!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            preset.presetDescription!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.3,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // 指示器
                  if (widget.onPresetWithModelSelected != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_right,
                      size: 16,
                      color: cs.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 显示模型选择对话框
  void _showModelSelectionDialog(BuildContext context, AIPromptPreset preset) {
    final cs = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<AiConfigBloc, AiConfigState>(
          builder: (context, aiState) {
            return BlocBuilder<PublicModelsBloc, PublicModelsState>(
              builder: (context, publicState) {
                final allModels = _combineModels(aiState, publicState);
                
                if (allModels.isEmpty) {
                  return AlertDialog(
                    title: const Text('无可用模型'),
                    content: const Text('请先配置AI模型后再使用预设功能'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('确定'),
                      ),
                    ],
                  );
                }

                // 按提供商分组模型
                final grouped = _groupUnifiedModelsByProvider(allModels);
                final providers = grouped.keys.toList();
                
                // 供应商排序：有系统模型的供应商优先
                providers.sort((a, b) {
                  final aHasPublic = grouped[a]!.any((m) => m.isPublic);
                  final bHasPublic = grouped[b]!.any((m) => m.isPublic);
                  if (aHasPublic && !bHasPublic) return -1;
                  if (!aHasPublic && bHasPublic) return 1;
                  return a.compareTo(b);
                });

            return AlertDialog(
              title: Text('选择模型 - ${preset.displayName}'),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              content: SizedBox(
                width: 320,
                height: 400,
                child: ListView.builder(
                  itemCount: providers.length,
                  itemBuilder: (context, providerIndex) {
                    final provider = providers[providerIndex];
                    final models = grouped[provider]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 提供商标题
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              _getProviderIcon(context, provider),
                              const SizedBox(width: 8),
                              Text(
                                provider.toUpperCase(),
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 该提供商下的模型
                        ...models.map((model) {
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                            leading: _getModelIcon(context, model.provider),
                            title: Text(
                              model.displayName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: _buildModelSubtitle(context, model),
                            onTap: () async {
                              Navigator.of(context).pop();
                              _handleModelSelected(preset, model);
                            },
                          );
                        }).toList(),
                        if (providerIndex < providers.length - 1)
                          const Divider(height: 8, thickness: 0.5),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ],
            );
              },
            );
          },
        );
      },
    );
  }

  /// 按提供商分组模型
  static Map<String, List<UserAIModelConfigModel>> _groupModelsByProvider(
      List<UserAIModelConfigModel> configs) {
    final Map<String, List<UserAIModelConfigModel>> grouped = {};
    for (var c in configs) {
      grouped.putIfAbsent(c.provider, () => []);
      grouped[c.provider]!.add(c);
    }
    for (var list in grouped.values) {
      list.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.name.compareTo(b.name);
      });
    }
    return grouped;
  }

  /// 获取提供商图标
  Widget _getProviderIcon(BuildContext context, String provider) {
    try {
      final color = ProviderIcons.getProviderColor(provider);
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.9) : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.25),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: ProviderIcons.getProviderIcon(provider, size: 10, useHighQuality: true),
        ),
      );
    } catch (e) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Icon(
          Icons.memory,
          size: 10,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  /// 获取模型图标
  Widget _getModelIcon(BuildContext context, String provider) {
    try {
      final color = ProviderIcons.getProviderColor(provider);
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(
          Icons.memory,
          size: 8,
          color: color,
        ),
      );
    } catch (e) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(
          Icons.memory,
          size: 8,
          color: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }

  /// 构建底部操作区域
  Widget _buildBottomSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 32,
        child: ElevatedButton.icon(
          onPressed: widget.onAdjustAndGenerate,
          icon: Icon(Icons.tune_rounded, size: 14, color: cs.primary),
          label: Text(
            '调整并生成',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: cs.primary,
              fontSize: 13,
            ),
          ),
          style: ElevatedButton.styleFrom(
            foregroundColor: cs.primary,
            backgroundColor: cs.primaryContainer.withOpacity(0.12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: cs.primary.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }


  /// 按优先级分类预设（移除缓存机制确保数据一致性）
  Map<String, List<AIPromptPreset>> _categorizePresets(PresetState state, String featureType) {
    // 🚀 移除缓存逻辑，确保每次都获取最新数据
    final Map<String, List<AIPromptPreset>> categorized = {
      'quick': [], // 用户快捷预设
      'system': [], // 系统预设
      'public': [], // 公共预设
      'user': [], // 其他用户预设
    };
    final Set<String> seenIds = {};

    // 1. 优先处理快捷访问预设
    for (final preset in state.quickAccessPresets) {
      if (preset.aiFeatureType == featureType && !seenIds.contains(preset.presetId)) {
        categorized['quick']!.add(preset);
        seenIds.add(preset.presetId);
      }
    }

    // 2. 处理分组预设中的预设（优先 groupedPresets，保证最新状态）
    final currentGroupedPresets = state.groupedPresets[featureType] ?? [];
    for (final preset in currentGroupedPresets) {
      if (!seenIds.contains(preset.presetId)) {
        if (preset.isSystem) {
          categorized['system']!.add(preset);
        } else {
          categorized['user']!.add(preset);
        }
        seenIds.add(preset.presetId);
      }
    }

    // 3. 处理聚合数据中的预设
    if (state.allPresetData != null) {
      final allData = state.allPresetData!;
      
      // 系统预设
      for (final preset in allData.systemPresets) {
        if (preset.aiFeatureType == featureType && !seenIds.contains(preset.presetId)) {
          categorized['system']!.add(preset);
          seenIds.add(preset.presetId);
        }
      }
      
      // 公共预设（这里假设有公共预设字段，如果没有可以忽略）
      // 由于代码中没有明确的公共预设字段，暂时跳过
      
      // 用户预设
      final userPresets = allData.userPresetsByFeatureType[featureType] ?? [];
      for (final preset in userPresets) {
        if (!seenIds.contains(preset.presetId)) {
          categorized['user']!.add(preset);
          seenIds.add(preset.presetId);
        }
      }
    }

    // 3. 处理分组预设中的剩余预设
    for (final preset in currentGroupedPresets) {
      if (!seenIds.contains(preset.presetId)) {
        // 根据isSystem字段判断分类
        if (preset.isSystem) {
          categorized['system']!.add(preset);
        } else {
          categorized['user']!.add(preset);
        }
        seenIds.add(preset.presetId);
      }
    }

    // 移除空分类
    categorized.removeWhere((key, value) => value.isEmpty);
    
    // 🚀 移除缓存存储，确保数据一致性
    // AppLogger.d(_tag, '预设分类结果: 功能类型=$featureType, 分类=${categorized.keys.join(", ")}');
    return categorized;
  }



  /// 合并私有模型和公共模型
  List<UnifiedAIModel> _combineModels(AiConfigState aiState, PublicModelsState publicState) {
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

  /// 按提供商分组统一模型
  Map<String, List<UnifiedAIModel>> _groupUnifiedModelsByProvider(List<UnifiedAIModel> models) {
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
        
        // 最后按名称排序
        return a.displayName.compareTo(b.displayName);
      });
    }
    
    return grouped;
  }

  /// 处理模型选择 - 支持公共模型和私有模型
  void _handleModelSelected(AIPromptPreset preset, UnifiedAIModel model) async {
    try {
      AppLogger.i(_tag, '选择模型: ${model.displayName} (公共: ${model.isPublic})');
      
      // 🚀 对于公共模型，先进行积分预估和确认
      if (model.isPublic) {
        AppLogger.i(_tag, '检测到公共模型，启动积分预估确认流程: ${model.displayName}');
        
        // 构建用于积分预估的请求对象
        final estimationRequest = _buildEstimationRequest(preset, model);
        
        bool shouldProceed = await handlePublicModelCreditConfirmation(model, estimationRequest);
        
        if (!shouldProceed) {
          AppLogger.i(_tag, '用户取消了积分预估确认，停止操作');
          return; // 用户取消或积分不足，停止执行
        }
        AppLogger.i(_tag, '用户确认了积分预估，继续操作');
      } else {
        AppLogger.i(_tag, '检测到私有模型，直接操作: ${model.displayName}');
      }
      
      // 🚀 先缓存回调，避免异步期间组件被卸载导致无法调用
      final streamingGenerate = widget.onStreamingGenerate;
      final presetWithModel = widget.onPresetWithModelSelected;
      
      // 🚀 优先启动流式生成（如果回调可用）
      if (streamingGenerate != null) {
        _startStreamingGeneration(preset, model, callback: streamingGenerate);
      } else {
        // 回退到传统回调
        presetWithModel?.call(preset, model);
      }
      
      AppLogger.i(_tag, '模型选择完成: 预设=${preset.presetName}, 模型=${model.displayName}');
    } catch (e) {
      AppLogger.e(_tag, '处理模型选择失败', e);
      if (mounted) {
        TopToast.error(context, '模型选择失败: $e');
      }
    }
  }
  
  /// 构建用于积分预估的请求对象
  UniversalAIRequest _buildEstimationRequest(AIPromptPreset preset, UnifiedAIModel model) {
    // 🚀 使用公共逻辑创建模型配置
    final modelConfig = createModelConfig(model);
    
    // 🚀 从预设中解析参数和上下文选择（用于积分预估）
    final parsedRequest = preset.parsedRequest;
    double temperature = 0.7;
    double topP = 0.9;
    int maxTokens = 4000;
    bool enableSmartContext = false;
    String? promptTemplateId;
    ContextSelectionData contextSelectionData;
    
    if (parsedRequest != null) {
      // 从预设中读取参数
      final presetTemperature = parsedRequest.parameters['temperature'];
      if (presetTemperature is double) {
        temperature = presetTemperature;
      } else if (presetTemperature is num) {
        temperature = presetTemperature.toDouble();
      }
      
      final presetTopP = parsedRequest.parameters['topP']; 
      if (presetTopP is double) {
        topP = presetTopP;
      } else if (presetTopP is num) {
        topP = presetTopP.toDouble();
      }
      
      final presetMaxTokens = parsedRequest.parameters['maxTokens'];
      if (presetMaxTokens is int) {
        maxTokens = presetMaxTokens;
      } else if (presetMaxTokens is num) {
        maxTokens = presetMaxTokens.toInt();
      }
      
      enableSmartContext = parsedRequest.enableSmartContext;
      
      // 🚀 从预设中读取提示词模板ID（用于积分预估）
      final presetTemplateId = parsedRequest.parameters['promptTemplateId'] ?? 
                              parsedRequest.parameters['associatedTemplateId'];
      if (presetTemplateId is String && presetTemplateId.isNotEmpty) {
        promptTemplateId = presetTemplateId;
        AppLogger.i(_tag, '🔧 积分预估 - 从预设中读取提示词模板ID: $promptTemplateId');
      }
      
      // 🚀 从预设中读取上下文选择数据（用于积分预估）
      if (parsedRequest.contextSelections != null) {
        contextSelectionData = parsedRequest.contextSelections!;
        AppLogger.i(_tag, '🔧 积分预估 - 从预设中读取上下文选择: ${contextSelectionData.selectedCount}个项目');
      } else {
        // 创建空的上下文选择数据
        contextSelectionData = ContextSelectionData(
          novelId: widget.novel?.id ?? 'unknown',
          availableItems: [],
          flatItems: {},
        );
        AppLogger.i(_tag, '🔧 积分预估 - 预设中没有上下文选择，使用空数据');
      }
      
      AppLogger.i(_tag, '🔧 积分预估 - 从预设中读取参数: temperature=$temperature, topP=$topP, maxTokens=$maxTokens, enableSmartContext=$enableSmartContext');
    } else {
      AppLogger.w(_tag, '⚠️ 积分预估 - 无法解析预设参数，使用默认值');
      // 创建空的上下文选择数据
      contextSelectionData = ContextSelectionData(
        novelId: widget.novel?.id ?? 'unknown',
        availableItems: [],
        flatItems: {},
      );
    }

    // 🚀 使用公共逻辑创建元数据
    final metadata = createModelMetadata(model, {
      'action': widget.requestType.name,
      'source': 'preset_quick_menu',
      'presetId': preset.presetId,
      'presetName': preset.presetName,
      'originalLength': widget.selectedText.length,
      'contextCount': contextSelectionData.selectedCount, // 🚀 使用实际的上下文数量
      'enableSmartContext': enableSmartContext,
    });

    return UniversalAIRequest(
      requestType: widget.requestType,
      userId: AppConfig.userId ?? 'unknown',
      novelId: widget.novel?.id,
      modelConfig: modelConfig,
      selectedText: widget.selectedText,
      instructions: preset.effectiveUserPrompt, // 使用预设的提示词
              contextSelections: contextSelectionData,
      enableSmartContext: enableSmartContext, // 🚀 从预设中读取
      parameters: {
        'temperature': temperature, // 🚀 从预设中读取
        'topP': topP, // 🚀 从预设中读取
        'maxTokens': maxTokens, // 🚀 从预设中读取
        'modelName': model.modelId,
        'presetId': preset.presetId,
        'presetName': preset.presetName,
        'enableSmartContext': enableSmartContext, // 🚀 从预设中读取
        if (promptTemplateId != null) 'promptTemplateId': promptTemplateId, // 🚀 从预设中读取模板ID
      },
      metadata: metadata,
    );
  }

  /// 🚀 启动流式生成（参考 refactor_dialog.dart 的实现）
  void _startStreamingGeneration(AIPromptPreset preset, UnifiedAIModel model, {required Function(UniversalAIRequest, UnifiedAIModel) callback}) {
    try {
      // 🚀 使用公共逻辑创建模型配置
      final modelConfig = createModelConfig(model);
      
      // 🚀 从预设中解析参数和上下文选择
      final parsedRequest = preset.parsedRequest;
      double temperature = 0.7;
      double topP = 0.9;
      int maxTokens = 4000;
      bool enableSmartContext = false;
      String? promptTemplateId;
      ContextSelectionData contextSelectionData;
      
      if (parsedRequest != null) {
        // 从预设中读取参数
        final presetTemperature = parsedRequest.parameters['temperature'];
        if (presetTemperature is double) {
          temperature = presetTemperature;
        } else if (presetTemperature is num) {
          temperature = presetTemperature.toDouble();
        }
        
        final presetTopP = parsedRequest.parameters['topP']; 
        if (presetTopP is double) {
          topP = presetTopP;
        } else if (presetTopP is num) {
          topP = presetTopP.toDouble();
        }
        
        final presetMaxTokens = parsedRequest.parameters['maxTokens'];
        if (presetMaxTokens is int) {
          maxTokens = presetMaxTokens;
        } else if (presetMaxTokens is num) {
          maxTokens = presetMaxTokens.toInt();
        }
        
        enableSmartContext = parsedRequest.enableSmartContext;
        
        // 🚀 从预设中读取提示词模板ID
        final presetTemplateId = parsedRequest.parameters['promptTemplateId'] ?? 
                                parsedRequest.parameters['associatedTemplateId'];
        if (presetTemplateId is String && presetTemplateId.isNotEmpty) {
          promptTemplateId = presetTemplateId;
          AppLogger.i(_tag, '🔧 从预设中读取提示词模板ID: $promptTemplateId');
        }
        
        // 🚀 从预设中读取上下文选择数据
        if (parsedRequest.contextSelections != null) {
          contextSelectionData = parsedRequest.contextSelections!;
          AppLogger.i(_tag, '🔧 从预设中读取上下文选择: ${contextSelectionData.selectedCount}个项目');
        } else {
          // 创建空的上下文选择数据
          contextSelectionData = ContextSelectionData(
            novelId: widget.novel?.id ?? 'unknown',
            availableItems: [],
            flatItems: {},
          );
          AppLogger.i(_tag, '🔧 预设中没有上下文选择，使用空数据');
        }
        
        AppLogger.i(_tag, '🔧 从预设中读取参数: temperature=$temperature, topP=$topP, maxTokens=$maxTokens, enableSmartContext=$enableSmartContext');
        // 🔍 调试：输出原始预设数据以排查更新问题
        AppLogger.i(_tag, '🔍 预设原始数据:');
        AppLogger.i(_tag, '  - presetId: ${preset.presetId}');
        AppLogger.i(_tag, '  - presetName: ${preset.presetName}');
        AppLogger.i(_tag, '  - requestData前50字符: ${preset.requestData.length > 50 ? preset.requestData.substring(0, 50) + "..." : preset.requestData}');
        AppLogger.i(_tag, '  - parsedRequest.parameters: ${parsedRequest.parameters}');
      } else {
        AppLogger.w(_tag, '⚠️ 无法解析预设参数，使用默认值');
        // 创建空的上下文选择数据
        contextSelectionData = ContextSelectionData(
          novelId: widget.novel?.id ?? 'unknown',
          availableItems: [],
          flatItems: {},
        );
      }

      // 🚀 使用公共逻辑创建元数据
      final metadata = createModelMetadata(model, {
        'action': widget.requestType.name,
        'source': 'preset_quick_menu',
        'presetId': preset.presetId,
        'presetName': preset.presetName,
        'originalLength': widget.selectedText.length,
        'contextCount': contextSelectionData.selectedCount, // 🚀 使用实际的上下文数量
        'enableSmartContext': enableSmartContext,
      });

      // 构建AI请求
      final request = UniversalAIRequest(
        requestType: widget.requestType,
        userId: AppConfig.userId ?? 'unknown',
        novelId: widget.novel?.id,
        modelConfig: modelConfig,
        selectedText: widget.selectedText,
        instructions: preset.effectiveUserPrompt, // 使用预设的提示词
        contextSelections: contextSelectionData,
        enableSmartContext: enableSmartContext, // 🚀 从预设中读取
        parameters: {
          'temperature': temperature, // 🚀 从预设中读取
          'topP': topP, // 🚀 从预设中读取
          'maxTokens': maxTokens, // 🚀 从预设中读取
          'modelName': model.modelId,
          'presetId': preset.presetId,
          'presetName': preset.presetName,
          'enableSmartContext': enableSmartContext, // 🚀 从预设中读取
          if (promptTemplateId != null) 'promptTemplateId': promptTemplateId, // 🚀 从预设中读取模板ID
        },
        metadata: metadata,
      );

      // 🚀 调用流式生成回调启动AI生成工具栏
      callback(request, model);
      
      AppLogger.i(_tag, '流式生成已启动: 预设=${preset.presetName}, 模型=${model.displayName}, 智能上下文=false, 原文长度=${widget.selectedText.length}');
      
    } catch (e) {
      AppLogger.e(_tag, '启动流式生成失败', e);
      if (mounted) {
        TopToast.error(context, '启动生成失败: $e');
      }
    }
  }

  /// 构建模型标签
  List<Widget> _buildModelTags(BuildContext context, UnifiedAIModel model) {
    final List<Widget> tags = [];
    
    // 公共模型标签
    if (model.isPublic) {
      tags.addAll([
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '公共',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ]);
    }
    
    // 默认模型标签
    if (!model.isPublic && (model as PrivateAIModel).userConfig.isDefault) {
      tags.addAll([
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '默认',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ]);
    }
    
    return tags;
  }

  /// 构建模型子标题
  Widget? _buildModelSubtitle(BuildContext context, UnifiedAIModel model) {
    final List<String> subtitles = [];
    
    if (model.isPublic) {
      subtitles.add('公共模型');
    }
    
    if (!model.isPublic && (model as PrivateAIModel).userConfig.isDefault) {
      subtitles.add('默认模型');
    }
    
    if (subtitles.isEmpty) return null;
    
    return Text(
      subtitles.join(' · '),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 12,
      ),
    );
  }


}


