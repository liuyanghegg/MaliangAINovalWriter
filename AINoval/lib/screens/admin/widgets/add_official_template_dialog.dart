import 'package:flutter/material.dart';

import '../../../models/prompt_models.dart';
import '../../../services/api_service/repositories/impl/admin_repository_impl.dart';
import '../../../utils/logger.dart';

/// 添加官方模板对话框
class AddOfficialTemplateDialog extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AddOfficialTemplateDialog({
    Key? key,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<AddOfficialTemplateDialog> createState() => _AddOfficialTemplateDialogState();
}

class _AddOfficialTemplateDialogState extends State<AddOfficialTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _templateContentController = TextEditingController();
  final _authorNameController = TextEditingController();
  final _versionController = TextEditingController(text: '1.0.0');
  final _tagsController = TextEditingController();
  
  String _selectedFeatureType = 'CHAT';
  bool _isPublic = true;
  bool _isVerified = true;
  bool _isLoading = false;

  final AdminRepositoryImpl _adminRepository = AdminRepositoryImpl();
  // 功能类型动态来源：AIFeatureTypeHelper.allFeatures

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _templateContentController.dispose();
    _authorNameController.dispose();
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
                const Icon(Icons.verified, size: 24, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '添加官方模板',
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
                  labelText: '版本号 *',
                  hintText: '1.0.0',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入版本号';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '模板描述',
            hintText: '请输入模板描述',
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
                  labelText: '功能类型 *',
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
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _authorNameController,
                decoration: const InputDecoration(
                  labelText: '作者名称',
                  hintText: '请输入作者名称',
                  border: OutlineInputBorder(),
                ),
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
        const Text(
          '模板内容',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _templateContentController,
          decoration: const InputDecoration(
            labelText: '模板内容 *',
            hintText: '请输入模板内容，支持变量占位符如 {{变量名}}',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 10,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入模板内容';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          '提示：可以使用 {{变量名}} 作为占位符，用户使用时可以填入具体内容',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
        
        CheckboxListTile(
          title: const Text('立即发布'),
          subtitle: const Text('创建后立即发布到公共模板库'),
          value: _isPublic,
          onChanged: (value) {
            setState(() {
              _isPublic = value ?? false;
            });
          },
        ),
        
        CheckboxListTile(
          title: const Text('设为认证'),
          subtitle: const Text('标记为官方认证模板'),
          value: _isVerified,
          onChanged: (value) {
            setState(() {
              _isVerified = value ?? false;
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
          onPressed: _isLoading ? null : _createOfficialTemplate,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('创建'),
        ),
      ],
    );
  }

  Future<void> _createOfficialTemplate() async {
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

      final now = DateTime.now();
      final template = PromptTemplate(
        id: '', // 将由后端生成
        name: _nameController.text.trim(),
        content: _templateContentController.text.trim(),
        featureType: _getFeatureTypeEnum(_selectedFeatureType),
        isPublic: _isPublic,
        isVerified: _isVerified,
        createdAt: now,
        updatedAt: now,
        description: _descriptionController.text.trim().isEmpty 
            ? null : _descriptionController.text.trim(),
        authorName: _authorNameController.text.trim().isEmpty 
            ? null : _authorNameController.text.trim(),
        templateTags: tags.isEmpty ? null : tags,
      );

      await _adminRepository.createOfficialTemplate(template);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('官方模板 "${template.name}" 创建成功')),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      AppLogger.e('AddOfficialTemplateDialog', '创建官方模板失败', e);
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

  AIFeatureType _getFeatureTypeEnum(String featureType) {
    try {
      return AIFeatureTypeHelper.fromApiString(featureType.toUpperCase());
    } catch (_) {
      return AIFeatureType.aiChat;
    }
  }
}