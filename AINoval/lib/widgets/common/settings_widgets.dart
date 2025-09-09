import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 设置项卡片组件
/// 提供统一的设置项容器样式
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.icon,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WebTheme.isDarkMode(context) 
            ? WebTheme.darkGrey200 
            : WebTheme.grey200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WebTheme.isDarkMode(context) 
                ? WebTheme.darkGrey100.withAlpha(128)
                : WebTheme.grey50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: WebTheme.getTextColor(context, isPrimary: false),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: WebTheme.getTextColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: WebTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
          // 内容区域
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// 滑块设置组件
/// 提供统一的滑块样式和标签
class SettingsSlider extends StatelessWidget {
  const SettingsSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.unit = '',
    this.description,
    this.showValue = true,
    this.formatValue,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final String unit;
  final String? description;
  final bool showValue;
  final String Function(double)? formatValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: WebTheme.getTextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showValue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WebTheme.isDarkMode(context) 
                    ? WebTheme.darkGrey200 
                    : WebTheme.grey100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formatValue?.call(value) ?? '${value.toStringAsFixed(1)}$unit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WebTheme.getTextColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: WebTheme.getTextColor(context),
            inactiveTrackColor: WebTheme.isDarkMode(context) 
              ? WebTheme.darkGrey300 
              : WebTheme.grey300,
            thumbColor: WebTheme.getTextColor(context),
            overlayColor: WebTheme.getTextColor(context).withAlpha(51),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// 开关设置组件
/// 提供统一的开关样式和标签
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.icon,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? description;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WebTheme.getTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: WebTheme.getTextColor(context),
            inactiveTrackColor: WebTheme.isDarkMode(context) 
              ? WebTheme.darkGrey300 
              : WebTheme.grey300,
          ),
        ],
      ),
    );
  }
}

/// 下拉选择设置组件
/// 提供统一的下拉选择样式
class SettingsDropdown<T> extends StatelessWidget {
  const SettingsDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.description,
    this.itemBuilder,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? description;
  final String Function(T)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: WebTheme.getTextColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: WebTheme.isDarkMode(context) 
                ? WebTheme.darkGrey300 
                : WebTheme.grey300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            decoration: WebTheme.getBorderlessInputDecoration(
              context: context,
            ).copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemBuilder?.call(item) ?? item.toString(),
                  style: TextStyle(
                    color: WebTheme.getTextColor(context),
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            style: TextStyle(
              color: WebTheme.getTextColor(context),
            ),
            dropdownColor: WebTheme.getSurfaceColor(context),
            icon: Icon(
              Icons.expand_more,
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
        ),
      ],
    );
  }
}

/// 颜色选择设置组件
/// 提供颜色选择器
class SettingsColorPicker extends StatelessWidget {
  const SettingsColorPicker({
    super.key,
    required this.label,
    required this.color,
    required this.onChanged,
    this.description,
    this.colors,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;
  final String? description;
  final List<Color>? colors;

  static const List<Color> defaultColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF795548), // Brown
    Color(0xFF424242), // Grey
  ];

  @override
  Widget build(BuildContext context) {
    final colorList = colors ?? defaultColors;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: WebTheme.getTextColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colorList.map((colorOption) {
            final isSelected = color.value == colorOption.value;
            return GestureDetector(
              onTap: () => onChanged(colorOption),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorOption,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                      ? WebTheme.getTextColor(context)
                      : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: isSelected
                  ? Icon(
                      Icons.check,
                      color: colorOption.computeLuminance() > 0.5 
                        ? Colors.black 
                        : Colors.white,
                      size: 16,
                    )
                  : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 预览组件
/// 用于实时预览设置效果
class SettingsPreview extends StatelessWidget {
  const SettingsPreview({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.isDarkMode(context) 
          ? WebTheme.darkGrey100.withAlpha(128)
          : WebTheme.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WebTheme.isDarkMode(context) 
            ? WebTheme.darkGrey200 
            : WebTheme.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: WebTheme.getSecondaryTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// 分组标题组件
/// 用于设置页面的分组标题
class SettingsGroupTitle extends StatelessWidget {
  const SettingsGroupTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 32, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: WebTheme.getTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 操作按钮组件
/// 提供保存、重置等操作按钮
class SettingsActionBar extends StatelessWidget {
  const SettingsActionBar({
    super.key,
    this.onSave,
    this.onReset,
    this.onCancel,
    this.saveText = '保存',
    this.resetText = '重置',
    this.cancelText = '取消',
    this.isLoading = false,
  });

  final VoidCallback? onSave;
  final VoidCallback? onReset;
  final VoidCallback? onCancel;
  final String saveText;
  final String resetText;
  final String cancelText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: WebTheme.isDarkMode(context) 
              ? WebTheme.darkGrey200 
              : WebTheme.grey200,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onReset != null) ...[
            TextButton(
              onPressed: isLoading ? null : onReset,
              style: WebTheme.getSecondaryButtonStyle(context),
              child: Text(resetText),
            ),
            const SizedBox(width: 12),
          ],
          const Spacer(),
          if (onCancel != null) ...[
            TextButton(
              onPressed: isLoading ? null : onCancel,
              child: Text(
                cancelText,
                style: TextStyle(
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (onSave != null)
            ElevatedButton(
              onPressed: isLoading ? null : onSave,
              style: WebTheme.getPrimaryButtonStyle(context),
              child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        WebTheme.white,
                      ),
                    ),
                  )
                : Text(saveText),
            ),
        ],
      ),
    );
  }
} 