import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/models/novel_setting_item.dart';
import 'package:ainoval/models/setting_relationship_type.dart';
import 'package:ainoval/blocs/setting/setting_bloc.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

/// 设定关系管理标签页
class SettingRelationsTab extends StatefulWidget {
  final NovelSettingItem settingItem;
  final String novelId;
  final List<NovelSettingItem> availableItems;
  final Function(NovelSettingItem)? onItemUpdated;

  const SettingRelationsTab({
    Key? key,
    required this.settingItem,
    required this.novelId,
    required this.availableItems,
    this.onItemUpdated,
  }) : super(key: key);

  @override
  State<SettingRelationsTab> createState() => _SettingRelationsTabState();
}

class _SettingRelationsTabState extends State<SettingRelationsTab> {
  bool _isAddingRelation = false;
  late NovelSettingItem _currentSettingItem;
  late List<NovelSettingItem> _currentAvailableItems;
  
  @override
  void initState() {
    super.initState();
    _currentSettingItem = widget.settingItem;
    _currentAvailableItems = List.from(widget.availableItems);
  }
  
  @override
  void didUpdateWidget(SettingRelationsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settingItem != widget.settingItem) {
      _currentSettingItem = widget.settingItem;
    }
    if (oldWidget.availableItems != widget.availableItems) {
      _currentAvailableItems = List.from(widget.availableItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 父子关系区域
          _buildHierarchySection(isDark),
          
          const SizedBox(height: 16),
          
          // 其他关系区域
          _buildOtherRelationsSection(isDark),
          
          const SizedBox(height: 16),
          
          // 添加关系按钮
          _buildAddRelationButton(isDark),
        ],
      ),
    );
  }

  /// 构建层级关系区域（父子关系）
  Widget _buildHierarchySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '层级关系',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WebTheme.getTextColor(context),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 父设定
        _buildParentSection(isDark),
        
        const SizedBox(height: 16),
        
        // 子设定
        _buildChildrenSection(isDark),
      ],
    );
  }

  /// 构建父设定区域
  Widget _buildParentSection(bool isDark) {
    // 从 relationships 中查找父关系
    String? parentId;
    if (_currentSettingItem.relationships != null) {
      final parentRelation = _currentSettingItem.relationships!
          .where((rel) => rel.type.value == 'parent')
          .firstOrNull;
      parentId = parentRelation?.targetItemId;
    }
    
    // 如果 relationships 中没有找到，再检查 parentId 字段
    parentId ??= _currentSettingItem.parentId;
    
    final hasParent = parentId != null;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? WebTheme.darkGrey100 : WebTheme.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? WebTheme.darkGrey700 : WebTheme.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.arrow_upward,
                size: 16,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                '父设定',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          if (hasParent) ...[
            // 显示父设定
            _buildParentItem(isDark),
          ] else ...[
            // 无父设定时的占位
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 24,
                    color: WebTheme.getSecondaryTextColor(context).withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '没有父设定',
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getSecondaryTextColor(context).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // 添加父设定按钮
            _buildSetParentButton(isDark),
          ],
        ],
      ),
    );
  }

  /// 构建父设定项目
  Widget _buildParentItem(bool isDark) {
    // 从 relationships 中查找父关系
    String? parentId;
    if (_currentSettingItem.relationships != null) {
      final parentRelation = _currentSettingItem.relationships!
          .where((rel) => rel.type.value == 'parent')
          .firstOrNull;
      parentId = parentRelation?.targetItemId;
    }
    
    // 如果 relationships 中没有找到，再检查 parentId 字段
    parentId ??= _currentSettingItem.parentId;
    
    final parentItem = _currentAvailableItems.firstWhere(
      (item) => item.id == parentId,
      orElse: () => NovelSettingItem(name: '未知父设定', type: 'unknown'),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? WebTheme.darkGrey600 : WebTheme.grey300,
        ),
      ),
      child: Row(
        children: [
          // 图标
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.person,
              size: 18,
              color: Colors.blue,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 名称和类型
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parentItem.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
                if (parentItem.type != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    parentItem.type!,
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 移除按钮
          IconButton(
            icon: Icon(
              Icons.close,
              size: 16,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            onPressed: () => _removeParent(),
            tooltip: '移除父子关系',
          ),
        ],
      ),
    );
  }

  /// 构建设置父设定按钮
  Widget _buildSetParentButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        icon: Icon(
          Icons.add,
          size: 16,
          color: WebTheme.getTextColor(context),
        ),
        label: Text(
          '设置父设定',
          style: TextStyle(
            fontSize: 13,
            color: WebTheme.getTextColor(context),
          ),
        ),
        onPressed: _showSetParentDialog,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: isDark ? WebTheme.darkGrey600 : WebTheme.grey300,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建子设定区域
  Widget _buildChildrenSection(bool isDark) {
    // 从两个地方查找子设定：
    // 1. 其他设定的 parentId 字段指向当前设定
    // 2. 其他设定的 relationships 中有指向当前设定的 parent 关系
    final children = _currentAvailableItems.where((item) {
      // 方法1：检查 parentId 字段
      if (item.parentId == _currentSettingItem.id) {
        return true;
      }
      
      // 方法2：检查 relationships 中的 parent 关系
      if (item.relationships != null) {
        return item.relationships!.any((rel) => 
          rel.type.value == 'parent' && rel.targetItemId == _currentSettingItem.id);
      }
      
      return false;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? WebTheme.darkGrey100 : WebTheme.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? WebTheme.darkGrey700 : WebTheme.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.arrow_downward,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                '子设定 (${children.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (children.isNotEmpty) ...[
            // 子设定列表
            ...children.map((child) => _buildChildItem(child, isDark)).toList(),
          ] else ...[
            // 无子设定时的占位
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 24,
                    color: WebTheme.getSecondaryTextColor(context).withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '没有子设定',
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getSecondaryTextColor(context).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建子设定项目
  Widget _buildChildItem(NovelSettingItem child, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? WebTheme.darkGrey600 : WebTheme.grey300,
        ),
      ),
      child: Row(
        children: [
          // 图标
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.person,
              size: 18,
              color: Colors.green,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 名称和类型
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
                if (child.type != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    child.type!,
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 移除按钮
          IconButton(
            icon: Icon(
              Icons.close,
              size: 16,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            onPressed: () => _removeChild(child.id!),
            tooltip: '移除父子关系',
          ),
        ],
      ),
    );
  }

  /// 构建其他关系区域
  Widget _buildOtherRelationsSection(bool isDark) {
    final relationships = _currentSettingItem.relationships ?? [];
    final nonHierarchicalRels = relationships.where(
      (rel) => !rel.type.isHierarchical,
    ).toList();

    // 按关系类型分组
    final groupedRelations = <String, List<SettingRelationship>>{};
    for (final rel in nonHierarchicalRels) {
      final groupName = _getRelationGroupName(rel.type);
      groupedRelations.putIfAbsent(groupName, () => []).add(rel);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '其他关系',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: WebTheme.getTextColor(context),
          ),
        ),
        
        const SizedBox(height: 12),
        
        if (groupedRelations.isEmpty) ...[
          // 无关系时的占位
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? WebTheme.darkGrey100 : WebTheme.grey50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? WebTheme.darkGrey700 : WebTheme.grey200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.link_off,
                  size: 24,
                  color: WebTheme.getSecondaryTextColor(context).withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  '没有其他关系',
                  style: TextStyle(
                    fontSize: 12,
                    color: WebTheme.getSecondaryTextColor(context).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // 按分组显示关系
          ...groupedRelations.entries.map((entry) {
            return _buildRelationGroup(entry.key, entry.value, isDark);
          }).toList(),
        ],
      ],
    );
  }

  /// 构建关系分组
  Widget _buildRelationGroup(String groupName, List<SettingRelationship> relations, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? WebTheme.darkGrey100 : WebTheme.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? WebTheme.darkGrey700 : WebTheme.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$groupName (${relations.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: WebTheme.getTextColor(context),
            ),
          ),
          
          const SizedBox(height: 12),
          
          ...relations.map((rel) => _buildRelationItem(rel, isDark)).toList(),
        ],
      ),
    );
  }

  /// 构建关系项目
  Widget _buildRelationItem(SettingRelationship relationship, bool isDark) {
    final targetItem = _currentAvailableItems.firstWhere(
      (item) => item.id == relationship.targetItemId,
      orElse: () => NovelSettingItem(name: '未知设定', type: 'unknown'),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? WebTheme.darkGrey600 : WebTheme.grey300,
        ),
      ),
      child: Row(
        children: [
          // 关系类型图标
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _getRelationColor(relationship.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _getRelationIcon(relationship.type),
              size: 18,
              color: _getRelationColor(relationship.type),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 关系信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      relationship.type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getRelationColor(relationship.type),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        targetItem.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: WebTheme.getTextColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (relationship.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    relationship.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  size: 16,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
                onPressed: () => _editRelation(relationship),
                tooltip: '编辑关系',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 16,
                  color: Colors.red,
                ),
                onPressed: () => _removeRelation(relationship),
                tooltip: '删除关系',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建添加关系按钮
  Widget _buildAddRelationButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(
          Icons.add,
          size: 16,
        ),
        label: Text('添加关系'),
        onPressed: _isAddingRelation ? null : _showAddRelationDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: WebTheme.getTextColor(context),
          foregroundColor: WebTheme.getBackgroundColor(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 获取关系分组名称
  String _getRelationGroupName(SettingRelationshipType type) {
    final groups = SettingRelationshipType.groupedTypes;
    for (final entry in groups.entries) {
      if (entry.value.contains(type)) {
        return entry.key;
      }
    }
    return '其他';
  }

  /// 获取关系图标
  IconData _getRelationIcon(SettingRelationshipType type) {
    switch (type) {
      case SettingRelationshipType.friend:
        return Icons.favorite;
      case SettingRelationshipType.enemy:
        return Icons.bolt;
      case SettingRelationshipType.ally:
        return Icons.handshake;
      case SettingRelationshipType.rival:
        return Icons.sports_martial_arts;
      case SettingRelationshipType.owns:
        return Icons.inventory;
      case SettingRelationshipType.ownedBy:
        return Icons.person;
      case SettingRelationshipType.memberOf:
        return Icons.group;
      case SettingRelationshipType.contains:
        return Icons.folder;
      case SettingRelationshipType.containedBy:
        return Icons.folder_open;
      case SettingRelationshipType.adjacent:
        return Icons.place;
      case SettingRelationshipType.uses:
        return Icons.build;
      case SettingRelationshipType.usedBy:
        return Icons.engineering;
      case SettingRelationshipType.related:
        return Icons.link;
      default:
        return Icons.more_horiz;
    }
  }

  /// 获取关系颜色
  Color _getRelationColor(SettingRelationshipType type) {
    switch (type) {
      case SettingRelationshipType.friend:
        return Colors.green;
      case SettingRelationshipType.enemy:
        return Colors.red;
      case SettingRelationshipType.ally:
        return Colors.blue;
      case SettingRelationshipType.rival:
        return Colors.orange;
      case SettingRelationshipType.owns:
      case SettingRelationshipType.ownedBy:
        return Colors.purple;
      case SettingRelationshipType.memberOf:
        return Colors.indigo;
      case SettingRelationshipType.contains:
      case SettingRelationshipType.containedBy:
        return Colors.teal;
      case SettingRelationshipType.adjacent:
        return Colors.lime;
      case SettingRelationshipType.uses:
      case SettingRelationshipType.usedBy:
        return Colors.amber;
      case SettingRelationshipType.related:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 显示设置父设定对话框
  void _showSetParentDialog() {
    final availableParents = _currentAvailableItems.where(
      (item) => item.id != _currentSettingItem.id && item.parentId != _currentSettingItem.id,
    ).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('设置父设定'),
        content: Container(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableParents.map((item) {
              return ListTile(
                leading: Icon(Icons.person),
                title: Text(item.name),
                subtitle: item.type != null ? Text(item.type!) : null,
                onTap: () {
                  Navigator.of(context).pop();
                  _setParent(item.id!);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示添加关系对话框
  void _showAddRelationDialog() {
    // TODO: 实现添加关系对话框
    TopToast.info(context, '添加关系功能开发中...');
  }

  /// 编辑关系
  void _editRelation(SettingRelationship relationship) {
    // TODO: 实现编辑关系功能
    TopToast.info(context, '编辑关系功能开发中...');
  }

  /// 设置父设定
  void _setParent(String parentId) {
    if (_currentSettingItem.id == null) return;
    
    // 移除现有的父关系，然后添加新的父关系
    final updatedRelationships = List<SettingRelationship>.from(_currentSettingItem.relationships ?? []);
    updatedRelationships.removeWhere((rel) => rel.type.value == 'parent');
    
    // 添加新的父关系
    updatedRelationships.add(SettingRelationship(
      targetItemId: parentId,
      type: SettingRelationshipType.parent,
    ));
    
    // 先更新本地状态
    setState(() {
      _currentSettingItem = _currentSettingItem.copyWith(
        parentId: parentId,
        relationships: updatedRelationships,
      );
    });
    
    // 立即通知父组件更新
    if (widget.onItemUpdated != null) {
      widget.onItemUpdated!(_currentSettingItem);
    }
    
    // 显示成功提示
    TopToast.success(context, '已设置父设定');
    
    // 异步保存到后端 - 使用专门的父子关系设置 API
    _saveRelationshipAsync(() {
      context.read<SettingBloc>().add(SetParentChildRelationship(
        novelId: widget.novelId,
        childId: _currentSettingItem.id!,
        parentId: parentId,
      ));
    });
  }

  /// 移除父设定
  void _removeParent() {
    if (_currentSettingItem.id == null) return;
    
    // 从 relationships 中查找父关系
    String? parentId;
    if (_currentSettingItem.relationships != null) {
      final parentRelation = _currentSettingItem.relationships!
          .where((rel) => rel.type.value == 'parent')
          .firstOrNull;
      parentId = parentRelation?.targetItemId;
    }
    
    // 如果 relationships 中没有找到，再检查 parentId 字段
    parentId ??= _currentSettingItem.parentId;
    
    if (parentId == null) return;
    
    final originalParentId = parentId;
    
    // 移除所有父关系
    final updatedRelationships = _currentSettingItem.relationships?.where((rel) => rel.type.value != 'parent').toList();
    
    // 创建一个新的NovelSettingItem，移除父关系
    final updatedItem = NovelSettingItem(
      id: _currentSettingItem.id,
      novelId: _currentSettingItem.novelId,
      userId: _currentSettingItem.userId,
      name: _currentSettingItem.name,
      type: _currentSettingItem.type,
      content: _currentSettingItem.content,
      description: _currentSettingItem.description,
      attributes: _currentSettingItem.attributes,
      imageUrl: _currentSettingItem.imageUrl,
      relationships: updatedRelationships,
      sceneIds: _currentSettingItem.sceneIds,
      priority: _currentSettingItem.priority,
      generatedBy: _currentSettingItem.generatedBy,
      tags: _currentSettingItem.tags,
      status: _currentSettingItem.status,
      vector: _currentSettingItem.vector,
      createdAt: _currentSettingItem.createdAt,
      updatedAt: _currentSettingItem.updatedAt,
      isAiSuggestion: _currentSettingItem.isAiSuggestion,
      metadata: _currentSettingItem.metadata,
      parentId: null, // 显式设置为null
      childrenIds: _currentSettingItem.childrenIds,
      nameAliasTracking: _currentSettingItem.nameAliasTracking,
      aiContextTracking: _currentSettingItem.aiContextTracking,
      referenceUpdatePolicy: _currentSettingItem.referenceUpdatePolicy,
    );
    
    // 先更新本地状态
    setState(() {
      _currentSettingItem = updatedItem;
    });
    
    // 立即通知父组件更新
    if (widget.onItemUpdated != null) {
      widget.onItemUpdated!(_currentSettingItem);
    }
    
    // 显示成功提示
    TopToast.success(context, '已移除父子关系');
    
    // 异步保存到后端 - 使用专门的父子关系移除 API
    _saveRelationshipAsync(() {
      context.read<SettingBloc>().add(RemoveParentChildRelationship(
        novelId: widget.novelId,
        childId: _currentSettingItem.id!,
      ));
    });
  }

  /// 移除子设定
  void _removeChild(String childId) {
    if (_currentSettingItem.id == null) return;
    
    // 先更新本地可用项目列表中的子项目
    setState(() {
      _currentAvailableItems = _currentAvailableItems.map((item) {
        if (item.id == childId) {
          // 创建新的NovelSettingItem，显式设置parentId为null
          return NovelSettingItem(
            id: item.id,
            novelId: item.novelId,
            userId: item.userId,
            name: item.name,
            type: item.type,
            content: item.content,
            description: item.description,
            attributes: item.attributes,
            imageUrl: item.imageUrl,
            relationships: item.relationships,
            sceneIds: item.sceneIds,
            priority: item.priority,
            generatedBy: item.generatedBy,
            tags: item.tags,
            status: item.status,
            vector: item.vector,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            isAiSuggestion: item.isAiSuggestion,
            metadata: item.metadata,
            parentId: null, // 显式设置为null
            childrenIds: item.childrenIds,
            nameAliasTracking: item.nameAliasTracking,
            aiContextTracking: item.aiContextTracking,
            referenceUpdatePolicy: item.referenceUpdatePolicy,
          );
        }
        return item;
      }).toList();
    });
    
    // 显示成功提示
    TopToast.success(context, '已移除父子关系');
    
    // 异步保存到后端 - 使用专门的父子关系移除 API
    _saveRelationshipAsync(() {
      context.read<SettingBloc>().add(RemoveParentChildRelationship(
        novelId: widget.novelId,
        childId: childId,
      ));
    });
  }

  /// 移除关系
  void _removeRelation(SettingRelationship relationship) {
    if (_currentSettingItem.id == null) return;
    
    // 先更新本地状态，移除关系
    setState(() {
      final relationships = List<SettingRelationship>.from(_currentSettingItem.relationships ?? []);
      relationships.removeWhere((rel) => 
        rel.targetItemId == relationship.targetItemId && 
        rel.type == relationship.type);
      _currentSettingItem = _currentSettingItem.copyWith(relationships: relationships);
    });
    
    // 立即通知父组件更新
    if (widget.onItemUpdated != null) {
      widget.onItemUpdated!(_currentSettingItem);
    }
    
    // 显示成功提示
    TopToast.success(context, '已删除关系');
    
    // 异步保存到后端
    _saveRelationshipAsync(() {
      context.read<SettingBloc>().add(RemoveSettingRelationship(
        novelId: widget.novelId,
        itemId: _currentSettingItem.id!,
        targetItemId: relationship.targetItemId,
        relationshipType: relationship.type.value,
      ));
    });
  }
  
  /// 异步保存关系变更到后端
  Future<void> _saveRelationshipAsync(VoidCallback action) async {
    try {
      action();
    } catch (e) {
      // 静默处理错误，不干扰用户体验
    }
  }
}