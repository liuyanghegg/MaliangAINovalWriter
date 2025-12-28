import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:ainoval/models/analytics_data.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/analytics/date_range_picker.dart';

class FunctionUsageChart extends StatefulWidget {
  final List<FunctionUsageData> data;
  final AnalyticsViewMode viewMode;
  final Function(AnalyticsViewMode)? onViewModeChanged;
  final DateTimeRange? dateRange;
  final Function(DateTimeRange?)? onDateRangeChanged;

  const FunctionUsageChart({
    super.key,
    required this.data,
    this.viewMode = AnalyticsViewMode.daily,
    this.onViewModeChanged,
    this.dateRange,
    this.onDateRangeChanged,
  });

  @override
  State<FunctionUsageChart> createState() => _FunctionUsageChartState();
}

class _FunctionUsageChartState extends State<FunctionUsageChart> {
  int touchedIndex = -1;

  static const List<Color> colors = [
    Color(0xFF3B82F6), // blue
    Color(0xFF8B5CF6), // purple
    Color(0xFF10B981), // green
    Color(0xFFF59E0B), // yellow
    Color(0xFFEF4444), // red
    Color(0xFF06B6D4), // cyan
  ];

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

    final double maxY = _getMaxY();
    final double yInterval = _getNiceGridInterval(maxY);

    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => WebTheme.getCardColor(context),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex >= 0 && groupIndex < widget.data.length) {
                  final data = widget.data[groupIndex];
                  return BarTooltipItem(
                    '${data.name}\n',
                    TextStyle(
                      color: WebTheme.getTextColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '使用次数: ${data.value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}',
                        style: TextStyle(
                          color: WebTheme.getSecondaryTextColor(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (data.growth != 0) TextSpan(
                        text: '\n增长率: ${data.growth > 0 ? '+' : ''}${data.growth.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: data.growth > 0 ? Colors.green[600] : Colors.red[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }
                return null;
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              setState(() {
                if (event is FlTapUpEvent &&
                    barTouchResponse != null &&
                    barTouchResponse.spot != null) {
                  touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                } else {
                  touchedIndex = -1;
                }
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < widget.data.length) {
                    final name = widget.data[index].name;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        name.length > 4 ? '${name.substring(0, 4)}...' : name,
                        style: TextStyle(
                          color: WebTheme.getSecondaryTextColor(context),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: yInterval,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatYAxisLabel(value),
                    style: TextStyle(
                      color: WebTheme.getSecondaryTextColor(context),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _buildBarGroups(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: WebTheme.getBorderColor(context).withOpacity(0.3),
              strokeWidth: 1,
              dashArray: [3, 3],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: widget.data.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final color = colors[index % colors.length];
          
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 24, maxWidth: 260),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  data.value.toString().replaceAllMapped(
                    RegExp(r'(\d)(?=(\d{3})+(?!\d))'), 
                    (match) => '${match[1]},',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(width: 4),
                if (data.growth != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: data.growth > 0 
                          ? Colors.green[50] 
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${data.growth > 0 ? '+' : ''}${data.growth.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: data.growth > 0 
                            ? Colors.green[600] 
                            : Colors.red[600],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final color = colors[index % colors.length];
      final isTouched = index == touchedIndex;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.value.toDouble(),
            color: color,
            width: isTouched ? 20 : 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(),
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY() {
    if (widget.data.isEmpty) return 1000;
    
    final maxValue = widget.data
        .map((d) => d.value)
        .reduce((a, b) => a > b ? a : b);
    
    // 添加20%的padding
    final maxWithPadding = maxValue * 1.2;
    return maxWithPadding;
  }

  // 计算漂亮的网格间隔（1/2/5 x 10^k）
  double _getNiceGridInterval(double maxY) {
    final double roughStep = (maxY <= 0 ? 1000.0 : maxY) / 5.0;
    final double magnitude = math.pow(10, (math.log(roughStep) / math.ln10).floor()).toDouble();
    final double residual = roughStep / magnitude;
    double nice;
    if (residual >= 5) {
      nice = 5;
    } else if (residual >= 2) {
      nice = 2;
    } else {
      nice = 1;
    }
    return nice * magnitude;
  }

  String _formatYAxisLabel(double value) {
    final double absVal = value.abs();
    if (absVal >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (absVal >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toInt().toString();
  }
}
