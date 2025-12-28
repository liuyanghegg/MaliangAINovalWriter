import 'dart:async';

import 'package:ainoval/blocs/editor/editor_bloc.dart';
import 'package:ainoval/screens/editor/controllers/editor_screen_controller.dart';
import 'package:ainoval/components/editable_title.dart';
import 'package:ainoval/utils/debouncer.dart' as debouncer;
import 'package:ainoval/utils/logger.dart';
import 'package:ainoval/screens/editor/widgets/custom_dropdown.dart';
import 'package:ainoval/screens/editor/widgets/menu_builder.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class ChapterSection extends StatefulWidget {
  const ChapterSection({
    super.key, // Will be replaced by chapterKey if passed
    required this.title,
    required this.scenes,
    required this.actId,
    required this.chapterId,
    required this.editorBloc,
    this.chapterIndex, // 添加章节序号参数
    this.chapterKey, // New GlobalKey parameter
  });
  final String title;
  final List<Widget> scenes;
  final String actId;
  final String chapterId;
  final EditorBloc editorBloc;
  final int? chapterIndex; // 章节在卷中的序号，从1开始
  final GlobalKey? chapterKey; // New GlobalKey parameter

  @override
  State<ChapterSection> createState() => _ChapterSectionState();
}

class _ChapterSectionState extends State<ChapterSection> {
  late TextEditingController _chapterTitleController;
  late debouncer.Debouncer _debouncer;
  // 为章节创建一个ValueKey，确保唯一性 - This will be overridden by widget.chapterKey if provided
  // late final Key _chapterKey =
  //     ValueKey('chapter_${widget.actId}_${widget.chapterId}');

  @override
  void initState() {
    super.initState();
    _chapterTitleController = TextEditingController(text: widget.title);
    _debouncer = debouncer.Debouncer();
  }

  @override
  void didUpdateWidget(ChapterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 更新标题控制器
    if (oldWidget.title != widget.title) {
      _chapterTitleController.text = widget.title;
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _chapterTitleController.dispose();
    super.dispose();
  }

  // 获取章节序号文本
  String _getChapterIndexText() {
    if (widget.chapterIndex == null) return '';
    
    // 使用中文数字表示章节序号
    final List<String> chineseNumbers = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
    
    if (widget.chapterIndex! <= 10) {
      return '第${chineseNumbers[widget.chapterIndex!]}章 · ';
    } else if (widget.chapterIndex! < 20) {
      return '第十${chineseNumbers[widget.chapterIndex! - 10]}章 · ';
    } else {
      // 对于更大的数字，直接使用阿拉伯数字
      return '第${widget.chapterIndex}章 · ';
    }
  }

  // 手动触发加载场景的方法
  void _loadScenes() {
    AppLogger.i('ChapterSection', '手动触发加载章节场景: ${widget.actId} - ${widget.chapterId}');
    
    try {
      final controller = Provider.of<EditorScreenController>(context, listen: false);
      controller.loadScenesForChapter(widget.actId, widget.chapterId);
    } catch (e) {
      // 如果无法获取控制器，直接使用EditorBloc
      widget.editorBloc.add(LoadMoreScenes(
        fromChapterId: widget.chapterId,
        direction: 'center',
        actId: widget.actId,
        chaptersLimit: 2,
        preventFocusChange: true,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: widget.chapterKey, // Use the passed GlobalKey here
      color: WebTheme.getBackgroundColor(context), // 使用动态背景色
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter标题
          Padding(
            // 调整间距
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24), // 调整上下间距
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中对齐
              children: [
                // 添加章节序号前缀
                if (widget.chapterIndex != null)
                  Text(
                    _getChapterIndexText(),
                    style: WebTheme.getAlignedTextStyle(
                      baseStyle: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: WebTheme.getTextColor(context),
                      ) ?? const TextStyle(),
                    ),
                  ),
                // 可编辑的文本字段
                Expanded(
                  child: EditableTitle(
                    // 保持 EditableTitle
                    initialText: widget.title,
                    style: WebTheme.getAlignedTextStyle(
                      baseStyle: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: WebTheme.getTextColor(context),
                      ) ?? const TextStyle(),
                    ),
                    onChanged: (value) {
                      // 使用防抖更新
                      _debouncer.run(() {
                        if (mounted) {
                          widget.editorBloc.add(UpdateChapterTitle(
                            actId: widget.actId,
                            chapterId: widget.chapterId,
                            title: value,
                          ));
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8), // 增加间距
                
                // 替换为MenuBuilder
                MenuBuilder.buildChapterMenu(
                  context: context,
                  editorBloc: widget.editorBloc,
                  actId: widget.actId,
                  chapterId: widget.chapterId,
                  onRenamePressed: () {
                    // 聚焦到标题编辑框
                    // 通过setState强制刷新使标题进入编辑状态
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          // 场景列表
          if (widget.scenes.isEmpty)
            // 显示空章节的UI，提供手动加载按钮
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.article_outlined, 
                        size: 48, color: WebTheme.getSecondaryTextColor(context)),
                    const SizedBox(height: 16),
                    Text(
                      '章节 "${widget.title}" 暂无场景内容',
                      style: TextStyle(color: WebTheme.getSecondaryTextColor(context)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '请手动加载或等待自动加载',
                      style: TextStyle(color: WebTheme.getSecondaryTextColor(context), fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    // 加载场景按钮
                    OutlinedButton.icon(
                      onPressed: _loadScenes,
                      icon: Icon(Icons.download, size: 18, color: WebTheme.getTextColor(context)),
                      label: Text('加载场景', style: TextStyle(color: WebTheme.getTextColor(context))),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WebTheme.getTextColor(context),
                        side: BorderSide.none, // 去掉边框
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        elevation: 0, // 去掉阴影
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(children: widget.scenes),

          // 移除添加新场景按钮 - 现在由EditorMainArea统一管理
        ],
      ),
    );
  }
}
