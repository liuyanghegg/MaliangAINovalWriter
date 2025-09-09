import 'package:flutter/material.dart';
import 'package:ainoval/models/novel_structure.dart';

/// 场景选择器组件
/// 提供场景信息显示和下拉选择功能，支持大量场景的性能优化
class SceneSelector extends StatefulWidget {
  const SceneSelector({
    Key? key,
    required this.novel,
    required this.activeSceneId,
    required this.onSceneSelected,
    this.onSummaryLoaded,
    this.compact = false,
  }) : super(key: key);

  final Novel novel;
  final String? activeSceneId;
  final Function(String sceneId, String actId, String chapterId) onSceneSelected;
  final Function(String summary)? onSummaryLoaded;
  final bool compact;

  @override
  State<SceneSelector> createState() => _SceneSelectorState();
}

class _SceneSelectorState extends State<SceneSelector> {
  final GlobalKey _buttonKey = GlobalKey();
  List<_SceneItem> _cachedSceneItems = [];
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  
  @override
  void initState() {
    super.initState();
    _buildSceneItemsCache();
  }

  @override
  void didUpdateWidget(SceneSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.novel != widget.novel) {
      _buildSceneItemsCache();
    }
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  /// 构建场景项缓存，提高性能
  void _buildSceneItemsCache() {
    _cachedSceneItems = [];
    
    for (final act in widget.novel.acts) {
      // 添加Act分组标题
      _cachedSceneItems.add(_SceneItem(
        type: _SceneItemType.actHeader,
        title: act.title,
        actId: act.id,
      ));

      // 添加Act下的Chapter和Scene
      for (final chapter in act.chapters) {
        // 添加Chapter分组标题
        _cachedSceneItems.add(_SceneItem(
          type: _SceneItemType.chapterHeader,
          title: chapter.title,
          actId: act.id,
          chapterId: chapter.id,
        ));

        // 添加Scene
        for (int i = 0; i < chapter.scenes.length; i++) {
          final scene = chapter.scenes[i];
          _cachedSceneItems.add(_SceneItem(
            type: _SceneItemType.scene,
            title: scene.title,
            actId: act.id,
            chapterId: chapter.id,
            sceneId: scene.id,
            sceneIndex: i,
                         sceneSummary: scene.summary?.content,
          ));
        }
      }
    }
  }

  /// 打开下拉菜单
  void _openDropdown() {
    if (_isDropdownOpen) return;
    
    final RenderBox buttonRenderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final buttonPosition = buttonRenderBox.localToGlobal(Offset.zero);
    final buttonSize = buttonRenderBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _DropdownOverlay(
        buttonPosition: buttonPosition,
        buttonSize: buttonSize,
        items: _cachedSceneItems,
        activeSceneId: widget.activeSceneId,
        onItemSelected: (sceneId, actId, chapterId) {
          _closeDropdown();
          widget.onSceneSelected(sceneId, actId, chapterId);
        },
        onClose: _closeDropdown,
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  /// 关闭下拉菜单
  void _closeDropdown() {
    if (!_isDropdownOpen) return;
    
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isDropdownOpen = false;
    });
  }

  /// 获取当前场景信息
  String _getCurrentSceneInfo() {
    final activeScene = _getActiveScene();
    if (activeScene == null) return '未选择场景';
    
    final scenePosition = _getScenePosition(activeScene);
    if (widget.compact) {
      return scenePosition;
    }
    
    return '$scenePosition · ${activeScene.title}';
  }

  /// 获取当前激活的场景
  Scene? _getActiveScene() {
    if (widget.activeSceneId == null) return null;
    
    for (final act in widget.novel.acts) {
      for (final chapter in act.chapters) {
        for (final scene in chapter.scenes) {
          if (scene.id == widget.activeSceneId) {
            return scene;
          }
        }
      }
    }
    return null;
  }

  /// 获取场景位置信息
  String _getScenePosition(Scene scene) {
    int actIndex = 0;
    int chapterIndex = 0;
    int sceneIndex = 0;
    
    for (int i = 0; i < widget.novel.acts.length; i++) {
      final act = widget.novel.acts[i];
      for (int j = 0; j < act.chapters.length; j++) {
        final chapter = act.chapters[j];
        for (int k = 0; k < chapter.scenes.length; k++) {
          final sceneItem = chapter.scenes[k];
          if (sceneItem.id == scene.id) {
            actIndex = i + 1;
            chapterIndex = j + 1;
            sceneIndex = k + 1;
            break;
          }
        }
      }
    }
    
    return '第${actIndex}卷 · 第${chapterIndex}章 · 第${sceneIndex}场';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _buttonKey,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isDropdownOpen ? Colors.blue : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: _isDropdownOpen ? [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isDropdownOpen ? _closeDropdown : _openDropdown,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.grey[50],
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getCurrentSceneInfo(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: _isDropdownOpen ? Colors.blue : Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 自定义下拉菜单覆盖层
class _DropdownOverlay extends StatefulWidget {
  const _DropdownOverlay({
    required this.buttonPosition,
    required this.buttonSize,
    required this.items,
    required this.activeSceneId,
    required this.onItemSelected,
    required this.onClose,
  });

  final Offset buttonPosition;
  final Size buttonSize;
  final List<_SceneItem> items;
  final String? activeSceneId;
  final Function(String sceneId, String actId, String chapterId) onItemSelected;
  final VoidCallback onClose;

  @override
  State<_DropdownOverlay> createState() => _DropdownOverlayState();
}

class _DropdownOverlayState extends State<_DropdownOverlay> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 计算下拉菜单的位置和大小
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = 300.0; // 增加最大高度
    
    // 计算菜单位置，确保上边缘紧贴按钮下边缘
    final menuTop = widget.buttonPosition.dy + widget.buttonSize.height;
    final menuLeft = widget.buttonPosition.dx;
    final menuWidth = widget.buttonSize.width;
    
    // 确保菜单不会超出屏幕
    final availableHeight = screenSize.height - menuTop - 20;
    final menuHeight = maxHeight < availableHeight ? maxHeight : availableHeight;

    return Stack(
      children: [
        // 背景遮罩，点击关闭下拉菜单
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        // 下拉菜单
        Positioned(
          left: menuLeft,
          top: menuTop,
          width: menuWidth,
          height: menuHeight,
          child: Material(
            elevation: 12, // 增加阴影
            borderRadius: BorderRadius.circular(8),
            shadowColor: Colors.black.withOpacity(0.15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Column(
                children: [
                  // 显示场景数量限制提示
                  if (widget.items.where((item) => item.type == _SceneItemType.scene).length > 200)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '场景数量过多，仅显示前200个场景',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // 场景列表
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        scrollbarTheme: ScrollbarThemeData(
                          thickness: MaterialStateProperty.all(6),
                          radius: const Radius.circular(3),
                          thumbColor: MaterialStateProperty.all(Colors.grey[400]),
                          trackColor: MaterialStateProperty.all(Colors.grey[200]),
                        ),
                      ),
                      child: Scrollbar(
                        controller: _scrollController,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: widget.items.length,
                          itemBuilder: (context, index) {
                            final item = widget.items[index];
                            return _buildDropdownItem(item);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownItem(_SceneItem item) {
    switch (item.type) {
      case _SceneItemType.actHeader:
        return Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            item.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
        );
      
      case _SceneItemType.chapterHeader:
        return Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          alignment: Alignment.centerLeft,
          child: Text(
            item.title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        );
      
      case _SceneItemType.scene:
        final isSelected = item.sceneId == widget.activeSceneId;
        final hasSummary = item.sceneSummary != null && item.sceneSummary!.isNotEmpty;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Material(
            color: isSelected ? Colors.blue[50] : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: () {
                widget.onItemSelected(item.sceneId!, item.actId, item.chapterId!);
              },
              borderRadius: BorderRadius.circular(6),
              hoverColor: isSelected ? Colors.blue[100] : Colors.grey[100],
              splashColor: isSelected ? Colors.blue[200] : Colors.grey[200],
              child: Container(
                // 动态高度：有摘要时使用更大的高度
                height: hasSummary ? 44 : 30,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 12),
                    // 场景序号容器，固定在顶部对齐
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[700],
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ] : null,
                        ),
                        child: Center(
                          child: Text(
                            '${item.sceneIndex! + 1}',
                            style: const TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.blue[700] : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasSummary) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.sceneSummary!,
                              style: TextStyle(
                                fontSize: 9,
                                color: isSelected ? Colors.blue[600] : Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}

/// 场景项类型枚举
enum _SceneItemType {
  actHeader,
  chapterHeader,
  scene,
}

/// 场景项数据类
class _SceneItem {
  final _SceneItemType type;
  final String title;
  final String actId;
  final String? chapterId;
  final String? sceneId;
  final int? sceneIndex;
  final String? sceneSummary;

  _SceneItem({
    required this.type,
    required this.title,
    required this.actId,
    this.chapterId,
    this.sceneId,
    this.sceneIndex,
    this.sceneSummary,
  });
} 