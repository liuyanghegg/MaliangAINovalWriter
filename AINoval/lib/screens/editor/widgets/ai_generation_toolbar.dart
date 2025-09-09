import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

/// AI生成工具栏
/// 在流式输出文本时显示，提供Apply、Retry、Discard、Section等操作
class AIGenerationToolbar extends StatefulWidget {
  const AIGenerationToolbar({
    super.key,
    required this.layerLink,
    required this.onApply,
    required this.onRetry,
    required this.onDiscard,
    required this.onSection,
    required this.wordCount,
    required this.modelName,
    this.isGenerating = false,
    this.onClosed,
    this.showAbove = false,
    this.onStop,
    this.offsetAbove = -60.0,
    this.offsetBelow = 30.0,
  });

  /// 用于定位工具栏的层链接
  final LayerLink layerLink;

  /// 应用生成的文本
  final VoidCallback onApply;

  /// 重新生成
  final VoidCallback onRetry;

  /// 丢弃生成的文本
  final VoidCallback onDiscard;

  /// 分段功能
  final VoidCallback onSection;

  /// 停止生成
  final VoidCallback? onStop;

  /// 生成文本的字数
  final int wordCount;

  /// 使用的模型名称
  final String modelName;

  /// 是否正在生成中
  final bool isGenerating;

  /// 工具栏关闭回调
  final VoidCallback? onClosed;

  /// 是否显示在上方
  final bool showAbove;

  /// 上方显示时的Y偏移量
  final double offsetAbove;

  /// 下方显示时的Y偏移量
  final double offsetBelow;

  @override
  State<AIGenerationToolbar> createState() => _AIGenerationToolbarState();
}

class _AIGenerationToolbarState extends State<AIGenerationToolbar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLight = !isDark;

    return CompositedTransformFollower(
      link: widget.layerLink,
      offset: widget.showAbove ? Offset(0, widget.offsetAbove) : Offset(0, widget.offsetBelow),
      followerAnchor: Alignment.topCenter,
      targetAnchor: Alignment.topCenter,
      showWhenUnlinked: false,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        opaque: true,
        hitTestBehavior: HitTestBehavior.opaque,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildToolbarContainer(isLightTheme: isLight),

          ),
        ),
      ),
    );
  }

  /// 构建工具栏容器
  Widget _buildToolbarContainer({required bool isLightTheme}) {
    return Container(
      decoration: BoxDecoration(
        // 统一使用 WebTheme 色系
        color: isLightTheme ? WebTheme.black : WebTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: WebTheme.getShadowColor(context, opacity: isLightTheme ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: WebTheme.getSecondaryBorderColor(context),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 估算内容总宽度
          final contentWidth = _estimateContentWidth();
          
          // 如果空间不足，使用垂直布局
          if (contentWidth > constraints.maxWidth && constraints.maxWidth > 0) {
            return _buildVerticalLayout(isLightTheme);
          } else {
            return _buildHorizontalLayout(isLightTheme);
          }
        },
      ),
    );
  }

  /// 构建水平布局
  Widget _buildHorizontalLayout(bool isLightTheme) {
    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 操作按钮区域
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.check,
                      label: 'Apply',
                      tooltip: '应用生成的文本',
                      onPressed: widget.isGenerating ? null : widget.onApply,
                    ),
                    if (widget.isGenerating && widget.onStop != null)
                      _buildActionButton(
                        icon: Icons.stop,
                        label: 'Stop',
                        tooltip: '停止生成',
                        onPressed: widget.onStop,
                      )
                    else
                      _buildActionButton(
                        icon: Icons.refresh,
                        label: 'Retry',
                        tooltip: '重新生成',
                        onPressed: widget.isGenerating ? null : widget.onRetry,
                      ),
                    _buildActionButton(
                      icon: Icons.close,
                      label: 'Discard',
                      tooltip: widget.isGenerating ? '停止并丢弃生成的文本' : '丢弃生成的文本',
                      onPressed: widget.onDiscard,
                    ),
                    _buildActionButton(
                      icon: Icons.crop_free,
                      label: 'Section',
                      tooltip: '分段处理',
                      onPressed: widget.isGenerating ? null : widget.onSection,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 分隔线
          Container(
            width: 1,
            height: 32,
            color: WebTheme.getSecondaryBorderColor(context),
          ),
          // 信息区域
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _buildInfoContent(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建垂直布局（当空间不足时）
  Widget _buildVerticalLayout(bool isLightTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 操作按钮区域
        Container(
          padding: const EdgeInsets.all(2),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.check,
                  label: 'Apply',
                  tooltip: '应用生成的文本',
                  onPressed: widget.isGenerating ? null : widget.onApply,
                ),
                if (widget.isGenerating && widget.onStop != null)
                  _buildActionButton(
                    icon: Icons.stop,
                    label: 'Stop',
                    tooltip: '停止生成',
                    onPressed: widget.onStop,
                  )
                else
                  _buildActionButton(
                    icon: Icons.refresh,
                    label: 'Retry',
                    tooltip: '重新生成',
                    onPressed: widget.isGenerating ? null : widget.onRetry,
                  ),
                _buildActionButton(
                  icon: Icons.close,
                  label: 'Discard',
                  tooltip: widget.isGenerating ? '停止并丢弃生成的文本' : '丢弃生成的文本',
                  onPressed: widget.onDiscard,
                ),
                _buildActionButton(
                  icon: Icons.crop_free,
                  label: 'Section',
                  tooltip: '分段处理',
                  onPressed: widget.isGenerating ? null : widget.onSection,
                ),
              ],
            ),
          ),
        ),
        // 分隔线
        Container(
          width: double.infinity,
          height: 1,
          color: WebTheme.getSecondaryBorderColor(context),
        ),
        // 信息区域
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildInfoContent(),
        ),
      ],
    );
  }

  /// 构建信息内容
  Widget _buildInfoContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isGenerating) ...[
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(WebTheme.white),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '生成中...',
              style: const TextStyle(
                color: WebTheme.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            '${widget.wordCount} Words',
            style: const TextStyle(
              color: WebTheme.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Text(
          ', ',
          style: TextStyle(
            color: WebTheme.white,
            fontSize: 12,
          ),
        ),
        Flexible(
          child: Text(
            widget.modelName,
            style: const TextStyle(
              color: WebTheme.white,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 估算内容总宽度
  double _estimateContentWidth() {
    // 操作按钮: 4个按钮 * 80px ≈ 320px
    // 分隔线: 1px
    // 信息区域: 约150px
    // 内边距: 约30px
    return 320 + 1 + 150 + 30; // ≈ 501px
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        opaque: true,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isEnabled 
                      ? WebTheme.white
                      : WebTheme.white,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled 
                        ? WebTheme.white
                        : WebTheme.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 