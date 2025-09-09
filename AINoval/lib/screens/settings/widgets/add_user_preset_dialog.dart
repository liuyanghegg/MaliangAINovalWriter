import 'package:flutter/material.dart';

import '../../../models/preset_models.dart';
import '../../../models/ai_request_models.dart';
import '../../../services/ai_preset_service.dart';
import '../../../utils/logger.dart';
import '../../../models/prompt_models.dart';

/// 添加用户预设对话框
class AddUserPresetDialog extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AddUserPresetDialog({
    Key? key,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<AddUserPresetDialog> createState() => _AddUserPresetDialogState();
}

class _AddUserPresetDialogState extends State<AddUserPresetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _systemPromptController = TextEditingController();
  final _userPromptController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String _selectedFeatureType = 'CHAT';
  bool _addToFavorites = false;
  bool _isLoading = false;

  final AIPresetService _presetService = AIPresetService();
  // 功能类型动态来源：AIFeatureTypeHelper.allFeatures

  // 功能类型标签由 AIFeatureType.displayName 提供

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
                const Icon(Icons.smart_button, size: 24, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '新建预设',
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
            hintText: '请输入标签，用逗号分隔，如：创意写作,角色对话',
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
                    '提示词写作要点',
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
                '• 系统提示词：定义AI的角色、专业领域和回答风格\n'
                '• 用户提示词：为用户提供输入的格式指导或示例\n'
                '• 使用清晰具体的描述，避免模糊的指令\n'
                '• 可以包含期望的输出格式和长度要求',
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
          '其他设置',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          onPressed: _isLoading ? null : _createPreset,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('创建预设'),
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
              _buildPromptTip('系统提示词示例', [
                '你是一个专业的小说编辑，擅长分析文学作品的情节结构和人物塑造。',
                '你是一位创意写作导师，能够提供具体而实用的写作建议。',
                '请以专业、友好的语气回答，并提供具体的例子和建议。',
              ]),
              const SizedBox(height: 16),
              
              _buildPromptTip('用户提示词示例', [
                '请分析以下文本的：\n1. 主要角色特点\n2. 情节发展\n3. 写作技巧',
                '文本内容：[在这里粘贴要分析的文本]',
              ]),
              const SizedBox(height: 16),
              
              _buildPromptTip('写作建议', [
                '• 明确定义AI的角色和专业领域',
                '• 指定期望的回答风格（正式/友好/专业等）',
                '• 提供具体的任务描述',
                '• 如果需要，指定输出格式',
                '• 使用具体而非抽象的描述',
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: const TextStyle(fontSize: 12),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _createPreset() async {
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

      final request = UniversalAIRequest(
        requestType: AIRequestType.chat,
        userId: '',
        instructions: _systemPromptController.text.trim(),
        prompt: _userPromptController.text.trim().isEmpty ? null : _userPromptController.text.trim(),
      );

      final created = await _presetService.createPreset(
        CreatePresetRequest(
          presetName: _nameController.text.trim(),
          presetDescription: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          presetTags: tags.isEmpty ? null : tags,
          request: request,
        ),
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('预设 "${created.presetName ?? '已创建'}" 创建成功')),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      AppLogger.error('AddUserPresetDialog', '创建预设失败', e);
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

  // 旧的图标/颜色映射方法已不再使用，移除以清理警告
}