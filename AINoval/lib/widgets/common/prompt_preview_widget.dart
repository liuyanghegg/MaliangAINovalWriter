import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_syntax_view/flutter_syntax_view.dart';
import 'package:ainoval/models/ai_request_models.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/utils/content_formatter.dart';

/// 提示词预览组件
/// 用于显示AI请求的预览内容，使用固定宽度布局，根据内容决定长度
class PromptPreviewWidget extends StatefulWidget {
  const PromptPreviewWidget({
    super.key,
    required this.previewResponse,
    this.onCopyToClipboard,
    this.showActions = true,
    this.fixedWidth = 680.0, // 固定宽度，可以根据需要调整
  });

  /// 预览响应数据
  final UniversalAIPreviewResponse previewResponse;
  
  /// 复制到剪贴板回调
  final VoidCallback? onCopyToClipboard;
  
  /// 是否显示操作按钮
  final bool showActions;
  
  /// 固定宽度
  final double fixedWidth;

  @override
  State<PromptPreviewWidget> createState() => _PromptPreviewWidgetState();
}

class _PromptPreviewWidgetState extends State<PromptPreviewWidget> {
  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    
    return Container(
      width: widget.fixedWidth,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(4), // 最小内边距，紧贴表单边缘
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部统计和操作栏
            _buildHeaderActions(context, isDark),
            
            const SizedBox(height: 8),
            
            // 系统提示词部分
            if (widget.previewResponse.systemPrompt.isNotEmpty) ...[
              _buildPromptSection(
                context: context,
                isDark: isDark,
                title: '系统提示词',
                content: widget.previewResponse.systemPrompt,
                wordCount: widget.previewResponse.systemPromptWordCount,
              ),
              const SizedBox(height: 8),
            ],
            
            // 用户提示词部分
            if (widget.previewResponse.userPrompt.isNotEmpty) ...[
              _buildPromptSection(
                context: context,
                isDark: isDark,
                title: '用户提示词',
                content: widget.previewResponse.userPrompt,
                wordCount: widget.previewResponse.userPromptWordCount,
              ),
              const SizedBox(height: 8),
            ],
            
            // 上下文信息部分（如果有）
            if (widget.previewResponse.context != null && widget.previewResponse.context!.isNotEmpty) ...[
              _buildPromptSection(
                context: context,
                isDark: isDark,
                title: '上下文信息',
                content: widget.previewResponse.context!,
                wordCount: widget.previewResponse.contextWordCount,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建顶部统计和操作栏
  Widget _buildHeaderActions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // 减少内边距
      decoration: BoxDecoration(
        color: isDark ? WebTheme.darkGrey50 : WebTheme.grey50,
        borderRadius: BorderRadius.circular(4), // 减少圆角
        border: Border.all(
          color: isDark ? WebTheme.darkGrey200 : WebTheme.grey200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 预览图标
          Icon(
            Icons.preview_outlined,
            size: 14, // 减少图标大小
            color: WebTheme.getSecondaryTextColor(context),
          ),
          const SizedBox(width: 6),
          
          Text(
            '提示词预览',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: WebTheme.getTextColor(context, isPrimary: true),
              fontWeight: FontWeight.w600,
              fontSize: 13, // 减少字体大小
            ),
          ),
          
          const Spacer(),
          
          // 复制到剪贴板按钮
          if (widget.showActions) ...[
            _buildActionButton(
              context: context,
              isDark: isDark,
              icon: Icons.content_copy_outlined,
              label: '复制',
              onPressed: () => _copyToClipboard(context, widget.previewResponse.preview),
            ),
            const SizedBox(width: 8),
          ],
          
          // 总字数统计
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // 减少内边距
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(3), // 减少圆角
            ),
            child: Text(
              '${widget.previewResponse.totalWordCount} 字',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
                fontSize: 10, // 减少字体大小
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建提示词区块
  Widget _buildPromptSection({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String content,
    required int wordCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 区块标题和操作
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 减少内边距
          decoration: BoxDecoration(
            color: isDark ? WebTheme.darkGrey100 : WebTheme.grey100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4), // 减少圆角
              topRight: Radius.circular(4),
            ),
            border: Border.all(
              color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: WebTheme.getTextColor(context, isPrimary: true),
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // 减少字体大小
                ),
              ),
              
              const Spacer(),
              
              // 字数统计
              Text(
                '$wordCount 字',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WebTheme.getSecondaryTextColor(context),
                  fontSize: 10, // 减少字体大小
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 复制按钮
              _buildActionButton(
                context: context,
                isDark: isDark,
                icon: Icons.content_copy_outlined,
                label: '复制',
                isSmall: true,
                onPressed: () => _copyToClipboard(context, content),
              ),
            ],
          ),
        ),
        
        // 内容区域 - 固定宽度，根据内容决定高度
        _buildContentArea(context, isDark, content),
      ],
    );
  }

  /// 构建内容区域
  Widget _buildContentArea(BuildContext context, bool isDark, String content) {
    // 计算内容行数来决定高度
    final lines = content.split('\n');
    final contentHeight = (lines.length * 18.0) + 16.0; // 每行18px高度 + 减少上下padding
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 50, // 减少最小高度
        maxHeight: contentHeight > 250 ? 250 : contentHeight, // 减少最大高度
      ),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
            width: 1,
          ),
          right: BorderSide(
            color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
            width: 1,
          ),
          bottom: BorderSide(
            color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
            width: 1,
          ),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(4), // 减少圆角
          bottomRight: Radius.circular(4),
        ),
        color: isDark ? WebTheme.darkGrey50 : WebTheme.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 行号区域
          Container(
            width: 35, // 减少宽度
            constraints: BoxConstraints(
              minHeight: 50,
              maxHeight: contentHeight > 250 ? 250 : contentHeight,
            ),
            decoration: BoxDecoration(
              color: isDark ? WebTheme.darkGrey100 : WebTheme.grey50,
              border: Border(
                right: BorderSide(
                  color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
                  width: 1,
                ),
              ),
            ),
            child: _buildLineNumbers(lines),
          ),
          
          // 内容区域
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                minHeight: 50,
                maxHeight: contentHeight > 250 ? 250 : contentHeight,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8), // 减少内边距
                child: SelectableText(
                  content,
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 12, // 减少字体大小
                    height: 1.4, // 调整行高
                    color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
                    letterSpacing: 0.1, // 减少字符间距
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建行号
  Widget _buildLineNumbers(List<String> lines) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8), // 减少内边距
      child: Column(
        children: List.generate(lines.length, (index) {
          return Container(
            height: 16.8, // 匹配调整后的文本行高 (12 * 1.4)
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 9, // 减少字体大小
                color: WebTheme.getSecondaryTextColor(context),
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isSmall = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(3), // 减少圆角
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 4 : 6, // 减少内边距
            vertical: isSmall ? 2 : 3,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? WebTheme.darkGrey400 : WebTheme.grey400,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(3), // 减少圆角
            color: isDark ? WebTheme.darkGrey100 : WebTheme.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isSmall ? 10 : 12, // 减少图标大小
                color: WebTheme.getSecondaryTextColor(context),
              ),
              if (!isSmall) ...[
                const SizedBox(width: 3),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WebTheme.getSecondaryTextColor(context),
                    fontSize: 10, // 减少字体大小
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 复制到剪贴板
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已复制到剪贴板'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// 提示词预览加载组件
/// 用于显示加载状态，加载图标位于中央
class PromptPreviewLoadingWidget extends StatelessWidget {
  const PromptPreviewLoadingWidget({
    super.key,
    this.message = '正在生成预览...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// 提示词预览对话框
/// 独立的对话框版本，可以单独使用
class PromptPreviewDialog extends StatelessWidget {
  const PromptPreviewDialog({
    super.key,
    required this.previewResponse,
    this.onGenerate,
  });

  final UniversalAIPreviewResponse previewResponse;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.preview_outlined),
          const SizedBox(width: 8),
          const Text('提示词预览'),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 600,
        child: PromptPreviewWidget(
          previewResponse: previewResponse,
          showActions: true,
          fixedWidth: 680,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        if (onGenerate != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onGenerate!();
            },
            child: const Text('生成'),
          ),
      ],
    );
  }
}

/// 显示提示词预览对话框的便捷函数
Future<void> showPromptPreviewDialog(
  BuildContext context, {
  required UniversalAIPreviewResponse previewResponse,
  VoidCallback? onGenerate,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => PromptPreviewDialog(
      previewResponse: previewResponse,
      onGenerate: onGenerate,
    ),
  );
} 