import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 单选按钮选项
class RadioOption<T> {
  /// 构造函数
  const RadioOption({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  /// 选项值
  final T value;

  /// 显示标签
  final String label;

  /// 是否启用
  final bool enabled;
}

/// 单选按钮组组件
/// 提供水平布局的单选按钮组，支持清除功能
class RadioButtonGroup<T> extends StatelessWidget {
  /// 构造函数
  const RadioButtonGroup({
    super.key,
    required this.options,
    this.value,
    required this.onChanged,
    this.showClear = false,
    this.onClear,
    this.clearLabel = '清除',
    this.spacing = 4,
    this.enabled = true,
  });

  /// 选项列表
  final List<RadioOption<T>> options;

  /// 当前选中值
  final T? value;

  /// 值改变回调
  final ValueChanged<T?> onChanged;

  /// 是否显示清除按钮
  final bool showClear;

  /// 清除回调
  final VoidCallback? onClear;

  /// 清除按钮文字
  final String clearLabel;

  /// 选项间距
  final double spacing;

  /// 是否启用
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);

    return Row(
      children: [
        // 选项按钮
        ...options.map((option) => Padding(
          padding: EdgeInsets.only(right: spacing),
          child: _buildRadioButton(context, option, isDark),
        )).toList(),

        // 清除按钮
        if (showClear) ...[
          const SizedBox(width: 8),
          _buildClearButton(context, isDark),
        ],
      ],
    );
  }

  /// 构建单个单选按钮
  Widget _buildRadioButton(BuildContext context, RadioOption<T> option, bool isDark) {
    final isSelected = value == option.value;
    final isEnabled = enabled && option.enabled;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: isEnabled ? () => onChanged(option.value) : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected && isEnabled
                ? (isDark ? WebTheme.darkGrey400 : WebTheme.grey400)
                : (isDark ? WebTheme.darkGrey200.withValues(alpha: 0.1) : WebTheme.grey200.withValues(alpha: 0.1)),
              width: 1,
            ),
            boxShadow: isSelected && isEnabled
              ? [
                  BoxShadow(
                    color: (isDark ? WebTheme.darkGrey400 : WebTheme.grey400).withValues(alpha: 0.2),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                option.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isEnabled
                    ? (isDark ? WebTheme.darkGrey800 : WebTheme.grey800)
                    : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建清除按钮
  Widget _buildClearButton(BuildContext context, bool isDark) {
    final isEnabled = enabled && onClear != null;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: isEnabled ? onClear : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block,
                size: 12,
                color: isEnabled
                  ? (isDark ? WebTheme.darkGrey600 : WebTheme.grey600)
                  : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
              ),
              const SizedBox(width: 4),
              Text(
                clearLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isEnabled
                    ? (isDark ? WebTheme.darkGrey600 : WebTheme.grey600)
                    : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 单选按钮组包装器，包含"或"分隔符
class RadioButtonGroupWithSeparator<T> extends StatelessWidget {
  /// 构造函数
  const RadioButtonGroupWithSeparator({
    super.key,
    required this.radioGroup,
    required this.alternativeWidget,
    this.separatorLabel = '或',
  });

  /// 单选按钮组
  final RadioButtonGroup<T> radioGroup;

  /// 替代组件（如输入框）
  final Widget alternativeWidget;

  /// 分隔符文字
  final String separatorLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);

    return Row(
      children: [
        // 单选按钮组
        radioGroup,

        // 分隔符
        const SizedBox(width: 8),
        Text(
          separatorLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
          ),
        ),
        const SizedBox(width: 8),

        // 替代组件
        Expanded(child: alternativeWidget),
      ],
    );
  }
} 