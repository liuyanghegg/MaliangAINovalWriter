import 'package:flutter/material.dart';

import '../../../models/prompt_models.dart';
import '../../../utils/web_theme.dart';
import '../../../widgets/common/dialog_container.dart';
import '../../../widgets/common/dialog_header.dart';

/// 批量操作确认对话框
class BatchOperationDialog extends StatefulWidget {
  final String operation;
  final String title;
  final String description;
  final List<EnhancedUserPromptTemplate> templates;
  final Function(String? comment) onConfirm;
  final Color? actionColor;
  final bool requiresComment;
  final String? commentHint;

  const BatchOperationDialog({
    Key? key,
    required this.operation,
    required this.title,
    required this.description,
    required this.templates,
    required this.onConfirm,
    this.actionColor,
    this.requiresComment = false,
    this.commentHint,
  }) : super(key: key);

  @override
  State<BatchOperationDialog> createState() => _BatchOperationDialogState();
}

class _BatchOperationDialogState extends State<BatchOperationDialog> {
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DialogHeader(
            title: widget.title,
            onClose: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningSection(),
                  const SizedBox(height: 24),
                  _buildTemplatesList(),
                  if (widget.requiresComment || widget.commentHint != null) ...[
                    const SizedBox(height: 24),
                    _buildCommentSection(),
                  ],
                ],
              ),
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildWarningSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (widget.actionColor ?? Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (widget.actionColor ?? Colors.orange).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: widget.actionColor ?? Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '批量操作确认',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.actionColor ?? Colors.orange,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  style: TextStyle(
                    color: WebTheme.getTextColor(context).withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.list, size: 20),
            const SizedBox(width: 8),
            Text(
              '影响的模板 (${widget.templates.length} 个)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: WebTheme.getTextColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: widget.templates.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final template = widget.templates[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: WebTheme.getPrimaryColor(context).withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      color: WebTheme.getPrimaryColor(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  template.name,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  _getFeatureTypeLabel(template.featureType.toApiString()),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: _buildTemplateStatusBadge(template),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateStatusBadge(EnhancedUserPromptTemplate template) {
    String status;
    Color color;
    
    if (template.isVerified) {
      status = '认证';
      color = Colors.green;
    } else if (template.isPublic) {
      status = '公开';
      color = Colors.blue;
    } else {
      status = '私有';
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.comment, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.requiresComment ? '操作备注 *' : '操作备注（可选）',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: WebTheme.getTextColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: widget.commentHint ?? '请输入操作备注...',
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
        if (widget.requiresComment)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '* 此操作需要填写备注信息',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.withOpacity(0.7),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebTheme.getCardColor(context),
        border: Border(
          top: BorderSide(
            color: WebTheme.getBorderColor(context),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.actionColor ?? WebTheme.getPrimaryColor(context),
              foregroundColor: WebTheme.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('确认${widget.operation}'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirm() async {
    // 检查是否需要备注且未填写
    if (widget.requiresComment && _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写操作备注')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final comment = _commentController.text.trim();
      await widget.onConfirm(comment.isNotEmpty ? comment : null);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFeatureTypeLabel(String? featureType) {
    switch (featureType) {
      case 'AI_CHAT':
        return 'AI聊天';
      case 'TEXT_EXPANSION':
        return '文本扩写';
      case 'TEXT_REFACTOR':
        return '文本润色';
      case 'TEXT_SUMMARY':
        return '文本总结';
      case 'SCENE_TO_SUMMARY':
        return '场景转摘要';
      case 'SUMMARY_TO_SCENE':
        return '摘要转场景';
      case 'NOVEL_GENERATION':
        return '小说生成';
      case 'PROFESSIONAL_FICTION_CONTINUATION':
        return '专业续写';
      case 'SCENE_BEAT_GENERATION':
        return '场景节拍生成';
      default:
        return featureType ?? '未知';
    }
  }
}

/// 批量操作类型枚举
enum BatchOperationType {
  review,
  verify,
  publish,
  delete,
  export,
}

/// 批量操作配置
class BatchOperationConfig {
  final BatchOperationType type;
  final String title;
  final String description;
  final Color actionColor;
  final bool requiresComment;
  final String? commentHint;

  const BatchOperationConfig({
    required this.type,
    required this.title,
    required this.description,
    required this.actionColor,
    this.requiresComment = false,
    this.commentHint,
  });

  static const Map<BatchOperationType, BatchOperationConfig> configs = {
    BatchOperationType.review: BatchOperationConfig(
      type: BatchOperationType.review,
      title: '批量审核',
      description: '您即将批量审核选中的模板。审核通过的模板将被发布为公共模板。',
      actionColor: Colors.green,
      requiresComment: false,
      commentHint: '可以添加审核意见（可选）',
    ),
    BatchOperationType.verify: BatchOperationConfig(
      type: BatchOperationType.verify,
      title: '批量认证',
      description: '您即将为选中的模板添加官方认证标识。认证后的模板将显示认证徽章。',
      actionColor: Colors.blue,
    ),
    BatchOperationType.publish: BatchOperationConfig(
      type: BatchOperationType.publish,
      title: '批量发布',
      description: '您即将批量发布选中的模板。发布后的模板将对所有用户可见。',
      actionColor: Colors.indigo,
    ),
    BatchOperationType.delete: BatchOperationConfig(
      type: BatchOperationType.delete,
      title: '批量删除',
      description: '您即将永久删除选中的模板。此操作不可撤销，请谨慎操作！',
      actionColor: Colors.red,
      requiresComment: true,
      commentHint: '请说明删除原因',
    ),
    BatchOperationType.export: BatchOperationConfig(
      type: BatchOperationType.export,
      title: '批量导出',
      description: '您即将导出选中的模板数据。导出的数据可用于备份或迁移。',
      actionColor: Colors.orange,
    ),
  };
}