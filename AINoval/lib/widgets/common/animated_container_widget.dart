import 'package:flutter/material.dart';

enum AnimationType {
  fadeIn,
  scaleIn,
  slideInRight,
}

class AnimatedContainerWidget extends StatefulWidget {
  final Widget child;
  final AnimationType animationType;
  final Duration duration;
  final Duration? delay;
  final Curve curve;

  const AnimatedContainerWidget({
    Key? key,
    required this.child,
    this.animationType = AnimationType.fadeIn,
    this.duration = const Duration(milliseconds: 300),
    this.delay,
    this.curve = Curves.easeOut,
  }) : super(key: key);

  @override
  State<AnimatedContainerWidget> createState() => _AnimatedContainerWidgetState();
}

class _AnimatedContainerWidgetState extends State<AnimatedContainerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    switch (widget.animationType) {
      case AnimationType.fadeIn:
        _animation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
        ));
        break;
      case AnimationType.scaleIn:
        _animation = Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
        ));
        break;
      case AnimationType.slideInRight:
        _slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
        ));
        break;
    }

    if (widget.delay != null) {
      Future.delayed(widget.delay!, () {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _controller.forward();
          }
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.animationType) {
      case AnimationType.fadeIn:
        return FadeTransition(
          opacity: _animation,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - _animation.value)),
            child: widget.child,
          ),
        );
      case AnimationType.scaleIn:
        return ScaleTransition(
          scale: _animation,
          child: FadeTransition(
            opacity: _animation,
            child: widget.child,
          ),
        );
      case AnimationType.slideInRight:
        return SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        );
    }
  }
}