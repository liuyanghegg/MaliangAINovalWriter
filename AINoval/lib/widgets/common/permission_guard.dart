import 'package:flutter/material.dart';

import '../../services/permission_service.dart';
import '../../utils/logger.dart';

/// 权限守卫小部件
/// 根据用户权限显示或隐藏内容
class PermissionGuard extends StatefulWidget {
  /// 需要的权限
  final String? permission;
  
  /// 需要的多个权限
  final List<String>? permissions;
  
  /// 多权限检查模式：true为需要全部权限，false为需要任一权限
  final bool requireAll;
  
  /// 功能名称（用于功能级权限检查）
  final String? feature;
  
  /// 有权限时显示的内容
  final Widget child;
  
  /// 无权限时显示的内容
  final Widget? fallback;
  
  /// 是否显示加载状态
  final bool showLoading;
  
  /// 加载状态的小部件
  final Widget? loadingWidget;
  
  /// 权限检查失败时的回调
  final VoidCallback? onPermissionDenied;

  const PermissionGuard({
    Key? key,
    this.permission,
    this.permissions,
    this.requireAll = false,
    this.feature,
    required this.child,
    this.fallback,
    this.showLoading = true,
    this.loadingWidget,
    this.onPermissionDenied,
  }) : assert(
         permission != null || permissions != null || feature != null,
         'Must provide either permission, permissions, or feature',
       ),
       super(key: key);

  /// 创建单权限守卫
  const PermissionGuard.permission(
    String permission, {
    Key? key,
    required Widget child,
    Widget? fallback,
    bool showLoading = true,
    Widget? loadingWidget,
    VoidCallback? onPermissionDenied,
  }) : this(
         key: key,
         permission: permission,
         child: child,
         fallback: fallback,
         showLoading: showLoading,
         loadingWidget: loadingWidget,
         onPermissionDenied: onPermissionDenied,
       );

  /// 创建多权限守卫
  const PermissionGuard.permissions(
    List<String> permissions, {
    Key? key,
    bool requireAll = false,
    required Widget child,
    Widget? fallback,
    bool showLoading = true,
    Widget? loadingWidget,
    VoidCallback? onPermissionDenied,
  }) : this(
         key: key,
         permissions: permissions,
         requireAll: requireAll,
         child: child,
         fallback: fallback,
         showLoading: showLoading,
         loadingWidget: loadingWidget,
         onPermissionDenied: onPermissionDenied,
       );

  /// 创建功能权限守卫
  const PermissionGuard.feature(
    String feature, {
    Key? key,
    required Widget child,
    Widget? fallback,
    bool showLoading = true,
    Widget? loadingWidget,
    VoidCallback? onPermissionDenied,
  }) : this(
         key: key,
         feature: feature,
         child: child,
         fallback: fallback,
         showLoading: showLoading,
         loadingWidget: loadingWidget,
         onPermissionDenied: onPermissionDenied,
       );

  /// 创建管理员权限守卫
  const PermissionGuard.admin({
    Key? key,
    required Widget child,
    Widget? fallback,
    bool showLoading = true,
    Widget? loadingWidget,
    VoidCallback? onPermissionDenied,
  }) : this(
         key: key,
         permission: 'ADMIN', // 特殊标识符，在检查时会调用isAdmin()
         child: child,
         fallback: fallback,
         showLoading: showLoading,
         loadingWidget: loadingWidget,
         onPermissionDenied: onPermissionDenied,
       );

  /// 创建超级管理员权限守卫
  const PermissionGuard.superAdmin({
    Key? key,
    required Widget child,
    Widget? fallback,
    bool showLoading = true,
    Widget? loadingWidget,
    VoidCallback? onPermissionDenied,
  }) : this(
         key: key,
         permission: 'SUPER_ADMIN', // 特殊标识符，在检查时会调用isSuperAdmin()
         child: child,
         fallback: fallback,
         showLoading: showLoading,
         loadingWidget: loadingWidget,
         onPermissionDenied: onPermissionDenied,
       );

  @override
  State<PermissionGuard> createState() => _PermissionGuardState();
}

class _PermissionGuardState extends State<PermissionGuard> {
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void didUpdateWidget(PermissionGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果权限参数发生变化，重新检查权限
    if (oldWidget.permission != widget.permission ||
        oldWidget.permissions != widget.permissions ||
        oldWidget.feature != widget.feature ||
        oldWidget.requireAll != widget.requireAll) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool hasPermission = false;

      if (widget.feature != null) {
        // 功能级权限检查
        hasPermission = await _permissionService.canAccessFeature(widget.feature!);
      } else if (widget.permission != null) {
        // 单权限检查
        if (widget.permission == 'ADMIN') {
          hasPermission = await _permissionService.isAdmin();
        } else if (widget.permission == 'SUPER_ADMIN') {
          hasPermission = await _permissionService.isSuperAdmin();
        } else {
          hasPermission = await _permissionService.hasPermission(widget.permission!);
        }
      } else if (widget.permissions != null) {
        // 多权限检查
        if (widget.requireAll) {
          hasPermission = await _permissionService.hasAllPermissions(widget.permissions!);
        } else {
          hasPermission = await _permissionService.hasAnyPermission(widget.permissions!);
        }
      }

      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
          _isLoading = false;
        });

        // 如果没有权限，调用回调
        if (!hasPermission && widget.onPermissionDenied != null) {
          widget.onPermissionDenied!();
        }
      }
    } catch (e) {
      AppLogger.error('PermissionGuard', '权限检查失败', e);
      
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _hasPermission = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 显示加载状态
    if (_isLoading && widget.showLoading) {
      return widget.loadingWidget ?? 
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }

    // 显示错误状态
    if (_error != null) {
      return widget.fallback ?? 
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 8),
                Text(
                  '权限检查失败',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
    }

    // 有权限时显示内容
    if (_hasPermission) {
      return widget.child;
    }

    // 无权限时显示备用内容
    return widget.fallback ?? const SizedBox.shrink();
  }
}

/// 权限装饰器小部件
/// 为按钮等交互元素提供权限控制
class PermissionWrapper extends StatelessWidget {
  /// 需要的权限
  final String? permission;
  
  /// 需要的多个权限
  final List<String>? permissions;
  
  /// 多权限检查模式
  final bool requireAll;
  
  /// 功能名称
  final String? feature;
  
  /// 子组件
  final Widget child;
  
  /// 无权限时是否禁用
  final bool disableWhenNoPermission;
  
  /// 无权限时的提示信息
  final String? deniedMessage;

  const PermissionWrapper({
    Key? key,
    this.permission,
    this.permissions,
    this.requireAll = false,
    this.feature,
    required this.child,
    this.disableWhenNoPermission = true,
    this.deniedMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: permission,
      permissions: permissions,
      requireAll: requireAll,
      feature: feature,
      child: child,
      fallback: disableWhenNoPermission 
          ? _buildDisabledChild(context)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDisabledChild(BuildContext context) {
    return Tooltip(
      message: deniedMessage ?? '权限不足',
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.5,
          child: child,
        ),
      ),
    );
  }
}

/// 权限检查的Future Builder
class PermissionFutureBuilder<T> extends StatelessWidget {
  /// 权限检查函数
  final Future<bool> Function() permissionChecker;
  
  /// 有权限时的构建器
  final Widget Function(BuildContext context) builder;
  
  /// 无权限时的构建器
  final Widget Function(BuildContext context)? fallbackBuilder;
  
  /// 加载状态构建器
  final Widget Function(BuildContext context)? loadingBuilder;

  const PermissionFutureBuilder({
    Key? key,
    required this.permissionChecker,
    required this.builder,
    this.fallbackBuilder,
    this.loadingBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: permissionChecker(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return fallbackBuilder?.call(context) ??
              Center(
                child: Text(
                  '权限检查失败',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
        }

        if (snapshot.data == true) {
          return builder(context);
        }

        return fallbackBuilder?.call(context) ?? const SizedBox.shrink();
      },
    );
  }
}