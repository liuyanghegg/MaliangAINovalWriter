// import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ainoval/models/novel_structure.dart';
import 'package:ainoval/models/novel_setting_item.dart';
import 'package:ainoval/models/novel_snippet.dart';
import 'package:ainoval/models/setting_group.dart';
import 'package:ainoval/models/setting_type.dart';

/// 上下文选择类型枚举
enum ContextSelectionType {
  fullNovelText('所有章节内容', Icons.menu_book),
  fullOutline('完整大纲', Icons.format_list_bulleted),
  novelBasicInfo('小说基本信息', Icons.info_outline),
  recentChaptersContent('最近5章内容', Icons.history_edu),
  recentChaptersSummary('最近5章摘要', Icons.summarize),
  // 固定分组（仅用于前端分组显示，不参与API传输）
  contentFixedGroup('内容分组', Icons.article_outlined),
  summaryFixedGroup('摘要分组', Icons.summarize),
  // 新增固定类型（内容/摘要）
  currentSceneContent('当前场景内容', Icons.movie_outlined),
  currentSceneSummary('当前场景摘要', Icons.summarize),
  currentChapterContent('当前章节内容', Icons.article_outlined),
  currentChapterSummaries('当前章节所有摘要', Icons.summarize),
  previousChaptersContent('之前所有章节内容', Icons.history_edu),
  previousChaptersSummary('之前所有章节摘要', Icons.summarize),
  acts('卷', Icons.bookmark_border),
  chapters('章节', Icons.article_outlined),
  scenes('场景', Icons.movie_outlined),
  snippets('片段', Icons.content_cut),
  settings('设定', Icons.settings_outlined),
  settingGroups('设定分组', Icons.folder_special_outlined),
  settingsByType('按设定类型', Icons.category_outlined),
  codexEntries('知识条目', Icons.library_books_outlined),
  entriesByType('按条目类型', Icons.category_outlined),
  entriesByDetail('按条目详情', Icons.info_outline),
  entriesByCategory('按条目分类', Icons.folder_outlined),
  entriesByTag('按条目标签', Icons.local_offer_outlined);

  const ContextSelectionType(this.displayName, this.icon);

  final String displayName;
  final IconData icon;
}

/// 上下文选择项
class ContextSelectionItem {
  const ContextSelectionItem({
    required this.id,
    required this.title,
    required this.type,
    this.subtitle,
    this.children = const [],
    this.parentId,
    this.metadata = const {},
    this.selectionState = SelectionState.unselected,
    this.order = 0,
  });

  /// 唯一标识
  final String id;

  /// 显示标题
  final String title;

  /// 选择类型
  final ContextSelectionType type;

  /// 副标题（可选）
  final String? subtitle;

  /// 子项列表
  final List<ContextSelectionItem> children;

  /// 父项ID（用于扁平化结构）
  final String? parentId;

  /// 元数据（可存储字数、章节数等信息）
  final Map<String, dynamic> metadata;

  /// 选择状态
  final SelectionState selectionState;

  /// 排序顺序
  final int order;

  /// 创建副本
  ContextSelectionItem copyWith({
    String? id,
    String? title,
    ContextSelectionType? type,
    String? subtitle,
    List<ContextSelectionItem>? children,
    String? parentId,
    Map<String, dynamic>? metadata,
    SelectionState? selectionState,
    int? order,
  }) {
    return ContextSelectionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      subtitle: subtitle ?? this.subtitle,
      children: children ?? this.children,
      parentId: parentId ?? this.parentId,
      metadata: metadata ?? this.metadata,
      selectionState: selectionState ?? this.selectionState,
      order: order ?? this.order,
    );
  }

  /// 是否有子项
  bool get hasChildren => children.isNotEmpty;

  /// 获取显示的子标题信息
  String get displaySubtitle {
    if (subtitle != null && subtitle!.isNotEmpty) {
      return subtitle!;
    }
    
    // 根据类型和元数据生成子标题
    switch (type) {
      case ContextSelectionType.scenes:
        final wordCount = metadata['wordCount'] ?? 0;
        return wordCount > 0 ? '$wordCount 词' : '无内容';
      case ContextSelectionType.chapters:
        final sceneCount = metadata['sceneCount'] ?? 0;
        final wordCount = metadata['wordCount'] ?? 0;
        if (sceneCount > 0 && wordCount > 0) {
          return '$sceneCount 个场景，$wordCount 词';
        } else if (sceneCount > 0) {
          return '$sceneCount 个场景';
        } else if (wordCount > 0) {
          return '$wordCount 词';
        }
        return '无内容';
      case ContextSelectionType.acts:
        final chapterCount = metadata['chapterCount'] ?? 0;
        final sceneCount = metadata['sceneCount'] ?? 0;
        if (chapterCount > 0 && sceneCount > 0) {
          return '$chapterCount 个章节，$sceneCount 个场景';
        } else if (chapterCount > 0) {
          return '$chapterCount 个章节';
        } else if (sceneCount > 0) {
          return '$sceneCount 个场景';
        }
        return '无内容';
      case ContextSelectionType.snippets:
        final wordCount = metadata['wordCount'] ?? 0;
        final itemCount = metadata['itemCount'] ?? 0;
        if (itemCount > 0 && wordCount > 0) {
          return '$itemCount 个片段，$wordCount 词';
        } else if (itemCount > 0) {
          return '$itemCount 个片段';
        } else if (wordCount > 0) {
          return '$wordCount 词';
        }
        return '无片段';
      case ContextSelectionType.settings:
        final itemCount = metadata['itemCount'] ?? 0;
        return itemCount > 0 ? '$itemCount 个设定' : '无设定';
      case ContextSelectionType.settingGroups:
        // 顶级容器显示组数量，个别组显示设定数量
        final groupCount = metadata['groupCount'];
        final itemCount = metadata['itemCount'];
        if (groupCount != null) {
          return groupCount > 0 ? '$groupCount 个分组' : '无分组';
        } else if (itemCount != null) {
          return itemCount > 0 ? '$itemCount 个设定' : '无设定';
        }
        return '';
      case ContextSelectionType.settingsByType:
        // 父容器：显示类型数量
        final groupCount = metadata['groupCount'];
        if (groupCount != null) {
          return groupCount > 0 ? '$groupCount 个类型' : '无类型';
        }
        // 子项：显示该类型下的条目数
        final itemCount = metadata['itemCount'] ?? 0;
        final settingType = metadata['settingType'];
        if (settingType != null) {
          final String zhType = _resolveSettingTypeZh(settingType);
          return itemCount > 0 ? '$zhType（$itemCount 项）' : '$zhType（无条目）';
        }
        return itemCount > 0 ? '$itemCount 项' : '无条目';
      case ContextSelectionType.fullNovelText:
        final wordCount = metadata['wordCount'] ?? 0;
        return wordCount > 0 ? '$wordCount 词' : '无内容';
      case ContextSelectionType.currentSceneContent:
        return '当前场景文本内容';
      case ContextSelectionType.currentSceneSummary:
        return '当前场景摘要';
      case ContextSelectionType.currentChapterContent:
        final wordCount2 = metadata['wordCount'] ?? 0;
        return wordCount2 > 0 ? '当前章节内容 · $wordCount2 词' : '当前章节内容';
      case ContextSelectionType.currentChapterSummaries:
        final count = metadata['summaryCount'] ?? 0;
        return count > 0 ? '当前章节摘要 · $count 条' : '当前章节摘要';
      case ContextSelectionType.previousChaptersContent:
        final prevCount = metadata['chapterCount'] ?? 0;
        final totalWords2 = metadata['totalWords'] ?? 0;
        if (prevCount == 0) return '无之前章节';
        return totalWords2 > 0 ? '之前$prevCount章内容，共$totalWords2词' : '之前$prevCount章内容';
      case ContextSelectionType.previousChaptersSummary:
        final prevSumCount = metadata['chapterCount'] ?? 0;
        final summaryCount2 = metadata['summaryCount'] ?? 0;
        if (prevSumCount == 0) return '无之前章节';
        return summaryCount2 > 0 ? '之前$prevSumCount章摘要，共$summaryCount2条' : '之前$prevSumCount章摘要';
      case ContextSelectionType.contentFixedGroup:
      case ContextSelectionType.summaryFixedGroup:
        return '';
      // 🚀 新增：基本信息和前五章相关类型的子标题
      case ContextSelectionType.novelBasicInfo:
        return '小说的基本信息，包括标题、作者、简介等';
      case ContextSelectionType.recentChaptersContent:
        final chapterCount = metadata['chapterCount'] ?? 5;
        final totalWords = metadata['totalWords'] ?? 0;
        return totalWords > 0 ? '最近$chapterCount章内容，共$totalWords词' : '最近$chapterCount章内容';
      case ContextSelectionType.recentChaptersSummary:
        final chapterCount = metadata['chapterCount'] ?? 5;
        final summaryCount = metadata['summaryCount'] ?? 0;
        return summaryCount > 0 ? '最近$chapterCount章摘要，共$summaryCount条' : '最近$chapterCount章摘要';
      default:
        return '';
    }
  }
}

/// 选择状态枚举
enum SelectionState {
  /// 未选中
  unselected,
  /// 部分选中（有子项被选中）
  partiallySelected,
  /// 完全选中
  fullySelected;

  /// 获取对应的图标
  IconData? get icon {
    switch (this) {
      case SelectionState.fullySelected:
        return Icons.check_circle;
      case SelectionState.partiallySelected:
        return Icons.circle;
      case SelectionState.unselected:
        return null;
    }
  }

  /// 是否为选中状态（包括部分选中）
  bool get isSelected => this != SelectionState.unselected;
}

/// 上下文选择数据
class ContextSelectionData {
  const ContextSelectionData({
    required this.novelId,
    this.selectedItems = const {},
    this.availableItems = const [],
    this.flatItems = const {},
  });

  /// 小说ID
  final String novelId;

  /// 已选择的项目 (itemId -> ContextSelectionItem)
  final Map<String, ContextSelectionItem> selectedItems;

  /// 可用的选择项（树形结构）
  final List<ContextSelectionItem> availableItems;

  /// 扁平化的选择项映射 (itemId -> ContextSelectionItem)
  final Map<String, ContextSelectionItem> flatItems;

  /// 创建副本
  ContextSelectionData copyWith({
    String? novelId,
    Map<String, ContextSelectionItem>? selectedItems,
    List<ContextSelectionItem>? availableItems,
    Map<String, ContextSelectionItem>? flatItems,
  }) {
    return ContextSelectionData(
      novelId: novelId ?? this.novelId,
      selectedItems: selectedItems ?? this.selectedItems,
      availableItems: availableItems ?? this.availableItems,
      flatItems: flatItems ?? this.flatItems,
    );
  }

  /// 选择项目
  ContextSelectionData selectItem(String itemId, {bool selectChildren = false}) {
    final item = flatItems[itemId];
    if (item == null) {
      if (kDebugMode) debugPrint('🚨 selectItem: 项目不存在 $itemId');
      return this;
    }

    if (kDebugMode) debugPrint('🚀 selectItem: 开始选择项目 ${item.title} (${item.id})${selectChildren ? ' 及其子项' : ''}');

    final newSelectedItems = Map<String, ContextSelectionItem>.from(selectedItems);
    final newFlatItems = Map<String, ContextSelectionItem>.from(flatItems);

    // 🚦 单选分组：如果属于 内容/摘要 固定分组，则取消同组其他子项的选择
    final String? parentId = item.parentId;
    if (parentId != null) {
      final ContextSelectionItem? parent = newFlatItems[parentId] ?? flatItems[parentId];
      if (parent != null && (parent.type == ContextSelectionType.contentFixedGroup || parent.type == ContextSelectionType.summaryFixedGroup)) {
        // 取消同组其他子项
        final siblingIds = newFlatItems.values
            .where((i) => i.parentId == parent.id)
            .map((i) => i.id)
            .toList();
        for (final sibId in siblingIds) {
          if (sibId == item.id) continue;
          final sib = newFlatItems[sibId];
          if (sib != null && sib.selectionState.isSelected) {
            newSelectedItems.remove(sibId);
            newFlatItems[sibId] = sib.copyWith(selectionState: SelectionState.unselected);
          }
        }
      }
    }

    // 添加到选中列表
    newSelectedItems[itemId] = item.copyWith(selectionState: SelectionState.fullySelected);

    // 更新扁平化映射中的状态
    newFlatItems[itemId] = item.copyWith(selectionState: SelectionState.fullySelected);

    // 🚀 新增：如果需要选择子项，递归选择所有子项
    if (selectChildren) {
      _selectAllChildren(item, newFlatItems, newSelectedItems);
    }

    if (kDebugMode) debugPrint('  ✅ 已更新选中列表和扁平化映射');

    // 更新父项的选择状态
    _updateParentSelectionState(item, newFlatItems, newSelectedItems);

    if (kDebugMode) debugPrint('  ✅ 已更新父项选择状态');

    // 重新构建树形结构
    final newAvailableItems = _rebuildTreeWithUpdatedStates(newFlatItems);

    if (kDebugMode) debugPrint('  ✅ 已重建树形结构');
    if (kDebugMode) debugPrint('🚀 selectItem: 完成，当前选中项目数: ${newSelectedItems.length}');

    return copyWith(
      selectedItems: newSelectedItems,
      availableItems: newAvailableItems,
      flatItems: newFlatItems,
    );
  }

  /// 取消选择项目
  ContextSelectionData deselectItem(String itemId) {
    final newSelectedItems = Map<String, ContextSelectionItem>.from(selectedItems);
    final newFlatItems = Map<String, ContextSelectionItem>.from(flatItems);

    // 从选中列表移除
    newSelectedItems.remove(itemId);

    // 更新扁平化映射中的状态
    final item = newFlatItems[itemId];
    if (item != null) {
      newFlatItems[itemId] = item.copyWith(selectionState: SelectionState.unselected);

      // 如果是固定分组子项，取消选择就是简单恢复未选状态
      // 父组状态由后续 _updateParentSelectionState 统一更新

      // 递归取消选择所有子项
      _deselectAllChildren(item, newFlatItems, newSelectedItems);

      // 更新父项的选择状态
      _updateParentSelectionState(item, newFlatItems, newSelectedItems);
    }

    // 重新构建树形结构
    final newAvailableItems = _rebuildTreeWithUpdatedStates(newFlatItems);

    return copyWith(
      selectedItems: newSelectedItems,
      availableItems: newAvailableItems,
      flatItems: newFlatItems,
    );
  }

  /// 获取选中项的数量
  int get selectedCount => selectedItems.length;

  /// 🚀 根据预设的上下文选择来更新当前选择状态
  /// 保持当前的菜单结构，根据预设中的具体项目ID来精确匹配并选择对应项目
  ContextSelectionData applyPresetSelections(ContextSelectionData presetSelections) {
    if (kDebugMode) debugPrint('🚀 [ContextSelectionData] 开始应用预设上下文选择');
    
    // 收集预设里选中的具体项目ID
    final presetSelectedIds = <String>{};
    for (final presetItem in presetSelections.selectedItems.values) {
      presetSelectedIds.add(presetItem.id);
      if (kDebugMode) debugPrint('🚀 [ContextSelectionData] 预设选择项目: ${presetItem.title} (${presetItem.id})');
    }
    if (kDebugMode) debugPrint('🚀 [ContextSelectionData] 预设共选择了 ${presetSelectedIds.length} 个具体项目');
    
    // 1) 清空现有选择，全部置为未选
    final Map<String, ContextSelectionItem> newFlatItems = flatItems.map(
      (key, value) => MapEntry(key, value.copyWith(selectionState: SelectionState.unselected)),
    );
    final Map<String, ContextSelectionItem> newSelectedItems = {};
    
    // 2) 单选分组去重：同一父为 contentFixedGroup/summaryFixedGroup 仅保留一个
    final Map<String, String> singleSelectChosenByParent = {};
    final List<String> finalIds = [];
    for (final id in presetSelectedIds) {
      final item = newFlatItems[id];
      if (item == null) continue;
      final parentId = item.parentId;
      if (parentId != null) {
        final parent = newFlatItems[parentId];
        if (parent != null && (parent.type == ContextSelectionType.contentFixedGroup || parent.type == ContextSelectionType.summaryFixedGroup)) {
          if (singleSelectChosenByParent.containsKey(parentId)) {
            // 已有同组选择，跳过后续同组项
            continue;
          }
          singleSelectChosenByParent[parentId] = id;
        }
      }
      finalIds.add(id);
    }
    
    // 3) 一次性标记选中项
    for (final id in finalIds) {
      final item = newFlatItems[id];
      if (item == null) continue;
      newSelectedItems[id] = item.copyWith(selectionState: SelectionState.fullySelected);
      newFlatItems[id] = item.copyWith(selectionState: SelectionState.fullySelected);
    }
    
    // 4) 更新所有相关父项的选择状态（自底向上）
    for (final id in finalIds) {
      final item = newFlatItems[id];
      if (item != null) {
        _updateParentSelectionState(item, newFlatItems, newSelectedItems);
      }
    }
    
    // 5) 重建树形结构一次
    final newAvailableItems = _rebuildTreeWithUpdatedStates(newFlatItems);
    final updatedData = copyWith(
      selectedItems: newSelectedItems,
      availableItems: newAvailableItems,
      flatItems: newFlatItems,
    );
    
    if (kDebugMode) debugPrint('🚀 [ContextSelectionData] 应用后总选择数: ${updatedData.selectedCount}');
    return updatedData;
  }

  /// 🚀 合并两个上下文选择数据
  /// 保留当前的所有选择，并添加新数据中未被选择的项目
  /// 这与 applyPresetSelections 不同，后者会清除现有选择后重新应用
  ContextSelectionData mergeSelections(ContextSelectionData newSelections) {
    debugPrint('🚀 [ContextSelectionData] 开始合并上下文选择');
    debugPrint('🚀 [ContextSelectionData] 当前选择数: ${selectedCount}');
    debugPrint('🚀 [ContextSelectionData] 新增选择数: ${newSelections.selectedCount}');
    
    ContextSelectionData merged = this;
    int addedCount = 0;
    
    // 遍历新选择的项目，将尚未选择的项目添加到当前选择中
    for (final newItem in newSelections.selectedItems.values) {
      if (!merged.selectedItems.containsKey(newItem.id)) {
        // 检查当前数据中是否存在对应的项目
        if (merged.flatItems.containsKey(newItem.id)) {
          merged = merged.selectItem(newItem.id);
          addedCount++;
          debugPrint('🚀 [ContextSelectionData] 添加新选择: ${newItem.title} (${newItem.type.displayName})');
        } else {
          debugPrint('⚠️ [ContextSelectionData] 跳过不存在的项目: ${newItem.title} (${newItem.id})');
        }
      } else {
        debugPrint('🔄 [ContextSelectionData] 项目已存在，跳过: ${newItem.title}');
      }
    }
    
    debugPrint('🚀 [ContextSelectionData] 合并完成，新增了 $addedCount 个选择');
    debugPrint('🚀 [ContextSelectionData] 合并后总选择数: ${merged.selectedCount}');
    
    return merged;
  }

  /// 更新父项的选择状态
  void _updateParentSelectionState(
    ContextSelectionItem item,
    Map<String, ContextSelectionItem> flatItems,
    Map<String, ContextSelectionItem> selectedItems,
  ) {
    if (item.parentId == null) return;

    final parent = flatItems[item.parentId];
    if (parent == null) return;

    // 计算父项的子项选择状态
    final childrenIds = flatItems.values
        .where((i) => i.parentId == parent.id)
        .map((i) => i.id)
        .toList();

    final selectedChildrenCount = childrenIds
        .where((id) => flatItems[id]?.selectionState.isSelected == true)
        .length;

    SelectionState newParentState;
    if (selectedChildrenCount == 0) {
      newParentState = SelectionState.unselected;
      selectedItems.remove(parent.id);
    } else if (selectedChildrenCount == childrenIds.length) {
      newParentState = SelectionState.fullySelected;
      // 🚀 修复：即使所有子项都被选中，也不自动将父项添加到选中列表
      // 只有用户明确选择父项本身时，父项才会被添加到选中列表
      selectedItems.remove(parent.id);
    } else {
      newParentState = SelectionState.partiallySelected;
      // 对于部分选中的父项，只更新其状态但不加入 selectedItems，
      // 这样在 UI 标签列表中只会显示实际被选中的叶子节点，避免重复显示。
      selectedItems.remove(parent.id);
    }

    flatItems[parent.id] = parent.copyWith(selectionState: newParentState);

    // 递归更新上级父项
    _updateParentSelectionState(parent, flatItems, selectedItems);
  }

  /// 🚀 新增：递归选择所有子项
  void _selectAllChildren(
    ContextSelectionItem item,
    Map<String, ContextSelectionItem> flatItems,
    Map<String, ContextSelectionItem> selectedItems,
  ) {
    final childrenIds = flatItems.values
        .where((i) => i.parentId == item.id)
        .map((i) => i.id)
        .toList();

    for (final childId in childrenIds) {
      final child = flatItems[childId];
      if (child != null) {
        selectedItems[childId] = child.copyWith(selectionState: SelectionState.fullySelected);
        flatItems[childId] = child.copyWith(selectionState: SelectionState.fullySelected);
        _selectAllChildren(child, flatItems, selectedItems);
      }
    }
  }

  /// 递归取消选择所有子项
  void _deselectAllChildren(
    ContextSelectionItem item,
    Map<String, ContextSelectionItem> flatItems,
    Map<String, ContextSelectionItem> selectedItems,
  ) {
    final childrenIds = flatItems.values
        .where((i) => i.parentId == item.id)
        .map((i) => i.id)
        .toList();

    for (final childId in childrenIds) {
      selectedItems.remove(childId);
      final child = flatItems[childId];
      if (child != null) {
        flatItems[childId] = child.copyWith(selectionState: SelectionState.unselected);
        _deselectAllChildren(child, flatItems, selectedItems);
      }
    }
  }

  /// 重新构建树形结构
  List<ContextSelectionItem> _rebuildTreeWithUpdatedStates(
    Map<String, ContextSelectionItem> flatItems,
  ) {
    // 递归更新树形结构中的所有项目状态
    return availableItems.map((item) => _rebuildItemWithUpdatedState(item, flatItems)).toList();
  }

  /// 递归重建单个项目及其子项的状态
  ContextSelectionItem _rebuildItemWithUpdatedState(
    ContextSelectionItem item,
    Map<String, ContextSelectionItem> flatItems,
  ) {
    // 获取更新后的项目状态
    final updatedItem = flatItems[item.id] ?? item;
    
    // 检查状态是否有变化
    if (updatedItem.selectionState != item.selectionState) {
      if (kDebugMode) debugPrint('  🔄 状态更新: ${item.title} ${item.selectionState} → ${updatedItem.selectionState}');
    }
    
    // 如果有子项，递归更新子项状态
    if (item.children.isNotEmpty) {
      final updatedChildren = item.children.map((child) => 
        _rebuildItemWithUpdatedState(child, flatItems)
      ).toList();
      
      return updatedItem.copyWith(children: updatedChildren);
    }
    
    return updatedItem;
  }
}

/// 上下文选择数据构建器
class ContextSelectionDataBuilder {
  /// 从小说结构构建上下文选择数据
  static ContextSelectionData fromNovel(Novel novel) {
    final List<ContextSelectionItem> items = [];
    final Map<String, ContextSelectionItem> flatItems = {};

    // 顶部固定分组：内容/摘要
    final contentGroupId = 'content_fixed_${novel.id}';
    final summaryGroupId = 'summary_fixed_${novel.id}';

    // 内容分组子项
    final List<ContextSelectionItem> contentChildren = [
      ContextSelectionItem(
        id: 'current_scene_content_${novel.id}',
        title: '当前场景内容',
        type: ContextSelectionType.currentSceneContent,
        parentId: contentGroupId,
        order: 0,
      ),
      ContextSelectionItem(
        id: 'current_chapter_content_${novel.id}',
        title: '当前章节内容',
        type: ContextSelectionType.currentChapterContent,
        parentId: contentGroupId,
        metadata: {'wordCount': 0},
        order: 1,
      ),
      ContextSelectionItem(
        id: 'previous_chapters_content_${novel.id}',
        title: '之前所有章节内容',
        type: ContextSelectionType.previousChaptersContent,
        parentId: contentGroupId,
        metadata: {
          'chapterCount': novel.getChapterCount() > 0 ? (novel.getChapterCount() - 1) : 0,
          'totalWords': 0,
        },
        order: 2,
      ),
      ContextSelectionItem(
        id: 'recent_chapters_content_${novel.id}',
        title: '最近5章内容',
        type: ContextSelectionType.recentChaptersContent,
        parentId: contentGroupId,
        metadata: {
          'chapterCount': 5,
          'totalWords': _calculateRecentChaptersWords(novel, 5),
          'includesCurrent': true,
        },
        order: 3,
      ),
      ContextSelectionItem(
        id: 'full_novel_${novel.id}',
        title: '所有章节内容',
        type: ContextSelectionType.fullNovelText,
        parentId: contentGroupId,
        subtitle: '包含所有小说文本，这将产生费用',
        metadata: {'wordCount': novel.wordCount},
        order: 4,
      ),
    ];

    // 摘要分组子项
    final List<ContextSelectionItem> summaryChildren = [
      ContextSelectionItem(
        id: 'current_scene_summary_${novel.id}',
        title: '当前场景摘要',
        type: ContextSelectionType.currentSceneSummary,
        parentId: summaryGroupId,
        order: 0,
      ),
      ContextSelectionItem(
        id: 'current_chapter_summaries_${novel.id}',
        title: '当前章节所有摘要',
        type: ContextSelectionType.currentChapterSummaries,
        parentId: summaryGroupId,
        metadata: {'summaryCount': 0},
        order: 1,
      ),
      ContextSelectionItem(
        id: 'previous_chapters_summary_${novel.id}',
        title: '之前所有章节摘要',
        type: ContextSelectionType.previousChaptersSummary,
        parentId: summaryGroupId,
        metadata: {'chapterCount': 0, 'summaryCount': 0},
        order: 2,
      ),
      ContextSelectionItem(
        id: 'recent_chapters_summary_${novel.id}',
        title: '最近5章摘要',
        type: ContextSelectionType.recentChaptersSummary,
        parentId: summaryGroupId,
        metadata: {'chapterCount': 5, 'summaryCount': _calculateRecentChaptersSummaryCount(novel, 5)},
        order: 3,
      ),
    ];

    final contentGroup = ContextSelectionItem(
      id: contentGroupId,
      title: '内容',
      type: ContextSelectionType.contentFixedGroup,
      children: contentChildren,
      order: 0,
    );
    final summaryGroup = ContextSelectionItem(
      id: summaryGroupId,
      title: '摘要',
      type: ContextSelectionType.summaryFixedGroup,
      children: summaryChildren,
      order: 1,
    );
    items.addAll([contentGroup, summaryGroup]);
    // 将分组与子项加入flat映射，便于父子/同级联动
    flatItems[contentGroup.id] = contentGroup;
    flatItems[summaryGroup.id] = summaryGroup;
    for (final child in contentChildren) {
      flatItems[child.id] = child;
    }
    for (final child in summaryChildren) {
      flatItems[child.id] = child;
    }

    // 🚀 新增：添加小说基本信息选项
    final novelBasicInfoItem = ContextSelectionItem(
      id: 'novel_basic_info_${novel.id}',
      title: '小说基本信息',
      type: ContextSelectionType.novelBasicInfo,
      subtitle: '包含小说标题、作者、简介、类型等基本信息',
      metadata: {
        'hasTitle': novel.title.isNotEmpty,
        'hasAuthor': novel.author?.username.isNotEmpty ?? false,
        'hasDescription': false, // Novel类暂时没有description字段
        'hasGenre': false, // Novel类暂时没有genre字段
      },
      order: 2,
    );
    items.add(novelBasicInfoItem);
    flatItems[novelBasicInfoItem.id] = novelBasicInfoItem;

    // 添加 Acts 选项（层级化结构）- 总是添加，即使为空
    final actsChildren = <ContextSelectionItem>[];
    
    if (novel.acts.isNotEmpty) {
      for (final act in novel.acts) {
        final chapterChildren = _buildChapterItems(act, act.id);
        
        final actItem = ContextSelectionItem(
          id: act.id, // 移除 'act_' 前缀，因为act.id本来就有前缀
          title: act.title.isNotEmpty ? act.title : '第${act.order}卷',
          type: ContextSelectionType.acts,
          parentId: 'acts_${novel.id}',
          metadata: {
            'chapterCount': act.chapters.length,
            'wordCount': act.wordCount,
          },
          order: act.order,
          children: chapterChildren,
        );
        actsChildren.add(actItem);
        
        // 添加到扁平化映射
        flatItems[actItem.id] = actItem;
        
        // 添加章节到扁平化映射
        for (final chapterItem in actItem.children) {
          flatItems[chapterItem.id] = chapterItem;
          
          // 添加场景到扁平化映射
          for (final sceneItem in chapterItem.children) {
            flatItems[sceneItem.id] = sceneItem;
          }
        }
      }
    }

    final actsItem = ContextSelectionItem(
      id: 'acts_${novel.id}',
      title: '卷',
      type: ContextSelectionType.acts,
      children: actsChildren,
      metadata: {
        'chapterCount': actsChildren.fold<int>(0, (sum, act) => sum + (act.metadata['chapterCount'] as int? ?? 0)),
      },
      order: 5,
    );
    items.add(actsItem);
    flatItems[actsItem.id] = actsItem;

    // 添加 Chapters 选项（扁平化显示所有章节）- 总是添加，即使为空
    final allChapters = <ContextSelectionItem>[];
    
    if (novel.acts.isNotEmpty) {
      for (final act in novel.acts) {
        for (final chapter in act.chapters) {
          final sceneChildren = _buildSceneItems(chapter, 'flat_${chapter.id}');
          
          final chapterItem = ContextSelectionItem(
            id: 'flat_${chapter.id}', // 保留flat_前缀避免与层级结构中的chapter.id冲突
            title: chapter.title.isNotEmpty ? chapter.title : '第${chapter.order}章',
            type: ContextSelectionType.chapters,
            parentId: 'chapters_${novel.id}',
            metadata: {
              'sceneCount': chapter.sceneCount,
              'wordCount': chapter.wordCount,
              'actTitle': act.title.isNotEmpty ? act.title : '第${act.order}卷',
            },
            order: chapter.order,
            children: sceneChildren,
          );
          allChapters.add(chapterItem);
          
          // 添加到扁平化映射
          flatItems[chapterItem.id] = chapterItem;
          
          // 添加场景到扁平化映射
          for (final sceneItem in chapterItem.children) {
            flatItems[sceneItem.id] = sceneItem;
          }
        }
      }
    }
    
    final chaptersItem = ContextSelectionItem(
      id: 'chapters_${novel.id}',
      title: '章节',
      type: ContextSelectionType.chapters,
      children: allChapters,
      metadata: {
        'sceneCount': allChapters.fold<int>(0, (sum, chapter) => sum + (chapter.metadata['sceneCount'] as int? ?? 0)),
      },
      order: 6,
    );
    items.add(chaptersItem);
    flatItems[chaptersItem.id] = chaptersItem;

    // 添加 Scenes 选项（扁平化显示所有场景）- 总是添加，即使为空
    final allScenes = <ContextSelectionItem>[];
    
    if (novel.acts.isNotEmpty) {
      for (final act in novel.acts) {
        for (final chapter in act.chapters) {
          for (final scene in chapter.scenes) {
            final sceneItem = ContextSelectionItem(
              id: 'flat_${scene.id}', // 保留flat_前缀避免与层级结构中的scene.id冲突
              title: scene.title.isNotEmpty ? scene.title : '新场景',
              type: ContextSelectionType.scenes,
              parentId: 'scenes_${novel.id}',
              metadata: {
                'wordCount': scene.wordCount,
                'chapterTitle': chapter.title.isNotEmpty ? chapter.title : '第${chapter.order}章',
                'actTitle': act.title.isNotEmpty ? act.title : '第${act.order}卷',
              },
              order: chapter.scenes.indexOf(scene),
            );
            allScenes.add(sceneItem);
            
            // 添加到扁平化映射
            flatItems[sceneItem.id] = sceneItem;
          }
        }
      }
    }
    
    final scenesItem = ContextSelectionItem(
      id: 'scenes_${novel.id}',
      title: '场景',
      type: ContextSelectionType.scenes,
      children: allScenes,
      metadata: {
        'wordCount': allScenes.fold<int>(0, (sum, scene) => sum + (scene.metadata['wordCount'] as int? ?? 0)),
      },
      order: 7,
    );
    items.add(scenesItem);
    flatItems[scenesItem.id] = scenesItem;

    // TODO: 添加其他类型的选项（Snippets, Codex Entries等）

    return ContextSelectionData(
      novelId: novel.id,
      availableItems: items,
      flatItems: flatItems,
    );
  }

  /// 构建章节选择项
  static List<ContextSelectionItem> _buildChapterItems(Act act, String parentId) {
    return act.chapters.map((chapter) {
      return ContextSelectionItem(
        id: chapter.id,
        title: chapter.title.isNotEmpty ? chapter.title : '第${chapter.order}章',
        type: ContextSelectionType.chapters,
        parentId: parentId,
        metadata: {
          'sceneCount': chapter.sceneCount,
          'wordCount': chapter.wordCount,
        },
        order: chapter.order,
        children: _buildSceneItems(chapter, chapter.id),
      );
    }).toList();
  }

  /// 构建场景选择项
  static List<ContextSelectionItem> _buildSceneItems(Chapter chapter, String parentId) {
    return chapter.scenes.map((scene) {
      return ContextSelectionItem(
        id: scene.id,
        title: scene.title.isNotEmpty ? scene.title : '新场景',
        type: ContextSelectionType.scenes,
        parentId: parentId,
        metadata: {
          'wordCount': scene.wordCount,
        },
        order: chapter.scenes.indexOf(scene),
      );
    }).toList();
  }

  /// 从小说结构、设定和片段构建完整的上下文选择数据
  static ContextSelectionData fromNovelWithContext(
    Novel novel, {
    List<NovelSettingItem>? settings,
    List<SettingGroup>? settingGroups,
    List<NovelSnippet>? snippets,
  }) {
    final List<ContextSelectionItem> items = [];
    final Map<String, ContextSelectionItem> flatItems = {};

    // 首先添加基础的小说结构项（Full Novel Text, Full Outline, Acts, Chapters, Scenes）
    final baseData = fromNovel(novel);
    items.addAll(baseData.availableItems);
    flatItems.addAll(baseData.flatItems);

    // 添加片段选项
    if (snippets != null) {
      final snippetsItem = _buildSnippetsItem(novel.id, snippets);
      items.add(snippetsItem);
      flatItems[snippetsItem.id] = snippetsItem;
      
      // 添加片段子项到扁平化映射
      for (final child in snippetsItem.children) {
        flatItems[child.id] = child;
      }
    }

    // 添加设定选项
    if (settings != null || settingGroups != null) {
      final settingsItems = _buildSettingsItems(novel.id, settings ?? [], settingGroups ?? []);
      items.addAll(settingsItems);
      
      // 添加设定项到扁平化映射
      for (final item in settingsItems) {
        flatItems[item.id] = item;
        for (final child in item.children) {
          flatItems[child.id] = child;
          // 如果有孙子项也要添加
          for (final grandChild in child.children) {
            flatItems[grandChild.id] = grandChild;
          }
        }
      }
    }

    return ContextSelectionData(
      novelId: novel.id,
      availableItems: items,
      flatItems: flatItems,
    );
  }

  /// 构建片段选择项
  static ContextSelectionItem _buildSnippetsItem(String novelId, List<NovelSnippet> snippets) {
    final snippetChildren = snippets.map((snippet) {
      return ContextSelectionItem(
        id: 'snippet_${snippet.id}',
        title: snippet.title,
        type: ContextSelectionType.snippets,
        parentId: 'snippets_$novelId',
        subtitle: snippet.content.length > 50 
          ? '${snippet.content.substring(0, 50)}...'
          : snippet.content,
        metadata: {
          'wordCount': snippet.metadata.wordCount,
          'isFavorite': snippet.isFavorite,
          'createdAt': snippet.createdAt.toIso8601String(),
        },
      );
    }).toList();

    return ContextSelectionItem(
      id: 'snippets_$novelId',
      title: '片段',
      type: ContextSelectionType.snippets,
      children: snippetChildren,
      metadata: {
        'itemCount': snippets.length,
      },
      order: 8,
    );
  }

  /// 构建设定选择项
  static List<ContextSelectionItem> _buildSettingsItems(
    String novelId, 
    List<NovelSettingItem> settings,
    List<SettingGroup> settingGroups,
  ) {
    final List<ContextSelectionItem> items = [];

    // 添加设定组选项
    if (settingGroups.isNotEmpty) {
      final groupChildren = settingGroups.map((group) {
        final groupSettings = settings.where((s) => 
          group.itemIds?.contains(s.id) == true
        ).toList();
        
        final settingChildren = groupSettings.map((setting) {
          return _buildSettingItem(setting, 'setting_group_${group.id}');
        }).toList();

        return ContextSelectionItem(
          id: 'setting_group_${group.id}',
          title: group.name,
          type: ContextSelectionType.settingGroups,
          parentId: 'setting_groups_$novelId',
          subtitle: group.description,
          children: settingChildren,
          metadata: {
            'itemCount': groupSettings.length,
            'isActive': group.isActiveContext,
          },
        );
      }).toList();

      final settingGroupsItem = ContextSelectionItem(
        id: 'setting_groups_$novelId',
        title: '设定分组',
        type: ContextSelectionType.settingGroups,
        children: groupChildren,
        metadata: {
          'groupCount': settingGroups.length,
        },
        order: 9,
      );
      items.add(settingGroupsItem);
    }

    // 添加所有设定选项（直接列出所有设定，不再按类型分组）
    if (settings.isNotEmpty) {
      final settingChildren = settings.map((setting) {
        return _buildSettingItem(setting, 'settings_$novelId');
      }).toList();

      final settingsItem = ContextSelectionItem(
        id: 'settings_$novelId',
        title: '设定',
        type: ContextSelectionType.settings,
        children: settingChildren,
        metadata: {
          'itemCount': settings.length,
        },
        order: 10,
      );
      items.add(settingsItem);
    }

    // 🚀 新增：按设定类型分组（Settings by Type）
    if (settings.isNotEmpty) {
      // 统计各类型及其条目
      final Map<String, List<NovelSettingItem>> typeToItems = <String, List<NovelSettingItem>>{};
      for (final s in settings) {
        final String settingType = (s.type ?? 'unknown').toString();
        typeToItems.putIfAbsent(settingType, () => <NovelSettingItem>[]).add(s);
      }

      final List<ContextSelectionItem> typeChildren = typeToItems.entries.map((entry) {
        final String settingType = entry.key;
        final List<NovelSettingItem> itemsOfType = entry.value;
        return ContextSelectionItem(
          id: 'type_$settingType',
          title: settingType,
          type: ContextSelectionType.settingsByType,
          parentId: 'settings_by_type_$novelId',
          metadata: {
            'itemCount': itemsOfType.length,
            'settingType': settingType,
          },
        );
      }).toList();

      final settingsByTypeItem = ContextSelectionItem(
        id: 'settings_by_type_$novelId',
        title: '设定类型',
        type: ContextSelectionType.settingsByType,
        children: typeChildren,
        metadata: {
          'groupCount': typeChildren.length,
        },
        order: 11,
      );
      items.add(settingsByTypeItem);
    }

    return items;
  }

  /// 构建单个设定项
  static ContextSelectionItem _buildSettingItem(NovelSettingItem setting, String parentId) {
    return ContextSelectionItem(
      id: setting.id ?? '',
      title: setting.name,
      type: ContextSelectionType.settings,
      parentId: parentId,
      subtitle: setting.description,
      metadata: {
        'type': setting.type ?? 'unknown',
        'hasContent': setting.content?.isNotEmpty ?? false,
        'priority': setting.priority ?? 0,
      },
    );
  }

  /// 获取设定类型的显示名称
  // static String _getSettingTypeDisplayName(String type) { return type; }

  // 🚀 新增：计算前N章的总字数
  static int _calculateRecentChaptersWords(Novel novel, int chapterCount) {
    int totalWords = 0;
    int processedChapters = 0;
    
    // 遍历所有卷和章节，取前N章
    outer: for (final act in novel.acts) {
      for (final chapter in act.chapters) {
        if (processedChapters >= chapterCount) {
          break outer;
        }
        totalWords += chapter.wordCount;
        processedChapters++;
      }
    }
    
    return totalWords;
  }

  // 🚀 新增：计算前N章的摘要数量
  static int _calculateRecentChaptersSummaryCount(Novel novel, int chapterCount) {
    int summaryCount = 0;
    int processedChapters = 0;
    
    // 遍历所有卷和章节，取前N章
    outer: for (final act in novel.acts) {
      for (final chapter in act.chapters) {
        if (processedChapters >= chapterCount) {
          break outer;
        }
        // 检查章节是否有场景（有场景就认为有可能有摘要）
        summaryCount += chapter.scenes.length;
        processedChapters++;
      }
    }
    
    return summaryCount;
  }
} 

/// 将设定类型解析为中文显示名（兼容字符串、枚举和Map）
String _resolveSettingTypeZh(dynamic rawType) {
  if (rawType == null) return '其他';
  try {
    if (rawType is SettingType) {
      return rawType.displayName;
    }
    if (rawType is Map<String, dynamic>) {
      final SettingType t = SettingType.fromJson(rawType);
      return t.displayName;
    }
    final String value = rawType.toString();
    final SettingType t = SettingType.fromValue(value);
    return t.displayName;
  } catch (_) {
    return '其他';
  }
}