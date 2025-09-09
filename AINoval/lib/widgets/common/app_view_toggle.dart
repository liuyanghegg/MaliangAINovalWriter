import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 通用视图切换组件
class AppViewToggle extends StatelessWidget {
  const AppViewToggle({
    super.key,
    required this.isGridView,
    required this.onViewTypeChanged,
    this.gridIcon = Icons.grid_view,
    this.listIcon = Icons.view_list,
    this.size = 18,
  });

  final bool isGridView;
  final ValueChanged<bool> onViewTypeChanged;
  final IconData gridIcon;
  final IconData listIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = WebTheme.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? WebTheme.darkGrey400 : WebTheme.grey300,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            icon: gridIcon,
            isSelected: isGridView,
            isFirst: true,
            onTap: () => onViewTypeChanged(true),
            size: size,
          ),
          _ToggleButton(
            icon: listIcon,
            isSelected: !isGridView,
            isFirst: false,
            onTap: () => onViewTypeChanged(false),
            size: size,
          ),
        ],
      ),
    );
  }
}

/// 切换按钮内部组件
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.isSelected,
    required this.isFirst,
    required this.onTap,
    required this.size,
  });

  final IconData icon;
  final bool isSelected;
  final bool isFirst;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = WebTheme.isDarkMode(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 5 : 0),
          bottomLeft: Radius.circular(isFirst ? 5 : 0),
          topRight: Radius.circular(isFirst ? 0 : 5),
          bottomRight: Radius.circular(isFirst ? 0 : 5),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            border: isFirst
                ? Border(
                    right: BorderSide(
                      color: isDark ? WebTheme.darkGrey400 : WebTheme.grey300,
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: Icon(
            icon,
            size: size,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
} 