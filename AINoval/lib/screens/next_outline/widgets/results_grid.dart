import 'package:ainoval/blocs/next_outline/next_outline_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/next_outline/next_outline_bloc.dart';
import '../../../models/user_ai_model_config_model.dart';
import 'package:ainoval/screens/next_outline/widgets/modern_result_card.dart';
import 'package:ainoval/widgets/common/loading_indicator.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// 剧情推演结果网格 - 全局通用组件
/// 
/// 此组件负责展示和管理剧情推演的生成结果：
/// 1. 结果展示 - 以网格形式展示多个剧情选项
/// 2. 交互操作 - 支持选择、重新生成、保存等操作
/// 3. 状态管理 - 处理加载、空状态、错误状态
/// 4. 响应式布局 - 适配不同屏幕尺寸
/// 
/// 设计特点：
/// - 采用纯黑白配色方案，保持视觉一致性
/// - 现代化的卡片设计和交互反馈
/// - 清晰的信息层次和操作引导
/// - 优化的间距和组件尺寸
class ResultsGrid extends StatefulWidget {
  /// 剧情选项列表 - 生成的剧情推演结果
  final List<OutlineOptionState> outlineOptions;

  /// 当前选中的剧情选项ID
  final String? selectedOptionId;

  /// AI模型配置列表 - 用于重新生成操作
  final List<UserAIModelConfigModel> aiModelConfigs;

  /// 是否正在生成 - 控制全局生成状态
  final bool isGenerating;

  /// 是否正在保存 - 控制保存操作状态
  final bool isSaving;

  /// 选项选中回调 - 用户选择特定剧情选项
  final Function(String optionId) onOptionSelected;

  /// 重新生成单个选项回调 - 重新生成特定选项
  final Function(String optionId, String configId, String? hint) onRegenerateSingle;

  /// 重新生成全部选项回调 - 批量重新生成
  final Function(String? hint) onRegenerateAll;

  /// 保存大纲回调 - 保存选中的剧情到小说结构
  final Function(String optionId, String insertType) onSaveOutline;

  const ResultsGrid({
    Key? key,
    required this.outlineOptions,
    this.selectedOptionId,
    required this.aiModelConfigs,
    this.isGenerating = false,
    this.isSaving = false,
    required this.onOptionSelected,
    required this.onRegenerateSingle,
    required this.onRegenerateAll,
    required this.onSaveOutline,
  }) : super(key: key);

  @override
  State<ResultsGrid> createState() => _ResultsGridState();
}

/// 结果网格状态管理
/// 
/// 负责：
/// 1. 本地状态管理（重新生成提示等）
/// 2. 响应式布局计算
/// 3. 用户交互处理
/// 4. 对话框和弹窗管理
class _ResultsGridState extends State<ResultsGrid> {
  final TextEditingController _regenerateHintController = TextEditingController();

  @override
  void dispose() {
    _regenerateHintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题区域 - 统一的视觉标识
        _buildSectionHeader(context),
        
        const SizedBox(height: 24), // 标题与内容的间距

        // 主内容区域 - 根据状态显示不同内容
        _buildMainContent(context),
      ],
    );
  }

  /// 构建区域标题
  /// 提供清晰的功能标识和视觉层次
  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          LucideIcons.layout_grid,
          size: 24,
          color: WebTheme.getTextColor(context),
        ),
        const SizedBox(width: 12),
        Text(
          '生成结果',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: WebTheme.getTextColor(context),
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const Spacer(),
        // 结果数量指示器
        if (widget.outlineOptions.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: WebTheme.getEmptyStateColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: WebTheme.getBorderColor(context),
                width: 1,
              ),
            ),
            child: Text(
              '${widget.outlineOptions.length} 个选项',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建主内容区域
  /// 根据不同状态显示相应的内容
  Widget _buildMainContent(BuildContext context) {
    // 全局加载状态 - 首次生成时的加载指示
    if (widget.isGenerating && widget.outlineOptions.isEmpty) {
      return _buildLoadingState();
    }

    // 空状态 - 尚未生成任何结果
    if (widget.outlineOptions.isEmpty) {
      return _buildEmptyState();
    }

    // 有结果状态 - 显示结果网格和操作区域
    return _buildResultsContent(context);
  }

  /// 构建加载状态
  /// 现代化的加载指示器
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: WebTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: WebTheme.getShadowColor(context, opacity: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const LoadingIndicator(message: '正在生成剧情选项...'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  /// 引导用户进行首次生成
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: WebTheme.getEmptyStateColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: WebTheme.getBorderColor(context),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 48,
                    color: WebTheme.getSecondaryTextColor(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '尚未生成剧情',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: WebTheme.getTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请在上方配置参数后点击"生成剧情大纲"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建结果内容
  /// 包含结果网格和操作按钮
  Widget _buildResultsContent(BuildContext context) {
    return Column(
      children: [
        // 结果卡片网格 - 响应式布局
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.62, // 调高卡片高度
                crossAxisSpacing: 24, // 增加间距
                mainAxisSpacing: 24, // 增加间距
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.outlineOptions.length,
              itemBuilder: (context, index) {
                final option = widget.outlineOptions[index];

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: WebTheme.getShadowColor(context, opacity: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ModernResultCard(
                    option: option,
                    isSelected: widget.selectedOptionId == option.optionId,
                    aiModelConfigs: widget.aiModelConfigs,
                    onSelected: () => widget.onOptionSelected(option.optionId),
                    onRegenerateSingle: (configId, hint) =>
                        widget.onRegenerateSingle(option.optionId, configId, hint),
                    onSave: (insertType) =>
                        widget.onSaveOutline(option.optionId, insertType),
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 32), // 网格与操作按钮的间距

        // 全局操作按钮区域
        if (widget.outlineOptions.isNotEmpty && !widget.isGenerating)
          _buildGlobalActionButtons(context),
      ],
    );
  }

  /// 构建全局操作按钮
  /// 提供批量操作和主要功能入口
  Widget _buildGlobalActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebTheme.getEmptyStateColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 重新生成按钮 - 次要操作
          OutlinedButton.icon(
            onPressed: widget.isGenerating || widget.isSaving
                ? null
                : () => widget.onRegenerateAll(null),
            icon: Icon(
              LucideIcons.refresh_cw,
              size: 18,
              color: WebTheme.getTextColor(context),
            ),
            label: Text(
              '重新生成全部',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: WebTheme.getTextColor(context),
              ),
            ),
            style: WebTheme.getSecondaryButtonStyle(context).copyWith(
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),

          const Spacer(),

          // 保存按钮 - 主要操作
          if (widget.selectedOptionId != null)
            ElevatedButton.icon(
              onPressed: widget.isGenerating || widget.isSaving
                  ? null
                  : () => _showSaveOptionsDialog(context),
              icon: widget.isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: WebTheme.getCardColor(context),
                      ),
                    )
                  : Icon(
                      LucideIcons.save,
                      size: 18,
                      color: WebTheme.getCardColor(context),
                    ),
              label: Text(
                widget.isSaving ? '保存中...' : '保存选中的大纲',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.getCardColor(context),
                ),
              ),
              style: WebTheme.getPrimaryButtonStyle(context).copyWith(
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 显示保存选项对话框
  /// 提供不同的保存方式选择
  void _showSaveOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: WebTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                LucideIcons.save,
                size: 24,
                color: WebTheme.getTextColor(context),
              ),
              const SizedBox(width: 12),
              Text(
                '保存大纲',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择保存方式：',
                style: TextStyle(
                  fontSize: 14,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              
              // 保存选项列表
              _buildSaveOption(
                context,
                icon: LucideIcons.folder_plus,
                title: '添加为新章节',
                subtitle: '在小说末尾添加新章节',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  widget.onSaveOutline(widget.selectedOptionId!, 'NEW_CHAPTER');
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildSaveOption(
                context,
                icon: LucideIcons.list_plus,
                title: '插入到现有章节',
                subtitle: '选择插入位置',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showChapterInsertDialog(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: WebTheme.getSecondaryButtonStyle(context),
              child: Text(
                '取消',
                style: TextStyle(
                  color: WebTheme.getTextColor(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建保存选项项目
  Widget _buildSaveOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: WebTheme.getBorderColor(context),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: WebTheme.getTextColor(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: WebTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevron_right,
              size: 18,
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示章节插入对话框
  /// 选择具体的插入位置
  void _showChapterInsertDialog(BuildContext context) {
    // 获取章节列表
    final chapters = context.read<NextOutlineBloc>().state.chapters;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: WebTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            '选择插入位置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: WebTheme.getTextColor(context),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: chapters.length,
              separatorBuilder: (context, index) => Divider(
                color: WebTheme.getBorderColor(context),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return ListTile(
                  title: Text(
                    chapter.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: WebTheme.getTextColor(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '插入到此章节后',
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    widget.onSaveOutline(widget.selectedOptionId!, 'CHAPTER_END');
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: WebTheme.getSecondaryButtonStyle(context),
              child: Text(
                '取消',
                style: TextStyle(
                  color: WebTheme.getTextColor(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 计算网格列数
  /// 基于屏幕宽度的响应式计算
  int _calculateCrossAxisCount(double width) {
    if (width < 600) return 1;      // 移动设备：单列
    if (width < 900) return 2;      // 平板：双列
    if (width < 1200) return 3;     // 小桌面：三列
    return 3;                       // 大桌面：最多三列，保持卡片适当大小
  }
}
