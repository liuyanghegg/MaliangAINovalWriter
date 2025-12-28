import 'package:flutter/material.dart';
import 'package:ainoval/models/analytics_data.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:intl/intl.dart';

class TokenUsageList extends StatelessWidget {
  final List<TokenUsageRecord> records;
  final Map<String, dynamic>? todaySummary;

  const TokenUsageList({
    super.key,
    required this.records,
    this.todaySummary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSummaryStats(),
        const SizedBox(height: 24),
        _buildRecordsList(context),
      ],
    );
  }

  Widget _buildSummaryStats() {
    // 从records数据中计算统计，不依赖后端汇总接口
    final stats = _calculateStats();
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: stats['isToday'] ? '今日调用次数' : '最近调用次数',
            value: stats['totalRecords'].toString(),
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: stats['isToday'] ? '今日 Token 消耗' : '最近 Token 消耗',
            value: _formatNumber(stats['totalTokens']),
            color: const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: stats['isToday'] ? '今日成本' : '最近成本',
            value: '\$${stats['totalCost'].toStringAsFixed(4)}',
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WebTheme.getCardColor(context).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: WebTheme.getBorderColor(context).withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: WebTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Token 使用记录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: WebTheme.getTextColor(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: WebTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: WebTheme.getBorderColor(context).withOpacity(0.5),
                ),
              ),
              child: Text(
                '最近 ${records.length} 条记录',
                style: TextStyle(
                  fontSize: 12,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _buildRecordItem(context, records[index]),
        ),
      ],
    );
  }

  Widget _buildRecordItem(BuildContext context, TokenUsageRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.getCardColor(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WebTheme.getBorderColor(context).withOpacity(0.5),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildFeatureAvatar(context, record.taskType),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRecordContent(context, record),
            ),
            const SizedBox(width: 16),
            _buildTokenStats(context, record),
          ],
        ),
      ),
    );
  }

  /// 构建功能类型头像，使用图标替代文字
  Widget _buildFeatureAvatar(BuildContext context, String taskType) {
    final color = _getFeatureTypeColor(taskType);
    final icon = _getFeatureTypeIcon(taskType);
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildRecordContent(BuildContext context, TokenUsageRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              record.taskType,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: WebTheme.getTextColor(context),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: WebTheme.getBorderColor(context),
                ),
              ),
              child: Text(
                record.model,
                style: TextStyle(
                  fontSize: 12,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 12,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(width: 4),
            Text(
              _formatDateTime(record.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTokenStats(BuildContext context, TokenUsageRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTokenStatItem(
              context: context,
              icon: Icons.unfold_more, // Text Expansion 风格，代表输入
              value: record.inputTokens,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 16),
            _buildTokenStatItem(
              context: context,
              icon: Icons.notes, // Text Summary 风格，代表输出
              value: record.outputTokens,
              color: const Color(0xFF8B5CF6),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '成本: \$${record.cost.toStringAsFixed(4)}',
          style: TextStyle(
            fontSize: 12,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTokenStatItem({
    required BuildContext context,
    required IconData icon,
    required int value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          _formatNumber(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('MM-dd HH:mm').format(dateTime);
    }
  }

  /// 根据任务类型中文名称获取对应的AI功能图标
  IconData _getFeatureTypeIcon(String taskType) {
    switch (taskType) {
      case '场景摘要':
        return Icons.summarize;
      case '摘要扩写':
        return Icons.expand_more;
      case '文本扩写':
        return Icons.unfold_more;
      case '文本重构':
        return Icons.edit;
      case '文本总结':
        return Icons.notes;
      case 'AI聊天':
        return Icons.chat;
      case '小说生成':
        return Icons.create;
      case '设定编排':
        return Icons.dashboard_customize;
      case '专业续写':
        return Icons.auto_stories;
      case '场景节拍生成':
        return Icons.timeline;
      case '设定树生成':
        return Icons.account_tree;
      case '设定生成':
        return Icons.settings_applications; // 设定生成专用图标
      // 兼容其他功能类型
      case '智能续写':
        return Icons.unfold_more;
      case 'AI对话':
        return Icons.chat;
      case '内容优化':
        return Icons.tune;
      case '语法检查':
        return Icons.spellcheck;
      case '风格改进':
        return Icons.auto_fix_high;
      default:
        return Icons.smart_toy; // 默认AI图标
    }
  }

  /// 根据任务类型中文名称获取对应的颜色
  Color _getFeatureTypeColor(String taskType) {
    switch (taskType) {
      case '场景摘要':
        return const Color(0xFF3B82F6); // 蓝色
      case '摘要扩写':
        return const Color(0xFF8B5CF6); // 紫色
      case '文本扩写':
        return const Color(0xFF10B981); // 绿色
      case '文本重构':
        return const Color(0xFFF59E0B); // 黄色
      case '文本总结':
        return const Color(0xFFEF4444); // 红色
      case 'AI聊天':
        return const Color(0xFF06B6D4); // 青色
      case '小说生成':
        return const Color(0xFF8B5CF6); // 紫色
      case '设定编排':
        return const Color(0xFF059669); // 深绿色
      case '专业续写':
        return const Color(0xFFDC2626); // 深红色
      case '场景节拍生成':
        return const Color(0xFF7C3AED); // 深紫色
      case '设定树生成':
        return const Color(0xFF0891B2); // 深青色
      case '设定生成':
        return const Color(0xFF6366F1); // 靛蓝色
      // 兼容其他功能类型
      case '智能续写':
        return const Color(0xFF10B981); // 绿色
      case 'AI对话':
        return const Color(0xFF06B6D4); // 青色
      case '内容优化':
        return const Color(0xFF8B5CF6); // 紫色
      case '语法检查':
        return const Color(0xFFF59E0B); // 黄色
      case '风格改进':
        return const Color(0xFFEF4444); // 红色
      default:
        return const Color(0xFF6B7280); // 灰色
    }
  }

  /// 从records数据中计算统计，不依赖后端汇总接口
  Map<String, dynamic> _calculateStats() {
    // 如果没有记录数据，返回空统计
    if (records.isEmpty) {
      return {
        'totalRecords': 0,
        'totalTokens': 0,
        'totalCost': 0.0,
        'isToday': false,
      };
    }
    
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    
    // 筛选今日的记录
    final todayRecords = records.where((record) {
      final recordDate = DateTime(record.timestamp.year, record.timestamp.month, record.timestamp.day);
      return recordDate.isAtSameMomentAs(todayDate);
    }).toList();
    
    // 如果有今日记录，返回今日统计
    if (todayRecords.isNotEmpty) {
      int totalRecords = todayRecords.length;
      int totalTokens = todayRecords.fold(0, (sum, record) => sum + record.totalTokens);
      double totalCost = todayRecords.fold(0.0, (sum, record) => sum + record.cost);
      
      return {
        'totalRecords': totalRecords,
        'totalTokens': totalTokens,
        'totalCost': totalCost,
        'isToday': true,
      };
    }
    
    // 没有今日记录，使用所有可见记录的统计
    int totalRecords = records.length;
    int totalTokens = records.fold(0, (sum, record) => sum + record.totalTokens);
    double totalCost = records.fold(0.0, (sum, record) => sum + record.cost);
    
    return {
      'totalRecords': totalRecords,
      'totalTokens': totalTokens,
      'totalCost': totalCost,
      'isToday': false,
    };
  }
}
