import 'package:flutter/material.dart';
// import 'package:ainoval/utils/web_theme.dart';

/// 对话框标题栏组件
/// 包含标题文字和关闭按钮
class DialogHeader extends StatelessWidget {
  /// 构造函数
  const DialogHeader({
    super.key,
    required this.title,
    this.onClose,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 6),
  });

  /// 标题文字
  final String title;

  /// 关闭回调
  final VoidCallback? onClose;

  /// 内边距
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // final isDark = WebTheme.isDarkMode(context);

    return Container(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 标题
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          
          // 关闭按钮
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onClose ?? () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '关闭',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 