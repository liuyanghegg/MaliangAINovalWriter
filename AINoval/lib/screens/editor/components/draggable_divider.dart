import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 可拖拽的分隔条组件
class DraggableDivider extends StatefulWidget {
  const DraggableDivider({
    super.key,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final Function(DragUpdateDetails) onDragUpdate;
  final Function(DragEndDetails) onDragEnd;

  @override
  State<DraggableDivider> createState() => _DraggableDividerState();
}

class _DraggableDividerState extends State<DraggableDivider> {
  bool _isDragging = false;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onHorizontalDragStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onHorizontalDragUpdate: widget.onDragUpdate,
        onHorizontalDragEnd: (details) {
          setState(() {
            _isDragging = false;
          });
          widget.onDragEnd(details);
        },
        child: Container(
          width: 8,
          height: double.infinity,
          // 🚀 修复：使用WebTheme动态背景色
          color: _isDragging
              ? WebTheme.getPrimaryColor(context).withOpacity(0.1)
              : _isHovering
                  ? WebTheme.isDarkMode(context) ? WebTheme.darkGrey200 : WebTheme.grey200
                  : WebTheme.getSurfaceColor(context),
          child: Center(
            child: Container(
              width: 1,
              height: double.infinity,
              // 🚀 修复：使用WebTheme动态分割线颜色
              color: _isDragging
                  ? WebTheme.getPrimaryColor(context)
                  : _isHovering
                      ? WebTheme.isDarkMode(context) ? WebTheme.darkGrey400 : WebTheme.grey400
                      : WebTheme.isDarkMode(context) ? WebTheme.darkGrey300 : WebTheme.grey300,
            ),
          ),
        ),
      ),
    );
  }
}
