import 'dart:convert';
import 'package:ainoval/models/ai_request_models.dart';
import 'package:ainoval/models/context_selection_models.dart';
import 'package:ainoval/utils/logger.dart';

/// 场景节拍组件数据模型
/// 存储在Quill文档中的自包含配置数据
class SceneBeatData {
  /// AI请求的完整配置，序列化为JSON字符串
  /// 这是配置的"快照"，包含模型、参数、上下文等所有信息
  final String requestData;

  /// AI最后生成的内容，存储为Quill的Delta JSON字符串
  /// 以便在内部的子编辑器中显示富文本
  final String generatedContentDelta;

  /// (可选) 为了UI方便，记录上次加载的预设ID
  /// 这样在下次打开编辑弹窗时，可以高亮显示对应的预设
  /// **注意：此字段仅用于UI展示，不参与AI请求逻辑**
  final String? lastUsedPresetId;

  /// 🚀 新增：选中的统一模型ID（用于UI状态恢复）
  final String? selectedUnifiedModelId;

  /// 🚀 新增：选中的字数长度（'200', '400', '600' 或自定义值）
  final String? selectedLength;

  /// 🚀 新增：温度参数（0.0-2.0）
  final double temperature;

  /// 🚀 新增：Top-P参数（0.0-1.0）
  final double topP;

  /// 🚀 新增：是否启用智能上下文
  final bool enableSmartContext;

  /// 🚀 新增：选中的提示词模板ID
  final String? selectedPromptTemplateId;

  /// 🚀 新增：上下文选择数据（序列化为JSON字符串）
  final String? contextSelectionsData;

  /// 组件创建时间
  final DateTime createdAt;

  /// 组件最后更新时间
  final DateTime updatedAt;

  /// 组件状态
  final SceneBeatStatus status;

  /// 生成进度（0.0-1.0）
  final double progress;

  SceneBeatData({
    required this.requestData,
    this.generatedContentDelta = '[{"insert":"\\n"}]', // 默认为空文档
    this.lastUsedPresetId,
    this.selectedUnifiedModelId,
    this.selectedLength,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.enableSmartContext = true,
    this.selectedPromptTemplateId,
    this.contextSelectionsData,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.status = SceneBeatStatus.draft,
    this.progress = 0.0,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 从存储在Quill Delta中的JSON字符串反序列化
  factory SceneBeatData.fromJson(String jsonString) {
    try {
      final map = jsonDecode(jsonString);
      return SceneBeatData(
        requestData: map['requestData'] as String? ?? '{}',
        generatedContentDelta: map['generatedContentDelta'] as String? ?? '[{"insert":"\\n"}]',
        lastUsedPresetId: map['lastUsedPresetId'] as String?,
        selectedUnifiedModelId: map['selectedUnifiedModelId'] as String?,
        selectedLength: map['selectedLength'] as String?,
        temperature: (map['temperature'] as num? ?? 0.7).toDouble(),
        topP: (map['topP'] as num? ?? 0.9).toDouble(),
        enableSmartContext: map['enableSmartContext'] as bool? ?? true,
        selectedPromptTemplateId: map['selectedPromptTemplateId'] as String?,
        contextSelectionsData: map['contextSelectionsData'] as String?,
        createdAt: map['createdAt'] != null 
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null 
            ? DateTime.parse(map['updatedAt'] as String)
            : DateTime.now(),
        status: SceneBeatStatus.values.firstWhere(
          (s) => s.name == (map['status'] as String? ?? 'draft'),
          orElse: () => SceneBeatStatus.draft,
        ),
        progress: (map['progress'] as num? ?? 0.0).toDouble(),
      );
    } catch (e) {
      AppLogger.e('SceneBeatData', '解析SceneBeatData失败: $e');
      // 如果解析失败，返回一个安全的默认值
      return SceneBeatData(
        requestData: '{}',
        generatedContentDelta: '[{"insert":"\\n"}]',
      );
    }
  }

  /// 序列化为JSON字符串，以存储在Quill Delta中
  String toJson() {
    return jsonEncode({
      'requestData': requestData,
      'generatedContentDelta': generatedContentDelta,
      'lastUsedPresetId': lastUsedPresetId,
      'selectedUnifiedModelId': selectedUnifiedModelId,
      'selectedLength': selectedLength,
      'temperature': temperature,
      'topP': topP,
      'enableSmartContext': enableSmartContext,
      'selectedPromptTemplateId': selectedPromptTemplateId,
      'contextSelectionsData': contextSelectionsData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'progress': progress,
    });
  }

  /// 一个方便的getter，用于获取反序列化后的请求对象
  UniversalAIRequest? get parsedRequest {
    try {
      if (requestData.isEmpty || requestData == '{}') {
        return null;
      }
      final requestJson = jsonDecode(requestData);
      
      // 🚀 兼容性处理：将旧的 NOVEL_GENERATION 类型转换为 SCENE_BEAT_GENERATION
      if (requestJson['requestType'] == 'NOVEL_GENERATION' && 
          requestJson['metadata'] != null &&
          requestJson['metadata']['action'] == 'scene_beat') {
        requestJson['requestType'] = 'SCENE_BEAT_GENERATION';
        AppLogger.d('SceneBeatData', '自动将旧版场景节拍请求类型更新为 SCENE_BEAT_GENERATION');
      }
      
      return UniversalAIRequest.fromJson(requestJson);
    } catch (e) {
      AppLogger.e('SceneBeatData', '解析UniversalAIRequest失败: $e');
      return null;
    }
  }

  /// 更新请求数据
  SceneBeatData updateRequestData(UniversalAIRequest request) {
    return SceneBeatData(
      requestData: jsonEncode(request.toApiJson()),
      generatedContentDelta: generatedContentDelta,
      lastUsedPresetId: lastUsedPresetId,
      selectedUnifiedModelId: selectedUnifiedModelId,
      selectedLength: selectedLength,
      temperature: temperature,
      topP: topP,
      enableSmartContext: enableSmartContext,
      selectedPromptTemplateId: selectedPromptTemplateId,
      contextSelectionsData: contextSelectionsData,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      status: status,
      progress: progress,
    );
  }

  /// 更新生成的内容
  SceneBeatData updateGeneratedContent(String deltaJson) {
    return SceneBeatData(
      requestData: requestData,
      generatedContentDelta: deltaJson,
      lastUsedPresetId: lastUsedPresetId,
      selectedUnifiedModelId: selectedUnifiedModelId,
      selectedLength: selectedLength,
      temperature: temperature,
      topP: topP,
      enableSmartContext: enableSmartContext,
      selectedPromptTemplateId: selectedPromptTemplateId,
      contextSelectionsData: contextSelectionsData,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      status: status == SceneBeatStatus.draft ? SceneBeatStatus.generated : status,
      progress: progress,
    );
  }

  /// 更新状态和进度
  SceneBeatData updateStatus(SceneBeatStatus newStatus, {double? newProgress}) {
    return SceneBeatData(
      requestData: requestData,
      generatedContentDelta: generatedContentDelta,
      lastUsedPresetId: lastUsedPresetId,
      selectedUnifiedModelId: selectedUnifiedModelId,
      selectedLength: selectedLength,
      temperature: temperature,
      topP: topP,
      enableSmartContext: enableSmartContext,
      selectedPromptTemplateId: selectedPromptTemplateId,
      contextSelectionsData: contextSelectionsData,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      status: newStatus,
      progress: newProgress ?? progress,
    );
  }

  /// 复制数据
  SceneBeatData copyWith({
    String? requestData,
    String? generatedContentDelta,
    String? lastUsedPresetId,
    String? selectedUnifiedModelId,
    String? selectedLength,
    double? temperature,
    double? topP,
    bool? enableSmartContext,
    String? selectedPromptTemplateId,
    String? contextSelectionsData,
    DateTime? createdAt,
    DateTime? updatedAt,
    SceneBeatStatus? status,
    double? progress,
  }) {
    return SceneBeatData(
      requestData: requestData ?? this.requestData,
      generatedContentDelta: generatedContentDelta ?? this.generatedContentDelta,
      lastUsedPresetId: lastUsedPresetId ?? this.lastUsedPresetId,
      selectedUnifiedModelId: selectedUnifiedModelId ?? this.selectedUnifiedModelId,
      selectedLength: selectedLength ?? this.selectedLength,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      enableSmartContext: enableSmartContext ?? this.enableSmartContext,
      selectedPromptTemplateId: selectedPromptTemplateId ?? this.selectedPromptTemplateId,
      contextSelectionsData: contextSelectionsData ?? this.contextSelectionsData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }

  /// 创建默认的场景节拍数据
  factory SceneBeatData.createDefault({
    required String userId,
    required String novelId,
    String? initialPrompt,
  }) {
    // 创建默认的AI请求配置
    final defaultRequest = UniversalAIRequest(
      requestType: AIRequestType.sceneBeat,
      userId: userId,
      novelId: novelId,
      prompt: initialPrompt ?? '续写故事。',
      instructions: '一个关键时刻，重要的事情发生改变，推动故事发展。',
      enableSmartContext: true,
      parameters: {
        'length': '400',
        'temperature': 0.7,
        'topP': 0.9,
        'maxTokens': 4000,
      },
      metadata: {
        'action': 'scene_beat',
        'source': 'scene_beat_component',
        'featureType': 'SCENE_BEAT_GENERATION',
      },
    );

    return SceneBeatData(
      requestData: jsonEncode(defaultRequest.toApiJson()),
      generatedContentDelta: '[{"insert":"\\n"}]',
      selectedLength: '400',
      temperature: 0.7,
      topP: 0.9,
      enableSmartContext: true,
      status: SceneBeatStatus.draft,
      progress: 0.0,
    );
  }

  /// 🚀 新增：获取解析后的上下文选择数据
  ContextSelectionData? get parsedContextSelections {
    if (contextSelectionsData == null || contextSelectionsData!.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(contextSelectionsData!);
      final selectedItems = <String, ContextSelectionItem>{};
      final availableItems = <ContextSelectionItem>[];
      final flatItems = <String, ContextSelectionItem>{};
      
      // 解析选中的项目
      final selectedList = map['selectedItems'] as List<dynamic>? ?? [];
      for (final itemData in selectedList) {
        final item = ContextSelectionItem(
          id: itemData['id'] as String,
          title: itemData['title'] as String,
          type: ContextSelectionType.values.firstWhere(
            (type) => type.value == itemData['type'], // 🚀 修复：使用API值而不是displayName
            orElse: () => ContextSelectionType.fullNovelText,
          ),
          metadata: Map<String, dynamic>.from(itemData['metadata'] ?? {}),
          selectionState: SelectionState.fullySelected,
        );
        selectedItems[item.id] = item;
        availableItems.add(item);
        flatItems[item.id] = item;
      }
      
      return ContextSelectionData(
        novelId: map['novelId'] as String? ?? 'scene_beat',
        selectedItems: selectedItems,
        availableItems: availableItems,
        flatItems: flatItems,
      );
    } catch (e) {
      AppLogger.e('SceneBeatData', '解析上下文选择数据失败: $e');
      return null;
    }
  }

  /// 🚀 新增：更新上下文选择数据
  SceneBeatData updateContextSelections(ContextSelectionData? contextData) {
    String? serializedData;
    if (contextData != null && contextData.selectedCount > 0) {
      // 序列化选中的项目
      final selectedList = contextData.selectedItems.values.map((item) => {
        'id': item.id,
        'title': item.title,
        'type': item.type.value, // 🚀 修复：使用API值而不是displayName
        'metadata': item.metadata,
      }).toList();
      
      serializedData = jsonEncode({
        'novelId': contextData.novelId,
        'selectedItems': selectedList,
      });
    }
    
    return copyWith(
      contextSelectionsData: serializedData,
      updatedAt: DateTime.now(),
    );
  }

  /// 🚀 新增：更新UI配置（不更新请求数据）
  SceneBeatData updateUIConfig({
    String? selectedUnifiedModelId,
    String? selectedLength,
    double? temperature,
    double? topP,
    bool? enableSmartContext,
    String? selectedPromptTemplateId,
    ContextSelectionData? contextSelections,
  }) {
    String? serializedContextData = this.contextSelectionsData;
    if (contextSelections != null) {
      final selectedList = contextSelections.selectedItems.values.map((item) => {
        'id': item.id,
        'title': item.title,
        'type': item.type.value, // 🚀 修复：使用API值而不是displayName
        'metadata': item.metadata,
      }).toList();
      
      serializedContextData = jsonEncode({
        'novelId': contextSelections.novelId,
        'selectedItems': selectedList,
      });
    }
    
    return copyWith(
      selectedUnifiedModelId: selectedUnifiedModelId,
      selectedLength: selectedLength,
      temperature: temperature,
      topP: topP,
      enableSmartContext: enableSmartContext,
      selectedPromptTemplateId: selectedPromptTemplateId,
      contextSelectionsData: serializedContextData,
      updatedAt: DateTime.now(),
    );
  }

  /// 轻量级占位实例：折叠状态下仅存最小信息、避免占用大量内存
  /// 注意：当面板真正展开时请调用 `createDefault` 或相应的 update* 方法替换掉该实例
  static SceneBeatData get empty => SceneBeatData(requestData: '{}');
}

/// 场景节拍状态枚举
enum SceneBeatStatus {
  /// 草稿状态 - 刚创建，还未生成内容
  draft,
  
  /// 生成中 - 正在进行AI生成
  generating,
  
  /// 已生成 - AI生成完成
  generated,
  
  /// 已应用 - 生成的内容已被用户接受并应用
  applied,
  
  /// 错误状态 - 生成过程中发生错误
  error,
}

extension SceneBeatStatusExtension on SceneBeatStatus {
  /// 获取状态的显示名称
  String get displayName {
    switch (this) {
      case SceneBeatStatus.draft:
        return '草稿';
      case SceneBeatStatus.generating:
        return '生成中';
      case SceneBeatStatus.generated:
        return '已生成';
      case SceneBeatStatus.applied:
        return '已应用';
      case SceneBeatStatus.error:
        return '错误';
    }
  }

  /// 获取状态的图标
  String get icon {
    switch (this) {
      case SceneBeatStatus.draft:
        return '📝';
      case SceneBeatStatus.generating:
        return '⚡';
      case SceneBeatStatus.generated:
        return '✅';
      case SceneBeatStatus.applied:
        return '🎯';
      case SceneBeatStatus.error:
        return '❌';
    }
  }

  /// 是否可以编辑
  bool get canEdit {
    return this != SceneBeatStatus.generating;
  }

  /// 是否可以生成
  bool get canGenerate {
    return this != SceneBeatStatus.generating;
  }

  /// 是否可以应用
  bool get canApply {
    return this == SceneBeatStatus.generated;
  }
} 