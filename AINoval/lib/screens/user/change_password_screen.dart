import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/forms/change_password_form.dart';

/// 修改密码页面
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          '修改密码',
          style: TextStyle(
            color: WebTheme.getTextColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: WebTheme.getBackgroundColor(context),
        elevation: 0,
        iconTheme: IconThemeData(
          color: WebTheme.getTextColor(context),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            shadowColor: WebTheme.getShadowColor(context, opacity: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: WebTheme.getSurfaceColor(context),
            child: ChangePasswordForm(
              onSuccess: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }
}
