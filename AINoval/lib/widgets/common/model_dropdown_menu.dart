import 'package:ainoval/utils/logger.dart';
import 'package:flutter/material.dart';

import '../../models/user_ai_model_config_model.dart';
import '../../models/novel_structure.dart';
import '../../models/novel_setting_item.dart';
import '../../models/setting_group.dart';
import '../../models/novel_snippet.dart';
import '../../screens/chat/widgets/chat_settings_dialog.dart';
import '../../config/provider_icons.dart';
import '../../models/ai_request_models.dart';

/// 纯粹的模型下拉菜单组件，供多个场景复用
/// 通过 [show] 静态方法弹出 Overlay 菜单
class ModelDropdownMenu {
  static OverlayEntry show({
    required BuildContext context,
    LayerLink? layerLink,
    Rect? anchorRect,
    required List<UserAIModelConfigModel> configs,
    UserAIModelConfigModel? selectedModel,
    required Function(UserAIModelConfigModel?) onModelSelected,
    bool showSettingsButton = true,
    double maxHeight = 2400,
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
        // 计算菜单高度（依据当前 UI 调整过的真实尺寸）
        const double groupHeaderHeight = 48.0;   // 分组标题约 28px
        const double modelItemHeight   = 36.0;   // 单条模型项约 36px
        const double bottomButtonHeight = 56.0;  // 底部操作区固定 56px
        const double verticalPadding    = 12.0;  // 上下留白

        final grouped = _groupModelsByProvider(configs);
        int totalItems = 0;
        for (var g in grouped.values) {
          totalItems += g.length;
        }
        final double contentHeight =
            (grouped.length * groupHeaderHeight) +
                (totalItems * modelItemHeight) +
                (showSettingsButton ? bottomButtonHeight : 0) +
                (verticalPadding * 2);
        final double minHeight = showSettingsButton ? 180 : 100;
        final double menuHeight = contentHeight.clamp(minHeight, maxHeight);

        // 主题检测
        final isDark = Theme.of(context).brightness == Brightness.dark;

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
                width: 300,
                child: CompositedTransformFollower(
                  link: layerLink!,
                  showWhenUnlinked: false,
                  targetAnchor: Alignment.topCenter,
                  followerAnchor: Alignment.bottomCenter,
                  offset: const Offset(0, -6), // 向上偏移6像素
                  child: _buildMenuContainer(context, menuHeight, configs, selectedModel, onModelSelected, showSettingsButton, novel, settings, settingGroups, snippets, chatConfig, onConfigChanged, safeClose),
                ),
              ),
            ] else if (anchorRect != null) ...[
              _buildPositionedMenu(context, anchorRect!, menuHeight, configs, selectedModel, onModelSelected, showSettingsButton, novel, settings, settingGroups, snippets, chatConfig, onConfigChanged, safeClose),
            ],
          ],
        );
      },
    );

    Overlay.of(context).insert(entry);
    return entry;
  }

  static void _remove(OverlayEntry entry) {
    if (entry.mounted) entry.remove();
  }

  // 分组逻辑提取
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

  // internal build helpers
  static Widget _buildMenuContainer(BuildContext context,double menuHeight,
      List<UserAIModelConfigModel> configs,
      UserAIModelConfigModel? selectedModel,
      Function(UserAIModelConfigModel?) onModelSelected,
      bool showSettingsButton,Novel? novel,List<NovelSettingItem> settings,List<SettingGroup> settingGroups,List<NovelSnippet> snippets,UniversalAIRequest? chatConfig,ValueChanged<UniversalAIRequest>? onConfigChanged,VoidCallback onClose){
        final isDark = Theme.of(context).brightness==Brightness.dark;
        return Material(
          elevation: isDark?12:8,
          borderRadius: BorderRadius.circular(16),
          color: isDark?Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.95):Theme.of(context).colorScheme.surfaceContainer,
          shadowColor: Colors.black.withOpacity(isDark?0.3:0.15),
          child: Container(
            height: menuHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color:Theme.of(context).colorScheme.outlineVariant.withOpacity(isDark?0.2:0.3),width:0.8),
            ),
            child: _MenuContent(
              configs:configs,
              selectedModel:selectedModel,
              onModelSelected:onModelSelected,
              onClose:onClose,
              showSettingsButton:showSettingsButton,
              novel:novel,
              settings:settings,
              settingGroups:settingGroups,
              snippets:snippets,
              chatConfig:chatConfig,
              onConfigChanged:onConfigChanged,
            ),
          ),
        );
  }

  static Widget _buildPositionedMenu(BuildContext context,Rect anchorRect,double menuHeight,
      List<UserAIModelConfigModel> configs,
      UserAIModelConfigModel? selectedModel,
      Function(UserAIModelConfigModel?) onModelSelected,
      bool showSettingsButton,Novel? novel,List<NovelSettingItem> settings,List<SettingGroup> settingGroups,List<NovelSnippet> snippets,UniversalAIRequest? chatConfig,ValueChanged<UniversalAIRequest>? onConfigChanged,VoidCallback onClose){

        final screenSize = MediaQuery.of(context).size;
        const double horizMargin=16;
        double left=anchorRect.left;
        if(left+300>screenSize.width-horizMargin){
          left=screenSize.width-300-horizMargin;
        }

        // Determine vertical placement
        double top=anchorRect.top-menuHeight-6; // above
        if(top<MediaQuery.of(context).padding.top+10){
          top=anchorRect.bottom+6; // below
        }

        return Positioned(
          left:left,
          top:top,
          width:300,
          child:_buildMenuContainer(context, menuHeight, configs, selectedModel, onModelSelected, showSettingsButton, novel, settings, settingGroups, snippets, chatConfig, onConfigChanged, onClose),
        );
  }
}

// ------------------ 内部菜单内容 ------------------
class _MenuContent extends StatelessWidget {
  const _MenuContent({
    Key? key,
    required this.configs,
    required this.selectedModel,
    required this.onModelSelected,
    required this.onClose,
    required this.showSettingsButton,
    this.novel,
    this.settings = const [],
    this.settingGroups = const [],
    this.snippets = const [],
    this.chatConfig,
    this.onConfigChanged,
  }) : super(key: key);

  final List<UserAIModelConfigModel> configs;
  final UserAIModelConfigModel? selectedModel;
  final Function(UserAIModelConfigModel?) onModelSelected;
  final VoidCallback onClose;
  final bool showSettingsButton;
  final Novel? novel;
  final List<NovelSettingItem> settings;
  final List<SettingGroup> settingGroups;
  final List<NovelSnippet> snippets;
  final UniversalAIRequest? chatConfig;
  final ValueChanged<UniversalAIRequest>? onConfigChanged;

  @override
  Widget build(BuildContext context) {
    if (configs.isEmpty) {
      return _buildEmpty(context);
    }
    final grouped = ModelDropdownMenu._groupModelsByProvider(configs);
    final providers = grouped.keys.toList()
      ..sort((a, b) {
        final aDef = grouped[a]!.any((c) => c.isDefault);
        final bDef = grouped[b]!.any((c) => c.isDefault);
        if (aDef && !bDef) return -1;
        if (!aDef && bDef) return 1;
        return a.compareTo(b);
      });

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            itemCount: providers.length,
            separatorBuilder: (c, i) => Divider(
              height: 8,
              thickness: 0.6,
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withOpacity(0.12),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (c, index) {
              final provider = providers[index];
              final models = grouped[provider]!;
              return _ProviderGroup(
                provider: provider,
                models: models,
                selectedModel: selectedModel,
                onModelSelected: (m){
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.model_training_outlined,
                size: 48, color: cs.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('无可用模型',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('请先配置AI模型',
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? cs.surface.withOpacity(0.8) : cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withOpacity(isDark ? 0.15 : 0.2),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            onClose(); // 先关闭 Overlay
            showChatSettingsDialog(
              context,
              selectedModel: selectedModel,
              onModelChanged: (m) => onModelSelected(m),
              novel: novel,
              settings: settings,
              settingGroups: settingGroups,
              snippets: snippets,
              initialChatConfig: chatConfig,
              onConfigChanged: onConfigChanged,
              initialContextSelections: null, // 🚀 让ChatSettingsDialog自己构建上下文数据
            );
          },
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('调整并生成'),
          style: ElevatedButton.styleFrom(
            foregroundColor:
                isDark ? cs.primary.withOpacity(0.9) : cs.primary,
            backgroundColor: isDark
                ? cs.primaryContainer.withOpacity(0.08)
                : cs.primaryContainer.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            side: BorderSide(color: cs.primary.withOpacity(isDark ? 0.2 : 0.3), width: 0.8),
          ),
        ),
      ),
    );
  }
}

// Provider 分组
class _ProviderGroup extends StatelessWidget {
  const _ProviderGroup({
    Key? key,
    required this.provider,
    required this.models,
    required this.selectedModel,
    required this.onModelSelected,
  }) : super(key: key);

  final String provider;
  final List<UserAIModelConfigModel> models;
  final UserAIModelConfigModel? selectedModel;
  final Function(UserAIModelConfigModel?) onModelSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Text(provider.toUpperCase(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDark ? cs.primary.withOpacity(0.9) : cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    fontSize: 14,
                  )),
        ),
        ...models.map((m) => _ModelItem(
              model: m,
              isSelected: selectedModel?.id == m.id,
              onTap: () => onModelSelected(m),
            )),
        const SizedBox(height: 2),
      ],
    );
  }
}

class _ModelItem extends StatelessWidget {
  const _ModelItem({
    Key? key,
    required this.model,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  final UserAIModelConfigModel model;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = model.alias.isNotEmpty ? model.alias : model.modelName;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      splashColor: cs.primary.withOpacity(0.08),
      highlightColor: cs.primary.withOpacity(0.04),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? cs.primaryContainer.withOpacity(0.2)
                  : cs.primaryContainer.withOpacity(0.15))
              : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: cs.primary.withOpacity(0.2), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(2),
              child: _getModelIcon(model.provider, context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? cs.primary
                            : (isDark
                                ? cs.onSurface.withOpacity(0.9)
                                : cs.onSurface),
                        fontSize: 13,
                        height: 1.2,
                      ),
                  overflow: TextOverflow.ellipsis),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 16, color: cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _getModelIcon(String provider, BuildContext context) {
    final color = ProviderIcons.getProviderColor(provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 18,
      height: 18,
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
        child: ProviderIcons.getProviderIcon(provider, size: 10, useHighQuality: true),
      ),
    );
  }
} 