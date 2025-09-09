import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../blocs/theme/theme_event.dart';
import '../../blocs/theme/theme_state.dart';
import '../../utils/web_theme.dart';

class ThemeToggleButton extends StatelessWidget {
  final double? size;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showLabel;
  final String? tooltip;

  const ThemeToggleButton({
    super.key,
    this.size,
    this.iconColor,
    this.backgroundColor,
    this.showLabel = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return _buildToggleButton(context, state);
      },
    );
  }

  Widget _buildToggleButton(BuildContext context, ThemeState state) {
    final isDarkTheme = WebTheme.isDarkMode(context);
    final iconData = _getIconData(state.themeMode);
    final label = _getLabel(state.themeMode);
    
    // 确保按钮图标和背景有足够的对比度
    final buttonColor = backgroundColor ?? 
        (isDarkTheme ? WebTheme.darkGrey100 : WebTheme.grey100);
    final buttonIconColor = iconColor ?? 
        (isDarkTheme ? WebTheme.darkGrey800 : WebTheme.grey800);

    if (showLabel) {
      return Container(
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkTheme ? WebTheme.darkGrey300 : WebTheme.grey300,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.read<ThemeBloc>().add(ThemeToggled()),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    iconData,
                    size: size ?? 20,
                    color: buttonIconColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: buttonIconColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkTheme ? WebTheme.darkGrey300 : WebTheme.grey300,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.read<ThemeBloc>().add(ThemeToggled()),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              iconData,
              size: size ?? 20,
              color: buttonIconColor,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getLabel(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '自动';
    }
  }
}