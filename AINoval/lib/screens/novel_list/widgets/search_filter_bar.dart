import 'package:flutter/material.dart';
import 'package:ainoval/widgets/common/app_search_field.dart';
import 'package:ainoval/widgets/common/app_filter_button.dart';
import 'package:ainoval/widgets/common/app_view_toggle.dart';
import 'package:ainoval/widgets/common/app_toolbar.dart';

/// 搜索和过滤工具栏组件
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.isGridView,
    required this.onSearchChanged,
    required this.onViewTypeChanged,
    required this.onFilterPressed,
    required this.onSortPressed,
    required this.onGroupPressed,
    this.onRefreshPressed,
  });

  final TextEditingController searchController;
  final bool isGridView;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onViewTypeChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onSortPressed;
  final VoidCallback onGroupPressed;
  final VoidCallback? onRefreshPressed;

  @override
  Widget build(BuildContext context) {
    return AppToolbar(
      children: [
        // 搜索框
        Expanded(
          child: AppSearchField(
            controller: searchController,
            onChanged: onSearchChanged,
            hintText: '搜索名称/系列...',
          ),
        ),

        const SizedBox(width: 16),

        // 过滤器按钮组
        Wrap(
          spacing: 8,
          children: [
            AppFilterButton(
              label: '过滤',
              icon: Icons.filter_list,
              onPressed: onFilterPressed,
            ),
            AppFilterButton(
              label: '排序',
              icon: Icons.sort,
              onPressed: onSortPressed,
            ),
            AppFilterButton(
              label: '分组',
              icon: Icons.group_work,
              onPressed: onGroupPressed,
            ),
            if (onRefreshPressed != null)
              AppFilterButton(
                label: '刷新',
                icon: Icons.refresh,
                onPressed: onRefreshPressed!,
              ),
          ],
        ),

        const SizedBox(width: 12),

        // 视图切换按钮
        AppViewToggle(
          isGridView: isGridView,
          onViewTypeChanged: onViewTypeChanged,
        ),
      ],
    );
  }
}
