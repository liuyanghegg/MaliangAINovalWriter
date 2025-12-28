import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/prompt_models.dart';
import '../../../utils/web_theme.dart';
import '../../../widgets/common/dialog_container.dart';
import '../../../widgets/common/dialog_header.dart';

/// 模板详情查看对话框
class TemplateDetailsDialog extends StatefulWidget {
  final EnhancedUserPromptTemplate template;
  final Map<String, Object>? statistics;

  const TemplateDetailsDialog({
    Key? key,
    required this.template,
    this.statistics,
  }) : super(key: key);

  @override
  State<TemplateDetailsDialog> createState() => _TemplateDetailsDialogState();
}

class _TemplateDetailsDialogState extends State<TemplateDetailsDialog> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogContainer(
      maxWidth: 900,
      height: 700,
      child: Column(
        children: [
          DialogHeader(
            title: '模板详情 - ${widget.template.name}',
            onClose: () => Navigator.of(context).pop(),
          ),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfoTab(),
                _buildContentTab(),
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: WebTheme.getBorderColor(context),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: WebTheme.getTextColor(context),
        unselectedLabelColor: WebTheme.getTextColor(context).withOpacity(0.6),
        indicatorColor: WebTheme.getPrimaryColor(context),
        tabs: const [
          Tab(
            icon: Icon(Icons.info),
            text: '基础信息',
          ),
          Tab(
            icon: Icon(Icons.code),
            text: '提示词内容',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: '统计信息',
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(),
          const SizedBox(height: 24),
          _buildStatusSection(),
          const SizedBox(height: 24),
          _buildTagsSection(),
          const SizedBox(height: 24),
          _buildMetadataSection(),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, size: 20),
                const SizedBox(width: 8),
                Text(
                  '基本信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('模板名称', widget.template.name),
            _buildInfoRow('模板ID', widget.template.id),
            _buildInfoRow('功能类型', _getFeatureTypeLabel(widget.template.featureType.toApiString())),
            _buildInfoRow('语言', _getLanguageLabel(widget.template.language)),
            _buildInfoRow('版本', (widget.template.version ?? 1).toString()),
            if (widget.template.description?.isNotEmpty == true)
              _buildInfoRow('描述', widget.template.description!, maxLines: 3),
            _buildInfoRow('作者ID', widget.template.authorId ?? '未知'),
            _buildInfoRow('创建时间', _formatDateTime(widget.template.createdAt)),
            _buildInfoRow('更新时间', _formatDateTime(widget.template.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, size: 20),
                const SizedBox(width: 8),
                Text(
                  '状态信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatusChip(
                  label: '公开状态',
                  value: widget.template.isPublic == true ? '已发布' : '私有',
                  color: widget.template.isPublic == true ? Colors.green : Colors.grey,
                ),
                _buildStatusChip(
                  label: '认证状态',
                  value: widget.template.isVerified == true ? '已认证' : '未认证',
                  color: widget.template.isVerified == true ? Colors.blue : Colors.grey,
                ),
                _buildStatusChip(
                  label: '评分',
                  value: widget.template.rating > 0 ? widget.template.rating.toStringAsFixed(1) : '无评分',
                  color: _getRatingColor(widget.template.rating),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    if (widget.template.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.label, size: 20),
                const SizedBox(width: 8),
                Text(
                  '标签',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.template.tags.map((tag) => _buildTag(tag)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.data_object, size: 20),
                const SizedBox(width: 8),
                Text(
                  '元数据',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('使用次数', widget.template.usageCount.toString()),
            _buildInfoRow('收藏次数', (widget.template.favoriteCount ?? 0).toString()),
            if (widget.template.reviewedAt != null)
              _buildInfoRow('审核时间', _formatDateTime(widget.template.reviewedAt)),
            if (widget.template.reviewedBy?.isNotEmpty == true)
              _buildInfoRow('审核人', widget.template.reviewedBy!),
            if (widget.template.reviewComment?.isNotEmpty == true)
              _buildInfoRow('审核备注', widget.template.reviewComment!, maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 系统提示词部分
          _buildPromptSection(
            title: '系统提示词 (System Prompt)',
            content: widget.template.systemPrompt.isNotEmpty 
                ? widget.template.systemPrompt 
                : '未设置系统提示词',
            icon: Icons.settings,
            isEmpty: widget.template.systemPrompt.isEmpty,
          ),
          const SizedBox(height: 24),
          
          // 用户提示词部分
          _buildPromptSection(
            title: '用户提示词 (User Prompt)',
            content: widget.template.userPrompt.isNotEmpty 
                ? widget.template.userPrompt 
                : '未设置用户提示词',
            icon: Icons.person,
            isEmpty: widget.template.userPrompt.isEmpty,
          ),
          
          const SizedBox(height: 24),
          
          // 占位符提示
          _buildPlaceholderInfo(),
        ],
      ),
    );
  }

  Widget _buildPromptSection({
    required String title,
    required String content,
    required IconData icon,
    bool isEmpty = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
                const Spacer(),
                if (!isEmpty)
                  IconButton(
                    onPressed: () => _copyToClipboard(content),
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: '复制到剪贴板',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isEmpty 
                    ? Colors.grey.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isEmpty 
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: SelectableText(
                content,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.4,
                  color: isEmpty 
                      ? WebTheme.getSecondaryTextColor(context)
                      : WebTheme.getTextColor(context),
                  fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建占位符信息
  Widget _buildPlaceholderInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.code, size: 20),
                const SizedBox(width: 8),
                Text(
                  '占位符说明',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '提示词中可以使用占位符来动态插入内容，常用占位符包括：',
              style: TextStyle(
                fontSize: 14,
                color: WebTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 12),
            _buildPlaceholderExample('{content}', '要处理的主要内容'),
            _buildPlaceholderExample('{context}', '上下文信息'),
            _buildPlaceholderExample('{requirement}', '具体要求'),
            _buildPlaceholderExample('{style}', '风格要求'),
            _buildPlaceholderExample('{length}', '长度要求'),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderExample(String placeholder, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: WebTheme.getPrimaryColor(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: WebTheme.getPrimaryColor(context).withOpacity(0.3),
              ),
            ),
            child: Text(
              placeholder,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: WebTheme.getPrimaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final stats = widget.statistics ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard('使用统计', [
            _buildStatRow('总使用次数', stats['usageCount']?.toString() ?? '0'),
            _buildStatRow('本月使用', stats['monthlyUsage']?.toString() ?? '0'),
            _buildStatRow('本周使用', stats['weeklyUsage']?.toString() ?? '0'),
            _buildStatRow('今日使用', stats['dailyUsage']?.toString() ?? '0'),
          ], Icons.play_arrow),
          const SizedBox(height: 24),
          _buildStatsCard('用户反馈', [
            _buildStatRow('收藏次数', stats['favoriteCount']?.toString() ?? '0'),
            _buildStatRow('平均评分', stats['averageRating']?.toString() ?? '0.0'),
            _buildStatRow('评分人数', stats['ratingCount']?.toString() ?? '0'),
            _buildStatRow('反馈次数', stats['feedbackCount']?.toString() ?? '0'),
          ], Icons.favorite),
          const SizedBox(height: 24),
          _buildStatsCard('性能数据', [
            _buildStatRow('平均响应时间', '${stats['averageResponseTime'] ?? 0}ms'),
            _buildStatRow('成功率', '${stats['successRate'] ?? 100}%'),
            _buildStatRow('错误次数', stats['errorCount']?.toString() ?? '0'),
            _buildStatRow('最后使用时间', _formatDateTime(stats['lastUsedAt'] as DateTime?)),
          ], Icons.speed),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, List<Widget> children, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: WebTheme.getTextColor(context).withOpacity(0.8),
              ),
              maxLines: maxLines,
              overflow: maxLines > 1 ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: WebTheme.getPrimaryColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WebTheme.getPrimaryColor(context).withOpacity(0.3),
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 13,
          color: WebTheme.getPrimaryColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
        return featureType ?? '未知类型';
    }
  }

  String _getLanguageLabel(String? language) {
    switch (language) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return language ?? '中文';
    }
  }

  Color _getRatingColor(double? rating) {
    if (rating == null) return WebTheme.getSecondaryTextColor(context);
    if (rating >= 4.5) return WebTheme.success;
    if (rating >= 3.5) return WebTheme.warning;
    if (rating >= 2.0) return WebTheme.error;
    return WebTheme.getSecondaryTextColor(context);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未设置';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}