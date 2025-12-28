import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/ai_config/ai_config_bloc.dart';
import '../../models/user_ai_model_config_model.dart';
import '../../models/novel_structure.dart';
import '../../models/novel_setting_item.dart';
import '../../models/setting_group.dart';
import '../../models/novel_snippet.dart';
import '../../models/ai_request_models.dart';
import '../../screens/chat/widgets/chat_settings_dialog.dart';
import '../../config/provider_icons.dart';
import 'model_dropdown_menu.dart';

/// 模型选择器公共组件
/// 
/// 功能特性：
/// - 按供应商分组显示模型
/// - 模型图标显示
/// - 默认模型标识
/// - 模型标签支持（如免费标签）
/// - 分为模型列表区和底部操作区
class ModelSelector extends StatefulWidget {
  const ModelSelector({
    Key? key,
    this.selectedModel,
    required this.onModelSelected,
    this.onSettingsPressed,
    this.compact = false,
    this.showSettingsButton = true,
    this.maxHeight = 2400,
    this.novel,
    this.settings = const [],
    this.settingGroups = const [],
    this.snippets = const [],
    this.chatConfig,
    this.onConfigChanged,
  }) : super(key: key);

  /// 当前选中的模型
  final UserAIModelConfigModel? selectedModel;
  
  /// 模型选择回调
  final Function(UserAIModelConfigModel?) onModelSelected;
  
  /// 设置按钮点击回调
  final VoidCallback? onSettingsPressed;
  
  /// 是否紧凑模式
  final bool compact;
  
  /// 是否显示设置按钮
  final bool showSettingsButton;
  
  /// 最大高度
  final double maxHeight;
  
  /// 小说数据，用于上下文选择
  final Novel? novel;
  
  /// 设定数据
  final List<NovelSettingItem> settings;
  
  /// 设定组数据
  final List<SettingGroup> settingGroups;
  
  /// 片段数据
  final List<NovelSnippet> snippets;
  
  /// 🚀 聊天配置
  final UniversalAIRequest? chatConfig;
  
  /// 🚀 配置变更回调
  final ValueChanged<UniversalAIRequest>? onConfigChanged;

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isMenuOpen = false;

  /// 公开方法：触发菜单显示/隐藏
  void showDropdown() {
    final aiConfigBloc = context.read<AiConfigBloc>();
    final validatedConfigs = aiConfigBloc.state.validatedConfigs;
    if (validatedConfigs.isNotEmpty) {
      _toggleMenu(context, validatedConfigs);
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isMenuOpen = false;
  }

  void _toggleMenu(BuildContext context, List<UserAIModelConfigModel> configs) {
    if (_isMenuOpen) {
      _removeOverlay();
    } else {
      _createOverlay(context, configs);
      _isMenuOpen = true;
    }
  }

  void _createOverlay(BuildContext context, List<UserAIModelConfigModel> configs) {
    _overlayEntry = ModelDropdownMenu.show(
      context: context,
      layerLink: _layerLink,
      configs: configs,
      selectedModel: widget.selectedModel,
      onModelSelected: (model) {
        widget.onModelSelected(model);
        setState(() {});
      },
      showSettingsButton: widget.showSettingsButton,
      maxHeight: widget.maxHeight,
      novel: widget.novel,
      settings: widget.settings,
      settingGroups: widget.settingGroups,
      snippets: widget.snippets,
      chatConfig: widget.chatConfig,
      onConfigChanged: widget.onConfigChanged,
      onClose: () {
        _overlayEntry = null;
        setState(() {
          _isMenuOpen = false;
        });
      },
    );
  }

  Widget _buildMenuContent(List<UserAIModelConfigModel> configs) {
    if (configs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.model_training_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                '无可用模型',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '请先配置AI模型',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: _buildModelList(configs),
        ),
        if (widget.showSettingsButton)
          _buildBottomActions(),
      ],
    );
  }

  Widget _buildModelList(List<UserAIModelConfigModel> configs) {
    final groupedModels = _groupModelsByProvider(configs);
    final colorScheme = Theme.of(context).colorScheme;
    
    
    // Sort providers: default provider first, then alphabetically
    final sortedProviders = groupedModels.keys.toList()..sort((a, b) {
      final aIsDefault = groupedModels[a]!.any((c) => c.isDefault);
      final bIsDefault = groupedModels[b]!.any((c) => c.isDefault);
      if (aIsDefault && !bIsDefault) return -1;
      if (!aIsDefault && bIsDefault) return 1;
      return a.compareTo(b);
    });


    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      itemCount: sortedProviders.length,
      separatorBuilder: (context, index) => Divider(
        height: 16,
        thickness: 0.8,
        color: colorScheme.outlineVariant.withOpacity(0.12),
        indent: 20,
        endIndent: 20,
      ),
      itemBuilder: (context, index) {
        final provider = sortedProviders[index];
        final models = groupedModels[provider]!;
        return _buildProviderGroup(provider, models);
      },
    );
  }

  Widget _buildProviderGroup(String provider, List<UserAIModelConfigModel> models) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 供应商分组标题 - 完全移除图标，增大字体
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Text(
            provider.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isDark 
                ? colorScheme.primary.withOpacity(0.9)
                : colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              fontSize: 14,
            ),
          ),
        ),
        // 该供应商下的模型列表
        ...models.map((model) => _buildModelItem(model)).toList(),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildModelItem(UserAIModelConfigModel model) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = widget.selectedModel?.id == model.id;
    final displayName = model.alias.isNotEmpty ? model.alias : model.modelName;

    return InkWell(
      onTap: () {
        widget.onModelSelected(model);
        _removeOverlay();
      },
      borderRadius: BorderRadius.circular(10),
      splashColor: colorScheme.primary.withOpacity(0.08),
      highlightColor: colorScheme.primary.withOpacity(0.04),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark 
                  ? colorScheme.primaryContainer.withOpacity(0.2)
                  : colorScheme.primaryContainer.withOpacity(0.15))
              : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            // 模型图标 - 外层包装防止突兀
            Container(
              padding: const EdgeInsets.all(2),
              child: _getModelIcon(model.provider),
            ),
            const SizedBox(width: 10),
            
            // 模型信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 模型名称行
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.primary
                                : (isDark 
                                    ? colorScheme.onSurface.withOpacity(0.9)
                                    : colorScheme.onSurface),
                            fontSize: 13,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 默认模型标识
                      if (model.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.amber.withOpacity(0.15)
                                : Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.amber.withOpacity(isDark ? 0.4 : 0.5), 
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '默认',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark 
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade700,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  // 模型标签行（预留区域）
                  if (_getModelTags(model).isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 3,
                      runSpacing: 2,
                      children: _getModelTags(model).map((tag) => _buildModelTag(tag)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            // 选中标识
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelTag(ModelTag tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    MaterialColor tagColor;
    switch (tag.type) {
      case ModelTagType.free:
        tagColor = Colors.green;
        break;
      case ModelTagType.premium:
        tagColor = Colors.purple;
        break;
      case ModelTagType.beta:
        tagColor = Colors.orange;
        break;
      default:
        tagColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark 
            ? tagColor.withOpacity(0.08)
            : tagColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: tagColor.withOpacity(isDark ? 0.2 : 0.3), 
          width: 0.5,
        ),
      ),
      child: Text(
        tag.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isDark 
              ? tagColor.shade300
              : tagColor.shade700,
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
            ? colorScheme.surface.withOpacity(0.8)
            : colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(isDark ? 0.15 : 0.2),
            width: 1.0,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            _removeOverlay();
            // 显示聊天设置对话框
            showChatSettingsDialog(
              context,
              selectedModel: widget.selectedModel,
              onModelChanged: (model) {
                widget.onModelSelected(model);
              },
              onSettingsSaved: () {
                widget.onSettingsPressed?.call();
              },
              novel: widget.novel,
              settings: widget.settings,
              settingGroups: widget.settingGroups,
              snippets: widget.snippets,
              // 🚀 传递聊天配置，确保设置对话框能够同步
              initialChatConfig: widget.chatConfig,
              onConfigChanged: widget.onConfigChanged,
              initialContextSelections: null, // 🚀 让ChatSettingsDialog自己构建上下文数据
            );
          },
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('调整并生成'),
          style: ElevatedButton.styleFrom(
            foregroundColor: isDark 
                ? colorScheme.primary.withOpacity(0.9)
                : colorScheme.primary,
            backgroundColor: isDark 
                ? colorScheme.primaryContainer.withOpacity(0.08)
                : colorScheme.primaryContainer.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
            side: BorderSide(
              color: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.3),
              width: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  Map<String, List<UserAIModelConfigModel>> _groupModelsByProvider(
      List<UserAIModelConfigModel> configs) {
    final Map<String, List<UserAIModelConfigModel>> grouped = {};
    
    for (final config in configs) {
      final provider = config.provider;
      grouped.putIfAbsent(provider, () => []);
      grouped[provider]!.add(config);
    }
    
    // 对每个供应商的模型按名称排序，默认模型排在前面
    for (final models in grouped.values) {
      models.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.name.compareTo(b.name);
      });
    }
    
    return grouped;
  }

  Widget _getProviderIcon(String provider) {
    return ProviderIcons.getProviderIconForContext(
      provider,
      iconSize: IconSize.small,
    );
  }

  Widget _getModelIcon(String provider) {
    final color = ProviderIcons.getProviderColor(provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.9)  // 暗黑模式下背景为白色
            : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark 
              ? color.withOpacity(0.3)
              : color.withOpacity(0.25), 
          width: 0.5,
        ),
        boxShadow: isDark ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ProviderIcons.getProviderIcon(
          provider,
          size: 10,
          useHighQuality: true,
        ),
      ),
    );
  }

  List<ModelTag> _getModelTags(UserAIModelConfigModel model) {
    // 根据模型信息返回标签列表
    List<ModelTag> tags = [];
    
    // 示例：根据模型名称或其他属性添加标签
    if (model.modelName.toLowerCase().contains('free') || 
        model.modelName.toLowerCase().contains('gpt-3.5')) {
      tags.add(const ModelTag(label: '免费', type: ModelTagType.free));
    }
    
    if (model.modelName.toLowerCase().contains('beta')) {
      tags.add(const ModelTag(label: 'Beta', type: ModelTagType.beta));
    }
    
    if (model.modelName.toLowerCase().contains('pro') ||
        model.modelName.toLowerCase().contains('gpt-4')) {
      tags.add(const ModelTag(label: '专业版', type: ModelTagType.premium));
    }
    
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return BlocBuilder<AiConfigBloc, AiConfigState>(
      builder: (context, state) {
        final validatedConfigs = state.validatedConfigs;

        // 确定当前选中的模型
        UserAIModelConfigModel? currentSelection;
        if (widget.selectedModel != null &&
            validatedConfigs.any((c) => c.id == widget.selectedModel!.id)) {
          currentSelection = widget.selectedModel;
        } else if (state.defaultConfig != null &&
            validatedConfigs.any((c) => c.id == state.defaultConfig!.id)) {
          currentSelection = state.defaultConfig;
        } else if (validatedConfigs.isNotEmpty) {
          currentSelection = validatedConfigs.first;
        }

        // 加载状态
        if (state.status == AiConfigStatus.loading && validatedConfigs.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 0.8,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 8),
                Text('加载中...', style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        }

        // 无模型状态
        if (state.status != AiConfigStatus.loading && validatedConfigs.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
              border: Border.all(
                color: colorScheme.error.withOpacity(0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_outlined,
                  size: 16,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 6),
                Text(
                  '无可用模型',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          );
        }

        // 正常状态 - 模型选择器
        return CompositedTransformTarget(
          link: _layerLink,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: validatedConfigs.isNotEmpty
                  ? () => _toggleMenu(context, validatedConfigs)
                  : null,
              borderRadius: BorderRadius.circular(8),
              hoverColor: colorScheme.onSurface.withOpacity(0.08),
              splashColor: colorScheme.onSurface.withOpacity(0.12),
              child: Container(
                height: 44,
                constraints: const BoxConstraints(maxWidth: 128),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: Colors.transparent,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // 主要内容区域
                    Expanded(
                      child: Row(
                        children: [
                          // 文字内容
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 第一行：General Chat
                                Text(
                                  'General Chat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // 第二行：模型名称
                                Text(
                                  _getModelDisplayName(currentSelection),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface.withOpacity(0.5),
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // 下拉箭头
                          if (validatedConfigs.length > 1)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              child: Icon(
                                _isMenuOpen
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 12,
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDisplayText(UserAIModelConfigModel? model) {
    if (model == null) {
      return '选择模型';
    }
    final namePart = model.alias.isNotEmpty ? model.alias : model.modelName;
    return widget.compact ? namePart : '${model.provider}/$namePart';
  }

  String _getModelDisplayName(UserAIModelConfigModel? model) {
    if (model == null) {
      return '请选择模型';
    }
    final namePart = model.alias.isNotEmpty ? model.alias : model.modelName;
    return namePart;
  }
}

/// 模型标签数据类
class ModelTag {
  const ModelTag({
    required this.label,
    required this.type,
  });
  
  final String label;
  final ModelTagType type;
}

/// 模型标签类型枚举
enum ModelTagType {
  free,     // 免费
  premium,  // 专业版
  beta,     // 测试版
  custom,   // 自定义
}