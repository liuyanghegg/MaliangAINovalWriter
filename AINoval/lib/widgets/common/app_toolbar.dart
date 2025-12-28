import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 通用工具栏组件
class AppToolbar extends StatelessWidget {
  const AppToolbar({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.showTopBorder = true,
    this.showBottomBorder = true,
    this.showShadow = true,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool showTopBorder;
  final bool showBottomBorder;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = WebTheme.isDarkMode(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? WebTheme.darkGrey100 : WebTheme.white,
        border: Border(
          top: showTopBorder
              ? BorderSide(
                  color: isDark ? WebTheme.darkGrey600 : WebTheme.grey200,
                  width: 1,
                )
              : BorderSide.none,
          bottom: showBottomBorder
              ? BorderSide(
                  color: isDark ? WebTheme.darkGrey600 : WebTheme.grey200,
                  width: 1,
                )
              : BorderSide.none,
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: (isDark ? WebTheme.black : WebTheme.grey300)
                      .withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Row(
        children: children,
      ),
    );
  }
} 