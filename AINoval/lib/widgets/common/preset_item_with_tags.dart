import 'package:flutter/material.dart';
import 'package:ainoval/models/preset_models.dart';

/// 带标签的预设项组件
class PresetItemWithTags extends StatelessWidget {
  final PresetItemWithTag presetItem;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool showDescription;

  const PresetItemWithTags({
    Key? key,
    required this.presetItem,
    this.onTap,
    this.onFavoriteToggle,
    this.showDescription = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preset = presetItem.preset;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.presetName ?? '未命名预设',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 收藏按钮
                  if (onFavoriteToggle != null)
                    IconButton(
                      icon: Icon(
                        preset.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: preset.isFavorite ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      onPressed: onFavoriteToggle,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // 标签行
              if (presetItem.getTags().isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: presetItem.getTags().map((tag) => _buildTag(context, tag)).toList(),
                ),
              
              // 描述
              if (showDescription && preset.presetDescription != null && preset.presetDescription!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  preset.presetDescription!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // 底部信息
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(preset.lastUsedAt ?? preset.updatedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                  ),
                  const Spacer(),
                  if (preset.useCount > 0) ...[
                    Icon(
                      Icons.trending_up,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${preset.useCount}次',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建标签
  Widget _buildTag(BuildContext context, String tag) {
    Color? tagColor;
    IconData? tagIcon;
    
    switch (tag) {
      case '收藏':
        tagColor = Colors.red;
        tagIcon = Icons.favorite;
        break;
      case '最近使用':
        tagColor = Colors.blue;
        tagIcon = Icons.access_time;
        break;
      case '推荐':
        tagColor = Colors.green;
        tagIcon = Icons.recommend;
        break;
      default:
        tagColor = Colors.grey;
        tagIcon = Icons.label;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        border: Border.all(color: tagColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tagIcon,
            size: 12,
            color: tagColor,
          ),
          const SizedBox(width: 4),
          Text(
            tag,
            style: TextStyle(
              fontSize: 11,
              color: tagColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时间
  String _formatDateTime(DateTime dateTime) {
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
}