import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 底部操作栏组件
/// 包含模型选择器和主要操作按钮
class BottomActionBar extends StatelessWidget {
  /// 构造函数
  const BottomActionBar({
    super.key,
    this.modelSelector,
    required this.primaryAction,
    this.secondaryActions = const [],
    this.padding = const EdgeInsets.all(16),
    this.spacing = 16,
  });

  /// 模型选择器组件
  final Widget? modelSelector;

  /// 主要操作按钮
  final Widget primaryAction;

  /// 次要操作按钮列表
  final List<Widget> secondaryActions;

  /// 内边距
  final EdgeInsets padding;

  /// 按钮间距
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? WebTheme.darkGrey100 : WebTheme.white,
        border: Border(
          top: BorderSide(
            color: isDark ? WebTheme.darkGrey200 : WebTheme.grey200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 模型选择器（如果提供）
          if (modelSelector != null) ...[
            Expanded(child: modelSelector!),
            SizedBox(width: spacing),
          ],

          // 次要操作按钮
          ...secondaryActions.map((action) => Padding(
            padding: EdgeInsets.only(right: spacing),
            child: action,
          )).toList(),

          // 主要操作按钮
          primaryAction,
        ],
      ),
    );
  }
}

/// 模型选择器组件
/// 显示当前选中的AI模型和相关信息
class ModelSelector extends StatelessWidget {
  /// 构造函数
  const ModelSelector({
    super.key,
    required this.modelName,
    required this.onTap,
    this.providerIcon,
    this.maxOutput,
    this.isModerated = false,
    this.enabled = true,
  });

  /// 模型名称
  final String modelName;

  /// 点击回调
  final VoidCallback? onTap;

  /// 提供商图标
  final Widget? providerIcon;

  /// 最大输出
  final String? maxOutput;

  /// 是否受监管
  final bool isModerated;

  /// 是否启用
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark 
                ? WebTheme.darkGrey300.withValues(alpha: 0.5)
                : WebTheme.grey300,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: enabled
              ? Colors.transparent
              : (isDark ? WebTheme.darkGrey200 : WebTheme.grey100),
          ),
          child: Row(
            children: [
              // 提供商图标
              if (providerIcon != null) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: providerIcon!,
                ),
                const SizedBox(width: 12),
              ],

              // 模型信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 模型名称
                    Flexible(
                      child: Text(
                        modelName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: enabled
                            ? (isDark ? WebTheme.darkGrey900 : WebTheme.grey900)
                            : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // 附加信息
                    if (isModerated || maxOutput != null) ...[
                      const SizedBox(height: 1),
                      Flexible(
                        child: Row(
                          children: [
                            if (isModerated) ...[
                              Flexible(
                                child: Text(
                                  '受监管',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark 
                                      ? WebTheme.warning.withValues(alpha: 0.8)
                                      : WebTheme.warning,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (maxOutput != null) const SizedBox(width: 6),
                            ],
                            if (maxOutput != null)
                              Flexible(
                                child: Text(
                                  '最大输出: $maxOutput',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: enabled
                                      ? (isDark ? WebTheme.darkGrey500 : WebTheme.grey500)
                                      : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 下拉箭头
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: enabled
                  ? (isDark ? WebTheme.darkGrey600 : WebTheme.grey600)
                  : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 