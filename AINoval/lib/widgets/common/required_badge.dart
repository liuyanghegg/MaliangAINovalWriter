import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 必填字段标识组件
/// 用于标识表单中的必填字段
class RequiredBadge extends StatelessWidget {
  /// 构造函数
  const RequiredBadge({
    super.key,
    this.text = 'Required',
  });

  /// 显示文本
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? Colors.red.shade700 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.red.shade300 : Colors.red.shade700,
        ),
      ),
    );
  }
} 