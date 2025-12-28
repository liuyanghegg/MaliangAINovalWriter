import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../../models/preset_models.dart';
import '../../../models/prompt_models.dart';
import '../../../models/context_selection_models.dart';
import '../../../models/ai_request_models.dart';
import '../../../services/api_service/repositories/impl/admin_repository_impl.dart';
import '../../../utils/logger.dart';
import '../../../widgets/common/form_dialog_template.dart';

/// 添加系统预设对话框
class AddSystemPresetDialog extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AddSystemPresetDialog({
    Key? key,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<AddSystemPresetDialog> createState() => _AddSystemPresetDialogState();
}

class _AddSystemPresetDialogState extends State<AddSystemPresetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _systemPromptController = TextEditingController();
  final _userPromptController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String _selectedFeatureType = 'AI_CHAT';
  bool _showInQuickAccess = false;
  bool _enableSmartContext = true;
  double _temperature = 0.7;
  double _topP = 0.9;
  String? _selectedTemplateId;
  late ContextSelectionData _contextSelectionData;
  bool _isLoading = false;

  final AdminRepositoryImpl _adminRepository = AdminRepositoryImpl();

  // 功能类型由 AIFeatureTypeHelper.allFeatures 动态提供

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
  void initState() {
    super.initState();
    _contextSelectionData = FormFieldFactory.createPresetTemplateContextData();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_button, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '添加系统预设',
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
            hintText: '请输入预设描述',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
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
        const Text(
          '提示词配置',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _systemPromptController,
          decoration: const InputDecoration(
            labelText: '系统提示词 *',
            hintText: '请输入系统提示词',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
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
            hintText: '请输入用户提示词',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
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
          title: const Text('显示在快捷访问'),
          subtitle: const Text('用户可以在快捷访问列表中看到此预设'),
          value: _showInQuickAccess,
          onChanged: (value) {
            setState(() {
              _showInQuickAccess = value ?? false;
            });
          },
        ),

        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('启用智能上下文'),
          value: _enableSmartContext,
          onChanged: (v) {
            setState(() {
              _enableSmartContext = v ?? true;
            });
          },
        ),

        const SizedBox(height: 8),
        // 温度
        FormFieldFactory.createTemperatureSliderField(
          context: context,
          value: _temperature,
          onChanged: (v) => setState(() => _temperature = v),
        ),

        const SizedBox(height: 8),
        // Top-P
        FormFieldFactory.createTopPSliderField(
          context: context,
          value: _topP,
          onChanged: (v) => setState(() => _topP = v),
        ),

        const SizedBox(height: 8),
        // 上下文选择
        FormFieldFactory.createContextSelectionField(
          contextData: _contextSelectionData,
          onSelectionChanged: (d) => setState(() => _contextSelectionData = d),
          title: '上下文选择',
          description: '选择参与提示词生成的上下文信息',
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
              : const Text('创建'),
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

      final now = DateTime.now();
      // 构建 requestData 与哈希
      final requestJson = _buildRequestDataJson();
      final newHash = _generatePresetHash(requestJson);

      final preset = AIPromptPreset(
        presetId: '',
        userId: 'system',
        presetName: _nameController.text.trim(),
        presetDescription: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        aiFeatureType: _selectedFeatureType,
        systemPrompt: _systemPromptController.text.trim(),
        userPrompt: _userPromptController.text.trim(),
        presetTags: tags.isEmpty ? null : tags,
        presetHash: newHash,
        requestData: requestJson,
        isSystem: true,
        createdAt: now,
        updatedAt: now,
        showInQuickAccess: _showInQuickAccess,
        isFavorite: false,
        isPublic: false,
        useCount: 0,
      );

      await _adminRepository.createSystemPreset(preset);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('系统预设 "${preset.presetName}" 创建成功')),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      AppLogger.e('AddSystemPresetDialog', '创建系统预设失败', e);
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

  String _buildRequestDataJson() {
    final reqType = _mapFeatureTypeToRequestType(_selectedFeatureType);
    final request = UniversalAIRequest(
      requestType: reqType,
      userId: 'system',
      novelId: _contextSelectionData.novelId,
      instructions: _userPromptController.text.trim().isNotEmpty
          ? _userPromptController.text.trim()
          : null,
      contextSelections: _contextSelectionData,
      enableSmartContext: _enableSmartContext,
      parameters: {
        'enableSmartContext': _enableSmartContext,
        'temperature': _temperature,
        'topP': _topP,
        if (_selectedTemplateId != null) 'promptTemplateId': _selectedTemplateId,
      },
      metadata: {
        'source': 'admin_system_preset_creator',
      },
    );
    return jsonEncode(request.toApiJson());
  }

  AIRequestType _mapFeatureTypeToRequestType(String featureType) {
    try {
      final ft = AIFeatureTypeHelper.fromApiString(featureType.toUpperCase());
      switch (ft) {
        case AIFeatureType.textExpansion:
          return AIRequestType.expansion;
        case AIFeatureType.textSummary:
          return AIRequestType.summary;
        case AIFeatureType.textRefactor:
          return AIRequestType.refactor;
        case AIFeatureType.aiChat:
          return AIRequestType.chat;
        case AIFeatureType.sceneToSummary:
          return AIRequestType.sceneSummary;
        case AIFeatureType.novelGeneration:
          return AIRequestType.generation;
        case AIFeatureType.novelCompose:
          return AIRequestType.novelCompose;
        default:
          return AIRequestType.expansion;
      }
    } catch (_) {
      return AIRequestType.expansion;
    }
  }

  String _generatePresetHash(String requestDataJson) {
    try {
      final bytes = utf8.encode(requestDataJson);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }
}