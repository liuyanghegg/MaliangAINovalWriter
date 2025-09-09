import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'custom_text_editor.dart';

// 导入InstructionPreset定义
import 'multi_select_instructions_with_presets.dart' show InstructionPreset;

/// 带预设选项的指令字段组件
class InstructionsWithPresets extends StatefulWidget {
  /// 构造函数
  const InstructionsWithPresets({
    super.key,
    this.controller,
    this.presets = const [],
    this.placeholder = 'e.g. You are a...',
    this.dropdownPlaceholder = 'Select \'Instructions\'...',
    this.onExpand,
    this.onCopy,
  });

  /// 文本控制器
  final TextEditingController? controller;
  
  /// 预设选项列表
  final List<InstructionPreset> presets;
  
  /// 输入框占位符
  final String placeholder;
  
  /// 下拉框占位符
  final String dropdownPlaceholder;
  
  /// 展开回调
  final VoidCallback? onExpand;
  
  /// 复制回调
  final VoidCallback? onCopy;

  @override
  State<InstructionsWithPresets> createState() => _InstructionsWithPresetsState();
}

class _InstructionsWithPresetsState extends State<InstructionsWithPresets> {
  InstructionPreset? _selectedPreset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 第一行：预设选择器
        Row(
          children: [
            // 预设下拉选择器
            if (widget.presets.isNotEmpty) ...[
              Expanded(
                child: _buildPresetDropdown(),
              ),
              const SizedBox(width: 8),
              // AND 分隔符
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                height: 36,
                alignment: Alignment.center,
                child: Text(
                  'AND',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? WebTheme.darkGrey300
                        : WebTheme.grey600,
                  ),
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 第二行：文本编辑器
        CustomTextEditor(
          controller: widget.controller,
          placeholder: widget.placeholder,
          onExpand: widget.onExpand,
          onCopy: widget.onCopy,
        ),
      ],
    );
  }

  /// 构建预设下拉选择器
  Widget _buildPresetDropdown() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<InstructionPreset>(
          value: _selectedPreset,
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.dropdownPlaceholder,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? WebTheme.darkGrey400
                    : WebTheme.grey500,
              ),
            ),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? WebTheme.darkGrey400
                  : WebTheme.grey400,
            ),
          ),
          items: widget.presets.map((preset) => DropdownMenuItem<InstructionPreset>(
            value: preset,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    preset.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? WebTheme.darkGrey100
                          : WebTheme.grey900,
                    ),
                  ),
                  if (preset.description != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      preset.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? WebTheme.darkGrey400
                            : WebTheme.grey600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          )).toList(),
          onChanged: (preset) {
            setState(() {
              _selectedPreset = preset;
            });
            
            // 将预设内容填入文本编辑器
            if (preset != null && widget.controller != null) {
              final currentText = widget.controller!.text;
              final newText = currentText.isEmpty 
                  ? preset.content 
                  : '$currentText\n\n${preset.content}';
              widget.controller!.text = newText;
            }
          },
          dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
        ),
      ),
    );
  }
} 