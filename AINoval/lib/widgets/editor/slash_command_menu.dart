import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ainoval/utils/logger.dart';

/// 斜杠命令类型
enum SlashCommandType {
  sceneBeat,
  continue_,
  summary,
  refactor,
  dialogue,
  sceneDescription;
  
  String get displayName {
    switch (this) {
      case SlashCommandType.sceneBeat:
        return '场景节拍';
      case SlashCommandType.continue_:
        return '续写';
      case SlashCommandType.summary:
        return '摘要';
      case SlashCommandType.refactor:
        return '重构';
      case SlashCommandType.dialogue:
        return '对话';
      case SlashCommandType.sceneDescription:
        return '描述';
    }
  }
  
  IconData get icon {
    switch (this) {
      case SlashCommandType.sceneBeat:
        return Icons.waves_outlined;
      case SlashCommandType.continue_:
        return Icons.edit_outlined;
      case SlashCommandType.summary:
        return Icons.summarize_outlined;
      case SlashCommandType.refactor:
        return Icons.transform_outlined;
      case SlashCommandType.dialogue:
        return Icons.chat_bubble_outline;
      case SlashCommandType.sceneDescription:
        return Icons.landscape_outlined;
    }
  }
  
  String get desc {
    switch (this) {
      case SlashCommandType.sceneBeat:
        return '一个关键时刻，重要的事情发生改变，推动故事发展';
      case SlashCommandType.continue_:
        return '基于当前上下文继续创作内容';
      case SlashCommandType.summary:
        return '生成当前内容的摘要';
      case SlashCommandType.refactor:
        return '重新整理和优化现有内容';
      case SlashCommandType.dialogue:
        return '生成角色之间的对话';
      case SlashCommandType.sceneDescription:
        return '添加场景或人物的详细描述';
    }
  }
}

/// 斜杠命令菜单组件
class SlashCommandMenu extends StatefulWidget {
  const SlashCommandMenu({
    super.key,
    required this.position,
    required this.onCommandSelected,
    this.onDismiss,
    this.availableCommands = SlashCommandType.values,
    this.maxWidth = 280,
  });

  /// 菜单显示位置
  final Offset position;
  
  /// 命令被选中时的回调
  final Function(SlashCommandType) onCommandSelected;
  
  /// 菜单被取消时的回调
  final VoidCallback? onDismiss;
  
  /// 可用的命令列表
  final List<SlashCommandType> availableCommands;
  
  /// 菜单最大宽度
  final double maxWidth;

  @override
  State<SlashCommandMenu> createState() => _SlashCommandMenuState();
}

class _SlashCommandMenuState extends State<SlashCommandMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectCommand(SlashCommandType command) {
    AppLogger.d('SlashCommandMenu', '选择命令: ${command.displayName}');
    widget.onCommandSelected(command);
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: widget.maxWidth,
                  maxHeight: 400,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI 写作助手',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    
                    // 命令列表
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: widget.availableCommands.length,
                        itemBuilder: (context, index) {
                          final command = widget.availableCommands[index];
                          final isSelected = index == _selectedIndex;
                          
                          return _buildCommandItem(
                            theme,
                            command,
                            isSelected,
                            () => _selectCommand(command),
                          );
                        },
                      ),
                    ),
                    
                    // 提示文字
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(
                        '使用 ↑↓ 选择，Enter 确认，Esc 取消',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommandItem(
    ThemeData theme,
    SlashCommandType command,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      onHover: (hovering) {
        if (hovering) {
          setState(() {
            _selectedIndex = widget.availableCommands.indexOf(command);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected 
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                command.icon,
                size: 16,
                color: isSelected 
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    command.desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

 