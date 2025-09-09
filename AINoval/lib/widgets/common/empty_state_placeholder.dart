import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 空状态占位符
class EmptyStatePlaceholder extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 标题
  final String title;

  /// 消息
  final String message;

  /// 操作按钮
  final Widget? action;

  const EmptyStatePlaceholder({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context), // 🚀 修复：使用动态表面色
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: WebTheme.isDarkMode(context) ? Colors.black.withAlpha(50) : Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: WebTheme.getSecondaryTextColor(context), // 🚀 修复：使用动态颜色
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: WebTheme.getTextColor(context), // 🚀 修复：使用动态文本色
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: WebTheme.getSecondaryTextColor(context), // 🚀 修复：使用动态次要文本色
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}
