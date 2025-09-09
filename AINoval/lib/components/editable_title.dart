import 'dart:async';

import 'package:flutter/material.dart';

class Debouncer {

  Debouncer({this.delay = const Duration(milliseconds: 500)});
  Timer? _timer;
  final Duration delay;

  void run(Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class EditableTitle extends StatefulWidget {

  const EditableTitle({
    Key? key,
    required this.initialText,
    this.onChanged,
    this.onSubmitted,
    this.commitOnBlur = true,
    this.style,
    this.textAlign = TextAlign.left,
    this.autofocus = false,
  }) : super(key: key);
  final String initialText;
  // 可选：仅用于本地UI联动（不做持久化）
  final Function(String)? onChanged;
  // 提交时回调：回车或失焦触发
  final Function(String)? onSubmitted;
  // 失焦时是否提交
  final bool commitOnBlur;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool autofocus;

  @override
  State<EditableTitle> createState() => _EditableTitleState();
}

class _EditableTitleState extends State<EditableTitle> {
  late TextEditingController _controller;
  late Debouncer _debouncer;
  late FocusNode _focusNode;
  String _lastCommittedText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _debouncer = Debouncer();
    _focusNode = FocusNode();
    _lastCommittedText = widget.initialText;

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && widget.commitOnBlur) {
        _commitIfChanged();
      }
    });
  }

  @override
  void didUpdateWidget(EditableTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText) {
      _controller.text = widget.initialText;
      // 外部更新时同步已提交文本基线
      _lastCommittedText = widget.initialText;
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _commitIfChanged() {
    final current = _controller.text;
    if (current != _lastCommittedText) {
      _lastCommittedText = current;
      if (widget.onSubmitted != null) {
        widget.onSubmitted!(current);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: widget.style,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        textAlign: widget.textAlign,
        autofocus: widget.autofocus,
        // onChanged 仅用于本地UI联动（不持久化）
        onChanged: (value) {
          if (widget.onChanged != null) {
            _debouncer.run(() {
              widget.onChanged!(value);
            });
          }
        },
        // 按下回车时提交
        onSubmitted: (_) {
          _commitIfChanged();
        },
      ),
    );
  }
}