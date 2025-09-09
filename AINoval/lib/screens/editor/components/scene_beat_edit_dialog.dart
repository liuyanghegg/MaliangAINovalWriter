import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/blocs/ai_config/ai_config_bloc.dart';
import 'package:ainoval/blocs/universal_ai/universal_ai_bloc.dart';
import 'package:ainoval/blocs/universal_ai/universal_ai_state.dart';
import 'package:ainoval/blocs/universal_ai/universal_ai_event.dart';
  // import 'package:ainoval/blocs/public_models/public_models_bloc.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_bloc.dart';
import 'package:ainoval/models/user_ai_model_config_model.dart';
import 'package:ainoval/models/context_selection_models.dart';
import 'package:ainoval/models/novel_structure.dart';
import 'package:ainoval/models/novel_setting_item.dart';
import 'package:ainoval/models/setting_group.dart';
import 'package:ainoval/models/novel_snippet.dart';
import 'package:ainoval/models/scene_beat_data.dart';
import 'package:ainoval/models/ai_request_models.dart';
import 'package:ainoval/models/unified_ai_model.dart';
import 'package:ainoval/models/preset_models.dart';
import 'package:ainoval/widgets/common/index.dart';
import 'package:ainoval/widgets/common/top_toast.dart';
import 'package:ainoval/widgets/common/unified_ai_model_dropdown.dart';
import 'package:ainoval/widgets/common/prompt_preview_widget.dart';
import 'package:ainoval/screens/editor/components/ai_dialog_common_logic.dart';
// 移除未使用的仓库相关导入
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/config/app_config.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:ainoval/blocs/public_models/public_models_bloc.dart';

/// 场景节拍编辑对话框
/// 完全按照SummaryDialog的样式和结构设计
class SceneBeatEditDialog extends StatefulWidget {
  const SceneBeatEditDialog({
    super.key,
    required this.data,
    this.novel,
    this.settings = const [],
    this.settingGroups = const [],
    this.snippets = const [],
    this.selectedUnifiedModel,
    this.onDataChanged,
    this.onGenerate,
  });

  final SceneBeatData data;
  final Novel? novel;
  final List<NovelSettingItem> settings;
  final List<SettingGroup> settingGroups;
  final List<NovelSnippet> snippets;
  final UnifiedAIModel? selectedUnifiedModel;
  final ValueChanged<SceneBeatData>? onDataChanged;
  final Function(UniversalAIRequest, UnifiedAIModel)? onGenerate;

  @override
  State<SceneBeatEditDialog> createState() => _SceneBeatEditDialogState();
}

class _SceneBeatEditDialogState extends State<SceneBeatEditDialog> with AIDialogCommonLogic {
  // 控制器
  late TextEditingController _promptController;
  late TextEditingController _instructionsController;
  late TextEditingController _lengthController;
  
  // 状态变量
  UnifiedAIModel? _selectedUnifiedModel;
  String? _selectedLength;
  bool _enableSmartContext = true;
  AIPromptPreset? _currentPreset;
  String? _selectedPromptTemplateId;
  // 临时自定义提示词
  String? _customSystemPrompt;
  String? _customUserPrompt;
  double _temperature = 0.7;
  double _topP = 0.9;
  late ContextSelectionData _contextSelectionData;
  
  // 模型选择器key（用于FormDialogTemplate）
  final GlobalKey _modelSelectorKey = GlobalKey();
  OverlayEntry? _tempOverlay;

  @override
  void initState() {
    super.initState();
    
    // 初始化控制器
    final parsedRequest = widget.data.parsedRequest;
    _promptController = TextEditingController(text: parsedRequest?.prompt ?? '续写故事。');
    _instructionsController = TextEditingController(text: parsedRequest?.instructions ?? '一个关键时刻，重要的事情发生改变，推动故事发展。');
    _lengthController = TextEditingController();
    
    // 初始化状态
    _selectedUnifiedModel = widget.selectedUnifiedModel;
    _selectedLength = widget.data.selectedLength;
    // 同步初始长度到输入框：若为自定义长度，则填入文本框并清空单选
    if (_selectedLength != null && !['200', '400', '600'].contains(_selectedLength)) {
      _lengthController.text = _selectedLength!;
      _selectedLength = null;
    }
    _temperature = widget.data.temperature;
    _topP = widget.data.topP;
    _enableSmartContext = widget.data.enableSmartContext;
    _selectedPromptTemplateId = widget.data.selectedPromptTemplateId;
    
    // 初始化上下文选择数据
    if (widget.data.parsedContextSelections != null) {
      // 如果已有保存的上下文选择，则在完整上下文树的基础上回显已选中项
      final baseData = _createDefaultContextSelectionData();
      _contextSelectionData = _mergeContextSelections(
        baseData,
        widget.data.parsedContextSelections!,
      );
    } else {
      _contextSelectionData = _createDefaultContextSelectionData();
    }
        
    debugPrint('SceneBeatEditDialog 初始化上下文选择数据');
    debugPrint('SceneBeatEditDialog Novel: ${widget.novel?.title}');
    debugPrint('SceneBeatEditDialog Settings: ${widget.settings.length}');
    debugPrint('SceneBeatEditDialog Setting Groups: ${widget.settingGroups.length}');
    debugPrint('SceneBeatEditDialog Snippets: ${widget.snippets.length}');
  }

  @override
  void dispose() {
    _promptController.dispose();
    _instructionsController.dispose();
    _lengthController.dispose();
    _tempOverlay?.remove();
    super.dispose();
  }

  ContextSelectionData _createDefaultContextSelectionData() {
    if (widget.novel != null) {
      return ContextSelectionDataBuilder.fromNovelWithContext(
        widget.novel!,
        settings: widget.settings,
        settingGroups: widget.settingGroups,
        snippets: widget.snippets,
      );
    } else {
      return ContextSelectionData(
        novelId: 'scene_beat',
        availableItems: const [],
        flatItems: const {},
      );
    }
  }

  // （已移除未使用的演示方法与扁平化构建方法）

  @override
  Widget build(BuildContext context) {
    // （已移除未使用的 Repository 初始化代码）

    return MultiBlocProvider(
      providers: [
        // 使用全局的 UniversalAIBloc 而不是创建新的
        BlocProvider.value(value: context.read<UniversalAIBloc>()),
        // 🚀 为FormDialogTemplate提供必要的Bloc
        BlocProvider.value(value: context.read<PromptNewBloc>()),
      ],
      child: FormDialogTemplate(
        title: '场景节拍配置',
        tabs: const [
          TabItem(
            id: 'tweak',
            label: '调整',
            icon: Icons.edit,
          ),
          TabItem(
            id: 'preview',
            label: '预览',
            icon: Icons.preview,
          ),
        ],
        tabContents: [
          _buildTweakTab(),
          _buildPreviewTab(),
        ],
        onTabChanged: _onTabChanged,
        showPresets: true,
        usePresetDropdown: true,
        presetFeatureType: 'SCENE_BEAT_GENERATION',
        currentPreset: _currentPreset,
        onPresetSelected: _handlePresetSelected,
        onCreatePreset: _showCreatePresetDialog,
        onManagePresets: _showManagePresetsPage,
        novelId: widget.novel?.id,
        showModelSelector: true,
        modelSelectorData: _selectedUnifiedModel != null
            ? ModelSelectorData(
                modelName: _selectedUnifiedModel!.displayName,
                maxOutput: '~12000 words',
                isModerated: true,
              )
            : const ModelSelectorData(
                modelName: '选择模型',
              ),
        onModelSelectorTap: _showModelSelectorDropdown,
        modelSelectorKey: _modelSelectorKey,
        primaryActionLabel: '保存配置',
        onPrimaryAction: _handleSave,
        onClose: _handleClose,
      ),
    );
  }

  /// 构建调整选项卡
  Widget _buildTweakTab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        
        // 指令字段
        FormFieldFactory.createInstructionsField(
          controller: _instructionsController,
          title: '指令',
          description: '为AI提供的额外指令和角色设定',
          placeholder: 'e.g. 一个关键时刻，重要的事情发生改变',
          onReset: () => setState(() => _instructionsController.clear()),
          onExpand: () {}, // TODO: 实现展开编辑器
          onCopy: () {}, // TODO: 实现复制功能
        ),

        const SizedBox(height: 16),

        // 长度字段
        FormFieldFactory.createLengthField<String>(
          options: const [
            RadioOption(value: '200', label: '200字'),
            RadioOption(value: '400', label: '400字'),
            RadioOption(value: '600', label: '600字'),
          ],
          value: _selectedLength,
          onChanged: (value) {
            setState(() {
              _selectedLength = value;
              _lengthController.clear();
            });
            if (value != null) {
              final updated = widget.data.copyWith(
                selectedLength: value,
                updatedAt: DateTime.now(),
              );
              widget.onDataChanged?.call(updated);
            }
          },
          title: '长度',
          description: '生成内容的目标长度',
          onReset: () => setState(() {
            _selectedLength = null;
            _lengthController.clear();
          }),
          alternativeInput: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 40),
            child: TextField(
              controller: _lengthController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'e.g. 300字',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? WebTheme.darkGrey300 
                      : WebTheme.grey300,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? WebTheme.darkGrey300 
                      : WebTheme.grey300,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: WebTheme.getPrimaryColor(context),
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                fillColor: Theme.of(context).brightness == Brightness.dark 
                  ? WebTheme.darkGrey100 
                  : WebTheme.white,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _selectedLength = null;
                });
                final trimmed = value.trim();
                final parsed = int.tryParse(trimmed);
                if (parsed != null) {
                  final clamped = parsed.clamp(50, 5000).toString();
                  final updated = widget.data.copyWith(
                    selectedLength: clamped,
                    updatedAt: DateTime.now(),
                  );
                  widget.onDataChanged?.call(updated);
                }
              },
              onSubmitted: (value) {
                final parsed = int.tryParse(value.trim());
                if (parsed != null) {
                  final clamped = parsed.clamp(50, 5000).toString();
                  if (_lengthController.text != clamped) {
                    _lengthController.text = clamped;
                  }
                  final updated = widget.data.copyWith(
                    selectedLength: clamped,
                    updatedAt: DateTime.now(),
                  );
                  widget.onDataChanged?.call(updated);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 附加上下文字段
        FormFieldFactory.createContextSelectionField(
          contextData: _contextSelectionData,
          onSelectionChanged: (newData) => setState(() => _contextSelectionData = newData),
          title: '附加上下文',
          description: '为AI提供的任何额外信息',
          onReset: () => setState(() => _contextSelectionData = _createDefaultContextSelectionData()),
          dropdownWidth: 400,
          initialChapterId: null,
          initialSceneId: null,
        ),
        
        const SizedBox(height: 16),
        
        // 智能上下文勾选组件
        SmartContextToggle(
          value: _enableSmartContext,
          onChanged: (value) => setState(() => _enableSmartContext = value),
          title: '智能上下文',
          description: '使用AI自动检索相关背景信息，提升生成质量',
        ),
        
        const SizedBox(height: 16),
        
        // 关联提示词模板选择字段
        FormFieldFactory.createPromptTemplateSelectionField(
          selectedTemplateId: _selectedPromptTemplateId,
          onTemplateSelected: (templateId) => setState(() => _selectedPromptTemplateId = templateId),
          aiFeatureType: 'SCENE_BEAT_GENERATION',
          title: '关联提示词模板',
          description: '选择要关联的提示词模板（可选）',
          onReset: () => setState(() => _selectedPromptTemplateId = null),
          onTemporaryPromptsSaved: (sys, user) {
            setState(() {
              _customSystemPrompt = sys.trim().isEmpty ? null : sys.trim();
              _customUserPrompt = user.trim().isEmpty ? null : user.trim();
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // 温度滑动组件
        FormFieldFactory.createTemperatureSliderField(
          context: context,
          value: _temperature,
          onChanged: (value) => setState(() => _temperature = value),
          onReset: () => setState(() => _temperature = 0.7),
        ),
        
        const SizedBox(height: 16),
        
        // Top-P滑动组件
        FormFieldFactory.createTopPSliderField(
          context: context,
          value: _topP,
          onChanged: (value) => setState(() => _topP = value),
          onReset: () => setState(() => _topP = 0.9),
        ),
      ],
    );
  }

  /// 构建预览选项卡
  Widget _buildPreviewTab() {
    return BlocBuilder<UniversalAIBloc, UniversalAIState>(
      builder: (context, state) {
        if (state is UniversalAILoading) {
          return const PromptPreviewLoadingWidget();
        } else if (state is UniversalAIPreviewSuccess) {
          return PromptPreviewWidget(
            previewResponse: state.previewResponse,
            showActions: true,
          );
        } else if (state is UniversalAIError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '预览失败',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _triggerPreview,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.preview_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 16),
                const Text(
                  '点击预览选项卡查看提示词',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _triggerPreview,
                  child: const Text('生成预览'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  /// Tab切换监听器
  void _onTabChanged(String tabId) {
    if (tabId == 'preview') {
      _triggerPreview();
    }
  }

  /// 触发预览请求
  void _triggerPreview() {
    if (_selectedUnifiedModel == null) {
      TopToast.warning(context, '请先选择AI模型');
      return;
    }

    // 根据模型类型获取配置
    late UserAIModelConfigModel modelConfig;
    if (_selectedUnifiedModel!.isPublic) {
      final publicModel = (_selectedUnifiedModel as PublicAIModel).publicConfig;
      modelConfig = UserAIModelConfigModel.fromJson({
        'id': publicModel.id,
        'userId': AppConfig.userId ?? 'unknown',
        'name': publicModel.displayName,
        'alias': publicModel.displayName,
        'modelName': publicModel.modelId,
        'provider': publicModel.provider,
        'apiEndpoint': '',
        'isDefault': false,
        'isValidated': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isPublic': true,
        'creditMultiplier': publicModel.creditRateMultiplier ?? 1.0,
      });
    } else {
      modelConfig = (_selectedUnifiedModel as PrivateAIModel).userConfig;
    }

    final request = UniversalAIRequest(
      requestType: AIRequestType.sceneBeat,
      userId: AppConfig.userId ?? 'unknown',
      novelId: widget.novel?.id,
      modelConfig: modelConfig,
      prompt: _promptController.text.trim(),
      instructions: _instructionsController.text.trim(),
      contextSelections: _contextSelectionData,
      enableSmartContext: _enableSmartContext,
      parameters: {
        'length': _selectedLength ?? _lengthController.text.trim(),
        'temperature': _temperature,
        'topP': _topP,
        'maxTokens': 4000,
        'modelName': _selectedUnifiedModel!.modelId,
        'enableSmartContext': _enableSmartContext,
        'promptTemplateId': _selectedPromptTemplateId,
        if (_customSystemPrompt != null) 'customSystemPrompt': _customSystemPrompt,
        if (_customUserPrompt != null) 'customUserPrompt': _customUserPrompt,
      },
      metadata: {
        'action': 'scene_beat',
        'source': 'preview',
        'contextCount': _contextSelectionData.selectedCount,
        'modelName': _selectedUnifiedModel!.modelId,
        'modelProvider': _selectedUnifiedModel!.provider,
        'modelConfigId': _selectedUnifiedModel!.id,
        'enableSmartContext': _enableSmartContext,
      },
    );

    // 发送预览请求
    context.read<UniversalAIBloc>().add(PreviewAIRequestEvent(request));

    // 无需返回值
  }

  /// 显示模型选择器下拉菜单
  void _showModelSelectorDropdown() {
    // 确保公共模型已加载，避免无私人模型时无法选择
    try {
      final publicBloc = context.read<PublicModelsBloc>();
      final st = publicBloc.state;
      if (st is PublicModelsInitial || st is PublicModelsError) {
        publicBloc.add(const LoadPublicModels());
      }
    } catch (_) {}

    final renderBox = _modelSelectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final anchorRect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

    _tempOverlay?.remove();

    _tempOverlay = UnifiedAIModelDropdown.show(
      context: context,
      anchorRect: anchorRect,
      selectedModel: _selectedUnifiedModel,
      onModelSelected: (unifiedModel) {
        setState(() {
          _selectedUnifiedModel = unifiedModel;
        });
      },
      showSettingsButton: true,
      novel: widget.novel,
      settings: widget.settings,
      settingGroups: widget.settingGroups,
      snippets: widget.snippets,
      onClose: () {
        _tempOverlay = null;
      },
    );
  }

  /// 构建当前请求对象（用于保存预设）
  UniversalAIRequest? _buildCurrentRequest() {
    // 情况 1：已选择新的统一模型，直接构建最新请求
    if (_selectedUnifiedModel != null) {
      final modelConfig = createModelConfig(_selectedUnifiedModel!);

      final metadata = createModelMetadata(_selectedUnifiedModel!, {
        'action': 'scene_beat',
        'source': 'scene_beat_edit_dialog',
        'contextCount': _contextSelectionData.selectedCount,
        'enableSmartContext': _enableSmartContext,
      });

      return UniversalAIRequest(
        requestType: AIRequestType.sceneBeat,
        userId: AppConfig.userId ?? 'unknown',
        novelId: widget.novel?.id,
        modelConfig: modelConfig,
        prompt: _promptController.text.trim(),
        instructions: _instructionsController.text.trim(),
        contextSelections: _contextSelectionData,
        enableSmartContext: _enableSmartContext,
        parameters: {
          'length': _selectedLength ?? _lengthController.text.trim(),
          'temperature': _temperature,
          'topP': _topP,
          'maxTokens': 4000,
          'modelName': _selectedUnifiedModel!.modelId,
          'enableSmartContext': _enableSmartContext,
          'promptTemplateId': _selectedPromptTemplateId,
          if (_customSystemPrompt != null) 'customSystemPrompt': _customSystemPrompt,
          if (_customUserPrompt != null) 'customUserPrompt': _customUserPrompt,
        },
        metadata: metadata,
      );
    }

    // 情况 2：未选择模型，但之前已有请求快照，基于旧请求更新可编辑字段
    final prevRequest = widget.data.parsedRequest;
    if (prevRequest == null) return null;

    final updatedParameters = Map<String, dynamic>.from(prevRequest.parameters);
    updatedParameters['length'] = _selectedLength ?? _lengthController.text.trim();
    updatedParameters['temperature'] = _temperature;
    updatedParameters['topP'] = _topP;
    updatedParameters['enableSmartContext'] = _enableSmartContext;
    updatedParameters['promptTemplateId'] = _selectedPromptTemplateId;
    if (_customSystemPrompt != null) {
      updatedParameters['customSystemPrompt'] = _customSystemPrompt;
    }
    if (_customUserPrompt != null) {
      updatedParameters['customUserPrompt'] = _customUserPrompt;
    }

    return UniversalAIRequest(
      requestType: prevRequest.requestType,
      userId: prevRequest.userId,
      novelId: prevRequest.novelId,
      modelConfig: prevRequest.modelConfig,
      prompt: prevRequest.prompt,
      instructions: _instructionsController.text.trim(),
      contextSelections: _contextSelectionData,
      enableSmartContext: _enableSmartContext,
      parameters: updatedParameters,
      metadata: prevRequest.metadata,
    );
  }

  /// 显示创建预设对话框
  void _showCreatePresetDialog() {
    final currentRequest = _buildCurrentRequest();
    if (currentRequest == null) {
      TopToast.warning(context, '无法创建预设：缺少表单数据');
      return;
    }
    showPresetNameDialog(currentRequest, onPresetCreated: _handlePresetCreated);
  }

  /// 显示预设管理页面
  void _showManagePresetsPage() {
    // TODO: 实现预设管理页面
    TopToast.info(context, '预设管理功能开发中...');
  }

  /// 处理预设选择
  void _handlePresetSelected(AIPromptPreset preset) {
    try {
      // 设置当前预设
      setState(() {
        _currentPreset = preset;
      });
      
      // 🚀 使用公共方法应用预设配置
      applyPresetToForm(
        preset,
        instructionsController: _instructionsController,
        onLengthChanged: (length) {
          setState(() {
            if (length != null && ['200', '400', '600'].contains(length)) {
              _selectedLength = length;
              _lengthController.clear();
            } else if (length != null) {
              _selectedLength = null;
              _lengthController.text = length;
            }
          });
        },
        onSmartContextChanged: (value) {
          setState(() {
            _enableSmartContext = value;
          });
        },
        onPromptTemplateChanged: (templateId) {
          setState(() {
            _selectedPromptTemplateId = templateId;
          });
        },
        onTemperatureChanged: (temperature) {
          setState(() {
            _temperature = temperature;
          });
        },
        onTopPChanged: (topP) {
          setState(() {
            _topP = topP;
          });
        },
        onContextSelectionChanged: (contextData) {
          setState(() {
            _contextSelectionData = contextData;
          });
        },
        onModelChanged: (unifiedModel) {
          setState(() {
            _selectedUnifiedModel = unifiedModel;
          });
        },
        currentContextData: _contextSelectionData,
      );
    } catch (e) {
      AppLogger.e('SceneBeatEditDialog', '应用预设失败', e);
      TopToast.error(context, '应用预设失败: $e');
    }
  }

  /// 处理预设创建
  void _handlePresetCreated(AIPromptPreset preset) {
    // 设置当前预设为新创建的预设
    setState(() {
      _currentPreset = preset;
    });
    
    TopToast.success(context, '预设 "${preset.presetName}" 创建成功');
    AppLogger.i('SceneBeatEditDialog', '预设创建成功: ${preset.presetName}');
  }

  void _handleSave() {
    // 构建更新的AI请求
    final request = _buildCurrentRequest();
    
    // 更新SceneBeatData
    final updatedData = widget.data.copyWith(
      requestData: request != null ? jsonEncode(request.toApiJson()) : widget.data.requestData,
      selectedUnifiedModelId: _selectedUnifiedModel?.id,
      selectedLength: _selectedLength ?? _lengthController.text.trim(),
      temperature: _temperature,
      topP: _topP,
      enableSmartContext: _enableSmartContext,
      selectedPromptTemplateId: _selectedPromptTemplateId,
      contextSelectionsData: _contextSelectionData.selectedCount > 0 
          ? jsonEncode({
              'novelId': _contextSelectionData.novelId,
              'selectedItems': _contextSelectionData.selectedItems.values.map((item) => {
                'id': item.id,
                'title': item.title,
                'type': item.type.value, // 🚀 修复：使用API值
                'metadata': item.metadata,
              }).toList(),
            })
          : null,
      updatedAt: DateTime.now(),
    );
    
    widget.onDataChanged?.call(updatedData);
    Navigator.of(context).pop();
    TopToast.success(context, '场景节拍配置已保存');
  }

  void _handleClose() {
    Navigator.of(context).pop();
  }

  /// 将已保存的上下文选择合并到新的完整上下文树中
  ContextSelectionData _mergeContextSelections(
    ContextSelectionData baseData,
    ContextSelectionData savedSelections,
  ) {
    var mergedData = baseData;

    // 遍历已保存的选项，将其在新的树中设为选中
    for (final itemId in savedSelections.selectedItems.keys) {
      if (mergedData.flatItems.containsKey(itemId)) {
        mergedData = mergedData.selectItem(itemId);
      } else {
        // 如果新树中没有该项，则将其追加到已选映射，避免数据丢失
        final savedItem = savedSelections.selectedItems[itemId]!;
        mergedData = mergedData.copyWith(
          selectedItems: {
            ...mergedData.selectedItems,
            savedItem.id: savedItem,
          },
        );
      }
    }

    return mergedData;
  }
}

/// 显示场景节拍编辑对话框的便捷函数
void showSceneBeatEditDialog(
  BuildContext context, {
  required SceneBeatData data,
  Novel? novel,
  List<NovelSettingItem> settings = const [],
  List<SettingGroup> settingGroups = const [],
  List<NovelSnippet> snippets = const [],
  UnifiedAIModel? selectedUnifiedModel,
  ValueChanged<SceneBeatData>? onDataChanged,
  Function(UniversalAIRequest, UnifiedAIModel)? onGenerate,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<AiConfigBloc>()),
          BlocProvider.value(value: context.read<PromptNewBloc>()),
        ],
        child: SceneBeatEditDialog(
          data: data,
          novel: novel,
          settings: settings,
          settingGroups: settingGroups,
          snippets: snippets,
          selectedUnifiedModel: selectedUnifiedModel,
          onDataChanged: onDataChanged,
          onGenerate: onGenerate,
        ),
      );
    },
  );
} 