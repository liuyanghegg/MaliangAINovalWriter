import 'package:flutter/material.dart';

class ChapterCountField extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String title;
  final String description;

  const ChapterCountField({
    super.key,
    required this.value,
    this.min = 1,
    this.max = 12,
    required this.onChanged,
    this.title = '章节数量',
    this.description = '生成的章节数（黄金三章=3，可自定义）',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min),
                value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
                label: '$value',
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text('$value', textAlign: TextAlign.center),
            ),
          ],
        ),
      ],
    );
  }
}



