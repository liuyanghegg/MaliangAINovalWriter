import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 通用卡片组件配置
class UniversalCardConfig {
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final Border? border;
  final Color? backgroundColor;
  final bool showCloseButton;
  final bool showHeader;
  final double elevation;

  const UniversalCardConfig({
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius,
    this.shadows,
    this.border,
    this.backgroundColor,
    this.showCloseButton = true,
    this.showHeader = true,
    this.elevation = 8.0,
  });

  /// 复制并修改配置
  UniversalCardConfig copyWith({
    double? width,
    double? height,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
    Border? border,
    Color? backgroundColor,
    bool? showCloseButton,
    bool? showHeader,
    double? elevation,
  }) {
    return UniversalCardConfig(
      width: width ?? this.width,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      borderRadius: borderRadius ?? this.borderRadius,
      shadows: shadows ?? this.shadows,
      border: border ?? this.border,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      showHeader: showHeader ?? this.showHeader,
      elevation: elevation ?? this.elevation,
    );
  }

  /// 预设配置 - 标准卡片
  static const standard = UniversalCardConfig(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    elevation: 8.0,
    padding: EdgeInsets.all(20),
  );

  /// 预设配置 - 紧凑卡片
  static const compact = UniversalCardConfig(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    elevation: 4.0,
    padding: EdgeInsets.all(16),
  );

  /// 预设配置 - 浮动预览卡片
  static const preview = UniversalCardConfig(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    elevation: 16.0,
    padding: EdgeInsets.all(20),
    showCloseButton: true,
  );
}

/// 通用卡片组件
/// 
/// 提供统一的卡片样式和主题，支持自定义配置
/// 应用 WebTheme 全局样式，确保视觉一致性
class UniversalCard extends StatelessWidget {
  final Widget child;
  final UniversalCardConfig config;
  final String? title;
  final Widget? headerAction;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  const UniversalCard({
    Key? key,
    required this.child,
    this.config = UniversalCardConfig.standard,
    this.title,
    this.headerAction,
    this.onClose,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: config.elevation,
      borderRadius: config.borderRadius ?? BorderRadius.circular(12),
      color: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.2),
      child: Container(
        width: config.width,
        height: config.height,
        margin: config.margin,
        decoration: _getCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 可选的头部区域
            if (config.showHeader && (title != null || config.showCloseButton))
              _buildHeader(context),

            // 主要内容区域
            Flexible(
              child: Container(
                padding: config.padding,
                child: child,
              ),
            ),

            // 可选的底部操作区域
            if (actions != null && actions!.isNotEmpty)
              _buildActions(context),
          ],
        ),
      ),
    );
  }

  /// 获取卡片装饰样式
  BoxDecoration _getCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: config.backgroundColor ?? WebTheme.white,
      borderRadius: config.borderRadius ?? BorderRadius.circular(12),
      border: config.border ?? Border.all(
        color: WebTheme.grey300,
        width: 1.5,
      ),
      boxShadow: config.shadows ?? [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// 构建头部区域
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        children: [
          // 标题
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: WebTheme.getAlignedTextStyle(
                  baseStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
              ),
            ),

          // 头部操作
          if (headerAction != null) ...[
            const SizedBox(width: 12),
            headerAction!,
          ],

          // 关闭按钮
          if (config.showCloseButton && onClose != null)
            _buildCloseButton(context),
        ],
      ),
    );
  }

  /// 构建关闭按钮
  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.close,
            size: 20,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
      ),
    );
  }

  /// 构建底部操作区域
  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: WebTheme.grey200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions!,
      ),
    );
  }
}

/// 简化的卡片组件 - 用于无头部的场景
class SimpleUniversalCard extends StatelessWidget {
  final Widget child;
  final UniversalCardConfig config;

  const SimpleUniversalCard({
    Key? key,
    required this.child,
    this.config = UniversalCardConfig.compact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: config.elevation,
      borderRadius: config.borderRadius ?? BorderRadius.circular(8),
      color: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.15),
      child: Container(
        width: config.width,
        height: config.height,
        margin: config.margin,
        padding: config.padding,
        decoration: BoxDecoration(
          color: config.backgroundColor ?? WebTheme.white,
          borderRadius: config.borderRadius ?? BorderRadius.circular(8),
          border: config.border ?? Border.all(
            color: WebTheme.grey300,
            width: 1,
          ),
          boxShadow: config.shadows ?? [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// 卡片工具类 - 提供快速创建常用卡片的方法
class UniversalCardUtils {
  /// 创建信息展示卡片
  static Widget createInfoCard({
    required BuildContext context,
    required String title,
    required String content,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return SimpleUniversalCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 24,
                  color: WebTheme.getTextColor(context),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: WebTheme.getAlignedTextStyle(
                        baseStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: WebTheme.getTextColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: WebTheme.getAlignedTextStyle(
                        baseStyle: TextStyle(
                          fontSize: 13,
                          color: WebTheme.getSecondaryTextColor(context),
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 创建统计数据卡片
  static Widget createStatCard({
    required BuildContext context,
    required String title,
    required String value,
    IconData? icon,
    Color? valueColor,
  }) {
    return SimpleUniversalCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 32,
              color: valueColor ?? WebTheme.getTextColor(context),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            value,
            style: WebTheme.getAlignedTextStyle(
              baseStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: valueColor ?? WebTheme.getTextColor(context),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: WebTheme.getAlignedTextStyle(
              baseStyle: TextStyle(
                fontSize: 12,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 