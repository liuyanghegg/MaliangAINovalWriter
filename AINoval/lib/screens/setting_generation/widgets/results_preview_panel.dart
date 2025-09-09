import 'package:flutter/material.dart';
import 'ai_shimmer_placeholder.dart';

class ChapterPreviewData {
  final String title;
  final String outline;
  final String content;

  const ChapterPreviewData({
    required this.title,
    required this.outline,
    required this.content,
  });

  ChapterPreviewData copyWith({String? title, String? outline, String? content}) {
    return ChapterPreviewData(
      title: title ?? this.title,
      outline: outline ?? this.outline,
      content: content ?? this.content,
    );
  }
}

class ResultsPreviewPanel extends StatefulWidget {
  final List<ChapterPreviewData> chapters;
  final bool isGenerating;
  final void Function(int index, ChapterPreviewData updated) onChapterChanged;

  const ResultsPreviewPanel({
    Key? key,
    required this.chapters,
    required this.isGenerating,
    required this.onChapterChanged,
  }) : super(key: key);

  @override
  State<ResultsPreviewPanel> createState() => _ResultsPreviewPanelState();
}

class _ResultsPreviewPanelState extends State<ResultsPreviewPanel> with TickerProviderStateMixin {
  TabController? _tabController; // 允许为空：当无章节时不创建
  List<TextEditingController> _outlineCtrls = const [];
  List<TextEditingController> _contentCtrls = const [];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // 仅当有章节时初始化控制器，避免 TabController 长度为 0 的错误
    if (widget.chapters.isNotEmpty) {
      _initControllers();
    }
  }

  @override
  void didUpdateWidget(covariant ResultsPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当从无到有或长度变化时，重建控制器
    if (oldWidget.chapters.length != widget.chapters.length) {
      _disposeControllers();
      if (widget.chapters.isNotEmpty) {
        _initControllers();
      }
      return;
    }
    // 同步内容（有章节时）
    if (widget.chapters.isNotEmpty &&
        _outlineCtrls.length == widget.chapters.length &&
        _contentCtrls.length == widget.chapters.length) {
      for (int i = 0; i < widget.chapters.length; i++) {
        _outlineCtrls[i].text = widget.chapters[i].outline;
        _contentCtrls[i].text = widget.chapters[i].content;
      }
    }
  }

  void _initControllers() {
    final tabLen = (widget.chapters.length * 2).clamp(1, 1000); // 至少为1
    _tabController = TabController(length: tabLen, vsync: this);
    _tabController!.addListener(() {
      final currentIndex = _tabController?.index ?? _selectedTabIndex;
      if (_selectedTabIndex != currentIndex) {
        setState(() {
          _selectedTabIndex = currentIndex;
        });
      }
    });
    _outlineCtrls = List.generate(widget.chapters.length, (i) => TextEditingController(text: widget.chapters[i].outline));
    _contentCtrls = List.generate(widget.chapters.length, (i) => TextEditingController(text: widget.chapters[i].content));
  }

  void _disposeControllers() {
    _tabController?.dispose();
    _tabController = null;
    for (final c in _outlineCtrls) {
      c.dispose();
    }
    for (final c in _contentCtrls) {
      c.dispose();
    }
    _outlineCtrls = const [];
    _contentCtrls = const [];
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chapters.isEmpty) {
      return widget.isGenerating
          ? const AIShimmerPlaceholder()
          : _buildEmptyResults(context, '暂无结果，点击右上角生成');
    }
    // 确保在首次有章节时已初始化控制器（防御性）
    if (_tabController == null) {
      _initControllers();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 多行自适应子Tab
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _buildMultiLineTabs(context),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController!,
            children: _buildTabViews(context),
          ),
        ),
      ],
    );
  }

  // 多行自适应标签头
  Widget _buildMultiLineTabs(BuildContext context) {
    final chips = <Widget>[];
    for (int i = 0; i < widget.chapters.length; i++) {
      final title = (widget.chapters[i].title.isNotEmpty) ? widget.chapters[i].title : '无标题';
      chips.add(_buildTabChip(context, index: i * 2, label: '第${i + 1}章-$title-大纲'));
      chips.add(_buildTabChip(context, index: i * 2 + 1, label: '第${i + 1}章-$title-正文'));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildTabChip(BuildContext context, {required int index, required String label}) {
    final bool selected = index == _selectedTabIndex;
    final theme = Theme.of(context);
    final selectedBg = theme.colorScheme.primary.withOpacity(0.12);
    final borderColor = selected ? theme.colorScheme.primary : theme.dividerColor;
    final textStyle = selected
        ? theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)
        : theme.textTheme.bodyMedium;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
          _tabController?.animateTo(index);
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Text(
          label,
          softWrap: true,
          overflow: TextOverflow.fade,
          maxLines: 2,
          style: textStyle,
        ),
      ),
    );
  }

  List<Widget> _buildTabViews(BuildContext context) {
    final List<Widget> views = [];
    for (int i = 0; i < widget.chapters.length; i++) {
      views.add(_buildPlainEditor(context, i, isOutline: true));
      views.add(_buildPlainEditor(context, i, isOutline: false));
    }
    return views;
  }

  // 极简编辑器：
  // - 无背景、无内边距
  // - 自适应高度（minLines=1, maxLines=null）
  // - 无头部小标签
  Widget _buildPlainEditor(BuildContext context, int index, {required bool isOutline}) {
    final controller = isOutline ? _outlineCtrls[index] : _contentCtrls[index];
    final onChanged = (String text) {
      if (isOutline) {
        widget.onChapterChanged(index, widget.chapters[index].copyWith(outline: text));
      } else {
        widget.onChapterChanged(index, widget.chapters[index].copyWith(content: text));
      }
    };

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          hintText: '',
        ),
        keyboardType: TextInputType.multiline,
        minLines: 1,
        maxLines: null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEmptyResults(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 48, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}


