import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 下拉选项
class DropdownOption<T> {
  /// 构造函数
  const DropdownOption({
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

/// 自定义下拉选择器组件
/// 提供统一的下拉选择器样式和功能
class CustomDropdown<T> extends StatelessWidget {
  /// 构造函数
  const CustomDropdown({
    super.key,
    required this.options,
    this.value,
    required this.onChanged,
    this.placeholder = '请选择...',
    this.enabled = true,
    this.width,
    this.height = 36,
  });

  /// 选项列表
  final List<DropdownOption<T>> options;

  /// 当前选中值
  final T? value;

  /// 值改变回调
  final ValueChanged<T?> onChanged;

  /// 占位符文字
  final String placeholder;

  /// 是否启用
  final bool enabled;

  /// 宽度
  final double? width;

  /// 高度
  final double height;

  @override
  Widget build(BuildContext context) {
    // final isDark = WebTheme.isDarkMode(context);
    final selectedOption = options.where((option) => option.value == value).firstOrNull;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enabled ? () => _showDropdown(context) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: enabled
                ? Theme.of(context).colorScheme.surfaceContainer
                : Theme.of(context).colorScheme.surfaceContainer,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // 选中值或占位符
              Expanded(
                child: Text(
                  selectedOption?.label ?? placeholder,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selectedOption != null ? FontWeight.w500 : FontWeight.normal,
                    color: selectedOption != null
                        ? (enabled
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7))
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 下拉箭头
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示下拉菜单
  void _showDropdown(BuildContext context) {
    // final isDark = WebTheme.isDarkMode(context);
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        offset.dy + size.height + 4,
      ),
      items: options.map((option) => PopupMenuItem<T>(
        value: option.value,
        enabled: option.enabled,
        child: Container(
          constraints: BoxConstraints(minWidth: size.width - 2),
          child: Text(
            option.label,
            style: TextStyle(
              fontSize: 14,
              color: option.enabled
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      )).toList(),
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shadowColor: WebTheme.getShadowColor(context, opacity: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
    ).then((selectedValue) {
      if (selectedValue != null) {
        onChanged(selectedValue);
      }
    });
  }
}

/// 带添加按钮的下拉选择器
class DropdownWithAddButton<T> extends StatelessWidget {
  /// 构造函数
  const DropdownWithAddButton({
    super.key,
    required this.dropdown,
    required this.onAdd,
    this.addLabel = '添加',
    this.addIcon = Icons.add,
  });

  /// 下拉选择器
  final CustomDropdown<T> dropdown;

  /// 添加按钮回调
  final VoidCallback onAdd;

  /// 添加按钮文字
  final String addLabel;

  /// 添加按钮图标
  final IconData addIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 下拉选择器
        Flexible(child: dropdown),

        const SizedBox(width: 8),

        // 添加按钮
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: dropdown.enabled ? onAdd : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: dropdown.height,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: dropdown.enabled
                  ? (isDark ? WebTheme.darkGrey100 : WebTheme.white)
                  : (isDark ? WebTheme.darkGrey200 : WebTheme.grey100),
                border: Border.all(
                  color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    addIcon,
                    size: 16,
                    color: dropdown.enabled
                      ? (isDark ? WebTheme.darkGrey600 : WebTheme.grey600)
                      : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    addLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dropdown.enabled
                        ? (isDark ? WebTheme.darkGrey600 : WebTheme.grey600)
                        : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
} 