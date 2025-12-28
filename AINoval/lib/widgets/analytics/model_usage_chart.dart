import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ainoval/models/analytics_data.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/analytics/date_range_picker.dart';

class ModelUsageChart extends StatefulWidget {
  final List<ModelUsageData> data;
  final AnalyticsViewMode viewMode;
  final Function(AnalyticsViewMode)? onViewModeChanged;
  final DateTimeRange? dateRange;
  final Function(DateTimeRange?)? onDateRangeChanged;

  const ModelUsageChart({
    super.key,
    required this.data,
    this.viewMode = AnalyticsViewMode.daily,
    this.onViewModeChanged,
    this.dateRange,
    this.onDateRangeChanged,
  });

  @override
  State<ModelUsageChart> createState() => _ModelUsageChartState();
}

class _ModelUsageChartState extends State<ModelUsageChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControls(),
        const SizedBox(height: 24),
        _buildChart(),
        const SizedBox(height: 24),
        _buildLegend(),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        _buildViewModeButtons(),
        const Spacer(),
        if (widget.viewMode == AnalyticsViewMode.range)
          AnalyticsDateRangePicker(
            dateRange: widget.dateRange,
            onDateRangeChanged: widget.onDateRangeChanged,
          ),
      ],
    );
  }

  Widget _buildViewModeButtons() {
    final modes = [
      AnalyticsViewMode.daily,
      AnalyticsViewMode.monthly,
      AnalyticsViewMode.range,
    ];

    return Row(
      children: modes.map((mode) {
        final isSelected = widget.viewMode == mode;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => widget.onViewModeChanged?.call(mode),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : WebTheme.getBorderColor(context),
                ),
              ),
              child: Text(
                mode.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected 
                      ? Colors.white 
                      : WebTheme.getTextColor(context),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChart() {
    if (widget.data.isEmpty) {
      return Container(
        height: 260,
        alignment: Alignment.center,
        child: Text(
          '暂无数据',
          style: TextStyle(
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
      );
    }

    return Container(
      height: 260,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            enabled: true,
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (event is FlTapUpEvent &&
                    pieTouchResponse != null &&
                    pieTouchResponse.touchedSection != null) {
                  touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                } else {
                  touchedIndex = -1;
                }
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: _buildPieSections(),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final int crossAxisCount = constraints.maxWidth < 480 ? 1 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 70, // 增加高度，确保有足够空间
              crossAxisSpacing: 16,
              mainAxisSpacing: 16, // 增加间距，避免溢出
            ),
            itemCount: widget.data.length,
            itemBuilder: (context, index) {
              final data = widget.data[index];
              final color = Color(int.parse(data.color.substring(1, 7), radix: 16) + 0xFF000000);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WebTheme.getCardColor(context).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: WebTheme.getBorderColor(context).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            data.modelName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,  // 稍微减小字体，确保不溢出
                              fontWeight: FontWeight.w500,
                              color: WebTheme.getTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 4), // 增加间距
                          Row(
                            children: [
                              Text(
                                '${data.percentage}%',
                                style: TextStyle(
                                  fontSize: 15,  // 稍微减小字体
                                  fontWeight: FontWeight.w600,
                                  color: WebTheme.getTextColor(context),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(data.totalTokens / 1000).toStringAsFixed(0)}K',
                                style: TextStyle(
                                  fontSize: 11,  // 稍微减小字体
                                  color: WebTheme.getSecondaryTextColor(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final color = Color(int.parse(data.color.substring(1, 7), radix: 16) + 0xFF000000);
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 16.0 : 14.0;
      final radius = isTouched ? 85.0 : 80.0;
      
      return PieChartSectionData(
        color: color,
        value: data.percentage.toDouble(),
        title: '${data.percentage}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        // 将标题放置在更靠内的位置，避免与边缘碰撞
        titlePositionPercentageOffset: 0.55,
        borderSide: isTouched 
            ? const BorderSide(color: Colors.white, width: 2)
            : BorderSide.none,
        showTitle: data.percentage >= 5, // 只有大于5%的才显示标题
      );
    }).toList();
  }
}

// 数据聚合工具类
class ModelUsageAnalytics {
  /// 根据Token使用数据按模型名聚合统计
  static List<ModelUsageData> aggregateModelUsage(List<TokenUsageData> tokenData) {
    final Map<String, int> modelTotals = {};
    int totalTokens = 0;

    // 聚合所有模型的token使用量
    for (final data in tokenData) {
      for (final entry in data.modelTokens.entries) {
        final modelName = entry.key;
        final tokens = entry.value;
        modelTotals[modelName] = (modelTotals[modelName] ?? 0) + tokens;
        totalTokens += tokens;
      }
    }

    if (totalTokens == 0) return [];

    // 按使用量排序并生成ModelUsageData列表
    final sortedEntries = modelTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<ModelUsageData> result = [];
    final colors = ['#3B82F6', '#8B5CF6', '#10B981', '#F59E0B', '#EF4444', '#06B6D4'];
    
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final percentage = ((entry.value / totalTokens) * 100).round();
      
      result.add(ModelUsageData(
        modelName: entry.key,
        percentage: percentage,
        totalTokens: entry.value,
        color: colors[i % colors.length],
      ));
    }

    return result;
  }

  /// 获取模型使用的颜色
  static String getModelColor(String modelName) {
    switch (modelName) {
      case 'GPT-4':
        return '#3B82F6';
      case 'Claude-3.5':
        return '#8B5CF6';
      case 'Gemini Pro':
        return '#10B981';
      case '其他模型':
        return '#F59E0B';
      default:
        return '#6B7280';
    }
  }

  /// 获取模型的显示名称
  static String getModelDisplayName(String modelName) {
    switch (modelName) {
      case 'gpt-4':
      case 'gpt-4-turbo':
        return 'GPT-4';
      case 'claude-3-5-sonnet':
      case 'claude-3.5':
        return 'Claude-3.5';
      case 'gemini-pro':
      case 'gemini-1.5-pro':
        return 'Gemini Pro';
      default:
        return modelName;
    }
  }
}

