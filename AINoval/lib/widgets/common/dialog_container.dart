import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 对话框容器组件
/// 提供统一的对话框样式和布局
class DialogContainer extends StatelessWidget {
  /// 构造函数
  const DialogContainer({
    super.key,
    required this.child,
    this.maxWidth = 768, // 3xl in Tailwind
    this.height,
    this.padding = const EdgeInsets.all(0),
  });

  /// 子组件
  final Widget child;

  /// 最大宽度
  final double maxWidth;

  /// 高度（可选）
  final double? height;

  /// 内边距
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // final isDark = WebTheme.isDarkMode(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 640; // sm breakpoint

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 32,
        vertical: isSmallScreen ? 0 : 64,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: height ?? (isSmallScreen ? screenSize.height * 0.95 : screenSize.height * 0.8),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 8),
          boxShadow: [
            BoxShadow(
              color: WebTheme.getShadowColor(context, opacity: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  padding: padding,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 