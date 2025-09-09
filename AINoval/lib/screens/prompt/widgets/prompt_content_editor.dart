import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_bloc.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_state.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_event.dart';
import 'package:ainoval/models/prompt_models.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

/// 提示词内容编辑器
class PromptContentEditor extends StatefulWidget {
  const PromptContentEditor({
    super.key,
    required this.prompt,
  });

  final UserPromptInfo prompt;

  @override
  State<PromptContentEditor> createState() => _PromptContentEditorState();
}

class _PromptContentEditorState extends State<PromptContentEditor> {
  late TextEditingController _systemPromptController;
  late TextEditingController _userPromptController;
  late FocusNode _systemPromptFocusNode;
  late FocusNode _userPromptFocusNode;
  bool _isEdited = false;
  String _lastFocusedField = 'user'; // 'system' or 'user'

  bool get _isReadOnlyTemplate =>
      widget.prompt.id.startsWith('system_default_') ||
      widget.prompt.id.startsWith('public_');

  @override
  void initState() {
    super.initState();
    _systemPromptController = TextEditingController(text: widget.prompt.systemPrompt ?? '');
    _userPromptController = TextEditingController(text: widget.prompt.userPrompt);
    _systemPromptFocusNode = FocusNode();
    _userPromptFocusNode = FocusNode();
    
    // 监听焦点变化
    _systemPromptFocusNode.addListener(() {
      if (_systemPromptFocusNode.hasFocus) {
        _lastFocusedField = 'system';
      }
    });
    _userPromptFocusNode.addListener(() {
      if (_userPromptFocusNode.hasFocus) {
        _lastFocusedField = 'user';
      }
    });
  }

  @override
  void didUpdateWidget(PromptContentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prompt.id != widget.prompt.id) {
      _systemPromptController.text = widget.prompt.systemPrompt ?? '';
      _userPromptController.text = widget.prompt.userPrompt;
      _isEdited = false;
    }
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    _userPromptController.dispose();
    _systemPromptFocusNode.dispose();
    _userPromptFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: WebTheme.getSurfaceColor(context),
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 占位符提示
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPlaceholderChips(),
              ),
              
              // 左右编辑器布局
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 系统提示词编辑器 - 左侧
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.only(left: 16, right: 8, bottom: 16),
                        child: _buildSystemPromptEditor(),
                      ),
                    ),
                    
                    // 分割线
                    Container(
                      width: 1,
                      color: WebTheme.isDarkMode(context) 
                          ? WebTheme.darkGrey200 
                          : WebTheme.grey200,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    
                    // 用户提示词编辑器 - 右侧
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.only(left: 8, right: 16, bottom: 16),
                        child: _buildUserPromptEditor(),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 保存按钮（系统/公共模板不显示）
              if (!_isReadOnlyTemplate && _isEdited)
                Container(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: _buildSaveButton(),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 构建占位符提示
  Widget _buildPlaceholderChips() {
    return BlocBuilder<PromptNewBloc, PromptNewState>(
      builder: (context, state) {
        // 获取当前功能类型的占位符数据
        final placeholders = _getPlaceholdersForCurrentFeature(state);
        
        if (placeholders.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '可用占位符',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: WebTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: placeholders.map((placeholder) => _buildPlaceholderChip(placeholder)).toList(),
            ),
          ],
        );
      },
    );
  }

  /// 构建占位符芯片
  Widget _buildPlaceholderChip(String placeholder) {
    final isDark = WebTheme.isDarkMode(context);
    final primaryColor = WebTheme.getPrimaryColor(context);
    final description = _getPlaceholderDescription(placeholder);
    
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      child: Tooltip(
        message: description,
        child: Material(
          color: isDark 
              ? primaryColor.withOpacity(0.15)
              : primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _insertPlaceholder(placeholder),
            onLongPress: () => _copyPlaceholder(placeholder),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark 
                      ? primaryColor.withOpacity(0.3)
                      : primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.code,
                    size: 14,
                    color: isDark ? primaryColor.withOpacity(0.8) : primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '{{$placeholder}}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? primaryColor.withOpacity(0.9) : primaryColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.touch_app_outlined,
                    size: 12,
                    color: isDark 
                        ? primaryColor.withOpacity(0.6) 
                        : primaryColor.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建系统提示词编辑器
  Widget _buildSystemPromptEditor() {
    final isDark = WebTheme.isDarkMode(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.settings_system_daydream_outlined,
              size: 18,
              color: WebTheme.getTextColor(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '系统提示词 (System Prompt)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '设置AI的角色、行为规则和基本约束条件',
          style: TextStyle(
            fontSize: 12,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _systemPromptFocusNode.hasFocus
                    ? WebTheme.getPrimaryColor(context).withOpacity(0.5)
                    : (isDark ? WebTheme.darkGrey300 : WebTheme.grey300),
                width: _systemPromptFocusNode.hasFocus ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isDark ? WebTheme.darkGrey50 : WebTheme.white,
            ),
            child: TextField(
              controller: _systemPromptController,
              focusNode: _systemPromptFocusNode,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              readOnly: _isReadOnlyTemplate,
              decoration: InputDecoration(
                hintText: '输入系统提示词...\n\n例如：你是一个专业的小说创作助手，请遵循以下原则：\n1. 保持情节连贯性\n2. 角色性格一致\n3. 语言风格统一',
                hintStyle: TextStyle(
                  color: WebTheme.getSecondaryTextColor(context),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: WebTheme.getTextColor(context),
              ),
              onChanged: (value) {
                if (!_isReadOnlyTemplate) {
                  setState(() {
                    _isEdited = true;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 构建用户提示词编辑器
  Widget _buildUserPromptEditor() {
    final isDark = WebTheme.isDarkMode(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 18,
              color: WebTheme.getTextColor(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '用户提示词 (User Prompt)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '包含具体的任务指令和要求，可以使用占位符来动态插入内容',
          style: TextStyle(
            fontSize: 12,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _userPromptFocusNode.hasFocus
                    ? WebTheme.getPrimaryColor(context).withOpacity(0.5)
                    : (isDark ? WebTheme.darkGrey300 : WebTheme.grey300),
                width: _userPromptFocusNode.hasFocus ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isDark ? WebTheme.darkGrey50 : WebTheme.white,
            ),
            child: TextField(
              controller: _userPromptController,
              focusNode: _userPromptFocusNode,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              readOnly: _isReadOnlyTemplate,
              decoration: InputDecoration(
                hintText: '输入用户提示词...\n\n例如：请基于以下设定生成小说情节：\n\n角色：{{character_name}}\n背景：{{story_background}}\n情节要求：{{plot_requirements}}\n\n请确保：\n1. 情节符合角色性格\n2. 与背景设定保持一致\n3. 满足指定的情节要求',
                hintStyle: TextStyle(
                  color: WebTheme.getSecondaryTextColor(context),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: WebTheme.getTextColor(context),
              ),
              onChanged: (value) {
                if (!_isReadOnlyTemplate) {
                  setState(() {
                    _isEdited = true;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save, size: 16),
        label: const Text('保存更改'),
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  /// 插入占位符
  void _insertPlaceholder(String placeholder) {
    if (_isReadOnlyTemplate) return;
    TextEditingController targetController;
    
    // 根据最后焦点的字段决定插入位置
    if (_lastFocusedField == 'system') {
      targetController = _systemPromptController;
    } else {
      targetController = _userPromptController;
    }
    
    final currentSelection = targetController.selection;
    final currentText = targetController.text;
    final placeholderText = '{{$placeholder}}';
    
    String newText;
    int newCursorPosition;
    
    if (currentSelection.isValid) {
      // 在光标位置插入
      final before = currentText.substring(0, currentSelection.start);
      final after = currentText.substring(currentSelection.end);
      newText = before + placeholderText + after;
      newCursorPosition = currentSelection.start + placeholderText.length;
    } else {
      // 在末尾插入
      newText = currentText + placeholderText;
      newCursorPosition = newText.length;
    }
    
    targetController.text = newText;
    targetController.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursorPosition),
    );
    
    setState(() {
      _isEdited = true;
    });
  }
  
  /// 复制占位符到剪贴板
  void _copyPlaceholder(String placeholder) {
    final placeholderText = '{{$placeholder}}';
    Clipboard.setData(ClipboardData(text: placeholderText));
    TopToast.success(context, '已复制 $placeholderText 到剪贴板');
  }

  /// 保存更改
  void _saveChanges() {
    if (_isReadOnlyTemplate) return;
    final request = UpdatePromptTemplateRequest(
      systemPrompt: _systemPromptController.text.trim(),
      userPrompt: _userPromptController.text.trim(),
    );

    context.read<PromptNewBloc>().add(UpdatePromptDetails(
      promptId: widget.prompt.id,
      request: request,
    ));

    setState(() {
      _isEdited = false;
    });
  }

  /// 从当前状态获取功能类型的占位符
  List<String> _getPlaceholdersForCurrentFeature(PromptNewState state) {
    // 获取当前选中提示词的功能类型
    final selectedFeatureType = state.selectedFeatureType;
    if (selectedFeatureType == null) {
      return [];
    }

    // 从 PromptPackage 中获取支持的占位符
    final package = state.promptPackages[selectedFeatureType];
    if (package == null) {
      return [];
    }

    return package.supportedPlaceholders.toList()..sort();
  }

  /// 获取占位符描述
  String _getPlaceholderDescription(String placeholder) {
    final state = BlocProvider.of<PromptNewBloc>(context).state;
    final selectedFeatureType = state.selectedFeatureType;
    
    if (selectedFeatureType != null) {
      final package = state.promptPackages[selectedFeatureType];
      final description = package?.placeholderDescriptions[placeholder];
      if (description != null && description.isNotEmpty) {
        return _enhanceDescription(placeholder, description, selectedFeatureType.toString());
      }
    }
    
    return _getDefaultDescription(placeholder);
  }
  
  /// 增强占位符描述，添加上下文关系说明
  String _enhanceDescription(String placeholder, String baseDescription, String featureType) {
    String contextInfo = '';
    
    // 分析占位符类型并添加上下文关系说明
    if (placeholder.contains('character')) {
      contextInfo = '\n\n🎭 角色上下文：\n• 与角色设定、性格特征相关\n• 可能包含多个角色的层级关系\n• 支持主角、配角、反派等分类';
    } else if (placeholder.contains('setting') || placeholder.contains('background')) {
      contextInfo = '\n\n🌍 设定上下文：\n• 与世界观、背景设定相关\n• 可能包含时代、地理、社会等层级\n• 支持主设定和子设定的嵌套关系';
    } else if (placeholder.contains('plot') || placeholder.contains('story')) {
      contextInfo = '\n\n📖 情节上下文：\n• 与故事情节、剧情发展相关\n• 可能包含主线、支线的层级关系\n• 支持章节、场景等结构化内容';
    } else if (placeholder.contains('dialogue') || placeholder.contains('conversation')) {
      contextInfo = '\n\n💬 对话上下文：\n• 与角色对话、交互相关\n• 可能包含说话者、语调等层级\n• 支持内心独白、旁白等分类';
    } else if (placeholder.contains('emotion') || placeholder.contains('mood')) {
      contextInfo = '\n\n💭 情感上下文：\n• 与情感表达、氛围营造相关\n• 可能包含角色情感、环境氛围等层级\n• 支持正面、负面、复杂情感等分类';
    } else if (placeholder.contains('action') || placeholder.contains('behavior')) {
      contextInfo = '\n\n⚡ 行为上下文：\n• 与角色行为、动作描述相关\n• 可能包含物理动作、心理活动等层级\n• 支持主动、被动、反应式行为等分类';
    }
    
    String usageHint = '\n\n💡 使用提示：\n• 单击插入到光标位置\n• 长按复制到剪贴板\n• 格式：{{' + placeholder + '}}';
    
    return baseDescription + contextInfo + usageHint;
  }
  
  /// 获取默认占位符描述
  String _getDefaultDescription(String placeholder) {
    final Map<String, String> defaultDescriptions = {
      'character_name': '角色名称',
      'character_description': '角色描述',
      'story_background': '故事背景',
      'plot_requirements': '情节要求',
      'scene_description': '场景描述',
      'dialogue_content': '对话内容',
      'emotion_description': '情感描述',
      'action_description': '行为描述',
      'setting_details': '设定详情',
      'context_information': '上下文信息',
    };
    
    final baseDescription = defaultDescriptions[placeholder] ?? '占位符：$placeholder';
    return _enhanceDescription(placeholder, baseDescription, 'unknown');
  }
} 