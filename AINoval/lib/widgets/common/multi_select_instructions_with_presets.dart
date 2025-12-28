import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'custom_text_editor.dart';

/// 指令预设选项
class InstructionPreset {
  /// 构造函数
  const InstructionPreset({
    required this.id,
    required this.title,
    required this.content,
    this.description,
  });

  /// 唯一标识
  final String id;
  
  /// 显示标题
  final String title;
  
  /// 指令内容
  final String content;
  
  /// 描述
  final String? description;

  @override
  bool operator ==(Object other) => 
      identical(this, other) || 
      other is InstructionPreset && 
      runtimeType == other.runtimeType && 
      id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 多选指令预设组件
/// 类似于HTML中的多选下拉框，支持选择多个预设
/// 选中的预设以badges/chips形式显示
class MultiSelectInstructionsWithPresets extends StatefulWidget {
  /// 构造函数
  const MultiSelectInstructionsWithPresets({
    super.key,
    this.controller,
    this.presets = const [],
    this.placeholder = 'e.g. You are a...',
    this.dropdownPlaceholder = 'Select Instructions...',
    this.onExpand,
    this.onCopy,
    this.onSelectionChanged,
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

  /// 选择改变回调
  final ValueChanged<List<InstructionPreset>>? onSelectionChanged;

  @override
  State<MultiSelectInstructionsWithPresets> createState() => _MultiSelectInstructionsWithPresetsState();
}

class _MultiSelectInstructionsWithPresetsState extends State<MultiSelectInstructionsWithPresets> {
  final Set<InstructionPreset> _selectedPresets = <InstructionPreset>{};
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _dropdownKey = GlobalKey();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 第一行：多选下拉框
        if (widget.presets.isNotEmpty) ...[
          _buildMultiSelectDropdown(),
          const SizedBox(height: 8),
        ],
        
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

  /// 构建多选下拉框
  Widget _buildMultiSelectDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _dropdownKey,
        onTap: _toggleDropdown,
        child: Container(
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                // 选中的badges区域
                Expanded(
                  child: _selectedPresets.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            widget.dropdownPlaceholder,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? WebTheme.darkGrey400 : WebTheme.grey500,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              ..._selectedPresets.map((preset) => _buildPresetBadge(preset)),
                            ],
                          ),
                        ),
                ),
                // 下拉箭头
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: isDark ? WebTheme.darkGrey400 : WebTheme.grey400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建预设badge
  Widget _buildPresetBadge(InstructionPreset preset) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF3A3A3A).withOpacity(0.8) 
            : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            preset.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark 
                  ? const Color(0xFFA1A1AA) 
                  : const Color(0xFF52525B),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removePreset(preset),
            child: Icon(
              Icons.close,
              size: 12,
              color: isDark 
                  ? const Color(0xFFA1A1AA) 
                  : const Color(0xFF52525B),
            ),
          ),
        ],
      ),
    );
  }

  /// 切换下拉菜单显示状态
  void _toggleDropdown() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  /// 显示下拉菜单覆盖层
  void _showOverlay() {
    final RenderBox? renderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final overlay = Overlay.of(context);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 透明背景，点击关闭
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          // 下拉菜单内容
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Container(
                width: size.width,
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: _buildDropdownContent(),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  /// 移除覆盖层
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 构建下拉菜单内容
  Widget _buildDropdownContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.presets.length,
      itemBuilder: (context, index) {
        final preset = widget.presets[index];
        final isSelected = _selectedPresets.contains(preset);
        
        return InkWell(
          onTap: () => _togglePreset(preset),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 复选框
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? WebTheme.darkGrey500 : WebTheme.grey400),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                
                const SizedBox(width: 12),
                
                // 预设信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? WebTheme.darkGrey100 : WebTheme.grey900,
                        ),
                      ),
                      if (preset.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          preset.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? WebTheme.darkGrey400 : WebTheme.grey600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 切换预设选择状态
  void _togglePreset(InstructionPreset preset) {
    setState(() {
      if (_selectedPresets.contains(preset)) {
        _selectedPresets.remove(preset);
      } else {
        _selectedPresets.add(preset);
      }
    });
    
    _updateInstructions();
    widget.onSelectionChanged?.call(_selectedPresets.toList());
  }

  /// 移除预设
  void _removePreset(InstructionPreset preset) {
    setState(() {
      _selectedPresets.remove(preset);
    });
    
    _updateInstructions();
    widget.onSelectionChanged?.call(_selectedPresets.toList());
  }

  /// 更新指令文本
  void _updateInstructions() {
    if (widget.controller != null && _selectedPresets.isNotEmpty) {
      final contents = _selectedPresets.map((preset) => preset.content).toList();
      final newText = contents.join('\n\n');
      
      // 只有当前文本为空或者只包含预设内容时才更新
      final currentText = widget.controller!.text.trim();
      if (currentText.isEmpty || _isOnlyPresetContent(currentText)) {
        widget.controller!.text = newText;
      } else {
        // 如果有自定义内容，追加到末尾
        widget.controller!.text = '$currentText\n\n$newText';
      }
    } else if (_selectedPresets.isEmpty && widget.controller != null) {
      // 如果没有选中任何预设，检查是否只有预设内容，如果是则清空
      final currentText = widget.controller!.text.trim();
      if (_isOnlyPresetContent(currentText)) {
        widget.controller!.clear();
      }
    }
  }

  /// 检查当前文本是否只包含预设内容
  bool _isOnlyPresetContent(String text) {
    if (text.isEmpty) return true;
    
    // 这里可以实现更复杂的逻辑来检测是否只包含预设内容
    // 暂时简化处理
    for (final preset in widget.presets) {
      if (text.contains(preset.content)) {
        return true;
      }
    }
    return false;
  }
} 