import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 搜索和操作栏公共组件
class SearchActionBar extends StatefulWidget {
  final TextEditingController searchController;
  final String searchHint;
  final VoidCallback? onFilterPressed;
  final VoidCallback? onNewPressed;
  final VoidCallback? onSettingsPressed;
  final String newButtonText;
  final Function(String)? onSearchChanged;
  final bool showFilterButton;
  final bool showNewButton;
  final bool showSettingsButton;

  const SearchActionBar({
    super.key,
    required this.searchController,
    this.searchHint = '搜索...',
    this.onFilterPressed,
    this.onNewPressed,
    this.onSettingsPressed,
    this.newButtonText = '新建',
    this.onSearchChanged,
    this.showFilterButton = true,
    this.showNewButton = true,
    this.showSettingsButton = true,
  });

  @override
  State<SearchActionBar> createState() => _SearchActionBarState();
}

class _SearchActionBarState extends State<SearchActionBar> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // 触发重建以更新清除按钮显示状态
  }

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: WebTheme.getBackgroundColor(context), // 🚀 修复：使用背景色而不是表面色
        border: Border(
          bottom: BorderSide(
            color: isDark ? WebTheme.darkGrey200 : WebTheme.grey200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 确保所有元素垂直居中
        children: [
          // 搜索框 - 占用大部分空间
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                // 根据主题模式设置背景，使用背景色而不是灰色
                color: WebTheme.getBackgroundColor(context), // 🚀 修复：使用背景色而不是灰色
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? WebTheme.darkGrey300 : WebTheme.grey200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // 搜索图标
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      Icons.search,
                      size: 18,
                      color: isDark ? WebTheme.darkGrey400 : WebTheme.grey500,
                    ),
                  ),
                  // 搜索输入框
                  Expanded(
                    child: TextField(
                      controller: widget.searchController,
                      onChanged: widget.onSearchChanged,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? WebTheme.darkGrey100 : WebTheme.grey900,
                        height: 1.0, // 确保文字垂直居中
                      ),
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: isDark ? WebTheme.darkGrey400 : WebTheme.grey500,
                          height: 1.0, // 确保提示文字垂直居中
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 10, // 调整垂直内边距确保居中
                        ),
                        isDense: true, // 减少默认内边距
                      ),
                    ),
                  ),
                  // 清除按钮
                  if (widget.searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          widget.searchController.clear();
                          widget.onSearchChanged?.call('');
                        },
                        child: Icon(
                          Icons.clear,
                          size: 18,
                          color: isDark ? WebTheme.darkGrey400 : WebTheme.grey500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 操作按钮区域
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center, // 确保按钮垂直居中
            children: [
              // 过滤器按钮
              if (widget.showFilterButton) ...[
                _buildIconButton(
                  icon: Icons.filter_list,
                  onPressed: widget.onFilterPressed,
                  tooltip: '过滤器',
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
              ],
              
              // 新建按钮
              if (widget.showNewButton) ...[
                _buildNewButton(
                  text: widget.newButtonText,
                  onPressed: widget.onNewPressed,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
              ],
              
              // 设置按钮
              if (widget.showSettingsButton)
                _buildIconButton(
                  icon: Icons.settings,
                  onPressed: widget.onSettingsPressed,
                  tooltip: '设置',
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    required bool isDark,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Tooltip(
            message: tooltip,
            child: Center( // 确保图标居中
              child: Icon(
                icon,
                size: 18,
                color: isDark ? WebTheme.darkGrey300 : WebTheme.grey700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? WebTheme.darkGrey100 : WebTheme.grey900,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center, // 确保内容居中
              children: [
                Icon(
                  Icons.add,
                  size: 16,
                  color: isDark ? WebTheme.darkGrey900 : WebTheme.white,
                ),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? WebTheme.darkGrey900 : WebTheme.white,
                    height: 1.0, // 确保文字垂直居中
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