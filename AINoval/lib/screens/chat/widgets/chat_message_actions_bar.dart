import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

/// 通用的消息操作栏组件
/// - 默认提供“复制”操作，复制整条消息文本
/// - 支持扩展更多自定义操作
/// - 自适应浅/深色主题
class ChatMessageActionsBar extends StatelessWidget {
  const ChatMessageActionsBar({
    super.key,
    required this.textToCopy,
    this.alignEnd = false,
    this.actions = const [],
    this.compact = true,
  });

  /// 要复制的完整文本
  final String textToCopy;

  /// 是否尾对齐（用户消息用右对齐，AI 消息用左对齐）
  final bool alignEnd;

  /// 额外自定义操作（可选）
  final List<Widget> actions;

  /// 紧凑模式（更小的尺寸与间距）
  final bool compact;

  void _copyToClipboard(BuildContext context) async {
    if (textToCopy.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: textToCopy));
    TopToast.success(context, '已复制到剪贴板');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurfaceVariant;
    final hoverColor = colorScheme.surfaceContainerHighest.withOpacity(0.6);

    return Padding(
      padding: EdgeInsets.only(top: compact ? 4.0 : 8.0),
      child: Row(
        mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 4 : 6,
              vertical: compact ? 2 : 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 复制按钮（默认提供）
                _IconActionButton(
                  icon: Icons.copy_rounded,
                  tooltip: '复制整条消息',
                  iconColor: iconColor,
                  hoverColor: hoverColor,
                  onPressed: () => _copyToClipboard(context),
                  compact: compact,
                ),
                // 分隔与扩展动作
                if (actions.isNotEmpty) ...[
                  SizedBox(width: compact ? 2 : 4),
                  ..._intersperse(actions, SizedBox(width: compact ? 2 : 4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> list, Widget separator) {
    if (list.isEmpty) return list;
    final result = <Widget>[];
    for (var i = 0; i < list.length; i++) {
      if (i > 0) result.add(separator);
      result.add(list[i]);
    }
    return result;
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.iconColor,
    required this.hoverColor,
    required this.onPressed,
    required this.compact,
  });

  final IconData icon;
  final String tooltip;
  final Color iconColor;
  final Color hoverColor;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          hoverColor: hoverColor,
          child: Padding(
            padding: EdgeInsets.all(compact ? 6 : 8),
            child: Icon(
              icon,
              size: compact ? 16 : 18,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}




