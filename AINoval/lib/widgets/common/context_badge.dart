import 'package:flutter/material.dart';
// import 'package:ainoval/utils/web_theme.dart';

/// 上下文数据
class ContextData {
  /// 构造函数
  const ContextData({
    required this.title,
    this.subtitle,
    this.icon,
    this.id,
  });

  /// 标题
  final String title;

  /// 副标题（可选）
  final String? subtitle;

  /// 图标（可选，如果不提供会根据内容自动判断）
  final IconData? icon;

  /// 唯一标识（可选）
  final String? id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContextData &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.icon == icon &&
        other.id == id;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        subtitle.hashCode ^
        icon.hashCode ^
        id.hashCode;
  }
}

/// 上下文标签组件
/// 显示上下文信息，支持删除操作，风格简洁现代
class ContextBadge extends StatelessWidget {
  /// 构造函数
  const ContextBadge({
    super.key,
    required this.data,
    this.onDelete,
    this.maxWidth = 200,
    this.showDeleteButton = true,
    this.globalKey,
  });

  /// 上下文数据
  final ContextData data;

  /// 删除回调
  final VoidCallback? onDelete;

  /// 最大宽度
  final double maxWidth;

  /// 是否显示删除按钮
  final bool showDeleteButton;

  /// 全局Key，用于定位
  final GlobalKey? globalKey;

  @override
  Widget build(BuildContext context) {
    // final isDark = WebTheme.isDarkMode(context);

      return Container(
      key: globalKey,
      constraints: BoxConstraints(maxWidth: maxWidth),
      height: 36, // h-9 equivalent
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图标
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
              child: Icon(
              _getIcon(),
              size: 16, // size-4 equivalent
                color: _getIconColor(context),
            ),
          ),

          // 内容
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600, // font-semibold
                      color: _getTextColor(context),
                      height: 1.2, // leading-tight
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 副标题
                  if (data.subtitle != null && data.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      data.subtitle!,
                      style: TextStyle(
                        fontSize: 10, // text-xs
                        color: _getSubtitleColor(context),
                        height: 1.2, // leading-tight
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 删除按钮
          if (showDeleteButton)
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 20, // h-5 w-5
                  height: 20,
                  margin: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.close,
                    size: 14, // h-3.5 w-3.5
                    color: _getDeleteButtonColor(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 获取图标
  IconData _getIcon() {
    // 如果提供了自定义图标，直接使用
    if (data.icon != null) {
      return data.icon!;
    }

    // 根据标题内容自动判断图标
    final title = data.title.toLowerCase();
    
    if (title.contains('act') || title.contains('chapter') || title.contains('scene')) {
      return Icons.menu_book_outlined; // block-quote equivalent
         } else if (title.contains('novel') || title.contains('book') || title.contains('text')) {
       return Icons.menu_book; // book-open equivalent
    } else if (title.contains('folder') || title.contains('directory')) {
      return Icons.folder_outlined; // folder-closed equivalent
    } else {
      return Icons.description_outlined; // 默认文档图标
    }
  }

  /// 获取背景颜色
  Color _getBackgroundColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = data.title.toLowerCase();
    final bool isContent = title.contains('novel') || title.contains('book') || title.contains('text');
    return isContent ? scheme.surfaceContainerHigh : scheme.surfaceContainer;
  }

  /// 获取图标颜色
  Color _getIconColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// 获取文字颜色
  Color _getTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  /// 获取副标题颜色
  Color _getSubtitleColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// 获取删除按钮颜色
  Color _getDeleteButtonColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
} 