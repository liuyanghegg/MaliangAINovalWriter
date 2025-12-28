import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/blocs/editor/editor_bloc.dart' as editor_bloc;
import 'package:ainoval/screens/editor/controllers/editor_screen_controller.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:provider/provider.dart';

/// 🚀 沉浸模式导航组件
/// 包含模式切换按钮和章节导航按钮
class ImmersiveModeNavigation extends StatelessWidget {
  const ImmersiveModeNavigation({
    super.key,
    required this.editorBloc,
  });

  final editor_bloc.EditorBloc editorBloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<editor_bloc.EditorBloc, editor_bloc.EditorState>(
      bloc: editorBloc,
      builder: (context, state) {
        if (state is! editor_bloc.EditorLoaded) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 沉浸模式切换按钮
            _buildModeToggleButton(context, state),
            
            // 保留章节导航按钮（普通/沉浸模式均可用）
            const SizedBox(width: 8),
            _buildChapterNavigationButtons(context, state),
          ],
        );
      },
    );
  }

  /// 构建模式切换按钮
  Widget _buildModeToggleButton(BuildContext context, editor_bloc.EditorLoaded state) {
    final theme = Theme.of(context);
    final isImmersive = state.isImmersiveMode;
    final editorController = Provider.of<EditorScreenController>(context, listen: false);
    final label = isImmersive ? '沉浸模式' : '普通模式';

    return Tooltip(
      message: isImmersive ? '切换到普通模式' : '切换到沉浸模式',
      child: TextButton.icon(
        icon: Icon(
          isImmersive ? Icons.center_focus_strong : Icons.view_stream,
          size: 20,
          color: isImmersive
              ? WebTheme.getPrimaryColor(context)
              : theme.colorScheme.onSurfaceVariant,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isImmersive
                ? WebTheme.getPrimaryColor(context)
                : theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: isImmersive
              ? WebTheme.getPrimaryColor(context).withAlpha(76)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        onPressed: () {
          AppLogger.i('ImmersiveModeNavigation', '用户点击模式切换按钮');
          editorController.toggleImmersiveMode();
        },
      ),
    );
  }

  /// 构建章节导航按钮组
  Widget _buildChapterNavigationButtons(BuildContext context, editor_bloc.EditorLoaded state) {
    final editorController = Provider.of<EditorScreenController>(context, listen: false);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上一章按钮
          _buildNavigationButton(
            context: context,
            icon: Icons.navigate_before,
            tooltip: '上一章',
            onPressed: editorController.canNavigateToPreviousChapter
              ? () {
                  AppLogger.i('ImmersiveModeNavigation', '导航到上一章');
                  editorController.navigateToPreviousChapter();
                }
              : null,
          ),
          
          // 分隔线
          Container(
            height: 24,
            width: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          
          // 章节信息
          _buildChapterInfo(context, state),
          
          // 分隔线
          Container(
            height: 24,
            width: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          
          // 下一章按钮
          _buildNavigationButton(
            context: context,
            icon: Icons.navigate_next,
            tooltip: '下一章',
            onPressed: editorController.canNavigateToNextChapter
              ? () {
                  AppLogger.i('ImmersiveModeNavigation', '导航到下一章');
                  editorController.navigateToNextChapter();
                }
              : null,
          ),
        ],
      ),
    );
  }

  /// 构建导航按钮
  Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
        ),
        style: IconButton.styleFrom(
          minimumSize: const Size(32, 32),
          padding: const EdgeInsets.all(4),
          foregroundColor: onPressed != null
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }

  /// 构建章节信息显示
  Widget _buildChapterInfo(BuildContext context, editor_bloc.EditorLoaded state) {
    final String? currentChapterId = state.immersiveChapterId ?? state.activeChapterId;
    if (currentChapterId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('未知章节'),
      );
    }

    // 查找当前章节信息
    String chapterTitle = '未知章节';
    String chapterInfo = '';
    
    for (int actIndex = 0; actIndex < state.novel.acts.length; actIndex++) {
      final act = state.novel.acts[actIndex];
      for (int chapterIndex = 0; chapterIndex < act.chapters.length; chapterIndex++) {
        final chapter = act.chapters[chapterIndex];
        if (chapter.id == currentChapterId) {
          chapterTitle = chapter.title.isNotEmpty ? chapter.title : '第${chapterIndex + 1}章';
          chapterInfo = '第${actIndex + 1}卷 第${chapterIndex + 1}章';
          break;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chapterTitle,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            chapterInfo,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🚀 沉浸模式边界提示组件
class ImmersiveModeBoundaryIndicator extends StatelessWidget {
  const ImmersiveModeBoundaryIndicator({
    super.key,
    required this.isFirstChapter,
    required this.isLastChapter,
    this.onNavigatePrevious,
    this.onNavigateNext,
  });

  final bool isFirstChapter;
  final bool isLastChapter;
  final VoidCallback? onNavigatePrevious;
  final VoidCallback? onNavigateNext;

  @override
  Widget build(BuildContext context) {
    if (!isFirstChapter && !isLastChapter) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFirstChapter ? Icons.first_page : Icons.last_page,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isFirstChapter ? '这是第一章' : '这是最后一章',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if ((isFirstChapter && onNavigateNext != null) ||
              (isLastChapter && onNavigatePrevious != null))
            TextButton.icon(
              onPressed: isFirstChapter ? onNavigateNext : onNavigatePrevious,
              icon: Icon(
                isFirstChapter ? Icons.arrow_forward : Icons.arrow_back,
                size: 16,
              ),
              label: Text(isFirstChapter ? '下一章' : '上一章'),
              style: TextButton.styleFrom(
                foregroundColor: WebTheme.getPrimaryColor(context),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
        ],
      ),
    );
  }
}

/// 🚀 沉浸模式工具栏
class ImmersiveModeToolbar extends StatelessWidget {
  const ImmersiveModeToolbar({
    super.key,
    required this.editorBloc,
  });

  final editor_bloc.EditorBloc editorBloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<editor_bloc.EditorBloc, editor_bloc.EditorState>(
      bloc: editorBloc,
      builder: (context, state) {
        if (state is! editor_bloc.EditorLoaded || !state.isImmersiveMode) {
          return const SizedBox.shrink();
        }

        final editorController = Provider.of<EditorScreenController>(context, listen: false);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 沉浸模式指示器
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WebTheme.getPrimaryColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.center_focus_strong,
                      size: 16,
                      color: WebTheme.getPrimaryColor(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '沉浸模式',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: WebTheme.getPrimaryColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // 快捷操作按钮
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 返回普通模式按钮
                  TextButton.icon(
                    onPressed: () {
                      editorController.switchToNormalMode();
                    },
                    icon: const Icon(Icons.view_stream, size: 16),
                    label: const Text('普通模式'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}