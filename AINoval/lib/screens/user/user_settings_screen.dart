import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/blocs/auth/auth_bloc.dart';
import 'package:ainoval/config/app_config.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/screens/user/change_password_screen.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

/// 用户设置页面
class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({Key? key}) : super(key: key);

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          '账户设置',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息卡片
            _buildUserInfoCard(),
            const SizedBox(height: 24),
            
            // 账户安全设置
            _buildAccountSecuritySection(),
            const SizedBox(height: 24),
            
            // 偏好设置
            _buildPreferencesSection(),
            const SizedBox(height: 24),
            
            // 关于应用
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  /// 构建用户信息卡片
  Widget _buildUserInfoCard() {
    final username = AppConfig.username ?? '游客';
    final userId = AppConfig.userId ?? '未知';

    return Card(
      elevation: 4,
      shadowColor: WebTheme.getShadowColor(context, opacity: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: WebTheme.getSurfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 头像
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WebTheme.getPrimaryColor(context).withOpacity(0.1),
              ),
              child: Icon(
                Icons.person,
                size: 30,
                color: WebTheme.getPrimaryColor(context),
              ),
            ),
            const SizedBox(width: 16),
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: WebTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: $userId',
                    style: TextStyle(
                      fontSize: 14,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: WebTheme.getPrimaryColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '已认证',
                      style: TextStyle(
                        fontSize: 12,
                        color: WebTheme.getPrimaryColor(context),
                        fontWeight: FontWeight.w500,
                      ),
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

  /// 构建账户安全设置区域
  Widget _buildAccountSecuritySection() {
    return _buildSection(
      title: '账户安全',
      icon: Icons.security,
      children: [
        _buildSettingItem(
          icon: Icons.lock_outline,
          title: '修改密码',
          subtitle: '定期更换密码，保护账户安全',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ChangePasswordScreen(),
              ),
            );
          },
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
        const Divider(height: 1),
        _buildSettingItem(
          icon: Icons.device_unknown,
          title: '登录设备管理',
          subtitle: '查看和管理登录设备',
          onTap: () {
            TopToast.info(context, '登录设备管理功能开发中');
          },
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
        const Divider(height: 1),
        _buildSettingItem(
          icon: Icons.logout,
          title: '退出登录',
          subtitle: '退出当前账户',
          onTap: () {
            _showLogoutConfirmDialog();
          },
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
          isDestructive: true,
        ),
      ],
    );
  }

  /// 构建偏好设置区域
  Widget _buildPreferencesSection() {
    return _buildSection(
      title: '偏好设置',
      icon: Icons.tune,
      children: [
        _buildSettingItem(
          icon: Icons.language,
          title: '语言设置',
          subtitle: '选择应用显示语言',
          onTap: () {
            TopToast.info(context, '语言设置功能开发中');
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '简体中文',
                style: TextStyle(
                  fontSize: 14,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        _buildSettingItem(
          icon: Icons.palette_outlined,
          title: '主题设置',
          subtitle: '选择浅色或深色主题',
          onTap: () {
            TopToast.info(context, '主题设置功能开发中');
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '跟随系统',
                style: TextStyle(
                  fontSize: 14,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        _buildSettingItem(
          icon: Icons.notifications_outlined,
          title: '通知设置',
          subtitle: '管理应用通知偏好',
          onTap: () {
            TopToast.info(context, '通知设置功能开发中');
          },
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }

  /// 构建关于应用区域
  Widget _buildAboutSection() {
    return _buildSection(
      title: '关于',
      icon: Icons.info_outline,
      children: [
        _buildSettingItem(
          icon: Icons.help_outline,
          title: '帮助中心',
          subtitle: '查看使用指南和常见问题',
          onTap: () {
            TopToast.info(context, '帮助中心功能开发中');
          },
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
        const Divider(height: 1),
        _buildSettingItem(
          icon: Icons.privacy_tip_outlined,
          title: '隐私政策',
          subtitle: '了解我们如何保护您的隐私',
          onTap: () {
            TopToast.info(context, '隐私政策功能开发中');
          },
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
        const Divider(height: 1),
        _buildSettingItem(
          icon: Icons.description_outlined,
          title: '服务条款',
          subtitle: '查看使用条款和协议',
          onTap: () {
            TopToast.info(context, '服务条款功能开发中');
          },
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
        const Divider(height: 1),
        _buildSettingItem(
          icon: Icons.info,
          title: '应用版本',
          subtitle: 'AINoval v1.0.0',
          onTap: () {
            TopToast.info(context, '当前版本：v1.0.0');
          },
        ),
      ],
    );
  }

  /// 构建设置区域
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区域标题
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: WebTheme.getPrimaryColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            ],
          ),
        ),
        // 设置项卡片
        Card(
          elevation: 2,
          shadowColor: WebTheme.getShadowColor(context, opacity: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: WebTheme.getSurfaceColor(context),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// 构建设置项
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDestructive
                    ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                    : WebTheme.getPrimaryColor(context).withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? Theme.of(context).colorScheme.error
                    : WebTheme.getPrimaryColor(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? Theme.of(context).colorScheme.error
                          : WebTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  /// 显示退出登录确认对话框
  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WebTheme.getSurfaceColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              '确认退出',
              style: TextStyle(
                color: WebTheme.getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          '您确定要退出登录吗？退出后需要重新登录才能使用。',
          style: TextStyle(
            color: WebTheme.getSecondaryTextColor(context),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: WebTheme.getSecondaryTextColor(context),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭对话框
              context.read<AuthBloc>().add(AuthLogout());
              Navigator.of(context).pop(); // 关闭设置页面
              TopToast.info(context, '已退出登录');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
  }
}


