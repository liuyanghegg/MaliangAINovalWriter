import 'package:flutter/material.dart';
import 'package:ainoval/models/analytics_data.dart';
import 'package:ainoval/services/api_service/repositories/impl/analytics_repository_impl.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/analytics/analytics_card.dart';
import 'package:ainoval/widgets/analytics/token_usage_chart.dart';
import 'package:ainoval/widgets/analytics/function_usage_chart.dart';
import 'package:ainoval/widgets/analytics/model_usage_chart.dart';
import 'package:ainoval/widgets/analytics/token_usage_list.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final _analyticsRepo = AnalyticsRepositoryImpl();
  
  bool _loading = true;
  AnalyticsData? _overviewData;
  List<TokenUsageData> _tokenData = [];
  List<FunctionUsageData> _functionData = [];
  List<ModelUsageData> _modelData = [];
  List<TokenUsageRecord> _recordData = [];
  Map<String, dynamic>? _todaySummary;

  AnalyticsViewMode _tokenViewMode = AnalyticsViewMode.daily;
  AnalyticsViewMode _functionViewMode = AnalyticsViewMode.daily;
  AnalyticsViewMode _modelViewMode = AnalyticsViewMode.daily;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      final results = await Future.wait([
        _analyticsRepo.getAnalyticsOverview(),
        _analyticsRepo.getTokenUsageTrend(viewMode: _tokenViewMode),
        _analyticsRepo.getFunctionUsageStats(viewMode: _functionViewMode),
        _analyticsRepo.getModelUsageStats(viewMode: _modelViewMode),
        _analyticsRepo.getTokenUsageRecords(limit: 50), // 增加记录数量，确保包含今日数据
      ]);

      if (!mounted) return;

      setState(() {
        _overviewData = results[0] as AnalyticsData;
        _tokenData = results[1] as List<TokenUsageData>;
        _functionData = results[2] as List<FunctionUsageData>;
        _modelData = results[3] as List<ModelUsageData>;
        _recordData = results[4] as List<TokenUsageRecord>;
        _todaySummary = null; // 不再使用后端汇总数据，前端自己计算
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        TopToast.error(context, '加载数据失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: WebTheme.getBackgroundColor(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOverviewCards(),
              const SizedBox(height: 32),
              _buildTokenUsageChart(),
              const SizedBox(height: 32),
              _buildChartsSection(),
              const SizedBox(height: 32),
              _buildTokenUsageList(),
              const SizedBox(height: 32),
              _buildInsightsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    if (_overviewData == null) return const SizedBox.shrink();
    
    final crossAxisCount = _getColumnCount();
    // 使用固定项高度，避免固定纵横比在不同宽度下导致轻微内容溢出
    final double itemMainAxisExtent = crossAxisCount >= 4
        ? 180
        : (crossAxisCount == 2 ? 200 : 220);

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: itemMainAxisExtent,
      ),
      children: [
        AnalyticsOverviewCard(
          title: '总字数',
          value: _formatLargeNumber(_overviewData!.totalWords),
          changeValue: 15.2,
          isUpTrend: true,
          icon: Icons.article,
          subtitle: '本月新增 ${_formatNumber(_overviewData!.monthlyNewWords)} 字',
        ),
        AnalyticsOverviewCard(
          title: 'Token 消耗',
          value: _formatLargeNumber(_overviewData!.totalTokens),
          changeValue: 23.8,
          isUpTrend: true,
          icon: Icons.flash_on,
          subtitle: '本月新增 ${_formatNumber(_overviewData!.monthlyNewTokens)} tokens',
        ),
        AnalyticsOverviewCard(
          title: '功能使用次数',
          value: _formatLargeNumber(_overviewData!.functionUsageCount),
          changeValue: 12.5,
          isUpTrend: true,
          icon: Icons.trending_up,
          subtitle: '${_overviewData!.mostPopularFunction}最受欢迎',
        ),
        AnalyticsOverviewCard(
          title: '写作天数',
          value: _overviewData!.writingDays.toString(),
          changeValue: 12.8,
          isUpTrend: true,
          icon: Icons.calendar_today,
          subtitle: '连续写作 ${_overviewData!.consecutiveDays} 天',
        ),
      ],
    );
  }

  Widget _buildTokenUsageChart() {
    return AnalyticsCard(
      title: '',
      value: '',
      child: TokenUsageChart(
        data: _tokenData,
        viewMode: _tokenViewMode,
        onViewModeChanged: (mode) {
          setState(() => _tokenViewMode = mode);
          _loadTokenData();
        },
        dateRange: _dateRange,
        onDateRangeChanged: (range) {
          setState(() => _dateRange = range);
          if (_tokenViewMode == AnalyticsViewMode.range) {
            _loadTokenData();
          }
        },
      ),
    );
  }

  Widget _buildChartsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AnalyticsCard(
            title: '功能使用统计',
            value: '',
            child: FunctionUsageChart(
              data: _functionData,
              viewMode: _functionViewMode,
              onViewModeChanged: (mode) {
                setState(() => _functionViewMode = mode);
                _loadFunctionData();
              },
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: AnalyticsCard(
            title: '大模型占比情况',
            value: '',
            child: ModelUsageChart(
              data: _modelData,
              viewMode: _modelViewMode,
              onViewModeChanged: (mode) {
                setState(() => _modelViewMode = mode);
                _loadModelData();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokenUsageList() {
    return AnalyticsCard(
      title: '',
      value: '',
      child: TokenUsageList(
        records: _recordData,
        todaySummary: _todaySummary,
      ),
    );
  }

  Widget _buildInsightsSection() {
    final width = MediaQuery.of(context).size.width;
    final insightsCrossAxisCount = width > 1200 ? 3 : (width > 800 ? 2 : 1);

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: insightsCrossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        // 固定每项高度，避免纵横比导致的轻微溢出
        mainAxisExtent: 190,
      ),
      children: [
        AnalyticsInsightCard(
          icon: Icons.trending_up,
          title: '效率提升',
          description: '智能续写功能使用率上升 15%，用户写作效率显著提升',
          iconColor: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).primaryColor,
        ),
        AnalyticsInsightCard(
          icon: Icons.article,
          title: '内容质量',
          description: '语法检查和风格优化功能显著提升了内容整体质量',
          iconColor: const Color(0xFF8B5CF6),
          backgroundColor: const Color(0xFF8B5CF6),
        ),
        AnalyticsInsightCard(
          icon: Icons.flash_on,
          title: '用户活跃',
          description: '用户日均使用时长增加 28%，平台粘性持续增强',
          iconColor: const Color(0xFF10B981),
          backgroundColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  int _getColumnCount() {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 2;
    return 1;
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  String _formatLargeNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return _formatNumber(number);
  }

  Future<void> _loadTokenData() async {
    final data = await _analyticsRepo.getTokenUsageTrend(
      viewMode: _tokenViewMode,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
    if (mounted) {
      setState(() => _tokenData = data);
    }
  }

  Future<void> _loadFunctionData() async {
    final data = await _analyticsRepo.getFunctionUsageStats(
      viewMode: _functionViewMode,
    );
    if (mounted) {
      setState(() => _functionData = data);
    }
  }

  Future<void> _loadModelData() async {
    final data = await _analyticsRepo.getModelUsageStats(
      viewMode: _modelViewMode,
    );
    if (mounted) {
      setState(() => _modelData = data);
    }
  }
}


