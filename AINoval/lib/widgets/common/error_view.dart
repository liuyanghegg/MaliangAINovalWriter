import 'package:flutter/material.dart';

/// 通用错误显示组件
class ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final String? retryText;

  const ErrorView({
    Key? key,
    required this.error,
    this.onRetry,
    this.retryText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              '出现错误',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText ?? '重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}