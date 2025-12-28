import 'package:ainoval/screens/next_outline/next_outline_screen.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:flutter/material.dart';

/// 剧情推演视图 - 全局通用组件
/// 
/// 此组件作为剧情推演功能的顶级容器，负责：
/// 1. 提供统一的主题样式和布局约束
/// 2. 在编辑器中嵌入剧情推演功能
/// 3. 管理与外部组件的交互回调
/// 
/// 设计原则：
/// - 使用纯黑白配色方案，保持现代简洁的视觉风格
/// - 采用全局主题WebTheme进行样式统一
/// - 提供合理的布局间距，避免界面拥挤或臃肿
/// - 支持响应式设计，适配不同屏幕尺寸
class NextOutlineView extends StatelessWidget {
  /// 小说ID - 用于标识当前编辑的小说
  final String novelId;
  
  /// 小说标题 - 用于显示上下文信息
  final String novelTitle;
  
  /// 切换到写作模式回调 - 用于在推演完成后返回编辑器
  final VoidCallback onSwitchToWrite;

  /// 跳转到添加模型页面的回调 - 用于配置AI模型
  final VoidCallback? onNavigateToAddModel;

  /// 跳转到配置特定模型页面的回调 - 用于模型参数调整
  final Function(String configId)? onConfigureModel;

  const NextOutlineView({
    Key? key,
    required this.novelId,
    required this.novelTitle,
    required this.onSwitchToWrite,
    this.onNavigateToAddModel,
    this.onConfigureModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // 使用主题定义的纯净背景色，确保视觉统一
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
      ),
      child: Column(
        children: [
          // 主内容区域 - 使用Expanded确保占据所有可用空间
          Expanded(
            child: Container(
              // 设置最大宽度，防止在超宽屏幕上内容过于分散
              constraints: const BoxConstraints(
                maxWidth: 1400, // 合理的最大宽度约束
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16), // 左右边距
              child: NextOutlineScreen(
                novelId: novelId,
                novelTitle: novelTitle,
                onSwitchToWrite: onSwitchToWrite,
                onNavigateToAddModel: onNavigateToAddModel,
                onConfigureModel: onConfigureModel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
