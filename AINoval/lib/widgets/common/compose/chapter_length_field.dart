import 'package:flutter/material.dart';

class ChapterLengthField extends StatefulWidget {
  final String? preset; // 'short' | 'medium' | 'long' | null
  final String? customLength;
  final ValueChanged<String?> onPresetChanged;
  final ValueChanged<String> onCustomChanged;
  final String title;
  final String description;

  const ChapterLengthField({
    super.key,
    this.preset,
    this.customLength,
    required this.onPresetChanged,
    required this.onCustomChanged,
    this.title = '每章长度',
    this.description = '每章期望长度（短/中/长）或自定义字数',
  });

  @override
  State<ChapterLengthField> createState() => _ChapterLengthFieldState();
}

class _ChapterLengthFieldState extends State<ChapterLengthField> {
  late TextEditingController _controller;
  String? _preset;

  @override
  void initState() {
    super.initState();
    _preset = widget.preset;
    _controller = TextEditingController(text: widget.customLength ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(widget.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('短'),
              selected: _preset == 'short',
              onSelected: (_) {
                setState(() { _preset = 'short'; _controller.clear(); });
                widget.onPresetChanged('short');
              },
            ),
            ChoiceChip(
              label: const Text('中'),
              selected: _preset == 'medium',
              onSelected: (_) {
                setState(() { _preset = 'medium'; _controller.clear(); });
                widget.onPresetChanged('medium');
              },
            ),
            ChoiceChip(
              label: const Text('长'),
              selected: _preset == 'long',
              onSelected: (_) {
                setState(() { _preset = 'long'; _controller.clear(); });
                widget.onPresetChanged('long');
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '自定义字数，如 2000 字',
          ),
          onChanged: (v) {
            setState(() { _preset = null; });
            widget.onCustomChanged(v);
          },
        ),
      ],
    );
  }
}



