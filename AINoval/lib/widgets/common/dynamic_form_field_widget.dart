import 'package:flutter/material.dart';
import 'package:ainoval/models/ai_feature_form_config.dart';
import 'package:ainoval/models/context_selection_models.dart';
import 'package:ainoval/widgets/common/index.dart';
import 'package:ainoval/widgets/common/multi_select_instructions_with_presets.dart' as multi_select;
// import 'package:ainoval/utils/web_theme.dart';

/// 动态表单字段组件
/// 根据FormFieldConfig配置动态渲染对应的表单字段
class DynamicFormFieldWidget extends StatelessWidget {
  /// 字段配置
  final FormFieldConfig config;
  
  /// 当前值映射表
  final Map<AIFormFieldType, dynamic> values;
  
  /// 值变更回调
  final Function(AIFormFieldType type, dynamic value) onValueChanged;
  
  /// 重置回调
  final Function(AIFormFieldType type) onReset;
  
  /// 上下文选择数据（仅用于上下文选择字段）
  final ContextSelectionData? contextSelectionData;
  
  /// 控制器映射表（用于文本输入字段）
  final Map<AIFormFieldType, TextEditingController>? controllers;
  
  /// AI功能类型（用于提示词模板选择）
  final String? aiFeatureType;
  
  /// 当前编辑的预设是否为系统预设（用于模板过滤）
  final bool? isSystemPreset;
  
  /// 当前编辑的预设是否为公共预设（用于模板过滤）
  final bool? isPublicPreset;

  const DynamicFormFieldWidget({
    super.key,
    required this.config,
    required this.values,
    required this.onValueChanged,
    required this.onReset,
    this.contextSelectionData,
    this.controllers,
    this.aiFeatureType,
    this.isSystemPreset,
    this.isPublicPreset,
  });

  @override
  Widget build(BuildContext context) {
    switch (config.type) {
      case AIFormFieldType.instructions:
        return _buildInstructionsField(context);
      case AIFormFieldType.length:
        return _buildLengthField(context);
      case AIFormFieldType.style:
        return _buildStyleField(context);
      case AIFormFieldType.contextSelection:
        return _buildContextSelectionField(context);
      case AIFormFieldType.smartContext:
        return _buildSmartContextField(context);
      case AIFormFieldType.promptTemplate:
        return _buildPromptTemplateField(context);
      case AIFormFieldType.temperature:
        return _buildTemperatureField(context);
      case AIFormFieldType.topP:
        return _buildTopPField(context);
      case AIFormFieldType.memoryCutoff:
        return _buildMemoryCutoffField(context);
      case AIFormFieldType.quickAccess:
        return _buildQuickAccessField(context);
      // 不需要 default：枚举已覆盖所有分支
    }
  }

  /// 构建指令字段
  Widget _buildInstructionsField(BuildContext context) {
    final controller = controllers?[config.type] ?? TextEditingController();
    final presets = _parseInstructionPresets(config.options?['presets']);
    
    if (presets.isNotEmpty) {
      // 如果有预设，使用多选指令组件
      return FormFieldFactory.createMultiSelectInstructionsWithPresetsField(
        controller: controller,
        presets: presets,
        title: config.title,
        description: config.description,
        placeholder: config.options?['placeholder'] ?? 'e.g. 输入指令...',
        dropdownPlaceholder: '选择指令预设',
        onReset: () => onReset(config.type),
        onExpand: () => _handleExpandInstructions(),
        onCopy: () => _handleCopyInstructions(),
        onSelectionChanged: (selectedPresets) => _handlePresetSelectionChanged(selectedPresets),
      );
    } else {
      // 如果没有预设，使用简单的指令字段
      return FormFieldFactory.createInstructionsField(
        controller: controller,
        title: config.title,
        description: config.description,
        placeholder: config.options?['placeholder'] ?? 'e.g. 输入指令...',
        onReset: () => onReset(config.type),
        onExpand: () => _handleExpandInstructions(),
        onCopy: () => _handleCopyInstructions(),
      );
    }
  }

  /// 构建长度字段
  Widget _buildLengthField(BuildContext context) {
    final radioOptions = _parseRadioOptions(config.options?['radioOptions']);
    final placeholder = config.options?['placeholder'] ?? 'e.g. 输入长度...';
    final controller = controllers?[config.type] ?? TextEditingController();
    
    return FormFieldFactory.createLengthField<String>(
      options: radioOptions,
      value: values[config.type] as String?,
      onChanged: (value) => onValueChanged(config.type, value),
      title: config.title,
      description: config.description,
      isRequired: config.isRequired,
      onReset: () => onReset(config.type),
      alternativeInput: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 40),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            fillColor: Theme.of(context).colorScheme.surfaceContainer,
            filled: true,
          ),
          onChanged: (value) {
            onValueChanged(config.type, null); // 清除单选按钮选择
          },
        ),
      ),
    );
  }

  /// 构建重构方式字段
  Widget _buildStyleField(BuildContext context) {
    final radioOptions = _parseRadioOptions(config.options?['radioOptions']);
    final placeholder = config.options?['placeholder'] ?? 'e.g. 输入样式...';
    final controller = controllers?[config.type] ?? TextEditingController();
    
    return FormFieldFactory.createLengthField<String>(
      options: radioOptions,
      value: values[config.type] as String?,
      onChanged: (value) => onValueChanged(config.type, value),
      title: config.title,
      description: config.description,
      onReset: () => onReset(config.type),
      alternativeInput: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 40),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            fillColor: Theme.of(context).colorScheme.surfaceContainer,
            filled: true,
            isDense: true,
          ),
          onChanged: (value) {
            onValueChanged(config.type, null); // 清除单选按钮选择
          },
        ),
      ),
    );
  }

  /// 构建上下文选择字段
  Widget _buildContextSelectionField(BuildContext context) {
    if (contextSelectionData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '上下文选择数据未提供',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return FormFieldFactory.createContextSelectionField(
      contextData: contextSelectionData!,
      onSelectionChanged: (newData) => onValueChanged(config.type, newData),
      title: config.title,
      description: config.description,
      onReset: () => onReset(config.type),
      dropdownWidth: 400,
      initialChapterId: null,
      initialSceneId: null,
    );
  }

  /// 构建智能上下文字段
  Widget _buildSmartContextField(BuildContext context) {
    return SmartContextToggle(
      value: values[config.type] as bool? ?? true,
      onChanged: (value) => onValueChanged(config.type, value),
      title: config.title,
      description: config.description,
    );
  }

  /// 构建提示词模板字段
  Widget _buildPromptTemplateField(BuildContext context) {
    // 获取AI功能类型，如果没有提供则默认为TEXT_EXPANSION
    final featureType = aiFeatureType ?? 'TEXT_EXPANSION';
    
    // 根据预设类型确定允许的模板类型
    // 系统预设：允许 系统默认 + 私有；禁止 公共
    // 公共预设：允许 系统默认 + 公共(仅已验证)；禁止 私有
    // 用户预设：允许全部（系统默认 + 私有 + 公共）
    Set<PromptTemplateType>? allowedTypes;
    bool onlyVerifiedPublic = false;
    if (isSystemPreset == true) {
      allowedTypes = {PromptTemplateType.system, PromptTemplateType.private};
      onlyVerifiedPublic = false;
    } else if (isPublicPreset == true) {
      allowedTypes = {PromptTemplateType.system, PromptTemplateType.public};
      onlyVerifiedPublic = true;
    } else {
      allowedTypes = {PromptTemplateType.system, PromptTemplateType.private, PromptTemplateType.public};
      onlyVerifiedPublic = false;
    }
    
    return FormFieldFactory.createPromptTemplateSelectionField(
      selectedTemplateId: values[config.type] as String?,
      onTemplateSelected: (templateId) => onValueChanged(config.type, templateId),
      aiFeatureType: featureType,
      allowedTypes: allowedTypes,
      onlyVerifiedPublic: onlyVerifiedPublic,
      title: config.title,
      description: config.description,
      onReset: () => onReset(config.type),
      onTemporaryPromptsSaved: (sys, user) {
        // 将临时提示词放入 values 的扩展槽位（若业务侧读取，需要自定义键）
        onValueChanged(config.type, values[config.type]);
        // 通过额外键把自定义提示词也放入values，供表单容器在提交时拼接到请求parameters
        onValueChanged(AIFormFieldType.promptTemplate, values[config.type]);
        values[AIFormFieldType.promptTemplate] = values[config.type];
        values[AIFormFieldType.instructions] = values[AIFormFieldType.instructions];
        // 不在此层直接发送请求，仅存储由上层容器读取
      },
    );
  }

  /// 构建温度字段
  Widget _buildTemperatureField(BuildContext context) {
    return FormFieldFactory.createTemperatureSliderField(
      context: context,
      value: values[config.type] as double? ?? 0.7,
      onChanged: (value) => onValueChanged(config.type, value),
      onReset: () => onReset(config.type),
    );
  }

  /// 构建Top-P字段
  Widget _buildTopPField(BuildContext context) {
    return FormFieldFactory.createTopPSliderField(
      context: context,
      value: values[config.type] as double? ?? 0.9,
      onChanged: (value) => onValueChanged(config.type, value),
      onReset: () => onReset(config.type),
    );
  }

  /// 构建记忆截断字段
  Widget _buildMemoryCutoffField(BuildContext context) {
    final radioOptions = _parseRadioIntOptions(config.options?['radioOptions']);
    final placeholder = config.options?['placeholder'] ?? 'e.g. 24';
    final controller = controllers?[config.type] ?? TextEditingController();
    
    return FormFieldFactory.createMemoryCutoffField(
      options: radioOptions,
      value: values[config.type] as int?,
      onChanged: (value) => onValueChanged(config.type, value),
      title: config.title,
      description: config.description,
      customInput: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: placeholder,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          fillColor: Theme.of(context).colorScheme.surfaceContainer,
          filled: true,
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          final intValue = int.tryParse(value);
          if (intValue != null) {
            onValueChanged(config.type, null); // 清除单选按钮选择
          }
        },
      ),
      onReset: () => onReset(config.type),
    );
  }

  /// 构建快捷访问字段
  Widget _buildQuickAccessField(BuildContext context) {
    return FormFieldFactory.createQuickAccessToggleField(
      value: values[config.type] as bool? ?? false,
      onChanged: (value) => onValueChanged(config.type, value),
      title: config.title,
      description: config.description,
      onReset: () => onReset(config.type),
    );
  }

  // 已移除未使用的不支持字段提示构建函数

  // 工具方法

  /// 解析指令预设
  List<multi_select.InstructionPreset> _parseInstructionPresets(dynamic presets) {
    if (presets is! List) return [];
    
    return presets.map<multi_select.InstructionPreset>((preset) {
      if (preset is Map<String, dynamic>) {
        return multi_select.InstructionPreset(
          id: preset['id'] as String? ?? '',
          title: preset['title'] as String? ?? '',
          content: preset['content'] as String? ?? '',
          description: preset['description'] as String?,
        );
      }
      return const multi_select.InstructionPreset(
        id: '',
        title: '',
        content: '',
      );
    }).toList();
  }

  /// 解析单选按钮选项（字符串值）
  List<RadioOption<String>> _parseRadioOptions(dynamic options) {
    if (options is! List) return [];
    
    return options.map<RadioOption<String>>((option) {
      if (option is Map<String, dynamic>) {
        return RadioOption<String>(
          value: option['value'] as String? ?? '',
          label: option['label'] as String? ?? '',
        );
      }
      return const RadioOption<String>(value: '', label: '');
    }).toList();
  }

  /// 解析单选按钮选项（整数值）
  List<RadioOption<int>> _parseRadioIntOptions(dynamic options) {
    if (options is! List) return [];
    
    return options.map<RadioOption<int>>((option) {
      if (option is Map<String, dynamic>) {
        return RadioOption<int>(
          value: option['value'] as int? ?? 0,
          label: option['label'] as String? ?? '',
        );
      }
      return const RadioOption<int>(value: 0, label: '');
    }).toList();
  }

  // 事件处理器

  void _handleExpandInstructions() {
    debugPrint('展开指令编辑器');
  }

  void _handleCopyInstructions() {
    debugPrint('复制指令内容');
  }

  void _handlePresetSelectionChanged(List<multi_select.InstructionPreset> selectedPresets) {
    debugPrint('选中的预设已改变: ${selectedPresets.map((p) => p.title).join(', ')}');
  }
} 