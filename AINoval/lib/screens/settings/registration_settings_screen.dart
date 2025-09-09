import 'package:flutter/material.dart';
import 'package:ainoval/models/app_registration_config.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 注册设置管理页面
/// 用于管理应用的注册功能配置
class RegistrationSettingsScreen extends StatefulWidget {
  const RegistrationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationSettingsScreen> createState() => _RegistrationSettingsScreenState();
}

class _RegistrationSettingsScreenState extends State<RegistrationSettingsScreen> {
  RegistrationConfig? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  /// 加载当前配置
  Future<void> _loadConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = RegistrationConfig(
        phoneRegistrationEnabled: await AppRegistrationConfig.isPhoneRegistrationEnabled(),
        emailRegistrationEnabled: await AppRegistrationConfig.isEmailRegistrationEnabled(),
        verificationRequired: await AppRegistrationConfig.isVerificationRequired(),
        quickRegistrationEnabled: await AppRegistrationConfig.isQuickRegistrationEnabled(),
      );

      setState(() {
        _config = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('加载配置失败: $e');
    }
  }

  /// 更新配置
  Future<void> _updateConfiguration(RegistrationConfig newConfig) async {
    try {
      await AppRegistrationConfig.setPhoneRegistrationEnabled(newConfig.phoneRegistrationEnabled);
      await AppRegistrationConfig.setEmailRegistrationEnabled(newConfig.emailRegistrationEnabled);
      await AppRegistrationConfig.setVerificationRequired(newConfig.verificationRequired);
      await AppRegistrationConfig.setQuickRegistrationEnabled(newConfig.quickRegistrationEnabled);

      setState(() {
        _config = newConfig;
      });

      _showSuccess('配置已保存');
    } catch (e) {
      _showError('保存配置失败: $e');
    }
  }

  /// 重置到默认配置
  Future<void> _resetToDefaults() async {
    try {
      await AppRegistrationConfig.resetToDefaults();
      await _loadConfiguration();
      _showSuccess('已重置为默认配置');
    } catch (e) {
      _showError('重置配置失败: $e');
    }
  }

  /// 显示成功消息
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary, size: 20),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 显示错误消息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.onError, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// 显示确认对话框
  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('确定'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('注册设置'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadConfiguration,
            tooltip: '刷新配置',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'reset') {
                final confirmed = await _showConfirmDialog(
                  '重置配置',
                  '确定要将所有注册设置重置为默认值吗？',
                );
                if (confirmed) {
                  _resetToDefaults();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, size: 20),
                    SizedBox(width: 8),
                    Text('重置为默认'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _config == null
              ? _buildErrorState()
              : _buildConfigurationForm(),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 16),
          Text(
            '加载配置失败',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(
            '请检查应用权限或重新启动应用',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadConfiguration,
            child: Text('重新加载'),
          ),
        ],
      ),
    );
  }

  /// 构建配置表单
  Widget _buildConfigurationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 配置概览卡片
          _buildOverviewCard(),
          const SizedBox(height: 24),

          // 注册方式设置
          _buildRegistrationMethodsSection(),
          const SizedBox(height: 24),

          // 验证设置
          _buildVerificationSection(),
          const SizedBox(height: 24),

          // 预览和测试
          _buildPreviewSection(),
        ],
      ),
    );
  }

  /// 构建概览卡片
  Widget _buildOverviewCard() {
    final availableMethods = _config!.availableMethods;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  '当前配置状态',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _config!.quickRegistrationEnabled ? Icons.flash_on : Icons.flash_off,
                  color: _config!.quickRegistrationEnabled ? Theme.of(context).colorScheme.primary : WebTheme.getSecondaryTextColor(context),
                ),
                SizedBox(width: 8),
                Text('快捷注册: ${_config!.quickRegistrationEnabled ? "开启" : "关闭"}'),
              ],
            ),
            SizedBox(height: 8),
            if (availableMethods.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '警告：当前没有启用邮箱或手机注册方式！',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                '可用的注册方式: ${availableMethods.map((m) => m.displayName).join('、')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 4),
              Text(
                '验证码验证: ${_config!.verificationRequired ? "必需" : "可选"}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建注册方式设置区域
  Widget _buildRegistrationMethodsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '注册方式',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // 快捷注册开关
            _buildSettingTile(
              title: '快捷注册',
              subtitle: '仅用户名+密码，无需邮箱/手机与验证码',
              value: _config!.quickRegistrationEnabled,
              icon: Icons.flash_on,
              onChanged: (value) {
                _updateConfiguration(_config!.copyWith(
                  quickRegistrationEnabled: value,
                ));
              },
            ),

            Divider(),
            
            // 邮箱注册开关
            _buildSettingTile(
              title: '邮箱注册',
              subtitle: '允许用户通过邮箱地址注册账户',
              value: _config!.emailRegistrationEnabled,
              icon: Icons.email,
              onChanged: (value) {
                _updateConfiguration(_config!.copyWith(
                  emailRegistrationEnabled: value,
                ));
              },
            ),
            
            Divider(),
            
            // 手机注册开关
            _buildSettingTile(
              title: '手机注册',
              subtitle: '允许用户通过手机号注册账户',
              value: _config!.phoneRegistrationEnabled,
              icon: Icons.phone,
              onChanged: (value) {
                _updateConfiguration(_config!.copyWith(
                  phoneRegistrationEnabled: value,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建验证设置区域
  Widget _buildVerificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '验证设置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            _buildSettingTile(
              title: '验证码验证',
              subtitle: '注册时是否必须进行邮箱或手机验证码验证',
              value: _config!.verificationRequired,
              icon: Icons.verified_user,
              onChanged: (value) {
                _updateConfiguration(_config!.copyWith(
                  verificationRequired: value,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建预览区域
  Widget _buildPreviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '配置预览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WebTheme.isDarkMode(context) 
                  ? WebTheme.darkGrey800 
                  : WebTheme.grey100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '注册页面将显示的选项:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (_config!.availableMethods.isEmpty) ...[
                    Text(
                      '• 无邮箱/手机注册（建议开启快捷注册以允许用户注册）',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ] else ...[
                    for (final method in _config!.availableMethods)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              method == RegistrationMethod.email 
                                ? Icons.email 
                                : Icons.phone,
                              size: 16,
                              color: WebTheme.getSecondaryTextColor(context),
                            ),
                            SizedBox(width: 8),
                            Text('${method.displayName}'),
                          ],
                        ),
                      ),
                    if (_config!.verificationRequired) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            size: 16,
                            color: WebTheme.getSecondaryTextColor(context),
                          ),
                          SizedBox(width: 8),
                          Text('需要验证码验证'),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            
            if (_config!.availableMethods.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                '提示：用户可以使用 EnhancedLoginScreen 进行注册',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建设置项
  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: WebTheme.getSecondaryTextColor(context),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: WebTheme.getTextColor(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: WebTheme.getSecondaryTextColor(context),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
