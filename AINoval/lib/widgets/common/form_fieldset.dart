import 'package:flutter/material.dart';

import 'package:ainoval/utils/web_theme.dart';

import 'required_badge.dart';

/// 表单字段集组件
/// 提供统一的表单字段布局，包含标题、描述和重置功能
class FormFieldset extends StatelessWidget {
  /// 构造函数
  const FormFieldset({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.showReset = false,
    this.onReset,
    this.resetEnabled = true,
    this.showRequired = false,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  /// 字段标题
  final String title;

  /// 字段描述（可选）
  final String? description;

  /// 子组件
  final Widget child;

  /// 是否显示重置按钮
  final bool showReset;

  /// 重置回调
  final VoidCallback? onReset;

  /// 重置按钮是否可用
  final bool resetEnabled;

  /// 是否显示必填标识
  final bool showRequired;

  /// 内边距
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);

    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 标题
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
                ),
              ),

              // 必填标识
              if (showRequired) ...[
                const SizedBox(width: 8),
                const RequiredBadge(),
              ],

              // 占据剩余空间
              const Spacer(),

              // 重置按钮
              if (showReset)
                _buildResetButton(context, isDark),
            ],
          ),

          // 描述文字
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? WebTheme.darkGrey500 : WebTheme.grey500,
              ),
            ),
          ],

          // 内容区域
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  /// 构建重置按钮
  Widget _buildResetButton(BuildContext context, bool isDark) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: resetEnabled ? onReset : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: resetEnabled 
              ? (isDark ? WebTheme.darkGrey700 : WebTheme.grey700)
              : (isDark ? WebTheme.darkGrey600 : WebTheme.grey600),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: resetEnabled
                ? (isDark ? WebTheme.darkGrey600 : WebTheme.grey800)
                : (isDark ? WebTheme.darkGrey600 : WebTheme.grey600),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 12,
                color: resetEnabled
                  ? (isDark ? WebTheme.darkGrey100 : WebTheme.grey50)
                  : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
              ),
              const SizedBox(width: 4),
              Text(
                '重置',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: resetEnabled
                    ? (isDark ? WebTheme.darkGrey100 : WebTheme.grey50)
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