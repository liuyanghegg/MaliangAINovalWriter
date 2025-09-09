import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 顶部吐司提示类型
enum TopToastType {
  success,
  warning,
  error,
  info,
}

/// 顶部吐司提示组件
/// 在屏幕顶部居中显示简洁的提示消息，与整体设计风格保持一致
class TopToast {
  static OverlayEntry? _currentOverlay;
  
  /// 显示顶部提示
  /// 
  /// [context] - 上下文，用于获取主题和Overlay
  /// [message] - 提示消息文本
  /// [type] - 提示类型，决定图标和颜色
  /// [duration] - 显示时长，默认3秒
  static void show(
    BuildContext context, {
    required String message,
    TopToastType type = TopToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // 如果有正在显示的toast，先移除它
    hide();
    
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    
    _currentOverlay = OverlayEntry(
      builder: (context) => _TopToastWidget(
        message: message,
        type: type,
        onDismiss: hide,
      ),
    );
    
    overlay.insert(_currentOverlay!);
    
    // 自动隐藏
    Future.delayed(duration, () {
      hide();
    });
  }
  
  /// 显示成功提示
  static void success(BuildContext context, String message) {
    show(context, message: message, type: TopToastType.success);
  }
  
  /// 显示警告提示
  static void warning(BuildContext context, String message) {
    show(context, message: message, type: TopToastType.warning);
  }
  
  /// 显示错误提示
  static void error(BuildContext context, String message) {
    show(context, message: message, type: TopToastType.error);
  }
  
  /// 显示信息提示
  static void info(BuildContext context, String message) {
    show(context, message: message, type: TopToastType.info);
  }
  
  /// 隐藏当前显示的提示
  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

/// 顶部吐司提示组件的内部实现
class _TopToastWidget extends StatefulWidget {
  const _TopToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });
  
  final String message;
  final TopToastType type;
  final VoidCallback onDismiss;
  
  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // 开始动画
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  /// 获取提示类型对应的配置
  _ToastConfig _getConfig(bool isDark) {
    switch (widget.type) {
      case TopToastType.success:
        return _ToastConfig(
          icon: Icons.check_circle_outline,
          backgroundColor: WebTheme.success,
          textColor: Colors.white,
        );
      case TopToastType.warning:
        return _ToastConfig(
          icon: Icons.warning_outlined,
          backgroundColor: WebTheme.warning,
          textColor: Colors.white,
        );
      case TopToastType.error:
        return _ToastConfig(
          icon: Icons.error_outline,
          backgroundColor: WebTheme.error,
          textColor: Colors.white,
        );
      case TopToastType.info:
        return _ToastConfig(
          icon: Icons.info_outline,
          backgroundColor: isDark ? WebTheme.darkGrey100 : WebTheme.white,
          textColor: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
        );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _getConfig(isDark);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          top: 20 + (_slideAnimation.value * 60), // 从顶部向下滑入
          left: 0,
          right: 0,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    minWidth: 200,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: config.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                    border: widget.type == TopToastType.info
                        ? Border.all(
                            color: isDark 
                                ? WebTheme.darkGrey300 
                                : WebTheme.grey300,
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        config.icon,
                        size: 18,
                        color: config.textColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: config.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 提示配置类
class _ToastConfig {
  const _ToastConfig({
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
  });
  
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
}