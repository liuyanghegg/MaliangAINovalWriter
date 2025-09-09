import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 浮动卡片配置
class FloatingCardConfig {
  final double? width;
  final double? height;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final Border? border;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool showCloseButton;
  final bool closeOnBackgroundTap;
  final bool enableBackgroundTap;
  final bool showFloatingCloseButton;

  const FloatingCardConfig({
    this.width,
    this.height,
    this.minWidth = 300.0,
    this.maxWidth = 800.0,
    this.minHeight = 200.0,
    this.maxHeight = 600.0,
    this.margin,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.shadows,
    this.border,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutCubic,
    this.showCloseButton = true,
    this.closeOnBackgroundTap = false,
    this.enableBackgroundTap = true,
    this.showFloatingCloseButton = true,
  });
}

/// 浮动卡片位置配置
class FloatingCardPosition {
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final Alignment? alignment;
  final double? offsetFromSidebar;

  const FloatingCardPosition({
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.alignment,
    this.offsetFromSidebar,
  });

  /// 默认居中位置
  static const center = FloatingCardPosition(alignment: Alignment.center);
  
  /// 从侧边栏偏移的位置
  static FloatingCardPosition fromSidebar({
    required double sidebarWidth,
    double offset = 16.0,
    double top = 80.0,
  }) {
    return FloatingCardPosition(
      left: sidebarWidth + offset,
      top: top,
    );
  }
}

/// 通用浮动卡片管理器
class FloatingCard {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// 显示浮动卡片
  static void show({
    required BuildContext context,
    required Widget child,
    FloatingCardConfig config = const FloatingCardConfig(),
    FloatingCardPosition position = FloatingCardPosition.center,
    VoidCallback? onClose,
    String? title,
    List<Widget>? actions,
  }) {
    if (_isShowing) {
      hide();
    }

    _overlayEntry = _createOverlayEntry(
      context: context,
      child: child,
      config: config,
      position: position,
      onClose: onClose,
      title: title,
      actions: actions,
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;
  }

  /// 隐藏浮动卡片
  static void hide() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }

  /// 检查是否正在显示
  static bool get isShowing => _isShowing;

  /// 创建 Overlay 条目
  static OverlayEntry _createOverlayEntry({
    required BuildContext context,
    required Widget child,
    required FloatingCardConfig config,
    required FloatingCardPosition position,
    VoidCallback? onClose,
    String? title,
    List<Widget>? actions,
  }) {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 背景遮罩
          if (config.enableBackgroundTap)
            Positioned.fill(
              child: GestureDetector(
                onTap: config.closeOnBackgroundTap ? (onClose ?? hide) : null,
                child: Container(
                  color: config.closeOnBackgroundTap 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.transparent,
                ),
              ),
            )
          else
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(color: Colors.transparent),
              ),
            ),
          
          // 浮动卡片
          _FloatingCardWidget(
            child: child,
            config: config,
            position: position,
            onClose: onClose ?? hide,
            title: title,
            actions: actions,
          ),
        ],
      ),
    );
  }
}

/// 浮动卡片组件
class _FloatingCardWidget extends StatefulWidget {
  final Widget child;
  final FloatingCardConfig config;
  final FloatingCardPosition position;
  final VoidCallback onClose;
  final String? title;
  final List<Widget>? actions;

  const _FloatingCardWidget({
    required this.child,
    required this.config,
    required this.position,
    required this.onClose,
    this.title,
    this.actions,
  });

  @override
  State<_FloatingCardWidget> createState() => _FloatingCardWidgetState();
}

class _FloatingCardWidgetState extends State<_FloatingCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: widget.config.animationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 400.0,  // 改为和原来相同的滑入距离
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.config.animationCurve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,  // 保持和原来相同的动画曲线
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => _buildPositionedCard(),
    );
  }

  Widget _buildPositionedCard() {
    final screenSize = MediaQuery.of(context).size;
    
    // 计算位置
    double? left = widget.position.left;
    double? top = widget.position.top;
    double? right = widget.position.right;
    double? bottom = widget.position.bottom;
    
    if (widget.position.alignment != null) {
      final alignment = widget.position.alignment!;
      final cardWidth = _calculateCardWidth(screenSize);
      final cardHeight = _calculateCardHeight(screenSize);
      
      switch (alignment) {
        case Alignment.center:
          left = (screenSize.width - cardWidth) / 2;
          top = (screenSize.height - cardHeight) / 2;
          break;
        case Alignment.topCenter:
          left = (screenSize.width - cardWidth) / 2;
          top = 50;
          break;
        case Alignment.bottomCenter:
          left = (screenSize.width - cardWidth) / 2;
          bottom = 50;
          break;
        // 可以添加更多对齐方式
      }
    }

    return Stack(
      children: [
        // 主卡片
        Positioned(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          child: Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildCard(context),
              ),
            ),
          ),
        ),
        
        // 浮动关闭按钮
        if (widget.config.showFloatingCloseButton)
          Positioned(
            left: (left ?? 0) - 12,
            top: (top ?? 0) - 12,
            child: Transform.translate(
              offset: Offset(_slideAnimation.value, 0),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildFloatingCloseButton(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  double _calculateCardWidth(Size screenSize) {
    if (widget.config.width != null) return widget.config.width!;
    
    double width = screenSize.width * 0.4; // 默认40%屏幕宽度
    
    if (widget.config.minWidth != null) {
      width = width.clamp(widget.config.minWidth!, double.infinity);
    }
    if (widget.config.maxWidth != null) {
      width = width.clamp(0, widget.config.maxWidth!);
    }
    
    return width;
  }

  double _calculateCardHeight(Size screenSize) {
    if (widget.config.height != null) return widget.config.height!;
    
    double height = screenSize.height * 0.6; // 默认60%屏幕高度
    
    if (widget.config.minHeight != null) {
      height = height.clamp(widget.config.minHeight!, double.infinity);
    }
    if (widget.config.maxHeight != null) {
      height = height.clamp(0, widget.config.maxHeight!);
    }
    
    return height;
  }

  Widget _buildCard(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    final screenSize = MediaQuery.of(context).size;
    
    final cardWidth = _calculateCardWidth(screenSize);
    final cardHeight = _calculateCardHeight(screenSize);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {}, // 阻止点击穿透
        child: Container(
          width: cardWidth,
          height: cardHeight,
          margin: widget.config.margin,
          padding: widget.config.padding,
          decoration: BoxDecoration(
            color: widget.config.backgroundColor ?? 
                (isDark ? WebTheme.darkGrey100 : WebTheme.getBackgroundColor(context)),
            borderRadius: widget.config.borderRadius ?? 
                BorderRadius.circular(12),
            border: widget.config.border ?? 
                Border.all(
                  color: isDark 
                      ? WebTheme.darkGrey800
                      : WebTheme.getShadowColor(context, opacity: 0.05),
                  width: 1,
                ),
            boxShadow: widget.config.shadows ?? [
              BoxShadow(
                color: WebTheme.getShadowColor(context, opacity: 0.2),
                offset: const Offset(0, 8),
                blurRadius: 32,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // 头部（如果有标题或动作）
              if (widget.title != null || 
                  widget.actions != null || 
                  (widget.config.showCloseButton && !widget.config.showFloatingCloseButton))
                _buildHeader(isDark),
              
              // 内容区域
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? WebTheme.darkGrey800 : WebTheme.getBorderColor(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 标题
          if (widget.title != null)
            Expanded(
              child: Text(
                widget.title!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? WebTheme.grey100 : WebTheme.grey900,
                ),
              ),
            ),
          
          // 自定义操作按钮
          if (widget.actions != null) ...[
            ...widget.actions!,
            const SizedBox(width: 8),
          ],
          
          // 关闭按钮（仅在不显示浮动关闭按钮时显示）
          if (widget.config.showCloseButton && !widget.config.showFloatingCloseButton)
            IconButton(
              onPressed: _handleClose,
              icon: Icon(
                Icons.close,
                size: 20,
                color: isDark ? WebTheme.grey400 : WebTheme.grey600,
              ),
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建浮动关闭按钮
  Widget _buildFloatingCloseButton() {
    return Material(
      elevation: 8,
      shape: const CircleBorder(),
      color: Colors.black87,
      child: InkWell(
        onTap: _handleClose,
        customBorder: const CircleBorder(),
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
} 