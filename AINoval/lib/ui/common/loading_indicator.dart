import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 加载指示器组件
class LoadingIndicator extends StatelessWidget {
  
  const LoadingIndicator({
    Key? key,
    this.message,
    this.color,
  }) : super(key: key);
  final String? message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? WebTheme.getPrimaryColor(context),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
} 