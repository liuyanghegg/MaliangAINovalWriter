import 'package:flutter/material.dart';
import 'package:ainoval/models/novel_setting_item.dart';
import 'package:ainoval/models/setting_group.dart';
import 'package:ainoval/screens/editor/widgets/novel_setting_detail.dart';
import 'package:ainoval/screens/editor/widgets/novel_setting_group_dialog.dart';
import 'package:ainoval/screens/editor/widgets/novel_setting_group_selection_dialog.dart';
import 'package:ainoval/screens/editor/widgets/novel_setting_relationship_dialog.dart';

/// 统一的浮动设定对话框管理器
class FloatingSettingDialogs {
  
  /// 显示设定详情编辑卡片
  static void showSettingDetail({
    required BuildContext context,
    String? itemId,
    required String novelId,
    String? groupId,
    bool isEditing = false,
    required Function(NovelSettingItem, String?) onSave,
    required VoidCallback onCancel,
  }) {
    // 使用浮动设定详情管理器
    FloatingNovelSettingDetail.show(
      context: context,
      itemId: itemId,
      novelId: novelId,
      groupId: groupId,
      isEditing: isEditing,
      onSave: onSave,
      onCancel: onCancel,
    );
  }

  /// 显示设定组管理卡片
  static void showSettingGroup({
    required BuildContext context,
    required String novelId,
    SettingGroup? group,
    required Function(SettingGroup) onSave,
  }) {
    // 使用浮动设定组管理器
    FloatingNovelSettingGroupDialog.show(
      context: context,
      novelId: novelId,
      group: group,
      onSave: onSave,
    );
  }

  /// 显示设定组选择卡片
  static void showSettingGroupSelection({
    required BuildContext context,
    required String novelId,
    required Function(String groupId, String groupName) onGroupSelected,
  }) {
    // 使用浮动设定组选择管理器
    FloatingNovelSettingGroupSelectionDialog.show(
      context: context,
      novelId: novelId,
      onGroupSelected: onGroupSelected,
    );
  }

  /// 显示设定关系创建卡片
  static void showSettingRelationship({
    required BuildContext context,
    required String novelId,
    required String sourceItemId,
    required String sourceName,
    required List<NovelSettingItem> availableTargets,
    required Function(String relationType, String targetItemId, String? description) onSave,
  }) {
    // 使用浮动设定关系管理器
    FloatingNovelSettingRelationshipDialog.show(
      context: context,
      novelId: novelId,
      sourceItemId: sourceItemId,
      sourceName: sourceName,
      availableTargets: availableTargets,
      onSave: onSave,
    );
  }
} 