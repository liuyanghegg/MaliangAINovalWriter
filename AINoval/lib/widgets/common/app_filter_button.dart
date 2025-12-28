import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 通用过滤器按钮组件
class AppFilterButton extends StatelessWidget {
  const AppFilterButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isSelected = false,
    this.size = AppFilterButtonSize.medium,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isSelected;
  final AppFilterButtonSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = WebTheme.isDarkMode(context);
    
    // 根据尺寸设置不同的参数
    final buttonConfig = _getButtonConfig(size);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(buttonConfig.borderRadius),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: buttonConfig.horizontalPadding,
            vertical: buttonConfig.verticalPadding,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(buttonConfig.borderRadius),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
              width: isSelected ? 1.5 : 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: buttonConfig.iconSize,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? WebTheme.darkGrey800 : WebTheme.grey800),
              ),
              if (label.isNotEmpty) ...[
                SizedBox(width: buttonConfig.spacing),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: buttonConfig.fontSize,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark ? WebTheme.darkGrey800 : WebTheme.grey800),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _FilterButtonConfig _getButtonConfig(AppFilterButtonSize size) {
    switch (size) {
      case AppFilterButtonSize.small:
        return const _FilterButtonConfig(
          horizontalPadding: 8,
          verticalPadding: 4,
          iconSize: 14,
          fontSize: 11,
          spacing: 3,
          borderRadius: 4,
        );
      case AppFilterButtonSize.medium:
        return const _FilterButtonConfig(
          horizontalPadding: 10,
          verticalPadding: 6,
          iconSize: 16,
          fontSize: 12,
          spacing: 4,
          borderRadius: 6,
        );
      case AppFilterButtonSize.large:
        return const _FilterButtonConfig(
          horizontalPadding: 12,
          verticalPadding: 8,
          iconSize: 18,
          fontSize: 14,
          spacing: 6,
          borderRadius: 8,
        );
    }
  }
}

/// 过滤器按钮尺寸枚举
enum AppFilterButtonSize {
  small,
  medium,
  large,
}

/// 按钮配置数据类
class _FilterButtonConfig {
  const _FilterButtonConfig({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    required this.fontSize,
    required this.spacing,
    required this.borderRadius,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final double fontSize;
  final double spacing;
  final double borderRadius;
} 