import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:ainoval/utils/web_theme.dart';

import '../../../models/novel_structure.dart';
import '../../../models/user_ai_model_config_model.dart';

/// 现代化剧情大纲生成配置卡片 - 全局通用组件
/// 
/// 此组件负责剧情推演的参数配置功能：
/// 1. 章节范围选择 - 确定推演的上下文范围
/// 2. AI模型配置 - 选择和管理生成模型
/// 3. 生成参数设置 - 选项数量、作者引导等
/// 4. 配置验证和错误提示
/// 
/// 设计特点：
/// - 采用纯黑白配色方案，符合现代简洁审美
/// - 响应式布局，适配宽屏和窄屏设备
/// - 统一的视觉层次和组件间距
/// - 清晰的信息架构和用户引导
class ModernConfigCard extends StatefulWidget {
  /// 章节列表 - 用于范围选择
  final List<Chapter> chapters;

  /// AI模型配置列表 - 可用的生成模型
  final List<UserAIModelConfigModel> aiModelConfigs;

  /// 当前选中的上下文开始章节ID
  final String? startChapterId;

  /// 当前选中的上下文结束章节ID
  final String? endChapterId;

  /// 生成选项数量 - 控制生成的剧情选项个数
  final int numOptions;

  /// 作者引导 - 用户对剧情发展的指导意见
  final String? authorGuidance;

  /// 是否正在生成 - 控制界面状态
  final bool isGenerating;

  /// 开始章节变更回调
  final Function(String?) onStartChapterChanged;

  /// 结束章节变更回调
  final Function(String?) onEndChapterChanged;

  /// 选项数量变更回调
  final Function(int) onNumOptionsChanged;

  /// 作者引导变更回调
  final Function(String?) onAuthorGuidanceChanged;

  /// 生成回调 - 触发剧情生成
  final Function(int numOptions, String? authorGuidance, List<String>? selectedConfigIds) onGenerate;

  /// 跳转到添加模型页面的回调
  final VoidCallback? onNavigateToAddModel;

  /// 跳转到配置特定模型页面的回调
  final Function(String configId)? onConfigureModel;

  const ModernConfigCard({
    Key? key,
    required this.chapters,
    required this.aiModelConfigs,
    this.startChapterId,
    this.endChapterId,
    this.numOptions = 3,
    this.authorGuidance,
    this.isGenerating = false,
    required this.onStartChapterChanged,
    required this.onEndChapterChanged,
    required this.onNumOptionsChanged,
    required this.onAuthorGuidanceChanged,
    required this.onGenerate,
    this.onNavigateToAddModel,
    this.onConfigureModel,
  }) : super(key: key);

  @override
  State<ModernConfigCard> createState() => _ModernConfigCardState();
}

/// 配置卡片状态管理
/// 
/// 负责：
/// 1. 本地状态管理（表单数据、验证状态等）
/// 2. 用户交互处理
/// 3. 数据验证和错误提示
/// 4. 响应式布局计算
class _ModernConfigCardState extends State<ModernConfigCard> {
  late int _numOptions;
  late TextEditingController _authorGuidanceController;
  List<String> _selectedConfigIds = [];
  String? _chapterRangeError;

  @override
  void initState() {
    super.initState();
    _numOptions = widget.numOptions;
    _authorGuidanceController = TextEditingController(text: widget.authorGuidance);

    // 默认选择第一个已验证的模型配置
    final validatedConfigs = widget.aiModelConfigs.where((config) => config.isValidated).toList();
    if (validatedConfigs.isNotEmpty) {
      _selectedConfigIds = [validatedConfigs.first.id];
    }
    
    // 初始化时验证章节范围
    _validateChapterRange(widget.startChapterId, widget.endChapterId);
  }

  @override
  void didUpdateWidget(ModernConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 同步外部状态变化
    if (oldWidget.authorGuidance != widget.authorGuidance) {
      _authorGuidanceController.text = widget.authorGuidance ?? '';
    }

    if (oldWidget.numOptions != widget.numOptions) {
      _numOptions = widget.numOptions;
    }
    
    // 当起止章节ID变化时验证范围
    if (oldWidget.startChapterId != widget.startChapterId || 
        oldWidget.endChapterId != widget.endChapterId) {
      _validateChapterRange(widget.startChapterId, widget.endChapterId);
    }
  }

  @override
  void dispose() {
    _authorGuidanceController.dispose();
    super.dispose();
  }

  /// 验证章节范围的合理性
  /// 确保选择的章节范围符合逻辑要求
  void _validateChapterRange(String? startChapterId, String? endChapterId) {
    setState(() {
      _chapterRangeError = null;
    });

    if (startChapterId == null || endChapterId == null) {
      setState(() {
        _chapterRangeError = '请选择完整的章节范围';
      });
      return;
    }

    // 查找章节在列表中的位置
    final startIndex = widget.chapters.indexWhere((c) => c.id == startChapterId);
    final endIndex = widget.chapters.indexWhere((c) => c.id == endChapterId);

    if (startIndex == -1 || endIndex == -1) {
      setState(() {
        _chapterRangeError = '选择的章节不存在';
      });
      return;
    }

    if (startIndex > endIndex) {
      setState(() {
        _chapterRangeError = '开始章节不能晚于结束章节';
      });
      return;
    }

    // 检查章节范围是否过大（可选的业务逻辑）
    final rangeSize = endIndex - startIndex + 1;
    if (rangeSize > 10) {
      setState(() {
        _chapterRangeError = '章节范围过大，建议选择不超过10个章节';
      });
      return;
    }
  }

  /// 根据模型名称获取对应的图标
  /// 提供视觉区分不同类型的AI模型
  IconData _getIconForModel(String modelName) {
    final lowerName = modelName.toLowerCase();
    if (lowerName.contains('gpt') || lowerName.contains('openai')) {
      return LucideIcons.gem;
    } else if (lowerName.contains('claude')) {
      return LucideIcons.search_code;
    } else if (lowerName.contains('gemini') || lowerName.contains('bard')) {
      return LucideIcons.brain_circuit;
    } else if (lowerName.contains('llama') || lowerName.contains('meta')) {
      return LucideIcons.flask_conical;
    } else if (lowerName.contains('mistral') || lowerName.contains('mixtral')) {
      return LucideIcons.zap;
    }
    return LucideIcons.cpu; // 默认图标
  }

  @override
  Widget build(BuildContext context) {
    // 检查生成按钮是否应该禁用
    final bool isGenerateButtonDisabled = widget.isGenerating || 
                                          _chapterRangeError != null;

    return Container(
      padding: const EdgeInsets.all(32), // 统一的内边距
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 响应式布局判断
          final isWideScreen = constraints.maxWidth >= 960;
          
          return isWideScreen 
            ? _buildWideLayout(context, isGenerateButtonDisabled) 
            : _buildNarrowLayout(context, isGenerateButtonDisabled);
        },
      ),
    );
  }
  
  /// 宽屏布局（AI模型配置显示在右侧）
  /// 充分利用宽屏空间，提供更好的信息组织
  Widget _buildWideLayout(BuildContext context, bool isGenerateButtonDisabled) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧：主要配置区域
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题区域
              _buildSectionHeader(
                context,
                '生成配置',
                '设置剧情推演的基本参数',
                LucideIcons.settings,
              ),
              
              const SizedBox(height: 24),
        
              // 章节配置字段
              _buildChapterConfigFields(),
              
              // 章节范围验证错误提示
              if (_chapterRangeError != null)
                _buildErrorMessage(_chapterRangeError!),
        
              const SizedBox(height: 24),
        
              // 作者引导输入区域
              _buildAuthorGuidanceField(),
        
              const SizedBox(height: 32),
        
              // 生成按钮
              Align(
                alignment: Alignment.centerRight,
                child: _buildGenerateButton(isGenerateButtonDisabled),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 40), // 左右区域间距
        
        // 右侧区域已移到左侧栏独立显示
      ],
    );
  }
  
  /// 窄屏布局（AI模型配置显示在下方）
  /// 适配移动设备和小屏幕的垂直布局
  Widget _buildNarrowLayout(BuildContext context, bool isGenerateButtonDisabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题区域
        _buildSectionHeader(
          context,
          '生成配置',
          '设置剧情推演的基本参数',
          LucideIcons.settings,
        ),
        
        const SizedBox(height: 24),

        // 章节配置字段
        _buildChapterConfigFields(),
        
        // 章节范围验证错误提示
        if (_chapterRangeError != null)
          _buildErrorMessage(_chapterRangeError!),

        const SizedBox(height: 24),

        // 作者引导输入区域
        _buildAuthorGuidanceField(),

        const SizedBox(height: 24),

        // AI模型选择区域已移到左侧栏独立显示

        const SizedBox(height: 32),

        // 生成按钮
        Align(
          alignment: Alignment.centerRight,
          child: _buildGenerateButton(isGenerateButtonDisabled),
        ),
      ],
    );
  }

  /// 构建区域标题组件
  /// 提供统一的标题样式和视觉层次
  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: WebTheme.getTextColor(context),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: WebTheme.getTextColor(context),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: WebTheme.getSecondaryTextColor(context),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建错误提示组件
  /// 统一的错误信息展示样式
  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WebTheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.circle_alert,
            size: 18,
            color: WebTheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: WebTheme.error,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建章节配置区域
  /// 包含起始章节、结束章节和生成数量的选择
  Widget _buildChapterConfigFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            // 起始章节选择
            SizedBox(
              width: totalWidth < 600 ? totalWidth : (totalWidth - 40) / 3,
              child: _buildStartChapterDropdown(),
            ),

            // 结束章节选择
            SizedBox(
              width: totalWidth < 600 ? totalWidth : (totalWidth - 40) / 3,
              child: _buildEndChapterDropdown(),
            ),

            // 生成数量选择
            SizedBox(
              width: totalWidth < 600 ? totalWidth : (totalWidth - 40) / 3,
              child: _buildNumOptionsDropdown(),
            ),
          ],
        );
      },
    );
  }

  /// 构建起始章节下拉框
  Widget _buildStartChapterDropdown() {
    return _buildDropdownField<String>(
      label: '起始章节',
      icon: LucideIcons.book_copy,
      value: widget.startChapterId,
      items: widget.chapters.map((chapter) {
        return DropdownMenuItem<String>(
          value: chapter.id,
          child: Text(
            chapter.title,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: widget.isGenerating ? null : widget.onStartChapterChanged,
      hint: '选择起始章节',
    );
  }

  /// 构建结束章节下拉框
  Widget _buildEndChapterDropdown() {
    return _buildDropdownField<String>(
      label: '结束章节',
      icon: LucideIcons.book_marked,
      value: widget.endChapterId,
      items: widget.chapters.map((chapter) {
        return DropdownMenuItem<String>(
          value: chapter.id,
          child: Text(
            chapter.title,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: widget.isGenerating ? null : widget.onEndChapterChanged,
      hint: '选择结束章节',
    );
  }

  /// 构建生成数量下拉框
  Widget _buildNumOptionsDropdown() {
    return _buildDropdownField<int>(
      label: '生成数量',
      icon: LucideIcons.list_ordered,
      value: _numOptions,
      items: [2, 3, 4, 5].map((number) {
        return DropdownMenuItem<int>(
          value: number,
          child: Text('$number 个选项'),
        );
      }).toList(),
      onChanged: widget.isGenerating
          ? null
          : (value) {
              if (value != null) {
                setState(() {
                  _numOptions = value;
                });
                widget.onNumOptionsChanged(value);
              }
            },
      hint: '选择数量',
    );
  }

  /// 通用下拉框组件
  /// 提供统一的下拉框样式和交互
  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?)? onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: WebTheme.getTextColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: WebTheme.getTextColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 下拉框
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: WebTheme.getBorderColor(context),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            decoration: WebTheme.getBorderlessInputDecoration(
              context: context,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            icon: Icon(
              LucideIcons.chevron_down,
              size: 18,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            hint: Text(
              hint,
              style: TextStyle(
                color: WebTheme.getSecondaryTextColor(context),
                fontSize: 14,
              ),
            ),
            dropdownColor: WebTheme.getCardColor(context),
            style: TextStyle(
              color: WebTheme.getTextColor(context),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建作者引导文本框
  /// 用户输入对剧情发展的指导意见
  Widget _buildAuthorGuidanceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签
        Row(
          children: [
            Icon(
              LucideIcons.lightbulb,
              size: 18,
              color: WebTheme.getTextColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              '作者引导（可选）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: WebTheme.getTextColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 输入框
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: WebTheme.getBorderColor(context),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _authorGuidanceController,
            enabled: !widget.isGenerating,
            decoration: WebTheme.getBorderlessInputDecoration(
              hintText: '例如：希望侧重角色成长；引入新的冲突；避免某些情节元素...',
              context: context,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              color: WebTheme.getTextColor(context),
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: 3,
            onChanged: widget.onAuthorGuidanceChanged,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 提示信息
        Row(
          children: [
            Icon(
              LucideIcons.info,
              size: 14,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '告诉AI您对下一段剧情的期望、偏好或需要避免的元素',
                style: TextStyle(
                  fontSize: 12,
                  color: WebTheme.getSecondaryTextColor(context),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建生成按钮
  /// 统一的主要操作按钮样式
  Widget _buildGenerateButton(bool isDisabled) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: isDisabled ? null : [
          BoxShadow(
            color: WebTheme.getShadowColor(context, opacity: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isDisabled
            ? null
            : () {
                widget.onGenerate(
                  _numOptions,
                  _authorGuidanceController.text.isEmpty ? null : _authorGuidanceController.text,
                  _selectedConfigIds.isEmpty ? null : _selectedConfigIds,
                );
              },
        icon: widget.isGenerating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: WebTheme.getCardColor(context),
                  strokeWidth: 2,
                ),
              )
            : Icon(
                LucideIcons.brain_circuit,
                size: 20,
                color: WebTheme.getCardColor(context),
              ),
        label: Text(
          widget.isGenerating ? '生成中...' : '生成剧情大纲',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WebTheme.getCardColor(context),
          ),
        ),
        style: WebTheme.getPrimaryButtonStyle(context).copyWith(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          minimumSize: MaterialStateProperty.all(const Size(160, 48)),
        ),
      ),
    );
  }

  /// 构建AI模型选择器
  /// 支持多选和模型状态显示
  Widget _buildAIModelSelection() {
    final allConfigs = widget.aiModelConfigs;

    // 模型列表为空的情况
    if (allConfigs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'AI 模型',
            '选择用于生成的AI模型',
            LucideIcons.list_checks,
          ),
          
          const SizedBox(height: 16),
          
          _buildEmptyModelState(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和添加按钮
        Row(
          children: [
            Expanded(
              child: _buildSectionHeader(
                context,
                'AI 模型',
                '选择用于生成的AI模型',
                LucideIcons.list_checks,
              ),
            ),
            if (widget.onNavigateToAddModel != null)
              TextButton.icon(
                icon: Icon(
                  LucideIcons.plus,
                  size: 16,
                  color: WebTheme.getTextColor(context),
                ),
                label: Text(
                  '添加',
                  style: TextStyle(
                    fontSize: 12,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
                onPressed: widget.onNavigateToAddModel,
                style: WebTheme.getSecondaryButtonStyle(context).copyWith(
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  minimumSize: MaterialStateProperty.all(Size.zero),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 16),

        // 模型列表
        _buildModelList(allConfigs),

        // 选择提示信息
        const SizedBox(height: 16),
        _buildModelSelectionHints(),
      ],
    );
  }

  /// 构建空模型状态
  Widget _buildEmptyModelState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebTheme.getEmptyStateColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.info,
            size: 32,
            color: WebTheme.getSecondaryTextColor(context),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无可用模型',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: WebTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请前往设置页面添加和配置AI模型服务',
            style: TextStyle(
              fontSize: 14,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建模型列表
  Widget _buildModelList(List<UserAIModelConfigModel> configs) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: configs.asMap().entries.map((entry) {
          final index = entry.key;
          final config = entry.value;
          final isSelected = _selectedConfigIds.contains(config.id);
          final isValidated = config.isValidated;
          final isLast = index == configs.length - 1;

          return Container(
            decoration: BoxDecoration(
              border: isLast ? null : Border(
                bottom: BorderSide(
                  color: WebTheme.getBorderColor(context),
                  width: 1,
                ),
              ),
            ),
            child: isValidated 
              ? _buildValidatedModelItem(config, isSelected)
              : _buildUnvalidatedModelItem(config),
          );
        }).toList(),
      ),
    );
  }

  /// 构建已验证的模型项
  Widget _buildValidatedModelItem(UserAIModelConfigModel config, bool isSelected) {
    return CheckboxListTile(
      title: Text(
        config.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: WebTheme.getTextColor(context),
        ),
      ),
      subtitle: Text(
        '已验证可用',
        style: TextStyle(
          fontSize: 12,
          color: WebTheme.success,
        ),
      ),
      value: isSelected,
      onChanged: widget.isGenerating
          ? null
          : (selected) {
              setState(() {
                if (selected == true) {
                  _selectedConfigIds.add(config.id);
                } else {
                  _selectedConfigIds.remove(config.id);
                }
              });
            },
      secondary: Icon(
        _getIconForModel(config.name),
        color: isSelected 
          ? WebTheme.getTextColor(context)
          : WebTheme.getSecondaryTextColor(context),
        size: 20,
      ),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: WebTheme.getTextColor(context),
      checkColor: WebTheme.getCardColor(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  /// 构建未验证的模型项
  Widget _buildUnvalidatedModelItem(UserAIModelConfigModel config) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        _getIconForModel(config.name),
        color: WebTheme.getSecondaryTextColor(context),
        size: 20,
      ),
      title: Text(
        config.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: WebTheme.getSecondaryTextColor(context),
          fontStyle: FontStyle.italic,
        ),
      ),
      subtitle: Text(
        '需要配置验证',
        style: TextStyle(
          fontSize: 12,
          color: WebTheme.warning,
        ),
      ),
      trailing: OutlinedButton(
        onPressed: () {
          if (widget.onConfigureModel != null) {
            widget.onConfigureModel!(config.id);
          }
        },
        style: WebTheme.getSecondaryButtonStyle(context).copyWith(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          minimumSize: MaterialStateProperty.all(Size.zero),
        ),
        child: Text(
          '配置',
          style: TextStyle(
            fontSize: 12,
            color: WebTheme.getTextColor(context),
          ),
        ),
      ),
      enabled: false,
    );
  }

  /// 构建模型选择提示信息
  Widget _buildModelSelectionHints() {
    if (_selectedConfigIds.isEmpty) {
      return _buildHintBox(
        '请至少选择一个AI模型',
        LucideIcons.circle_alert,
        WebTheme.error,
      );
    } else if (_selectedConfigIds.length < _numOptions) {
      return _buildHintBox(
        '注意：选择的模型数量少于生成数量，部分模型将被重复使用',
        LucideIcons.info,
        WebTheme.warning,
      );
    }
    
    return const SizedBox.shrink();
  }

  /// 构建提示框组件
  Widget _buildHintBox(String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 