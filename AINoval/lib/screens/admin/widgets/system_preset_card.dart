import 'package:flutter/material.dart';

import '../../../models/preset_models.dart';
import '../../../utils/web_theme.dart';

/// 系统预设卡片组件
/// 显示系统预设的基本信息和操作按钮
class SystemPresetCard extends StatelessWidget {
  final AIPromptPreset preset;
  final bool isSelected;
  final bool batchMode;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onViewStats;
  final VoidCallback? onViewDetails;
  final ValueChanged<bool>? onSelectionChanged;

  const SystemPresetCard({
    Key? key,
    required this.preset,
    this.isSelected = false,
    this.batchMode = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleVisibility,
    this.onViewStats,
    this.onViewDetails,
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
              Text(
                preset.presetName ?? '未命名预设',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: WebTheme.getTextColor(context),
                ),
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
          _buildQuickAccessIndicator(context),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('编辑'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'visibility',
                child: Row(
                  children: [
                    Icon(
                      preset.showInQuickAccess ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(preset.showInQuickAccess ? '隐藏快捷访问' : '显示在快捷访问'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.article, size: 18),
                    SizedBox(width: 8),
                    Text('查看内容'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics, size: 18),
                    SizedBox(width: 8),
                    Text('查看统计'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuickAccessIndicator(BuildContext context) {
    if (!preset.showInQuickAccess) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flash_on,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '快捷',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Row(
      children: [
        _buildFeatureTypeChip(context),
        const SizedBox(width: 12),
        if (preset.presetTags?.isNotEmpty == true) ...[
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: preset.presetTags!.take(3).map((tag) => _buildTag(context, tag)).toList(),
            ),
          ),
        ] else
          const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _buildFeatureTypeChip(BuildContext context) {
    final featureType = preset.aiFeatureType;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getFeatureTypeColor(featureType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getFeatureTypeColor(featureType).withOpacity(0.3),
        ),
      ),
      child: Text(
        _getFeatureTypeLabel(featureType),
        style: TextStyle(
          fontSize: 12,
          color: _getFeatureTypeColor(featureType),
          fontWeight: FontWeight.w500,
        ),
      ),
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
        Icon(
          Icons.play_circle_outline,
          size: 14,
          color: WebTheme.getTextColor(context).withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          '使用 ${preset.useCount} 次',
          style: TextStyle(
            fontSize: 12,
            color: WebTheme.getTextColor(context).withOpacity(0.5),
          ),
        ),
        
        const Spacer(),
        
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
      case 'visibility':
        onToggleVisibility?.call();
        break;
      case 'details':
        onViewDetails?.call();
        break;
      case 'stats':
        onViewStats?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}