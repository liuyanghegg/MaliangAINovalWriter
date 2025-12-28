import 'package:flutter/material.dart';

import '../../../services/api_service/repositories/impl/admin_repository_impl.dart';
import '../../../utils/logger.dart';
import '../../../widgets/common/loading_indicator.dart';

/// 模板统计对话框
class TemplateStatisticsDialog extends StatefulWidget {
  const TemplateStatisticsDialog({Key? key}) : super(key: key);

  @override
  State<TemplateStatisticsDialog> createState() => _TemplateStatisticsDialogState();
}

class _TemplateStatisticsDialogState extends State<TemplateStatisticsDialog> {
  final AdminRepositoryImpl _adminRepository = AdminRepositoryImpl();
  
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: _buildContent(),
            ),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.analytics, size: 24),
        const SizedBox(width: 8),
        const Text(
          '模板统计',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStatistics,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_statistics == null) {
      return const Center(
        child: Text('暂无统计数据'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewSection(),
          const SizedBox(height: 24),
          _buildCategorySection(),
          const SizedBox(height: 24),
          _buildStatusSection(),
          const SizedBox(height: 24),
          _buildTopTemplatesSection(),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    final overview = _statistics!['overview'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '总览',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildStatCard('总模板数', '${overview['totalTemplates'] ?? 0}', Icons.article, Colors.blue),
            _buildStatCard('官方模板', '${overview['officialTemplates'] ?? 0}', Icons.verified, Colors.green),
            _buildStatCard('用户模板', '${overview['userTemplates'] ?? 0}', Icons.person, Colors.orange),
            _buildStatCard('已发布', '${overview['publishedTemplates'] ?? 0}', Icons.public, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = _statistics!['byCategory'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '按功能类型分布',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        ...categories.entries.map((entry) {
          final label = _getFeatureTypeLabel(entry.key);
          final count = entry.value as int;
          return _buildProgressItem(label, count, _getMaxCount(categories));
        }).toList(),
      ],
    );
  }

  Widget _buildStatusSection() {
    final status = _statistics!['byStatus'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '按状态分布',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        ...status.entries.map((entry) {
          final label = _getStatusLabel(entry.key);
          final count = entry.value as int;
          final color = _getStatusColor(entry.key);
          return _buildProgressItem(label, count, _getMaxCount(status), color);
        }).toList(),
      ],
    );
  }

  Widget _buildProgressItem(String label, int count, int maxCount, [Color? color]) {
    final progress = maxCount > 0 ? count / maxCount : 0.0;
    final itemColor = color ?? Theme.of(context).colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: itemColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: itemColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(itemColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTemplatesSection() {
    final topTemplates = _statistics!['topTemplates'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '热门模板 Top 5',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        if (topTemplates.isEmpty)
          const Text('暂无数据')
        else
          ...topTemplates.asMap().entries.map((entry) {
            final index = entry.key;
            final template = entry.value as Map<String, dynamic>;
            return _buildTopTemplateItem(
              index + 1,
              template['templateName'] as String,
              template['useCount'] as int,
              template['averageRating'] as double?,
            );
          }).toList(),
      ],
    );
  }

  Widget _buildTopTemplateItem(int rank, String name, int useCount, double? rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '使用 $useCount 次',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (rating != null && rating > 0) ...[
            const SizedBox(width: 8),
            Icon(Icons.star, size: 16, color: Colors.amber),
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: _loadStatistics,
          icon: const Icon(Icons.refresh),
          label: const Text('刷新'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final statistics = await _adminRepository.getTemplateStatistics();
      setState(() {
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('TemplateStatisticsDialog', '加载模板统计失败', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  int _getMaxCount(Map<String, dynamic> data) {
    if (data.isEmpty) return 1;
    return data.values.cast<int>().reduce((a, b) => a > b ? a : b);
  }

  String _getFeatureTypeLabel(String featureType) {
    switch (featureType) {
      case 'CHAT':
        return 'AI聊天';
      case 'SCENE_GENERATION':
        return '场景生成';
      case 'CONTINUATION':
        return '续写';
      case 'SUMMARY':
        return '总结';
      case 'OUTLINE':
        return '大纲';
      default:
        return featureType;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PUBLISHED':
        return '已发布';
      case 'PENDING':
        return '待审核';
      case 'REJECTED':
        return '已拒绝';
      case 'VERIFIED':
        return '已认证';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PUBLISHED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      case 'VERIFIED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.orange[300]!;
      default:
        return Colors.blue;
    }
  }
}