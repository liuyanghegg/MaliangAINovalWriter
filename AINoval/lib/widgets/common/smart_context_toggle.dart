import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 智能上下文勾选组件
/// 用于控制是否启用RAG智能检索上下文
class SmartContextToggle extends StatelessWidget {
  /// 构造函数
  const SmartContextToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.title = '智能上下文',
    this.description = '使用AI自动检索相关背景信息',
    this.enabled = true,
  });

  /// 当前状态
  final bool value;
  
  /// 状态改变回调
  final ValueChanged<bool> onChanged;
  
  /// 标题
  final String title;
  
  /// 描述
  final String description;
  
  /// 是否启用
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 勾选框和标题行
          Row(
            children: [
              // 自定义勾选框
              GestureDetector(
                onTap: enabled ? () => onChanged(!value) : null,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: enabled
                          ? (value ? colorScheme.primary : Theme.of(context).colorScheme.outlineVariant)
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: 1.5,
                    ),
                    color: enabled && value 
                        ? colorScheme.primary 
                        : Colors.transparent,
                  ),
                  child: enabled && value
                      ? Icon(
                          Icons.check,
                          size: 12,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              
              // 标题和智能标识
              Expanded(
                child: GestureDetector(
                  onTap: enabled ? () => onChanged(!value) : null,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: enabled
                              ? (isDark ? WebTheme.darkGrey800 : WebTheme.grey800)
                              : (isDark ? WebTheme.darkGrey500 : WebTheme.grey500),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // AI智能标识
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: enabled
                                ? [
                                    colorScheme.primary.withOpacity(0.85),
                                    colorScheme.secondary.withOpacity(0.85),
                                  ]
                                : [
                                    colorScheme.onSurfaceVariant.withOpacity(0.25),
                                    colorScheme.onSurfaceVariant.withOpacity(0.25),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 10,
                              color: enabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'AI',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: enabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 信息提示图标
              Tooltip(
                message: _getTooltipMessage(),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDark ? WebTheme.darkGrey500 : WebTheme.grey500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 描述文本
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: enabled
                  ? (isDark ? WebTheme.darkGrey600 : WebTheme.grey600)
                  : (isDark ? WebTheme.darkGrey500 : WebTheme.grey500),
              height: 1.4,
            ),
          ),
          
          // 启用状态下的额外说明
          if (enabled && value) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 12,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'AI将自动搜索相关的角色、场景、设定等背景信息',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// 获取提示信息
  String _getTooltipMessage() {
    return '''智能上下文功能说明：
• 启用后，AI会自动检索相关背景信息
• 包括相关角色、场景、设定等内容
• 提升AI生成内容的准确性和连贯性
• 可能会增加一定的处理时间''';
  }
} 