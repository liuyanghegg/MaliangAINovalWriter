import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 空小说列表视图组件
class EmptyNovelView extends StatelessWidget {
  const EmptyNovelView({
    super.key,
    required this.onCreateTap,
  });

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1.0,
              ),
            ),
            child: Icon(
              Icons.auto_stories,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '没有找到小说',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: WebTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始创建您的第一部小说作品吧',
            style: TextStyle(
              fontSize: 16,
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add),
            label: const Text('创建小说'),
            style: WebTheme.getSecondaryButtonStyle(context).copyWith(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 16),
              ),
              foregroundColor: WidgetStateProperty.all(
                WebTheme.getTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
