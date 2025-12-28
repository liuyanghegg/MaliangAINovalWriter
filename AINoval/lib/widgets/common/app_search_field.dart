import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 通用搜索框组件
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hintText = '搜索...',
    this.height,
    this.width,
    this.enabled = true,
    this.borderRadius = 6.0,
    this.showClearButton = true,
    this.prefixIcon,
    this.suffixIcon,
    this.dense = true,
    this.textAlign = TextAlign.start,
    this.fillColor,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final String hintText;
  final double? height;
  final double? width;
  final bool enabled;
  final double borderRadius;
  final bool showClearButton;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool dense;
  final TextAlign textAlign;
  final Color? fillColor;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = WebTheme.isDarkMode(context);

    Widget searchField = TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textAlign: widget.textAlign,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontSize: 13,
        ),
        prefixIcon: widget.prefixIcon ?? Icon(
          Icons.search,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          size: 16,
        ),
        suffixIcon: widget.showClearButton && widget.controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                onPressed: widget.onClear ?? () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
                splashRadius: 16,
                tooltip: '清除',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
              )
            : widget.suffixIcon,
        filled: true,
        fillColor: widget.fillColor ?? WebTheme.getBackgroundColor(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: widget.dense 
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: widget.dense,
      ),
    );

    // 如果指定了宽度或高度，则包装在Container中
    if (widget.width != null || widget.height != null) {
      searchField = Container(
        width: widget.width,
        height: widget.height,
        child: searchField,
      );
    }

    return searchField;
  }
} 