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

/// 编辑系统预设对话框
class EditSystemPresetDialog extends StatefulWidget {
  final AIPromptPreset preset;
  final VoidCallback? onSuccess;

  const EditSystemPresetDialog({
    Key? key,
    required this.preset,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<EditSystemPresetDialog> createState() => _EditSystemPresetDialogState();
}

class _EditSystemPresetDialogState extends State<EditSystemPresetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _systemPromptController;
  late final TextEditingController _userPromptController;
  late final TextEditingController _tagsController;
  
  late String _selectedFeatureType;
  late bool _showInQuickAccess;
  bool _enableSmartContext = true;
  double _temperature = 0.7;
  double _topP = 0.9;
  String? _selectedTemplateId;
  late ContextSelectionData _contextSelectionData;
  bool _isLoading = false;

  final AdminRepositoryImpl _adminRepository = AdminRepositoryImpl();
  // 功能类型选项改为从 AIFeatureTypeHelper.allFeatures 动态获取

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
    
    // 如果传入的功能类型不在枚举表中，退回到一个安全的默认值，避免 Dropdown 报错
    final allApi = AIFeatureTypeHelper.allFeatures.map((e) => e.toApiString()).toList();
    _selectedFeatureType = allApi.contains(widget.preset.aiFeatureType)
        ? widget.preset.aiFeatureType
        : AIFeatureType.aiChat.toApiString();
    _showInQuickAccess = widget.preset.showInQuickAccess;

    // 初始化上下文与参数（从请求数据解析）
    try {
      final request = widget.preset.parsedRequest;
      if (request != null) {
        _enableSmartContext = request.enableSmartContext;
        _contextSelectionData = request.contextSelections ?? FormFieldFactory.createPresetTemplateContextData();
        final temp = request.parameters['temperature'];
        if (temp is num) _temperature = temp.toDouble();
        final topP = request.parameters['topP'];
        if (topP is num) _topP = topP.toDouble();
        final tmpl = request.parameters['promptTemplateId'];
        if (tmpl is String && tmpl.isNotEmpty) _selectedTemplateId = tmpl;
      } else {
        _contextSelectionData = FormFieldFactory.createPresetTemplateContextData();
      }
    } catch (e) {
      _contextSelectionData = FormFieldFactory.createPresetTemplateContextData();
    }
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
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
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
                  '编辑系统预设',
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
                child: _buildInfoItem('创建时间', _formatDateTime(widget.preset.createdAt) ?? '未知'),
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
          onPressed: _isLoading ? null : _updatePreset,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
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

      // 构建统一请求数据（包含上下文与参数）
      final requestJson = _buildRequestDataJson();
      final newHash = _generatePresetHash(requestJson);

      final updatedPreset = widget.preset.copyWith(
        presetName: _nameController.text.trim(),
        presetDescription: _descriptionController.text.trim().isEmpty 
            ? null : _descriptionController.text.trim(),
        aiFeatureType: _selectedFeatureType,
        systemPrompt: _systemPromptController.text.trim(),
        userPrompt: _userPromptController.text.trim().isEmpty 
            ? '' : _userPromptController.text.trim(),
        presetTags: tags.isEmpty ? null : tags,
        showInQuickAccess: _showInQuickAccess,
        requestData: requestJson,
        presetHash: newHash,
        updatedAt: DateTime.now(),
      );

      await _adminRepository.updateSystemPreset(updatedPreset);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('系统预设 "${updatedPreset.presetName}" 更新成功')),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      AppLogger.e('EditSystemPresetDialog', '更新系统预设失败', e);
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

  String _buildRequestDataJson() {
    // 将系统预设编辑为一个可回放的 UniversalAIRequest
    final reqType = _mapFeatureTypeToRequestType(_selectedFeatureType);
    final request = UniversalAIRequest(
      requestType: reqType,
      userId: widget.preset.userId,
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
        'source': 'admin_system_preset_editor',
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