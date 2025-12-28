import 'package:flutter/material.dart';

import '../../../models/prompt_models.dart';
import '../../../utils/logger.dart';

/// 模板审核对话框
class TemplateReviewDialog extends StatefulWidget {
  final EnhancedUserPromptTemplate template;
  final Function(bool approved, String? comment) onReview;

  const TemplateReviewDialog({
    Key? key,
    required this.template,
    required this.onReview,
  }) : super(key: key);

  @override
  State<TemplateReviewDialog> createState() => _TemplateReviewDialogState();
}

class _TemplateReviewDialogState extends State<TemplateReviewDialog> {
  final _reviewCommentController = TextEditingController();
  
  String _reviewAction = 'approve'; // 'approve', 'reject'
  bool _setAsVerified = false;
  bool _isLoading = false;

  static const Map<String, String> _actionLabels = {
    'approve': '通过审核',
    'reject': '拒绝',
  };

  static const Map<String, Color> _actionColors = {
    'approve': Colors.green,
    'reject': Colors.red,
  };

  @override
  void dispose() {
    _reviewCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTemplateInfo(),
                    const SizedBox(height: 24),
                    _buildTemplateContent(),
                    const SizedBox(height: 24),
                    _buildReviewSection(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.rate_review, size: 24),
        const SizedBox(width: 8),
        const Text(
          '模板审核',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        _buildStatusChip(),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    String status;
    Color color;
    
    if (widget.template.isVerified == true) {
      status = '已认证';
      color = Colors.green;
    } else if (widget.template.isPublic == true) {
      status = '已发布';
      color = Colors.blue;
    } else {
      status = '待审核';
      color = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTemplateInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 20),
              const SizedBox(width: 8),
              const Text(
                '模板信息',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 基本信息
          _buildInfoRow('模板名称', widget.template.name),
          if (widget.template.description?.isNotEmpty == true)
            _buildInfoRow('描述', widget.template.description!),
          _buildInfoRow('功能类型', _getFeatureTypeLabel(widget.template.featureType.toApiString())),
          if (widget.template.authorId?.isNotEmpty == true)
            _buildInfoRow('作者', widget.template.authorId!),
          _buildInfoRow('版本', (widget.template.version ?? 1).toString()),
          _buildInfoRow('语言', widget.template.language ?? 'zh'),
          _buildInfoRow('创建时间', _formatDateTime(widget.template.createdAt)),
          _buildInfoRow('使用次数', '${widget.template.usageCount} 次'),
          _buildInfoRow('收藏次数', '${widget.template.favoriteCount ?? 0} 次'),
          if (widget.template.rating > 0)
            _buildInfoRow('评分', widget.template.rating.toStringAsFixed(1)),
          
          // 标签
          if (widget.template.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '标签：',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.template.tags.map((tag) => 
                      _buildTag(tag)).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label：',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTemplateContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '模板内容',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.template.systemPrompt.isNotEmpty) ...[
                Text(
                  '系统提示词：',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    widget.template.systemPrompt,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.template.userPrompt.isNotEmpty) ...[
                Text(
                  '用户提示词：',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    widget.template.userPrompt,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '审核操作',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // 审核动作选择
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '审核结果：',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              
              Column(
                children: _actionLabels.entries.map((entry) {
                  return RadioListTile<String>(
                    title: Text(
                      entry.value,
                      style: TextStyle(
                        color: _actionColors[entry.key],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: entry.key,
                    groupValue: _reviewAction,
                    onChanged: (value) {
                      setState(() {
                        _reviewAction = value!;
                      });
                    },
                  );
                }).toList(),
              ),
              
              if (_reviewAction == 'approve') ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('同时设为认证模板'),
                  subtitle: const Text('为该模板添加官方认证标识'),
                  value: _setAsVerified,
                  onChanged: (value) {
                    setState(() {
                      _setAsVerified = value ?? false;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 审核评论
        TextFormField(
          controller: _reviewCommentController,
          decoration: InputDecoration(
            labelText: '审核备注',
            hintText: _getCommentHint(),
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  String _getCommentHint() {
    switch (_reviewAction) {
      case 'approve':
        return '可以添加通过审核的说明（可选）';
      case 'reject':
        return '请说明拒绝的原因';
      case 'request_changes':
        return '请详细说明需要修改的内容';
      default:
        return '请输入审核备注';
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: _actionColors[_reviewAction],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_actionLabels[_reviewAction]!),
        ),
      ],
    );
  }

  Future<void> _submitReview() async {
    if (_reviewAction == 'reject') {
      if (_reviewCommentController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('拒绝审核时请填写审核备注')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reviewComment = _reviewCommentController.text.trim();
      final approved = _reviewAction == 'approve';
      
      await widget.onReview(approved, reviewComment.isEmpty ? null : reviewComment);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      AppLogger.e('TemplateReviewDialog', '提交模板审核失败', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e')),
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

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}