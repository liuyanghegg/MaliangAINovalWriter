import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/blocs/auth/auth_bloc.dart';
import 'package:ainoval/config/app_config.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'dart:math' as math;
import 'package:ainoval/screens/auth/enhanced_login_screen.dart';
import 'package:ainoval/screens/user/user_settings_screen.dart';
import 'package:ainoval/screens/settings/settings_panel.dart';
import 'package:ainoval/screens/editor/managers/editor_state_manager.dart';
import 'package:ainoval/models/editor_settings.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

/// 用户头像下拉菜单组件
class UserAvatarMenu extends StatefulWidget {
  const UserAvatarMenu({
    Key? key,
    this.size = 16,
    this.showName = false,
    this.onMySubscription,
    this.onProfile,
    this.onAccountSettings,
    this.onHelp,
    this.onLogout,
    this.onOpenSettings,
  }) : super(key: key);

  final double size;
  final bool showName;
  final VoidCallback? onMySubscription;
  final VoidCallback? onProfile;
  final VoidCallback? onAccountSettings;
  final VoidCallback? onHelp;
  final VoidCallback? onLogout;
  final VoidCallback? onOpenSettings;

  @override
  State<UserAvatarMenu> createState() => _UserAvatarMenuState();
}

class _UserAvatarMenuState extends State<UserAvatarMenu> {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;
  final GlobalKey _menuContentKey = GlobalKey();
  double? _resolvedMenuTop;
  double? _resolvedMenuLeft;

  @override
  void dispose() {
    // 只关闭overlay，不调用setState
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_buttonKey.currentContext == null) {
      return;
    }
    
    final RenderBox renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final double screenWidth = MediaQuery.of(context).size.width;
    const double baseMenuWidth = 240.0;
    // 默认对齐按钮右侧，向左展开，并作水平边界夹紧
    final double initialDesiredLeft = offset.dx + size.width - baseMenuWidth;
    final double initialLeft = initialDesiredLeft.clamp(8.0, screenWidth - baseMenuWidth - 8.0);
    _resolvedMenuLeft = initialLeft;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 透明层，点击关闭菜单
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // 菜单内容
          Positioned(
            top: _resolvedMenuTop ?? (offset.dy + size.height + 8),
            left: _resolvedMenuLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: WebTheme.getBackgroundColor(context),
              shadowColor: WebTheme.getShadowColor(context, opacity: 0.2),
              child: Container(
                key: _menuContentKey,
                width: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: WebTheme.getBorderColor(context),
                    width: 1,
                  ),
                ),
                child: _buildMenuContent(),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isMenuOpen = true;
    });

    // 计算菜单高度，若底部空间不足则向上展开
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final menuSize = _menuContentKey.currentContext?.size;
      if (menuSize == null) return;
      final media = MediaQuery.of(context);
      final screenHeight = media.size.height;
      final screenWidth = media.size.width;
      final spaceBelow = screenHeight - (offset.dy + size.height) - 8;
      if (spaceBelow < menuSize.height + 8) {
        final newTop = math.max(8.0, offset.dy - menuSize.height - 8);
        if (_resolvedMenuTop != newTop) {
          _resolvedMenuTop = newTop;
          _overlayEntry?.markNeedsBuild();
        }
      } else {
        final newTop = offset.dy + size.height + 8;
        if (_resolvedMenuTop != newTop) {
          _resolvedMenuTop = newTop;
          _overlayEntry?.markNeedsBuild();
        }
      }

      // 根据实际菜单宽度再次夹紧水平位置，避免左/右越界
      final menuWidth = menuSize.width;
      final desiredLeft = offset.dx + size.width - menuWidth; // 右对齐按钮
      final clampedLeft = desiredLeft.clamp(8.0, screenWidth - menuWidth - 8.0);
      if (_resolvedMenuLeft != clampedLeft) {
        _resolvedMenuLeft = clampedLeft;
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isMenuOpen = false;
        _resolvedMenuTop = null;
        _resolvedMenuLeft = null;
      });
    }
  }

  Widget _buildMenuContent() {
    final username = AppConfig.username ?? '游客';
    final userId = AppConfig.userId ?? '游客';
    final bool isAuthed = context.read<AuthBloc>().state is AuthAuthenticated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 用户信息头部
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WebTheme.getSurfaceColor(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: WebTheme.getPrimaryColor(context).withOpacity(WebTheme.isDarkMode(context) ? 0.2 : 0.1),
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: WebTheme.getPrimaryColor(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: WebTheme.getTextColor(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: $userId',
                      style: TextStyle(
                        fontSize: 12,
                        color: WebTheme.getSecondaryTextColor(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 分割线
        Divider(
          height: 1,
          color: WebTheme.getBorderColor(context),
          thickness: 1,
        ),
        // 菜单项
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              if (isAuthed) ...[
                _buildMenuItem(
                  icon: Icons.person_outline,
                  label: '个人资料',
                  onTap: () {
                    _closeMenu();
                    if (widget.onProfile != null) {
                      widget.onProfile!.call();
                    } else {
                      _handleProfileTap();
                    }
                  },
                ),
                _buildMenuItem(
                  icon: Icons.workspace_premium,
                  label: '我的订阅',
                  onTap: () {
                    _closeMenu();
                    if (widget.onMySubscription != null) {
                      widget.onMySubscription!.call();
                    } else {
                      _openMySubscriptionPanel();
                    }
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  label: '账户设置',
                  onTap: () {
                    _closeMenu();
                    if (widget.onAccountSettings != null) {
                      widget.onAccountSettings!.call();
                    } else {
                      _handleSettingsTap();
                    }
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  label: '帮助中心',
                  onTap: () {
                    _closeMenu();
                    if (widget.onHelp != null) {
                      widget.onHelp!.call();
                    } else {
                      _handleHelpTap();
                    }
                  },
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: WebTheme.getBorderColor(context),
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  icon: Icons.logout,
                  label: '退出登录',
                  onTap: () {
                    _closeMenu();
                    if (widget.onLogout != null) {
                      widget.onLogout!.call();
                    } else {
                      _handleLogout();
                    }
                  },
                  isDestructive: true,
                ),
              ] else ...[
                _buildMenuItem(
                  icon: Icons.login,
                  label: '登录账号',
                  onTap: () {
                    _closeMenu();
                    _openLoginDialog();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  label: '帮助中心',
                  onTap: () {
                    _closeMenu();
                    if (widget.onHelp != null) {
                      widget.onHelp!.call();
                    } else {
                      _handleHelpTap();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive 
                ? Theme.of(context).colorScheme.error 
                : WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDestructive 
                  ? Theme.of(context).colorScheme.error 
                  : WebTheme.getTextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProfileTap() {
    // 通过onOpenSettings回调打开设置面板并定位到账户管理
    if (widget.onOpenSettings != null) {
      widget.onOpenSettings!.call();
      return;
    }
    // 回退：如果缺少回调，则尝试在当前上下文直接打开设置面板
    try {
      _openSettingsPanelFallback();
    } catch (_) {
      TopToast.info(context, '请通过设置面板查看个人资料');
    }
  }

  void _handleSettingsTap() {
    if (widget.onOpenSettings != null) {
      widget.onOpenSettings!.call();
      return;
    }
    // 回退：优先尝试打开设置面板，其次再退回旧的设置页
    try {
      _openSettingsPanelFallback();
      return;
    } catch (_) {}
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserSettingsScreen(),
      ),
    );
  }

  void _handleHelpTap() {
    // TODO: 导航到帮助页面
    TopToast.info(context, '帮助中心功能开发中');
  }

  void _openMySubscriptionPanel() {
    // 简单实现：打开设置面板并定位到“会员与订阅”标签页
    // 如果现有页面没有路由，先给出提示
    TopToast.info(context, '打开“我的订阅”，请在设置面板中查看会员与订阅标签');
    // TODO: 若有全局状态或路由可直接跳转到 SettingsPanel 并定位到会员页
  }

  // 回退：在没有 onOpenSettings 的页面尝试直接弹出 SettingsPanel
  void _openSettingsPanelFallback() {
    // 需要 EditorLayoutManager/StateManager 等依赖在构造 SettingsPanel，
    // 在非编辑器页面使用最小依赖构造并通过 Dialog 弹出
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        // 延迟导入，避免循环依赖
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: SettingsPanel(
            stateManager: EditorStateManager(),
            userId: AppConfig.userId ?? 'current_user',
            onClose: () => Navigator.of(dialogContext).pop(),
            editorSettings: const EditorSettings(),
            onEditorSettingsChanged: (_) {},
            initialCategoryIndex: SettingsPanel.accountManagementCategoryIndex,
          ),
        );
      },
    );
  }

  void _handleLogout() {
    _showLogoutConfirmDialog();
  }

  void _openLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 992
              ? 960
              : MediaQuery.of(context).size.width - 32,
          height: MediaQuery.of(context).size.height - 32,
          child: const EnhancedLoginScreen(),
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WebTheme.getBackgroundColor(context),
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
              _performLogoutAndClose();
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

  void _performLogoutAndClose() async {
    // 立即关闭对话框
    Navigator.of(context).pop();
    
    // 显示简短的退出提示
    if (mounted) {
      TopToast.info(context, '正在退出登录...');
    }

    // 稍微延迟后执行退出，确保UI更新完成
    await Future.delayed(Duration(milliseconds: 100));
    
    if (mounted) {
      // 调用AuthBloc执行登出
      context.read<AuthBloc>().add(AuthLogout());
      
      // 强制导航到登录页面，确保退出后立即跳转
      await Future.delayed(Duration(milliseconds: 200)); // 等待AuthBloc处理完毕
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/', // 回到根路由（登录页面）
          (route) => false, // 清除所有路由栈
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _buttonKey,
      onTap: _toggleMenu,
      behavior: HitTestBehavior.opaque, // 确保整个区域都可点击
      child: Container(
        padding: const EdgeInsets.all(8), // 增大点击区域
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isMenuOpen 
            ? WebTheme.getSurfaceColor(context)
            : Colors.transparent,
        ),
        child: widget.showName 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: widget.size,
                  backgroundColor: WebTheme.getEmptyStateColor(context),
                  child: Icon(
                    Icons.person,
                    size: widget.size * 1.2,
                    color: WebTheme.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppConfig.username ?? '游客',
                  style: TextStyle(
                    color: WebTheme.getTextColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isMenuOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ],
            )
          : CircleAvatar(
              radius: widget.size,
              backgroundColor: WebTheme.getEmptyStateColor(context),
              child: Icon(
                Icons.person,
                size: widget.size * 1.2,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
      ),
    );
  }
}