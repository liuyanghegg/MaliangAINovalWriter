import 'package:flutter/material.dart';
import 'package:ainoval/widgets/editor/slash_command_menu.dart';

/// 斜杠命令覆盖层
/// 用于在编辑器上显示命令选择菜单
class SlashCommandOverlay {
  static OverlayEntry? _overlayEntry;

  /// 显示斜杠命令菜单
  static void show({
    required BuildContext context,
    required Offset position,
    required Function(SlashCommandType) onCommandSelected,
    required VoidCallback onDismiss,
    required List<SlashCommandType> availableCommands,
  }) {
    // 如果已经显示了菜单，先隐藏
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy,
        child: Material(
          color: Colors.transparent,
          child: SlashCommandMenu(
            position: position,
            onCommandSelected: onCommandSelected,
            onDismiss: onDismiss,
            availableCommands: availableCommands,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 隐藏斜杠命令菜单
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 检查是否正在显示菜单
  static bool get isShowing => _overlayEntry != null;
} 