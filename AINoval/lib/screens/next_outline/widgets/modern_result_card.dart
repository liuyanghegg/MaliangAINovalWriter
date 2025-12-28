import 'package:ainoval/blocs/next_outline/next_outline_state.dart';
import 'package:ainoval/utils/web_theme.dart';
import '../../../models/user_ai_model_config_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// 现代化剧情推演结果卡片 - 全局通用组件
/// 
/// 此组件负责展示单个剧情推演结果：
/// 1. 内容展示 - 显示生成的剧情内容
/// 2. 状态指示 - 加载、完成、选中状态
/// 3. 操作控件 - 选择、重新生成、保存等
/// 4. 交互反馈 - 悬停效果和状态变化
/// 
/// 设计特点：
/// - 采用纯黑白配色方案，保持视觉一致性
/// - 现代化的卡片设计和微交互
/// - 清晰的信息层次和操作引导
/// - 优化的间距和组件尺寸
class ModernResultCard extends StatefulWidget {
  /// 剧情选项数据
  final OutlineOptionState option;

  /// 是否被选中
  final bool isSelected;

  /// AI模型配置列表 - 用于重新生成操作
  final List<UserAIModelConfigModel> aiModelConfigs;

  /// 选中回调
  final VoidCallback onSelected;

  /// 重新生成回调
  final Function(String configId, String? hint) onRegenerateSingle;

  /// 保存回调
  final Function(String insertType) onSave;

  const ModernResultCard({
    Key? key,
    required this.option,
    this.isSelected = false,
    required this.aiModelConfigs,
    required this.onSelected,
    required this.onRegenerateSingle,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ModernResultCard> createState() => _ModernResultCardState();
}

/// 结果卡片状态管理
/// 
/// 负责：
/// 1. 悬停状态管理
/// 2. 模型选择状态
/// 3. 交互动画控制
/// 4. 用户操作处理
class _ModernResultCardState extends State<ModernResultCard> {
  String? _selectedConfigId;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();

    // 默认选择第一个已验证的模型配置
    final validatedConfigs = widget.aiModelConfigs
        .where((config) => config.isValidated)
        .toList();
    if (validatedConfigs.isNotEmpty) {
      _selectedConfigId = validatedConfigs.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovering
            ? (Matrix4.identity()..translate(0, -2))
            : Matrix4.identity(),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: WebTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? WebTheme.getTextColor(context)
                  : _isHovering
                      ? WebTheme.getSecondaryTextColor(context)
                      : WebTheme.getBorderColor(context),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (_isHovering || widget.isSelected)
                BoxShadow(
                  color: WebTheme.getShadowColor(context, opacity: 0.3),
                  blurRadius: widget.isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              // 内容区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题区域
                      _buildTitleSection(context),
                      
                      const SizedBox(height: 16),
                      
                      // 内容区域
                      Expanded(
                        child: _buildContentSection(context),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 底部操作区域
              _buildActionSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建标题区域
  Widget _buildTitleSection(BuildContext context) {
    return Row(
      children: [
        // 状态指示器
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.option.isGenerating
                ? WebTheme.warning
                : widget.isSelected
                    ? WebTheme.getTextColor(context)
                    : WebTheme.success,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // 标题文本
        Expanded(
          child: Text(
            widget.option.title ?? '生成中...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: WebTheme.getTextColor(context),
              fontWeight: FontWeight.w600,
              fontSize: 20,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // 选中指示器
        if (widget.isSelected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: WebTheme.getTextColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '已选择',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: WebTheme.getCardColor(context),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建内容区域
  Widget _buildContentSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.getEmptyStateColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: ValueListenableBuilder<String>(
        valueListenable: widget.option.contentStreamController,
        builder: (context, content, child) {
          // 生成中状态
          if (content.isEmpty && widget.option.isGenerating) {
            return _buildLoadingContent(context);
          }
          
          // 内容展示
          return _buildTextContent(context, content);
        },
      ),
    );
  }

  /// 构建加载内容
  Widget _buildLoadingContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '正在生成内容...',
            style: TextStyle(
              fontSize: 12,
              color: WebTheme.getSecondaryTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建文本内容
  Widget _buildTextContent(BuildContext context, String content) {
    return SingleChildScrollView(
      child: Text(
        content.isEmpty ? '暂无内容' : content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 20,
          height: 2.0,
          color: content.isEmpty 
              ? WebTheme.getSecondaryTextColor(context)
              : WebTheme.getTextColor(context),
        ),
      ),
    );
  }

  /// 构建操作区域
  Widget _buildActionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.getEmptyStateColor(context),
        border: Border(
          top: BorderSide(
            color: WebTheme.getBorderColor(context),
            width: 1,
          ),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // 模型选择和重新生成
          Row(
            children: [
              // 模型选择下拉框
              Expanded(
                child: _buildModelSelector(context),
              ),
              
              const SizedBox(width: 12),
              
              // 重新生成按钮
              _buildRegenerateButton(context),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 主要操作按钮
          _buildMainActionButton(context),
        ],
      ),
    );
  }

  /// 构建模型选择器
  Widget _buildModelSelector(BuildContext context) {
    final validatedConfigs = widget.aiModelConfigs
        .where((config) => config.isValidated)
        .toList();

    if (validatedConfigs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: WebTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: WebTheme.getBorderColor(context),
            width: 1,
          ),
        ),
        child: Text(
          '无可用模型',
          style: TextStyle(
            fontSize: 12,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: WebTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedConfigId,
          items: validatedConfigs.map((config) {
            return DropdownMenuItem<String>(
              value: config.id,
              child: Text(
                config.name,
                style: TextStyle(
                  fontSize: 12,
                  color: WebTheme.getTextColor(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedConfigId = value;
              });
            }
          },
          isDense: true,
          isExpanded: true,
          icon: Icon(
            LucideIcons.chevron_down,
            size: 14,
            color: WebTheme.getSecondaryTextColor(context),
          ),
          dropdownColor: WebTheme.getCardColor(context),
        ),
      ),
    );
  }

  /// 构建重新生成按钮
  Widget _buildRegenerateButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          LucideIcons.refresh_cw,
          size: 16,
          color: widget.option.isGenerating || _selectedConfigId == null
              ? WebTheme.getSecondaryTextColor(context)
              : WebTheme.getTextColor(context),
        ),
        tooltip: '重新生成',
        onPressed: widget.option.isGenerating || _selectedConfigId == null
            ? null
            : () => widget.onRegenerateSingle(_selectedConfigId!, null),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }

  /// 构建主要操作按钮
  Widget _buildMainActionButton(BuildContext context) {
    if (widget.option.isGenerating) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: WebTheme.getEmptyStateColor(context),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            '生成中...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.onSelected,
        style: widget.isSelected
            ? WebTheme.getPrimaryButtonStyle(context).copyWith(
                backgroundColor: MaterialStateProperty.all(WebTheme.getTextColor(context)),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 12),
                ),
              )
            : WebTheme.getSecondaryButtonStyle(context).copyWith(
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
        child: Text(
          widget.isSelected ? '已选择' : '选择此大纲',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.isSelected
                ? WebTheme.getCardColor(context)
                : WebTheme.getTextColor(context),
          ),
        ),
      ),
    );
  }
} 