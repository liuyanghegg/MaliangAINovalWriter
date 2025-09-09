import 'package:flutter/material.dart';
import 'package:ainoval/config/app_config.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/forms/change_password_form.dart';
import 'package:ainoval/widgets/common/top_toast.dart';
import 'package:ainoval/services/auth_service.dart';

/// 账户管理面板
/// 集成在设置面板中的账户相关功能
class AccountManagementPanel extends StatefulWidget {
  const AccountManagementPanel({Key? key}) : super(key: key);

  @override
  State<AccountManagementPanel> createState() => _AccountManagementPanelState();
}

class _AccountManagementPanelState extends State<AccountManagementPanel> {
  int _selectedTabIndex = 0;
  Map<String, dynamic>? _userInfo;
  bool _isLoadingUserInfo = false;
  bool _isEditingPersonalInfo = false;
  bool _isSavingPersonalInfo = false;

  final GlobalKey<FormState> _personalInfoFormKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final List<String> _tabs = ['个人信息', '修改密码', '安全设置'];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// 加载用户信息
  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoadingUserInfo = true;
    });

    try {
      final authService = AuthService();
      // 确保初始化以加载本地存储中的登录状态
      await authService.init();
      final userInfo = await authService.getCurrentUser();
      if (!mounted) return;
      
      setState(() {
        _userInfo = userInfo;
        _isLoadingUserInfo = false;
      });
      _populateControllersFromUserInfo(userInfo);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUserInfo = false;
        });
        TopToast.error(context, '加载用户信息失败：${e.toString().replaceAll('AuthException: ', '')}');
      }
    }
  }

  void _populateControllersFromUserInfo(Map<String, dynamic> info) {
    try {
      _displayNameController.text = (info['displayName'] ?? '').toString();
      _emailController.text = (info['email'] ?? '').toString();
      _phoneController.text = (info['phone'] ?? '').toString();
    } catch (_) {}
  }

  void _toggleEditing() {
    setState(() {
      _isEditingPersonalInfo = !_isEditingPersonalInfo;
      if (_isEditingPersonalInfo && _userInfo != null) {
        _populateControllersFromUserInfo(_userInfo!);
      }
    });
  }

  Future<void> _savePersonalInfo() async {
    if (!_isEditingPersonalInfo) return;
    final form = _personalInfoFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() {
      _isSavingPersonalInfo = true;
    });

    try {
      final authService = AuthService();
      await authService.init();
      final updated = await authService.updateUserProfile({
        'displayName': _displayNameController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _userInfo = updated;
        _isEditingPersonalInfo = false;
        _isSavingPersonalInfo = false;
      });
      TopToast.success(context, '个人信息已保存');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingPersonalInfo = false;
      });
      TopToast.error(context, e.toString().replaceAll('AuthException: ', '保存失败：'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          '账户管理',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: WebTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        
        // 用户信息概览卡片
        _buildUserOverviewCard(),
        const SizedBox(height: 24),
        
        // Tab导航
        _buildTabNavigation(),
        const SizedBox(height: 16),
        
        // Tab内容
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  /// 构建用户概览卡片
  Widget _buildUserOverviewCard() {
    final username = AppConfig.username ?? '游客';
    final userId = AppConfig.userId ?? '未知';

    return Card(
      elevation: 2,
      shadowColor: WebTheme.getShadowColor(context, opacity: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: WebTheme.getSurfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 头像
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WebTheme.getPrimaryColor(context).withOpacity(0.1),
              ),
              child: Icon(
                Icons.person,
                size: 25,
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
                      fontSize: 18,
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
                  if (_userInfo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '积分: ${_userInfo!['credits'] ?? 0}',
                      style: TextStyle(
                        fontSize: 14,
                        color: WebTheme.getPrimaryColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 刷新按钮
            IconButton(
              onPressed: _isLoadingUserInfo ? null : _loadUserInfo,
              icon: _isLoadingUserInfo
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          WebTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.refresh,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
              tooltip: '刷新用户信息',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建Tab导航
  Widget _buildTabNavigation() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = _selectedTabIndex == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isSelected
                      ? WebTheme.getPrimaryColor(context).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? WebTheme.getPrimaryColor(context)
                          : WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建Tab内容
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildPersonalInfoTab();
      case 1:
        return _buildChangePasswordTab();
      case 2:
        return _buildSecuritySettingsTab();
      default:
        return Container();
    }
  }

  /// 个人信息Tab
  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      child: Card(
        elevation: 2,
        shadowColor: WebTheme.getShadowColor(context, opacity: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: WebTheme.getSurfaceColor(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: WebTheme.getPrimaryColor(context),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '个人信息',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: WebTheme.getTextColor(context),
                    ),
                  ),
                  const Spacer(),
                  if (_userInfo != null && !_isLoadingUserInfo && !_isEditingPersonalInfo)
                    OutlinedButton.icon(
                      onPressed: _toggleEditing,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('编辑'),
                    ),
                  if (_isEditingPersonalInfo) ...[
                    TextButton(
                      onPressed: _isSavingPersonalInfo ? null : _toggleEditing,
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isSavingPersonalInfo ? null : _savePersonalInfo,
                      icon: _isSavingPersonalInfo
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, size: 16),
                      label: const Text('保存'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              
              if (_isLoadingUserInfo)
                const Center(child: CircularProgressIndicator())
              else if (_userInfo != null && !_isEditingPersonalInfo) ...[
                _buildInfoField('用户名', AppConfig.username ?? '未知'),
                const SizedBox(height: 16),
                _buildInfoField('显示名称', (_userInfo!['displayName'] ?? '未设置').toString()),
                const SizedBox(height: 16),
                _buildInfoField('邮箱', (_userInfo!['email'] ?? '未设置').toString()),
                const SizedBox(height: 16),
                _buildInfoField('手机号', (_userInfo!['phone'] ?? '未设置').toString()),
                const SizedBox(height: 16),
                _buildInfoField('注册时间', _formatDateTime(_userInfo!['createdAt'])),
                const SizedBox(height: 16),
                _buildInfoField('最后登录', _formatDateTime(_userInfo!['lastLoginAt'])),
              ] else if (_userInfo != null && _isEditingPersonalInfo) ...[
                Form(
                  key: _personalInfoFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEditableTextField(
                        label: '显示名称',
                        controller: _displayNameController,
                        hintText: '请输入显示名称',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return '显示名称不能为空';
                          }
                          if (v.trim().length > 32) {
                            return '显示名称过长（最多32个字符）';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildEditableTextField(
                        label: '邮箱',
                        controller: _emailController,
                        hintText: '请输入邮箱（可留空）',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return null; // 允许空
                          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(value)) {
                            return '邮箱格式不正确';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildEditableTextField(
                        label: '手机号',
                        controller: _phoneController,
                        hintText: '请输入手机号（可留空）',
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return null; // 允许空
                          final phoneRegex = RegExp(r'^[0-9+\-\s]{6,20}$');
                          if (!phoneRegex.hasMatch(value)) {
                            return '手机号格式不正确';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: WebTheme.getSecondaryTextColor(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '无法加载用户信息',
                        style: TextStyle(
                          fontSize: 16,
                          color: WebTheme.getSecondaryTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadUserInfo,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 修改密码Tab
  Widget _buildChangePasswordTab() {
    return Card(
      elevation: 2,
      shadowColor: WebTheme.getShadowColor(context, opacity: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: WebTheme.getSurfaceColor(context),
      child: ChangePasswordForm(
        showTitle: false,
        onSuccess: () {
          TopToast.success(context, '密码修改成功');
        },
      ),
    );
  }

  /// 安全设置Tab
  Widget _buildSecuritySettingsTab() {
    return SingleChildScrollView(
      child: Card(
        elevation: 2,
        shadowColor: WebTheme.getShadowColor(context, opacity: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: WebTheme.getSurfaceColor(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security,
                    color: WebTheme.getPrimaryColor(context),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '安全设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: WebTheme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildSecurityItem(
                icon: Icons.device_unknown,
                title: '登录设备管理',
                subtitle: '查看和管理登录设备',
                onTap: () {
                  TopToast.info(context, '登录设备管理功能开发中');
                },
              ),
              const Divider(height: 32),
              _buildSecurityItem(
                icon: Icons.history,
                title: '登录历史',
                subtitle: '查看最近的登录记录',
                onTap: () {
                  TopToast.info(context, '登录历史功能开发中');
                },
              ),
              const Divider(height: 32),
              _buildSecurityItem(
                icon: Icons.key,
                title: 'API密钥管理',
                subtitle: '管理第三方API访问密钥',
                onTap: () {
                  TopToast.info(context, 'API密钥管理功能开发中');
                },
              ),
              const Divider(height: 32),
              _buildSecurityItem(
                icon: Icons.privacy_tip,
                title: '隐私设置',
                subtitle: '管理数据使用和隐私偏好',
                onTap: () {
                  TopToast.info(context, '隐私设置功能开发中');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建信息字段
  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: WebTheme.getBackgroundColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: WebTheme.getBorderColor(context),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: WebTheme.getTextColor(context),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建可编辑文本字段
  Widget _buildEditableTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: WebTheme.getBackgroundColor(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: WebTheme.getBorderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: WebTheme.getPrimaryColor(context), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// 构建安全设置项
  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WebTheme.getPrimaryColor(context).withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: 20,
                color: WebTheme.getPrimaryColor(context),
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
                      color: WebTheme.getTextColor(context),
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
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化日期时间（兼容多种后端返回格式）
  String _formatDateTime(dynamic value) {
    if (value == null) return '未知';
    try {
      DateTime dateTime;
      if (value is String) {
        dateTime = DateTime.parse(value);
      } else if (value is int) {
        // 兼容时间戳（秒/毫秒）
        if (value > 1000000000000) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(value);
        } else if (value > 1000000000) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(value * 1000);
        } else {
          return '未知';
        }
      } else if (value is List) {
        // 兼容 [year, month, day, hour?, minute?, second?]
        final year = _toInt(value, 0);
        final month = _toInt(value, 1);
        final day = _toInt(value, 2);
        final hour = _toInt(value, 3) ?? 0;
        final minute = _toInt(value, 4) ?? 0;
        final second = _toInt(value, 5) ?? 0;
        if (year != null && month != null && day != null) {
          dateTime = DateTime(year, month, day, hour, minute, second);
        } else {
          return '未知';
        }
      } else if (value is Map && value.containsKey('\$date')) {
        final d = value['\$date'];
        if (d is String) {
          dateTime = DateTime.parse(d);
        } else if (d is int) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(d);
        } else {
          return '未知';
        }
      } else {
        return '未知';
      }

      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '未知';
    }
  }

  int? _toInt(List<dynamic> list, int index) {
    if (index >= list.length) return null;
    final v = list[index];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
}


