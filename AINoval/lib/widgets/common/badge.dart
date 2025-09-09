import 'package:ainoval/utils/web_theme.dart';
import 'package:flutter/material.dart';


enum BadgeVariant {
  solid,
  outline,
  secondary,
  destructive,
  success,
  warning,
}

class Badge extends StatefulWidget {
  final String text;
  final BadgeVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final int? animationDelay; // In milliseconds

  const Badge({
    Key? key,
    required this.text,
    this.variant = BadgeVariant.solid,
    this.onTap,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.animationDelay,
  }) : super(key: key);

  @override
  State<Badge> createState() => _BadgeState();
}

class _BadgeState extends State<Badge> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    if (widget.animationDelay != null) {
      Future.delayed(Duration(milliseconds: widget.animationDelay!), () {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _animationController.forward();
          }
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animationController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    
    switch (widget.variant) {
      case BadgeVariant.solid:
        return WebTheme.getPrimaryColor(context);
      case BadgeVariant.outline:
        return Colors.transparent;
      case BadgeVariant.secondary:
        return isDark ? WebTheme.darkGrey200 : WebTheme.grey200;
      case BadgeVariant.destructive:
        return WebTheme.error.withOpacity(0.1);
      case BadgeVariant.success:
        return WebTheme.success.withOpacity(0.1);
      case BadgeVariant.warning:
        return WebTheme.warning.withOpacity(0.1);
    }
  }

  Color _getTextColor(BuildContext context) {
    switch (widget.variant) {
      case BadgeVariant.solid:
        return WebTheme.white;
      case BadgeVariant.outline:
        return WebTheme.getTextColor(context, isPrimary: false);
      case BadgeVariant.secondary:
        return WebTheme.getTextColor(context, isPrimary: false);
      case BadgeVariant.destructive:
        return WebTheme.error;
      case BadgeVariant.success:
        return WebTheme.success;
      case BadgeVariant.warning:
        return WebTheme.warning;
    }
  }

  Color? _getBorderColor(BuildContext context) {
    switch (widget.variant) {
      case BadgeVariant.outline:
        return WebTheme.getBorderColor(context);
      case BadgeVariant.destructive:
        return WebTheme.error.withOpacity(0.3);
      case BadgeVariant.success:
        return WebTheme.success.withOpacity(0.3);
      case BadgeVariant.warning:
        return WebTheme.warning.withOpacity(0.3);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClickable = widget.onTap != null;
    
    Widget badge = ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(_isHovered && isClickable ? 1.05 : 1.0),
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(12),
          border: _getBorderColor(context) != null
            ? Border.all(
                color: _getBorderColor(context)!,
                width: 1,
              )
            : null,
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: widget.fontSize ?? 12,
            fontWeight: widget.fontWeight ?? FontWeight.w500,
            color: _getTextColor(context),
          ),
        ),
      ),
    );
    
    if (isClickable) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: badge,
        ),
      );
    }
    
    return badge;
  }
}