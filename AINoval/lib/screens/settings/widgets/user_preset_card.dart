import 'package:flutter/material.dart';

import '../../../models/preset_models.dart';
import '../../../utils/web_theme.dart';

/// 用户预设卡片组件
class UserPresetCard extends StatelessWidget {
  final AIPromptPreset preset;
  final bool isSelected;
  final bool batchMode;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onFavorite;
  final VoidCallback? onDelete;
  final VoidCallback? onUse;
  final ValueChanged<bool>? onSelectionChanged;

  const UserPresetCard({
    Key? key,
    required this.preset,
    this.isSelected = false,
    this.batchMode = false,
    this.onTap,
    this.onEdit,
    this.onFavorite,
    this.onDelete,
    this.onUse,
    this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : WebTheme.getCardColor(context),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildContent(context),
              const SizedBox(height: 12),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (batchMode) ...[ 
          Checkbox(
            value: isSelected,
            onChanged: (value) => onSelectionChanged?.call(value ?? false),
          ),
          const SizedBox(width: 8),
        ],
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.presetName ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: WebTheme.getTextColor(context),
                      ),
                    ),
                  ),
                  _buildStatusIndicators(context),
                ],
              ),
              if (preset.presetDescription?.isNotEmpty == true) ...[ 
                const SizedBox(height: 4),
                Text(
                  preset.presetDescription!,
                  style: TextStyle(
                    fontSize: 14,
                    color: WebTheme.getTextColor(context).withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        
        if (!batchMode) ...[
          // 使用按钮
          ElevatedButton.icon(
            onPressed: onUse,
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('使用'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => _buildMenuItems(),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIndicators(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (preset.isFavorite == true) 
          Container(
            margin: const EdgeInsets.only(left: 6),
            child: Icon(
              Icons.favorite,
              size: 16,
              color: Colors.red,
            ),
          ),
        if (preset.isSystem == true) 
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Text(
              '系统',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (preset.isPublic == true) 
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
            ),
            child: Text(
              '公开',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 系统提示词预览
        if ((preset.systemPrompt ?? '').isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '系统提示词:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.getTextColor(context).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  preset.systemPrompt ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: WebTheme.getTextColor(context).withOpacity(0.8),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
        
        // 用户提示词预览
        if ((preset.userPrompt ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '用户提示词:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.getTextColor(context).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  preset.userPrompt ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: WebTheme.getTextColor(context).withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
        
        // 标签
        if ((preset.presetTags ?? const <String>[]).isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: (preset.presetTags ?? const <String>[])
                .map((tag) => _buildTag(context, tag))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTag(BuildContext context, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: WebTheme.getTextColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 11,
          color: WebTheme.getTextColor(context).withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // 功能类型
        _buildFeatureTypeChip(context),
        const SizedBox(width: 12),
        
        // 创建时间
        Icon(
          Icons.access_time,
          size: 14,
          color: WebTheme.getTextColor(context).withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          _formatDateTime(preset.createdAt),
          style: TextStyle(
            fontSize: 12,
            color: WebTheme.getTextColor(context).withOpacity(0.5),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // 使用次数
        Icon(
          Icons.play_circle_outline,
          size: 14,
          color: WebTheme.getTextColor(context).withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          '使用 ${preset.useCount ?? 0} 次',
          style: TextStyle(
            fontSize: 12,
            color: WebTheme.getTextColor(context).withOpacity(0.5),
          ),
        ),
        
        const Spacer(),
        
        // 最后使用时间
        if (preset.lastUsedAt != null) ...[
          Text(
            '最后使用: ${_formatDateTime(preset.lastUsedAt)}',
            style: TextStyle(
              fontSize: 12,
              color: WebTheme.getTextColor(context).withOpacity(0.5),
            ),
          ),
        ] else
          Text(
            '从未使用',
            style: TextStyle(
              fontSize: 12,
              color: WebTheme.getTextColor(context).withOpacity(0.5),
            ),
          ),
      ],
    );
  }

  Widget _buildFeatureTypeChip(BuildContext context) {
    final featureType = preset.aiFeatureType ?? 'UNKNOWN';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getFeatureTypeColor(featureType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getFeatureTypeColor(featureType).withOpacity(0.3),
        ),
      ),
      child: Text(
        _getFeatureTypeLabel(featureType),
        style: TextStyle(
          fontSize: 11,
          color: _getFeatureTypeColor(featureType),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    List<PopupMenuEntry<String>> items = [];
    
    // 编辑选项（仅非系统预设可编辑）
    if (preset.isSystem != true) {
      items.add(const PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit, size: 18),
            SizedBox(width: 8),
            Text('编辑'),
          ],
        ),
      ));
    }
    
    // 收藏选项
    if (preset.isFavorite != true) {
      items.add(const PopupMenuItem(
        value: 'favorite',
        child: Row(
          children: [
            Icon(Icons.favorite_border, size: 18),
            SizedBox(width: 8),
            Text('添加到收藏'),
          ],
        ),
      ));
    } else {
      items.add(const PopupMenuItem(
        value: 'unfavorite',
        child: Row(
          children: [
            Icon(Icons.favorite, size: 18, color: Colors.red),
            SizedBox(width: 8),
            Text('取消收藏'),
          ],
        ),
      ));
    }
    
    // 复制选项
    items.add(const PopupMenuItem(
      value: 'duplicate',
      child: Row(
        children: [
          Icon(Icons.copy, size: 18),
          SizedBox(width: 8),
          Text('复制预设'),
        ],
      ),
    ));
    
    // 导出选项
    items.add(const PopupMenuItem(
      value: 'export',
      child: Row(
        children: [
          Icon(Icons.file_download, size: 18),
          SizedBox(width: 8),
          Text('导出'),
        ],
      ),
    ));
    
    // 删除选项（仅非系统预设可删除）
    if (preset.isSystem != true) {
      items.add(const PopupMenuDivider());
      items.add(const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 18, color: Colors.red),
            SizedBox(width: 8),
            Text('删除', style: TextStyle(color: Colors.red)),
          ],
        ),
      ));
    }
    
    return items;
  }

  Color _getFeatureTypeColor(String featureType) {
    switch (featureType) {
      case 'CHAT':
        return Colors.blue;
      case 'SCENE_GENERATION':
        return Colors.green;
      case 'CONTINUATION':
        return Colors.orange;
      case 'SUMMARY':
        return Colors.purple;
      case 'OUTLINE':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getFeatureTypeLabel(String featureType) {
    switch (featureType) {
      case 'CHAT':
        return 'AI聊天';
      case 'SCENE_GENERATION':
        return '场景生成';
      case 'CONTINUATION':
        return '续写';
      case 'SUMMARY':
        return '总结';
      case 'OUTLINE':
        return '大纲';
      default:
        return featureType;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'favorite':
      case 'unfavorite':
        onFavorite?.call();
        break;
      case 'duplicate':
        // TODO: 实现复制预设功能
        break;
      case 'export':
        // TODO: 实现导出预设功能
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}