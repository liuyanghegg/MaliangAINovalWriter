import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/blocs/auth/auth_bloc.dart';
import 'package:ainoval/blocs/credit/credit_bloc.dart';
// import 'package:ainoval/models/user_credit.dart';

/// 积分显示组件
/// 用于在聊天输入框等位置显示用户当前积分
class CreditDisplay extends StatefulWidget {
  const CreditDisplay({
    super.key,
    this.size = CreditDisplaySize.small,
    this.showRefreshButton = false,
    this.onTap,
  });

  /// 显示尺寸
  final CreditDisplaySize size;
  
  /// 是否显示刷新按钮
  final bool showRefreshButton;
  
  /// 点击回调
  final VoidCallback? onTap;

  @override
  State<CreditDisplay> createState() => _CreditDisplayState();
}

class _CreditDisplayState extends State<CreditDisplay> {
  @override
  void initState() {
    super.initState();
    // 组件初始化时加载积分信息
    try {
      final authed = context.read<AuthBloc>().state is AuthAuthenticated;
      if (!authed) return;
      // 若已在加载或已加载，避免重复触发
      final state = context.read<CreditBloc>().state;
      if (state is CreditLoading || state is CreditLoaded) return;
      context.read<CreditBloc>().add(const LoadUserCredits());
    } catch (_) {
      // 在无 AuthBloc 场景下静默忽略
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreditBloc, CreditState>(
      builder: (context, state) {
        return _buildCreditWidget(context, state);
      },
    );
  }

  Widget _buildCreditWidget(BuildContext context, CreditState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (state is CreditLoading) {
      return _buildLoadingWidget(colorScheme);
    }
    
    if (state is CreditError) {
      return _buildErrorWidget(context, colorScheme, state.message);
    }
    
    if (state is CreditLoaded) {
      return _buildLoadedWidget(context, colorScheme, isDark, state);
    }
    
    // 默认状态（游客视为0积分）
    return _buildGuestWidget(context, colorScheme);
  }

  /// 构建加载中的小部件
  Widget _buildLoadingWidget(ColorScheme colorScheme) {
    final double size = _getIconSize();
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: _getPadding(),
        decoration: _getContainerDecoration(colorScheme, false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ),
            if (widget.size != CreditDisplaySize.iconOnly) ...[
              const SizedBox(width: 6),
              Text(
                '...',
                style: _getTextStyle(colorScheme),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建错误状态的小部件
  Widget _buildErrorWidget(BuildContext context, ColorScheme colorScheme, String message) {
    final double iconSize = _getIconSize();
    
    return GestureDetector(
      onTap: widget.onTap ?? () {
        try {
          final authed = context.read<AuthBloc>().state is AuthAuthenticated;
          if (authed) {
            context.read<CreditBloc>().add(const LoadUserCredits());
          }
        } catch (_) {}
      },
      child: Container(
        padding: _getPadding(),
        decoration: _getContainerDecoration(colorScheme, false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: iconSize,
              color: colorScheme.error,
            ),
            if (widget.size != CreditDisplaySize.iconOnly) ...[
              const SizedBox(width: 6),
              Text(
                '错误',
                style: _getTextStyle(colorScheme).copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建已加载状态的小部件
  Widget _buildLoadedWidget(
    BuildContext context, 
    ColorScheme colorScheme, 
    bool isDark, 
    CreditLoaded state,
  ) {
    final double iconSize = _getIconSize();
    final bool isLowCredit = state.userCredit.credits < 100; // 小于100积分视为余额不足
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: _getPadding(),
        decoration: _getContainerDecoration(colorScheme, isLowCredit),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGradientIcon(colorScheme, isDark, iconSize),
            if (widget.size != CreditDisplaySize.iconOnly) ...[
              const SizedBox(width: 6),
              Text(
                _formatCredits(state.userCredit.credits),
                style: _getTextStyle(colorScheme).copyWith(
                  fontWeight: isLowCredit ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
            // 刷新按钮
            if (widget.showRefreshButton) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () => context.read<CreditBloc>().add(const RefreshUserCredits()),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.refresh,
                    size: iconSize * 0.8,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建游客状态的小部件（显示0）
  Widget _buildGuestWidget(BuildContext context, ColorScheme colorScheme) {
    final double iconSize = _getIconSize();
    
    return GestureDetector(
      onTap: widget.onTap, // 游客不触发加载
      child: Container(
        padding: _getPadding(),
        decoration: _getContainerDecoration(colorScheme, false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGradientIcon(colorScheme, Theme.of(context).brightness == Brightness.dark, iconSize),
            if (widget.size != CreditDisplaySize.iconOnly) ...[
              const SizedBox(width: 6),
              Text(
                '0',
                style: _getTextStyle(colorScheme).copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 获取图标尺寸
  double _getIconSize() {
    switch (widget.size) {
      case CreditDisplaySize.small:
        return 14;
      case CreditDisplaySize.medium:
        return 16;
      case CreditDisplaySize.large:
        return 20;
      case CreditDisplaySize.iconOnly:
        return 16;
    }
  }

  /// 获取内边距
  EdgeInsets _getPadding() {
    switch (widget.size) {
      case CreditDisplaySize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case CreditDisplaySize.medium:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
      case CreditDisplaySize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case CreditDisplaySize.iconOnly:
        return const EdgeInsets.all(6);
    }
  }

  /// 获取文本样式
  TextStyle _getTextStyle(ColorScheme colorScheme) {
    switch (widget.size) {
      case CreditDisplaySize.small:
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        );
      case CreditDisplaySize.medium:
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        );
      case CreditDisplaySize.large:
        return TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        );
      case CreditDisplaySize.iconOnly:
        return const TextStyle(); // 不显示文本
    }
  }

  /// 获取容器装饰
  BoxDecoration _getContainerDecoration(ColorScheme colorScheme, bool isLowCredit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 背景与主题一致：使用表面容器色系，形成轻微对比；取消红色处理
    final Color backgroundColor = isDark 
        ? colorScheme.surfaceContainerHighest.withOpacity(0.6)
        : colorScheme.surfaceContainerHighest.withOpacity(0.8);
    final Color borderColor = colorScheme.outline.withOpacity(0.2);

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(widget.size == CreditDisplaySize.iconOnly ? 12 : 8),
      border: Border.all(
        color: borderColor,
        width: 0.8,
      ),
    );
  }

  // 渐变图标：星光图标 + 主题友好的多彩渐变
  Widget _buildGradientIcon(ColorScheme colorScheme, bool isDark, double size) {
    final List<Color> colors = _getIconGradientColors(isDark);
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Icon(
        Icons.auto_awesome,
        size: size,
        color: Colors.white,
      ),
    );
  }

  List<Color> _getIconGradientColors(bool isDark) {
    // 深浅色模式下均使用鲜明但优雅的配色
    return isDark
        ? const [
            Color(0xFF60A5FA), // blue-400
            Color(0xFF8B5CF6), // violet-500
            Color(0xFFF472B6), // pink-400
          ]
        : const [
            Color(0xFF6366F1), // indigo-500
            Color(0xFF8B5CF6), // violet-500
            Color(0xFFEC4899), // pink-500
          ];
  }

  /// 格式化积分显示
  String _formatCredits(num credits) {
    if (credits >= 10000) {
      return '${(credits / 1000).toStringAsFixed(1)}K';
    } else if (credits >= 1000) {
      return '${(credits / 1000).toStringAsFixed(1)}K';
    } else {
      return credits.toStringAsFixed(0);
    }
  }
}

/// 积分显示尺寸
enum CreditDisplaySize {
  /// 小尺寸，适用于工具栏
  small,
  
  /// 中等尺寸，适用于一般用途
  medium,
  
  /// 大尺寸，适用于强调显示
  large,
  
  /// 仅图标，不显示文本
  iconOnly,
} 