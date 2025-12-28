import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/common/preset_dropdown_button.dart';
import 'package:ainoval/models/preset_models.dart';

/// 选项卡项目数据
class TabItem {
  /// 构造函数
  const TabItem({
    required this.id,
    required this.label,
    this.icon,
  });

  /// 标识符
  final String id;

  /// 显示文字
  final String label;

  /// 图标
  final IconData? icon;
}

/// 自定义选项卡栏组件
/// 支持图标、文字和预设按钮
class CustomTabBar extends StatelessWidget {
  /// 构造函数
  const CustomTabBar({
    super.key,
    required this.tabs,
    required this.selectedTabId,
    required this.onTabChanged,
    this.showPresets = false,
    this.onPresetsPressed,
    this.presetsLabel = '预设',
    this.usePresetDropdown = false,
    this.presetFeatureType,
    this.currentPreset,
    this.onPresetSelected,
    this.onCreatePreset,
    this.onManagePresets,
    this.novelId,
  });

  /// 选项卡列表
  final List<TabItem> tabs;

  /// 当前选中的选项卡ID
  final String selectedTabId;

  /// 选项卡改变回调
  final ValueChanged<String> onTabChanged;

  /// 是否显示预设按钮
  final bool showPresets;

  /// 预设按钮点击回调
  final VoidCallback? onPresetsPressed;

  /// 预设按钮文字
  final String presetsLabel;

  /// 是否使用新的预设下拉框
  final bool usePresetDropdown;

  /// 预设功能类型（用于过滤预设）
  final String? presetFeatureType;

  /// 当前选中的预设
  final AIPromptPreset? currentPreset;

  /// 预设选择回调
  final ValueChanged<AIPromptPreset>? onPresetSelected;

  /// 创建预设回调
  final VoidCallback? onCreatePreset;

  /// 管理预设回调
  final VoidCallback? onManagePresets;

  /// 小说ID（用于过滤预设）
  final String? novelId;

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? WebTheme.darkGrey200 : WebTheme.grey200,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // 选项卡列表
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tabs.map((tab) => _buildTab(context, tab, isDark)).toList(),
                ),
              ),
            ),

            // 预设按钮
            if (showPresets) ...[
              const SizedBox(width: 8),
              usePresetDropdown ? _buildPresetDropdown() : _buildPresetsButton(context, isDark),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建单个选项卡
  Widget _buildTab(BuildContext context, TabItem tab, bool isDark) {
    final isSelected = tab.id == selectedTabId;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => onTabChanged(tab.id),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 选项卡内容
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isSelected 
                    ? (isDark ? WebTheme.darkGrey300.withValues(alpha: 0.2) : WebTheme.grey100)
                    : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tab.icon != null) ...[
                      Icon(
                        tab.icon,
                        size: 16,
                        color: isSelected
                          ? (isDark ? WebTheme.darkGrey700 : WebTheme.grey700)
                          : (isDark ? WebTheme.darkGrey500 : WebTheme.grey500),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                          ? (isDark ? WebTheme.darkGrey700 : WebTheme.grey700)
                          : (isDark ? WebTheme.darkGrey500 : WebTheme.grey500),
                      ),
                    ),
                  ],
                ),
              ),

              // 底部指示线
              Container(
                height: 2,
                width: 40,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: isSelected
                    ? (isDark ? WebTheme.darkGrey700 : WebTheme.grey700)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建预设下拉框
  Widget _buildPresetDropdown() {
    return PresetDropdownButton(
      featureType: presetFeatureType ?? '',
      currentPreset: currentPreset,
      onPresetSelected: onPresetSelected,
      onCreatePreset: onCreatePreset,
      onManagePresets: onManagePresets,
      novelId: novelId,
      label: presetsLabel,
    );
  }

  /// 构建预设按钮
  Widget _buildPresetsButton(BuildContext context, bool isDark) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPresetsPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                presetsLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 