import 'package:flutter/material.dart';
import 'package:ainoval/screens/user/change_password_screen.dart';
import 'package:ainoval/widgets/forms/change_password_form.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 修改密码对话框
/// 可以在任何地方调用此对话框来显示修改密码界面
class ChangePasswordDialog {
  /// 显示修改密码对话框
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 700,
          ),
          decoration: BoxDecoration(
            color: WebTheme.getBackgroundColor(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 对话框头部
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WebTheme.getSurfaceColor(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: WebTheme.getPrimaryColor(context),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '修改密码',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: WebTheme.getTextColor(context),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: WebTheme.getSecondaryTextColor(context),
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              // 对话框内容
              Expanded(
                child: ChangePasswordForm(
                  showTitle: false,
                  onSuccess: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示全屏修改密码页面（推荐用于移动端）
  static void showFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  /// 根据屏幕尺寸自动选择显示方式
  static void showAdaptive(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 768) {
      // 桌面端或平板端使用对话框
      show(context);
    } else {
      // 移动端使用全屏页面
      showFullScreen(context);
    }
  }
}
