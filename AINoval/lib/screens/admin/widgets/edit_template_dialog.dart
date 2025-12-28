import 'package:flutter/material.dart';

import '../../../models/prompt_models.dart';
import '../../../services/api_service/repositories/impl/admin_repository_templates_extension.dart';
import '../../../services/api_service/repositories/impl/admin_repository_impl.dart';
import '../../../utils/web_theme.dart';
import '../../../utils/logger.dart';
import '../../../widgets/common/dialog_container.dart';
import '../../../widgets/common/dialog_header.dart';

/// 编辑提示词模板对话框
class EditTemplateDialog extends StatefulWidget {
  final PromptTemplate template;
  final VoidCallback? onSuccess;

  const EditTemplateDialog({
    Key? key,
    required this.template,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<EditTemplateDialog> createState() => _EditTemplateDialogState();
}

class _EditTemplateDialogState extends State<EditTemplateDialog> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _systemPromptController;
  late final TextEditingController _userPromptController;
  late final TextEditingController _tagsController;
  
  late AIFeatureType _featureType;
  late bool _isPublic;
  late bool _isVerified;
  late bool _isDefault;
  bool _isLoading = false;
  bool _isEdited = false;
  
  late TabController _tabController;

  final AdminRepositoryImpl _adminRepository = AdminRepositoryImpl();

  final List<AIFeatureType> _featureTypes = [
    AIFeatureType.textExpansion,
    AIFeatureType.textRefactor,
    AIFeatureType.textSummary,
    AIFeatureType.sceneToSummary,
    AIFeatureType.summaryToScene,
    AIFeatureType.aiChat,
    AIFeatureType.novelGeneration,
    AIFeatureType.professionalFictionContinuation,
    AIFeatureType.sceneBeatGeneration,
    AIFeatureType.novelCompose,
    AIFeatureType.settingTreeGeneration,
  ];

  final Map<AIFeatureType, String> _featureTypeLabels = {
    AIFeatureType.textExpansion: '文本扩写',
    AIFeatureType.textRefactor: '文本润色',
    AIFeatureType.textSummary: '文本总结',
    AIFeatureType.sceneToSummary: '场景转摘要',
    AIFeatureType.summaryToScene: '摘要转场景',
    AIFeatureType.aiChat: 'AI对话',
    AIFeatureType.novelGeneration: '小说生成',
    AIFeatureType.professionalFictionContinuation: '专业续写',
    AIFeatureType.sceneBeatGeneration: '场景节拍生成',
    AIFeatureType.novelCompose: '设定编排',
    AIFeatureType.settingTreeGeneration: '设定树生成',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.template.name);
    _descriptionController = TextEditingController(text: widget.template.description ?? '');
    // 将content拆分为systemPrompt和userPrompt，这里简单处理
    _systemPromptController = TextEditingController(text: '');
    _userPromptController = TextEditingController(text: widget.template.content);
    _tagsController = TextEditingController(text: widget.template.templateTags?.join(', ') ?? '');
    
    _featureType = widget.template.featureType;
    _isPublic = widget.template.isPublic;
    _isVerified = widget.template.isVerified;
    _isDefault = widget.template.isDefault;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    _userPromptController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogContainer(
      maxWidth: 800,
      height: 700,
      child: Column(
        children: [
          DialogHeader(
            title: '编辑模板 - ${widget.template.name}',
            onClose: () => Navigator.of(context).pop(),
          ),
          _buildTopBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContentEditor(),
                _buildPropertiesEditor(),
              ],
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  /// 构建顶部标题栏（参考业务组件）
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        border: Border(
          bottom: BorderSide(
            color: WebTheme.getBorderColor(context),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // 模板标题编辑
          Expanded(
            child: TextField(
              controller: _nameController,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: WebTheme.getTextColor(context),
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: '输入模板名称...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _isEdited = true;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签栏
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        border: Border(
          bottom: BorderSide(
            color: WebTheme.getBorderColor(context),
            width: 1.0,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: WebTheme.getTextColor(context),
        unselectedLabelColor: WebTheme.getSecondaryTextColor(context),
        indicatorColor: WebTheme.getTextColor(context),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            text: '内容编辑',
            icon: Icon(Icons.edit, size: 16),
          ),
          Tab(
            text: '属性设置',
            icon: Icon(Icons.settings, size: 16),
          ),
        ],
      ),
    );
  }

  /// 构建内容编辑器（参考 PromptContentEditor）
  Widget _buildContentEditor() {
    return Container(
      color: WebTheme.getSurfaceColor(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 占位符提示
          _buildPlaceholderChips(),
          
          const SizedBox(height: 16),
          
          // 系统提示词编辑器
          _buildSystemPromptEditor(),
          
          const SizedBox(height: 16),
          
          // 用户提示词编辑器
          Expanded(
            child: _buildUserPromptEditor(),
          ),
        ],
      ),
    );
  }

  /// 构建占位符提示
  Widget _buildPlaceholderChips() {
    final placeholders = [
      'content', 'context', 'requirement', 'style', 'length'
    ];
    
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
  }

  /// 构建占位符芯片
  Widget _buildPlaceholderChip(String placeholder) {
    final primaryColor = WebTheme.getPrimaryColor(context);
    
    return Tooltip(
      message: _getPlaceholderDescription(placeholder),
      child: ActionChip(
        label: Text(
          '{$placeholder}',
          style: TextStyle(
            fontSize: 12,
            color: primaryColor,
          ),
        ),
        onPressed: () {
          _insertPlaceholder(placeholder);
        },
        backgroundColor: primaryColor.withOpacity(0.1),
        side: BorderSide(
          color: primaryColor.withOpacity(0.3),
        ),
      ),
    );
  }

  /// 构建系统提示词编辑器
  Widget _buildSystemPromptEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '系统提示词 (System Prompt)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WebTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: WebTheme.getBorderColor(context),
            ),
            borderRadius: BorderRadius.circular(8),
            color: WebTheme.getSurfaceColor(context),
          ),
          child: TextField(
            controller: _systemPromptController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: '输入系统提示词...\n\n系统提示词用于设置AI的角色和基本行为规则。',
              hintStyle: TextStyle(
                color: WebTheme.getSecondaryTextColor(context),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: WebTheme.getTextColor(context),
            ),
            onChanged: (value) {
              setState(() {
                _isEdited = true;
              });
            },
          ),
        ),
      ],
    );
  }

  /// 构建用户提示词编辑器
  Widget _buildUserPromptEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '用户提示词 (User Prompt)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WebTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: WebTheme.getBorderColor(context),
              ),
              borderRadius: BorderRadius.circular(8),
              color: WebTheme.getSurfaceColor(context),
            ),
            child: TextField(
              controller: _userPromptController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: '输入用户提示词...\n\n用户提示词包含具体的任务指令和要求。可以使用占位符来动态插入内容。',
                hintStyle: TextStyle(
                  color: WebTheme.getSecondaryTextColor(context),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: WebTheme.getTextColor(context),
              ),
              onChanged: (value) {
                setState(() {
                  _isEdited = true;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 构建属性编辑器（参考 PromptPropertiesEditor）
  Widget _buildPropertiesEditor() {
    return Container(
      color: WebTheme.getSurfaceColor(context),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildSettings(),
              const SizedBox(height: 24),
              _buildMetadata(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '基础信息',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: WebTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '模板名称 *',
            hintText: '请输入模板名称',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入模板名称';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '模板描述',
            hintText: '请输入模板描述',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) {
            setState(() {
              _isEdited = true;
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<AIFeatureType>(
          value: _featureType,
          decoration: const InputDecoration(
            labelText: '功能类型 *',
            border: OutlineInputBorder(),
          ),
          items: _featureTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_featureTypeLabels[type] ?? type.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _featureType = value;
                _isEdited = true;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            labelText: '标签',
            hintText: '请输入标签，用逗号分隔',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _isEdited = true;
            });
          },
        ),
      ],
    );
  }

  /// 插入占位符
  void _insertPlaceholder(String placeholder) {
    final currentText = _userPromptController.text;
    final selection = _userPromptController.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      '{$placeholder}',
    );
    _userPromptController.text = newText;
    _userPromptController.selection = TextSelection.fromPosition(
      TextPosition(offset: selection.start + placeholder.length + 2),
    );
    setState(() {
      _isEdited = true;
    });
  }

  /// 获取占位符描述
  String _getPlaceholderDescription(String placeholder) {
    switch (placeholder) {
      case 'content':
        return '要处理的主要内容';
      case 'context':
        return '上下文信息';
      case 'requirement':
        return '具体要求';
      case 'style':
        return '风格要求';
      case 'length':
        return '长度要求';
      default:
        return '占位符：$placeholder';
    }
  }

  /// 构建元数据显示
  Widget _buildMetadata() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '元数据',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WebTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 12),
        _buildMetadataRow('创建时间', _formatDateTime(widget.template.createdAt)),
        _buildMetadataRow('更新时间', _formatDateTime(widget.template.updatedAt)),
        _buildMetadataRow('使用次数', widget.template.useCount?.toString() ?? '0'),
        _buildMetadataRow('评分', widget.template.averageRating?.toStringAsFixed(1) ?? '无'),
      ],
    );
  }

  /// 构建元数据行
  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: WebTheme.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '设置选项',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: WebTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('公开模板'),
          subtitle: const Text('是否将此模板设为公开可见'),
          value: _isPublic,
          onChanged: (value) {
            setState(() {
              _isPublic = value ?? false;
              _isEdited = true;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('官方认证'),
          subtitle: const Text('是否标记为官方认证模板'),
          value: _isVerified,
          onChanged: (value) {
            setState(() {
              _isVerified = value ?? false;
              _isEdited = true;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('默认模板'),
          subtitle: const Text('是否设为该功能类型的默认模板'),
          value: _isDefault,
          onChanged: (value) {
            setState(() {
              _isDefault = value ?? false;
              _isEdited = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: WebTheme.getBorderColor(context)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          const SizedBox(width: 16),
          if (_isEdited || _isLoading)
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTemplate,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
        ],
      ),
    );
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final updatedTemplate = widget.template.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        content: _combinePrompts(),
        featureType: _featureType,
        templateTags: tags,
        isPublic: _isPublic,
        isVerified: _isVerified,
        isDefault: _isDefault,
        updatedAt: DateTime.now(),
      );

      await _adminRepository.updateTemplate(widget.template.id, updatedTemplate);
      
      if (mounted) {
        setState(() {
          _isEdited = false;
        });
        Navigator.of(context).pop();
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板更新成功')),
        );
      }
    } catch (e) {
      AppLogger.e('EditTemplateDialog', '更新模板失败', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 合并系统提示词和用户提示词
  String _combinePrompts() {
    final systemPrompt = _systemPromptController.text.trim();
    final userPrompt = _userPromptController.text.trim();
    
    if (systemPrompt.isEmpty) {
      return userPrompt;
    } else if (userPrompt.isEmpty) {
      return systemPrompt;
    } else {
      return '$systemPrompt\n\n$userPrompt';
    }
  }
} 