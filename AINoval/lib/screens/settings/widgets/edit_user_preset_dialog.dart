import 'package:flutter/material.dart';

import '../../../models/preset_models.dart';
import '../../../services/ai_preset_service.dart';
import '../../../utils/logger.dart';
import '../../../models/prompt_models.dart';

/// 编辑用户预设对话框
class EditUserPresetDialog extends StatefulWidget {
  final AIPromptPreset preset;
  final VoidCallback? onSuccess;

  const EditUserPresetDialog({
    Key? key,
    required this.preset,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<EditUserPresetDialog> createState() => _EditUserPresetDialogState();
}

class _EditUserPresetDialogState extends State<EditUserPresetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _systemPromptController;
  late final TextEditingController _userPromptController;
  late final TextEditingController _tagsController;
  
  late String _selectedFeatureType;
  late bool _isFavorite;
  bool _isLoading = false;

  final AIPresetService _presetService = AIPresetService();
  // 功能类型动态来源：AIFeatureTypeHelper.allFeatures

  // 功能类型标签由 AIFeatureType.displayName 提供

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.preset.presetName ?? '');
    _descriptionController = TextEditingController(text: widget.preset.presetDescription ?? '');
    _systemPromptController = TextEditingController(text: widget.preset.systemPrompt);
    _userPromptController = TextEditingController(text: widget.preset.userPrompt);
    _tagsController = TextEditingController(
      text: widget.preset.presetTags?.join(', ') ?? '',
    );
    
    final allApi = AIFeatureType.values.map((e) => e.toApiString()).toList();
    _selectedFeatureType = allApi.contains(widget.preset.aiFeatureType)
        ? widget.preset.aiFeatureType
        : AIFeatureType.aiChat.toApiString();
    _isFavorite = widget.preset.isFavorite;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    _userPromptController.dispose();
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
                  '编辑预设',
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
                      _buildPresetInfo(),
                      const SizedBox(height: 24),
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildPromptSection(),
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

  Widget _buildPresetInfo() {
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
                '预设信息',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('预设ID', widget.preset.presetId),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem('使用次数', '${widget.preset.useCount}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('创建时间', _formatDateTime(widget.preset.createdAt) ?? ''),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem('最后使用', _formatDateTime(widget.preset.lastUsedAt) ?? '从未使用'),
              ),
            ],
          ),
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
        
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '预设名称 *',
            hintText: '请输入预设名称',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入预设名称';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '预设描述',
            hintText: '请简要描述此预设的用途和特点',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          value: _selectedFeatureType,
          decoration: const InputDecoration(
            labelText: '适用功能 *',
            border: OutlineInputBorder(),
          ),
          items: AIFeatureType.values.map((t) {
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

  Widget _buildPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '提示词配置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showPromptHelper,
              icon: const Icon(Icons.help_outline, size: 16),
              label: const Text('写作技巧'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _systemPromptController,
          decoration: const InputDecoration(
            labelText: '系统提示词 *',
            hintText: '定义AI的角色和行为规则...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入系统提示词';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _userPromptController,
          decoration: const InputDecoration(
            labelText: '用户提示词',
            hintText: '可选：为用户输入提供默认格式或示例...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
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
          title: const Text('添加到我的收藏'),
          subtitle: const Text('在收藏夹中显示此预设'),
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
          onPressed: _isLoading ? null : _updatePreset,
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

  void _showPromptHelper() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示词写作技巧'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPromptTip('优化建议', [
                '• 使用具体而非抽象的描述',
                '• 明确定义期望的输出格式',
                '• 提供具体的例子和情境',
                '• 避免过于复杂的指令',
                '• 根据功能类型调整提示词风格',
              ]),
              const SizedBox(height: 16),
              
              _buildPromptTip('功能特定建议', [
                '聊天: 强调对话风格和个性',
                '场景生成: 注重描述细节和氛围',
                '续写: 保持风格一致性',
                '总结: 明确长度和要点',
                '大纲: 指定结构和层次',
              ]),
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

  Widget _buildPromptTip(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('$item', style: const TextStyle(fontSize: 12)),
        )),
      ],
    );
  }

  Future<void> _updatePreset() async {
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

      final updatedPreset = widget.preset.copyWith(
        presetName: _nameController.text.trim(),
        presetDescription: _descriptionController.text.trim().isEmpty 
            ? null : _descriptionController.text.trim(),
        aiFeatureType: _selectedFeatureType,
        systemPrompt: _systemPromptController.text.trim(),
        userPrompt: _userPromptController.text.trim().isEmpty 
            ? null : _userPromptController.text.trim(),
        presetTags: tags.isEmpty ? null : tags,
        isFavorite: _isFavorite,
        updatedAt: DateTime.now(),
      );

      await _presetService.updatePresetInfo(
        updatedPreset.presetId,
        UpdatePresetInfoRequest(
          presetName: updatedPreset.presetName ?? '未命名预设',
          presetDescription: updatedPreset.presetDescription,
          presetTags: updatedPreset.presetTags,
        ),
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('预设 "${updatedPreset.presetName}" 更新成功')),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      AppLogger.error('更新预设失败', e.toString());
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

  // 已废弃的图标/颜色映射方法已移除

  String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    
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