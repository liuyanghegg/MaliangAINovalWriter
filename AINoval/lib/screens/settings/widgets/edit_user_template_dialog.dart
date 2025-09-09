import 'package:flutter/material.dart';

import '../../../models/prompt_models.dart';
import '../../../services/api_service/repositories/impl/prompt_repository_impl.dart';
import '../../../services/api_service/base/api_client.dart';
import '../../../utils/logger.dart';

/// 编辑用户模板对话框
class EditUserTemplateDialog extends StatefulWidget {
  final PromptTemplate template;
  final VoidCallback? onSuccess;

  const EditUserTemplateDialog({
    Key? key,
    required this.template,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<EditUserTemplateDialog> createState() => _EditUserTemplateDialogState();
}

class _EditUserTemplateDialogState extends State<EditUserTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _templateContentController;
  late final TextEditingController _versionController;
  late final TextEditingController _tagsController;
  
  late String _selectedFeatureType;
  late bool _isPrivate;
  late bool _isFavorite;
  bool _isLoading = false;

  final PromptRepositoryImpl _promptRepository = PromptRepositoryImpl(ApiClient());
  // 功能类型动态来源：AIFeatureTypeHelper.allFeatures

  // 功能类型标签由 AIFeatureType.displayName 提供

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.template.name);
    _descriptionController = TextEditingController(text: widget.template.description ?? '');
    _templateContentController = TextEditingController(text: widget.template.content);
    _versionController = TextEditingController(text: '1.0.0');
    _tagsController = TextEditingController(
      text: (widget.template.templateTags ?? const <String>[]) .join(', '),
    );
    
    _selectedFeatureType = widget.template.featureType.toApiString();
    _isPrivate = !widget.template.isPublic;
    _isFavorite = widget.template.isFavorite ?? false;
  }

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
                const Icon(Icons.edit, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '编辑模板',
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
                      _buildTemplateInfo(),
                      const SizedBox(height: 24),
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

  Widget _buildTemplateInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 20),
              const SizedBox(width: 8),
              const Text(
                '模板信息',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('模板ID', widget.template.id),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem('使用次数', '${widget.template.useCount ?? 0}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('创建时间', _formatDateTime(widget.template.createdAt)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem('最后更新', _formatDateTime(widget.template.updatedAt)),
              ),
            ],
          ),
          if (widget.template.averageRating != null && widget.template.averageRating! > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('平均评分', '${(widget.template.averageRating ?? 0).toStringAsFixed(1)} ⭐'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem('评分人数', '${widget.template.ratingCount ?? 0}'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
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
            hintText: '请输入标签，用逗号分隔',
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
            hintText: '请输入模板内容，可以使用 {{变量名}} 作为占位符',
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
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '使用 {{变量名}} 创建可填写的占位符，用户使用时可以替换为具体内容',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.withOpacity(0.8),
                  ),
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
          '设置选项',
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
                onChanged: widget.template.isPublic == true ? null : (value) {
                  setState(() {
                    _isPrivate = value!;
                  });
                },
              ),
              RadioListTile<bool>(
                title: const Text('公开模板'),
                subtitle: widget.template.isPublic == true 
                    ? const Text('已分享到社区，无法改为私有')
                    : const Text('分享到社区，其他用户也可以使用'),
                value: false,
                groupValue: _isPrivate,
                onChanged: widget.template.isPublic == true ? null : (value) {
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
          subtitle: const Text('在收藏夹中显示此模板'),
          value: _isFavorite,
          onChanged: (value) {
            setState(() {
              _isFavorite = value ?? false;
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
          onPressed: _isLoading ? null : _updateTemplate,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存更改'),
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

  Future<void> _updateTemplate() async {
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
        description: _descriptionController.text.trim().isEmpty 
            ? null : _descriptionController.text.trim(),
        content: _templateContentController.text.trim(),
        featureType: AIFeatureTypeHelper.fromApiString(_selectedFeatureType),
        templateTags: tags.isEmpty ? null : tags,
        isFavorite: _isFavorite,
      );

      await _promptRepository.updatePromptTemplate(
        templateId: updatedTemplate.id,
        name: updatedTemplate.name,
        content: updatedTemplate.content,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('模板 "${updatedTemplate.name}" 更新成功')),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      AppLogger.error('EditUserTemplateDialog', '更新模板失败', e);
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

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}