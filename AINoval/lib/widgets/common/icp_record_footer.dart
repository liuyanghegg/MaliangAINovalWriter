import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ainoval/utils/web_theme.dart';

/// ICP备案信息组件
/// 包含备案号、工信部链接和图标
class ICPRecordFooter extends StatelessWidget {
  final String icpNumber;
  final String recordUrl;
  final EdgeInsets? padding;
  final bool showIcon;

  const ICPRecordFooter({
    Key? key,
    this.icpNumber = '沪ICP备2025140539号-1',
    this.recordUrl = 'https://beian.miit.gov.cn/#/',
    this.padding,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: WebTheme.getBorderColor(context).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: InkWell(
          onTap: () => _launchICPUrl(),
          hoverColor: WebTheme.getPrimaryColor(context).withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcon) ...[
                  // 工信部图标 - 使用简化的政府图标
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: WebTheme.getSecondaryTextColor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      size: 12,
                      color: WebTheme.getBackgroundColor(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  icpNumber,
                  style: TextStyle(
                    fontSize: 12,
                    color: WebTheme.getSecondaryTextColor(context),
                    decoration: TextDecoration.underline,
                    decorationColor: WebTheme.getSecondaryTextColor(context).withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 打开工信部备案查询网站
  Future<void> _launchICPUrl() async {
    try {
      final uri = Uri.parse(recordUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // 静默处理错误，避免在生产环境中显示错误信息
      print('无法打开ICP备案查询网站: $e');
    }
  }
}

/// 简化版ICP备案信息组件，仅显示文本
class ICPRecordText extends StatelessWidget {
  final String icpNumber;
  final String recordUrl;
  final TextStyle? textStyle;

  const ICPRecordText({
    Key? key,
    this.icpNumber = '沪ICP备2025140539号-1',
    this.recordUrl = 'https://beian.miit.gov.cn/#/',
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launchICPUrl(),
      child: Text(
        icpNumber,
        style: textStyle ??
            TextStyle(
              fontSize: 12,
              color: WebTheme.getSecondaryTextColor(context),
              decoration: TextDecoration.underline,
              decorationColor: WebTheme.getSecondaryTextColor(context).withOpacity(0.5),
            ),
      ),
    );
  }

  /// 打开工信部备案查询网站
  Future<void> _launchICPUrl() async {
    try {
      final uri = Uri.parse(recordUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('无法打开ICP备案查询网站: $e');
    }
  }
}
