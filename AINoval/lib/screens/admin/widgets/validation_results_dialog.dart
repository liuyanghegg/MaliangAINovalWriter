import 'package:flutter/material.dart';

import '../../../models/public_model_config.dart';
import '../../../utils/web_theme.dart';

class ValidationResultsDialog extends StatelessWidget {
  const ValidationResultsDialog({
    super.key,
    required this.config,
  });

  final PublicModelConfigWithKeys config;

  @override
  Widget build(BuildContext context) {
    final keys = config.apiKeyStatuses ?? const <ApiKeyWithStatus>[];
    final successCount = keys.where((k) => k.isValid == true).length;
    final total = keys.length;
    final bool allPass = total > 0 && successCount == total;
    final bool somePass = successCount > 0 && successCount < total;

    return Dialog(
      backgroundColor: WebTheme.getCardColor(context),
      child: Container(
        width: 720,
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'API Key 验证结果',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(width: 12),
                _statusChip(
                  context,
                  successCount == total && total > 0 ? '全部通过' : '$successCount/$total 通过',
                  successCount == total && total > 0 ? Colors.green : Colors.orange,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: WebTheme.getTextColor(context)),
                  tooltip: '关闭',
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildSummaryBanner(context, allPass: allPass, somePass: somePass, total: total, successCount: successCount),
            const SizedBox(height: 12),
            Text(
              '${config.provider}:${config.modelId}${config.displayName != null && config.displayName!.isNotEmpty ? ' (${config.displayName})' : ''}',
              style: TextStyle(color: WebTheme.getSecondaryTextColor(context)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: WebTheme.getBackgroundColor(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WebTheme.getSecondaryBorderColor(context)),
                ),
                child: keys.isEmpty
                    ? Center(
                        child: Text('没有可显示的API Key', style: TextStyle(color: WebTheme.getSecondaryTextColor(context))),
                      )
                    : ListView.separated(
                        itemCount: keys.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: WebTheme.getSecondaryBorderColor(context)),
                        itemBuilder: (context, index) {
                          final item = keys[index];
                          return _buildRow(context, item);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBanner(BuildContext context, {required bool allPass, required bool somePass, required int total, required int successCount}) {
    late Color bg;
    late Color fg;
    late IconData icon;
    late String text;
    if (allPass) {
      bg = Colors.green.withOpacity(0.12);
      fg = Colors.green;
      icon = Icons.check_circle_rounded;
      text = '全部通过：$successCount/$total';
    } else if (somePass) {
      bg = Colors.orange.withOpacity(0.12);
      fg = Colors.orange;
      icon = Icons.error_outline_rounded;
      text = '部分通过：$successCount/$total';
    } else {
      bg = Colors.red.withOpacity(0.12);
      fg = Colors.red;
      icon = Icons.cancel_rounded;
      text = total == 0 ? '未配置任何API Key' : '全部失败：$successCount/$total';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, ApiKeyWithStatus item) {
    final maskedKey = _maskKey(item.apiKey ?? '');
    final isOk = item.isValid == true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: isOk ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        maskedKey,
                        style: TextStyle(
                          color: WebTheme.getTextColor(context),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusChip(context, isOk ? '有效' : '无效', isOk ? Colors.green : Colors.red),
                  ],
                ),
                if ((item.validationError ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.validationError!,
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ],
                if ((item.note ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '备注: ${item.note}',
                    style: TextStyle(color: WebTheme.getSecondaryTextColor(context)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _maskKey(String key) {
    if (key.isEmpty) return '(空)';
    if (key.length <= 8) return '****$key';
    final start = key.substring(0, 4);
    final end = key.substring(key.length - 4);
    return '$start••••••••$end';
  }

  Widget _statusChip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}


