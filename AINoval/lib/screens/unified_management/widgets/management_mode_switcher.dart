import 'package:flutter/material.dart';
import 'package:ainoval/screens/unified_management/unified_management_screen.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 管理模式切换器
/// 提供提示词模板管理和预设管理之间的切换功能
class ManagementModeSwitcher extends StatelessWidget {
  const ManagementModeSwitcher({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  final ManagementMode currentMode;
  final ValueChanged<ManagementMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        border: Border(
          bottom: BorderSide(
            color: isDark ? WebTheme.darkGrey200 : WebTheme.grey200,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentedControl(context),
          ),
        ],
      ),
    );
  }

  /// 构建分段控制器
  Widget _buildSegmentedControl(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? WebTheme.darkGrey100 : WebTheme.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? WebTheme.darkGrey200 : WebTheme.grey200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              context,
              mode: ManagementMode.prompts,
              title: '提示词管理',
              icon: Icons.auto_awesome_outlined,
              isSelected: currentMode == ManagementMode.prompts,
            ),
          ),
          Expanded(
            child: _buildModeButton(
              context,
              mode: ManagementMode.presets,
              title: '预设管理',
              icon: Icons.settings_suggest_outlined,
              isSelected: currentMode == ManagementMode.presets,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建模式按钮
  Widget _buildModeButton(
    BuildContext context, {
    required ManagementMode mode,
    required String title,
    required IconData icon,
    required bool isSelected,
  }) {
    final isDark = WebTheme.isDarkMode(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected
            ? WebTheme.getCardColor(context)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: WebTheme.getShadowColor(context, opacity: isDark ? 0.3 : 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onModeChanged(mode),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? WebTheme.getPrimaryColor(context)
                      : WebTheme.getSecondaryTextColor(context),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: WebTheme.labelMedium.copyWith(
                      color: isSelected
                          ? WebTheme.getTextColor(context)
                          : WebTheme.getSecondaryTextColor(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}