import 'package:flutter/material.dart';

import '../../../models/prompt_models.dart';
import '../../../services/api_service/repositories/impl/prompt_repository_impl.dart';
import '../../../services/api_service/base/api_client.dart';
import '../../../models/prompt_models.dart' show AIFeatureTypeHelper;
import '../../../config/app_config.dart';
import '../../../utils/logger.dart';

/// 添加用户模板对话框
class AddUserTemplateDialog extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AddUserTemplateDialog({
    Key? key,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<AddUserTemplateDialog> createState() => _AddUserTemplateDialogState();
}

class _AddUserTemplateDialogState extends State<AddUserTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _templateContentController = TextEditingController();
  final _versionController = TextEditingController(text: '1.0.0');
  final _tagsController = TextEditingController();
  
  String _selectedFeatureType = 'CHAT';
  bool _isPrivate = true;
  bool _addToFavorites = false;
  bool _isLoading = false;

  final PromptRepositoryImpl _promptRepository = PromptRepositoryImpl(ApiClient());
  // 功能类型动态来源：AIFeatureTypeHelper.allFeatures

  static const Map<String, String> _featureTypeLabels = {
    'CHAT': 'AI聊天',
    'SCENE_GENERATION': '场景生成',
    'CONTINUATION': '续写',
    'SUMMARY': '总结',
    'OUTLINE': '大纲',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _templateContentController.dispose();
    _versionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle, size: 24, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '新建模板',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildTemplateContentSection(),
                      const SizedBox(height: 24),
                      _buildSettingsSection(),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '基本信息',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
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
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _versionController,
                decoration: const InputDecoration(
                  labelText: '版本号',
                  hintText: '1.0.0',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '模板描述',
            hintText: '请简要描述此模板的用途和特点',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFeatureType,
                decoration: const InputDecoration(
                  labelText: '适用功能 *',
                  border: OutlineInputBorder(),
                ),
                items: AIFeatureTypeHelper.allFeatures.map((t) {
                  final api = t.toApiString();
                  return DropdownMenuItem(
                    value: api,
                    child: Text(t.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFeatureType = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            labelText: '标签',
            hintText: '请输入标签，用逗号分隔，如：创意写作,角色对话',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '模板内容',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showVariableHelper,
              icon: const Icon(Icons.help_outline, size: 16),
              label: const Text('变量使用帮助'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _templateContentController,
          decoration: const InputDecoration(
            labelText: '模板内容 *',
            hintText: '请输入模板内容，可以使用 {{变量名}} 作为占位符\n\n示例：\n你是一个专业的{{角色}}，请帮我{{任务描述}}。\n要求：\n1. {{要求1}}\n2. {{要求2}}',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 12,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入模板内容';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '使用提示',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '• 使用 {{变量名}} 创建可填写的占位符\n• 变量名应该简洁明了，如 {{角色}}、{{任务}}、{{风格}}\n• 用户使用时可以替换这些变量为具体内容',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '隐私设置',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              RadioListTile<bool>(
                title: const Text('私有模板'),
                subtitle: const Text('仅自己可见和使用'),
                value: true,
                groupValue: _isPrivate,
                onChanged: (value) {
                  setState(() {
                    _isPrivate = value!;
                  });
                },
              ),
              RadioListTile<bool>(
                title: const Text('公开模板'),
                subtitle: const Text('分享到社区，其他用户也可以使用'),
                value: false,
                groupValue: _isPrivate,
                onChanged: (value) {
                  setState(() {
                    _isPrivate = value!;
                  });
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        CheckboxListTile(
          title: const Text('添加到我的收藏'),
          subtitle: const Text('创建后自动添加到收藏夹'),
          value: _addToFavorites,
          onChanged: (value) {
            setState(() {
              _addToFavorites = value ?? false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _createTemplate,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('创建模板'),
        ),
      ],
    );
  }

  void _showVariableHelper() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('变量使用帮助'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '变量语法：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[100],
                child: const Text(
                  '{{变量名}}',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                '常用变量示例：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...const [
                '{{角色}} - 如：专业编剧、资深编辑',
                '{{任务}} - 如：写一个故事、分析文本',
                '{{风格}} - 如：正式、幽默、诗意',
                '{{主题}} - 如：科幻、爱情、悬疑',
                '{{长度}} - 如：500字、简短、详细',
                '{{语言}} - 如：中文、英文、双语',
              ].map((example) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('• $example'),
              )),
              
              const SizedBox(height: 16),
              const Text(
                '使用建议：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 变量名要简洁明了\n'
                '• 避免使用特殊字符\n'
                '• 可以使用中文变量名\n'
                '• 合理组织变量顺序',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final feature = AIFeatureTypeHelper.fromApiString(_selectedFeatureType.toUpperCase());
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      await _promptRepository.createPromptTemplate(
        name: _nameController.text.trim(),
        content: _templateContentController.text.trim(),
        featureType: feature,
        authorId: (AppConfig.userId ?? '').toString(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        tags: tags.isEmpty ? null : tags,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板创建成功')),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      AppLogger.e('AddUserTemplateDialog', '创建模板失败', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
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
}