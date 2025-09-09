import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/blocs/auth/auth_bloc.dart';
import 'package:ainoval/services/auth_service.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

/// 修改密码表单组件
/// 可以在对话框或页面中复用的修改密码表单
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({
    Key? key,
    this.onSuccess,
    this.showTitle = true,
  }) : super(key: key);

  final VoidCallback? onSuccess;
  final bool showTitle;

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 验证密码强度
  String? _validatePasswordStrength(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入新密码';
    }
    
    if (value.length < 8) {
      return '密码长度至少为8位';
    }
    
    // 检查是否包含数字
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return '密码必须包含至少一个数字';
    }
    
    // 检查是否包含字母
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return '密码必须包含至少一个字母';
    }
    
    return null;
  }

  /// 提交修改密码表单
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      
      if (mounted) {
        TopToast.success(context, '密码修改成功');
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e.toString().contains('当前密码')) {
          errorMessage = '当前密码错误，请重新输入';
        } else if (e.toString().contains('认证已过期')) {
          errorMessage = '登录已过期，请重新登录';
          // 可以选择跳转到登录页面
          context.read<AuthBloc>().add(AuthLogout());
        } else {
          errorMessage = '密码修改失败：${e.toString().replaceAll('AuthException: ', '')}';
        }
        TopToast.error(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头部图标和标题
            if (widget.showTitle) ...[
              Container(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: WebTheme.getPrimaryColor(context).withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 40,
                        color: WebTheme.getPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '修改密码',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: WebTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '为了您的账户安全，请定期更换密码',
                      style: TextStyle(
                        fontSize: 14,
                        color: WebTheme.getSecondaryTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // 当前密码输入框
            _buildPasswordField(
              controller: _currentPasswordController,
              label: '当前密码',
              hint: '请输入当前密码',
              isVisible: _isCurrentPasswordVisible,
              onVisibilityToggle: () {
                setState(() {
                  _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入当前密码';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // 新密码输入框
            _buildPasswordField(
              controller: _newPasswordController,
              label: '新密码',
              hint: '请输入新密码（至少8位，包含字母和数字）',
              isVisible: _isNewPasswordVisible,
              onVisibilityToggle: () {
                setState(() {
                  _isNewPasswordVisible = !_isNewPasswordVisible;
                });
              },
              validator: _validatePasswordStrength,
            ),

            const SizedBox(height: 20),

            // 确认新密码输入框
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: '确认新密码',
              hint: '请再次输入新密码',
              isVisible: _isConfirmPasswordVisible,
              onVisibilityToggle: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请确认新密码';
                }
                if (value != _newPasswordController.text) {
                  return '两次输入的密码不一致';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // 提交按钮
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WebTheme.getPrimaryColor(context),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: WebTheme.getSecondaryTextColor(context).withOpacity(0.3),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '修改密码',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // 安全提示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WebTheme.getPrimaryColor(context).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: WebTheme.getPrimaryColor(context).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        size: 20,
                        color: WebTheme.getPrimaryColor(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '密码安全提示',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: WebTheme.getPrimaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 密码长度至少8位\n'
                    '• 包含字母和数字\n'
                    '• 不要使用简单的密码\n'
                    '• 定期更换密码以保证安全',
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getSecondaryTextColor(context),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建密码输入框
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      style: TextStyle(
        fontSize: 16,
        color: WebTheme.getTextColor(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          Icons.lock_outline,
          color: WebTheme.getSecondaryTextColor(context),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: WebTheme.getSecondaryTextColor(context),
          ),
          onPressed: onVisibilityToggle,
        ),
        filled: true,
        fillColor: WebTheme.getBackgroundColor(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: WebTheme.getBorderColor(context),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: WebTheme.getBorderColor(context),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: WebTheme.getPrimaryColor(context),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        labelStyle: TextStyle(
          color: WebTheme.getSecondaryTextColor(context),
          fontSize: 16,
        ),
        hintStyle: TextStyle(
          color: WebTheme.getSecondaryTextColor(context).withOpacity(0.7),
          fontSize: 14,
        ),
      ),
    );
  }
}


