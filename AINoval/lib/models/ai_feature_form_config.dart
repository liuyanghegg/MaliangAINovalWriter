import 'package:ainoval/models/prompt_models.dart';

/// AI功能表单字段类型
enum AIFormFieldType {
  instructions,           // 指令字段
  length,                // 长度字段 (扩写/缩写)
  style,                 // 重构方式字段 (重构)
  contextSelection,      // 上下文选择
  smartContext,          // 智能上下文开关
  promptTemplate,        // 提示词模板选择
  temperature,           // 温度滑动条
  topP,                  // Top-P滑动条
  memoryCutoff,          // 记忆截断 (聊天)
  quickAccess,           // 快捷访问开关
}

/// 表单字段配置
class FormFieldConfig {
  final AIFormFieldType type;
  final String title;
  final String description;
  final bool isRequired;
  final Map<String, dynamic>? options; // 用于存储字段特定选项

  const FormFieldConfig({
    required this.type,
    required this.title,
    required this.description,
    this.isRequired = false,
    this.options,
  });
}

/// AI功能表单配置
class AIFeatureFormConfig {
  static const Map<AIFeatureType, List<FormFieldConfig>> _configs = {
    // 文本扩写
    AIFeatureType.textExpansion: [
      const FormFieldConfig(
        type: AIFormFieldType.instructions,
        title: '指令',
        description: '应该如何扩写文本？',
        options: {
          'placeholder': 'e.g. 描述设定',
          'presets': [
            {'id': 'descriptive', 'title': '描述性扩写', 'content': '请为这段文本添加更详细的描述，包括环境、感官细节和人物心理描写。'},
            {'id': 'dialogue', 'title': '对话扩写', 'content': '请为这段文本添加更多的对话和人物互动，展现人物性格。'},
            {'id': 'action', 'title': '动作扩写', 'content': '请为这段文本添加更多的动作描写和情节发展。'},
          ],
        },
      ),
      const FormFieldConfig(
        type: AIFormFieldType.length,
        title: '长度',
        description: '扩写后的文本应该多长？',
        options: {
          'radioOptions': [
            {'value': 'double', 'label': '双倍'},
            {'value': 'triple', 'label': '三倍'},
          ],
          'placeholder': 'e.g. 400 words',
        },
      ),
      const FormFieldConfig(
        type: AIFormFieldType.contextSelection,
        title: '附加上下文',
        description: '为AI提供的任何额外信息',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.smartContext,
        title: '智能上下文',
        description: '使用AI自动检索相关背景信息，提升生成质量',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.promptTemplate,
        title: '关联提示词模板',
        description: '选择要关联的提示词模板（可选）',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.temperature,
        title: '温度',
        description: '控制生成内容的创造性',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.topP,
        title: 'Top-P',
        description: '控制生成内容的多样性',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.quickAccess,
        title: '快捷访问',
        description: '是否在功能对话框中显示此预设',
      ),
    ],

    // 文本缩写
    AIFeatureType.textSummary: [
      const FormFieldConfig(
        type: AIFormFieldType.length,
        title: '长度',
        description: '缩短后的文本应该多长？',
        isRequired: true,
        options: {
          'radioOptions': [
            {'value': 'half', 'label': '一半'},
            {'value': 'quarter', 'label': '四分之一'},
            {'value': 'paragraph', 'label': '单段落'},
          ],
          'placeholder': 'e.g. 100 words',
        },
      ),
      const FormFieldConfig(
        type: AIFormFieldType.instructions,
        title: '指令',
        description: '为AI提供的任何（可选）额外指令和角色',
        options: {
          'placeholder': 'e.g. You are a...',
          'presets': [
            {'id': 'brief', 'title': '简洁摘要', 'content': '请将这段文本总结为简洁的要点。'},
            {'id': 'detailed', 'title': '详细摘要', 'content': '请提供详细的摘要，保留关键细节。'},
          ],
        },
      ),
      const FormFieldConfig(
        type: AIFormFieldType.contextSelection,
        title: '附加上下文',
        description: '为AI提供的任何额外信息',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.smartContext,
        title: '智能上下文',
        description: '使用AI自动检索相关背景信息，提升缩写质量',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.promptTemplate,
        title: '关联提示词模板',
        description: '选择要关联的提示词模板（可选）',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.temperature,
        title: '温度',
        description: '控制生成内容的创造性',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.topP,
        title: 'Top-P',
        description: '控制生成内容的多样性',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.quickAccess,
        title: '快捷访问',
        description: '是否在功能对话框中显示此预设',
      ),
    ],

    // 文本重构
    AIFeatureType.textRefactor: [
      const FormFieldConfig(
        type: AIFormFieldType.instructions,
        title: '指令',
        description: '应该如何重构文本？',
        options: {
          'placeholder': 'e.g. 重写以提高清晰度',
          'presets': [
            {'id': 'dramatic', 'title': '增强戏剧性', 'content': '让这段文字更具戏剧性和冲突感，增强情节张力。'},
            {'id': 'style', 'title': '改变风格', 'content': '请将这段文字改写为更优雅/现代/古典的文学风格。'},
            {'id': 'pov', 'title': '转换视角', 'content': '请将这段文字从第一人称改写为第三人称（或相反）。'},
            {'id': 'mood', 'title': '调整情绪', 'content': '请调整这段文字的情绪氛围，使其更加轻松/严肃/神秘/温馨。'},
          ],
        },
      ),
      const FormFieldConfig(
        type: AIFormFieldType.style,
        title: '重构方式',
        description: '重点关注哪个方面？',
        options: {
          'radioOptions': [
            {'value': 'clarity', 'label': '清晰度'},
            {'value': 'flow', 'label': '流畅性'},
            {'value': 'tone', 'label': '语调'},
          ],
          'placeholder': 'e.g. 更加正式',
        },
      ),
      const FormFieldConfig(
        type: AIFormFieldType.contextSelection,
        title: '附加上下文',
        description: '为AI提供的任何额外信息',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.smartContext,
        title: '智能上下文',
        description: '使用AI自动检索相关背景信息，提升重构质量',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.promptTemplate,
        title: '关联提示词模板',
        description: '选择要关联的提示词模板（可选）',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.temperature,
        title: '温度',
        description: '控制生成内容的创造性',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.topP,
        title: 'Top-P',
        description: '控制生成内容的多样性',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.quickAccess,
        title: '快捷访问',
        description: '是否在功能对话框中显示此预设',
      ),
    ],

    // AI聊天
    AIFeatureType.aiChat: [
      const FormFieldConfig(
        type: AIFormFieldType.instructions,
        title: 'Instructions',
        description: 'Any (optional) additional instructions and roles for the AI',
        options: {
          'placeholder': 'e.g. You are a...',
        },
      ),
      const FormFieldConfig(
        type: AIFormFieldType.contextSelection,
        title: 'Additional Context',
        description: 'Any additional information to provide to the AI',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.smartContext,
        title: 'Smart Context',
        description: 'Use AI to automatically retrieve relevant background information',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.promptTemplate,
        title: '关联提示词模板',
        description: '选择要关联的提示词模板（可选）',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.temperature,
        title: '温度',
        description: '控制生成内容的创造性',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.topP,
        title: 'Top-P',
        description: '控制生成内容的多样性',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.memoryCutoff,
        title: 'Memory Cutoff',
        description: 'Specify a maximum number of message pairs to be sent to the AI. Any messages exceeding this limit will be ignored.',
        options: {
          'radioOptions': [
            {'value': 14, 'label': '14 (Default)'},
            {'value': 28, 'label': '28'},
            {'value': 48, 'label': '48'},
            {'value': 64, 'label': '64'},
          ],
          'placeholder': 'e.g. 24',
        },
      ),
      const FormFieldConfig(
        type: AIFormFieldType.quickAccess,
        title: '快捷访问',
        description: '是否在功能对话框中显示此预设',
      ),
    ],

    // 🚀 新增：场景节拍生成
    AIFeatureType.sceneBeatGeneration: [
      const FormFieldConfig(
        type: AIFormFieldType.instructions,
        title: '指令',
        description: '为AI提供的场景节拍生成指令',
        options: {
          'placeholder': 'e.g. 续写故事，创造一个转折点...',
          'presets': [
            {'id': 'turning_point', 'title': '转折点', 'content': '创造一个重要的转折点，改变故事走向。'},
            {'id': 'character_growth', 'title': '角色成长', 'content': '展现角色的内心成长和变化。'},
            {'id': 'conflict_escalation', 'title': '冲突升级', 'content': '加剧现有冲突，增强戏剧张力。'},
            {'id': 'revelation', 'title': '重要揭示', 'content': '揭示重要信息或秘密，推动情节发展。'},
          ],
        },
      ),
      const FormFieldConfig(
        type: AIFormFieldType.length,
        title: '长度',
        description: '生成内容的字数',
        isRequired: true,
        options: {
          'radioOptions': [
            {'value': '200', 'label': '200字'},
            {'value': '400', 'label': '400字'},
            {'value': '600', 'label': '600字'},
          ],
          'placeholder': 'e.g. 500',
        },
      ),
      const FormFieldConfig(
        type: AIFormFieldType.contextSelection,
        title: '附加上下文',
        description: '为AI提供的任何额外信息',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.smartContext,
        title: '智能上下文',
        description: '使用AI自动检索相关背景信息，提升生成质量',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.promptTemplate,
        title: '关联提示词模板',
        description: '选择要关联的提示词模板（可选）',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.temperature,
        title: '温度',
        description: '控制生成内容的创造性',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.topP,
        title: 'Top-P',
        description: '控制生成内容的多样性',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.quickAccess,
        title: '快捷访问',
        description: '是否在功能对话框中显示此预设',
      ),
    ],

    // 🚀 新增：写作编排（大纲/章节/组合）
    AIFeatureType.novelCompose: [
      const FormFieldConfig(
        type: AIFormFieldType.instructions,
        title: '指令',
        description: '为AI提供写作编排的总体目标（如风格、体裁、读者定位等）',
        options: {
          'placeholder': 'e.g. 悬疑+家庭剧的现代都市小说，目标读者18-35，节奏偏快',
        },
      ),
      const FormFieldConfig(
        type: AIFormFieldType.contextSelection,
        title: '附加上下文',
        description: '为AI提供的任何额外信息（设定、摘要、章节等）',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.smartContext,
        title: '智能上下文',
        description: '使用AI自动检索相关背景信息，提升编排质量',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.promptTemplate,
        title: '关联提示词模板',
        description: '选择要关联的提示词模板（可选）',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.temperature,
        title: '温度',
        description: '控制生成内容的创造性',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.topP,
        title: 'Top-P',
        description: '控制生成内容的多样性',
      ),
      const FormFieldConfig(
        type: AIFormFieldType.quickAccess,
        title: '快捷访问',
        description: '是否在功能对话框中显示此预设',
      ),
    ],
  };

  /// 获取指定AI功能类型的表单配置
  static List<FormFieldConfig> getFormConfig(AIFeatureType featureType) {
    return _configs[featureType] ?? [];
  }

  /// 获取指定AI功能类型的表单配置（通过字符串）
  static List<FormFieldConfig> getFormConfigByString(String featureTypeString) {
    try {
      final featureType = AIFeatureTypeHelper.fromApiString(featureTypeString.toUpperCase());
      return getFormConfig(featureType);
    } catch (e) {
      return [];
    }
  }

  /// 检查指定功能类型是否包含某个字段
  static bool hasField(AIFeatureType featureType, AIFormFieldType fieldType) {
    final config = getFormConfig(featureType);
    return config.any((field) => field.type == fieldType);
  }

  /// 获取指定功能类型的指定字段配置
  static FormFieldConfig? getFieldConfig(AIFeatureType featureType, AIFormFieldType fieldType) {
    final config = getFormConfig(featureType);
    try {
      return config.firstWhere((field) => field.type == fieldType);
    } catch (e) {
      return null;
    }
  }
} 