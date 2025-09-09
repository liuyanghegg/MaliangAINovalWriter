import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 文本编辑器操作按钮类型
enum EditorAction {
  expand,  // 展开
  copy,    // 复制
}

/// 自定义文本编辑器组件
/// 支持多行文本编辑、占位符和操作按钮
class CustomTextEditor extends StatefulWidget {
  /// 构造函数
  const CustomTextEditor({
    super.key,
    this.controller,
    this.placeholder = '请输入内容...',
    this.minLines = 3,
    this.maxLines = 10,
    this.showActions = true,
    this.actions = const [EditorAction.expand, EditorAction.copy],
    this.onExpand,
    this.onCopy,
    this.enabled = true,
    this.readOnly = false,
  });

  /// 文本控制器
  final TextEditingController? controller;

  /// 占位符文字
  final String placeholder;

  /// 最小行数
  final int minLines;

  /// 最大行数
  final int maxLines;

  /// 是否显示操作按钮
  final bool showActions;

  /// 操作按钮列表
  final List<EditorAction> actions;

  /// 展开回调
  final VoidCallback? onExpand;

  /// 复制回调
  final VoidCallback? onCopy;

  /// 是否启用
  final bool enabled;

  /// 是否只读
  final bool readOnly;

  @override
  State<CustomTextEditor> createState() => _CustomTextEditorState();
}

class _CustomTextEditorState extends State<CustomTextEditor> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);

    return Column(
      children: [
        // 文本输入区域
        Container(
          constraints: BoxConstraints(
            minHeight: widget.minLines * 24.0,
            maxHeight: widget.maxLines * 24.0,
          ),
          decoration: BoxDecoration(
            color: widget.enabled
                ? Theme.of(context).colorScheme.surfaceContainer
                : Theme.of(context).colorScheme.surfaceContainer,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: null,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: _controller.text.isEmpty ? widget.placeholder : null,
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              isDense: true,
            ),
          ),
        ),

        // 操作按钮区域
        if (widget.showActions && widget.actions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.actions.map((action) => _buildActionButton(context, action, isDark)).toList(),
            ),
          ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton(BuildContext context, EditorAction action, bool isDark) {
    IconData icon;
    String label;
    VoidCallback? onPressed;
    bool enabled = widget.enabled && !widget.readOnly;

    switch (action) {
      case EditorAction.expand:
        icon = Icons.open_in_full;
        label = '展开';
        onPressed = enabled ? widget.onExpand : null;
        break;
      case EditorAction.copy:
        icon = Icons.content_copy;
        label = '复制';
        onPressed = enabled ? widget.onCopy : null;
        // 复制功能在有内容时才启用
        enabled = enabled && _controller.text.isNotEmpty;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 12,
                  color: enabled
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 