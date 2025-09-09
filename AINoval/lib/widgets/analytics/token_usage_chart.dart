import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:ainoval/models/analytics_data.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/analytics/date_range_picker.dart';

class TokenUsageChart extends StatefulWidget {
  final List<TokenUsageData> data;
  final AnalyticsViewMode viewMode;
  final Function(AnalyticsViewMode)? onViewModeChanged;
  final DateTimeRange? dateRange;
  final Function(DateTimeRange?)? onDateRangeChanged;

  const TokenUsageChart({
    super.key,
    required this.data,
    this.viewMode = AnalyticsViewMode.monthly,
    this.onViewModeChanged,
    this.dateRange,
    this.onDateRangeChanged,
  });

  @override
  State<TokenUsageChart> createState() => _TokenUsageChartState();
}

class _TokenUsageChartState extends State<TokenUsageChart> {
  int touchedIndex = -1;

  List<TokenUsageData> get _sortedData {
    final List<TokenUsageData> copy = List<TokenUsageData>.from(widget.data);
    copy.sort((a, b) {
      final DateTime? da = _parseDate(a.date);
      final DateTime? db = _parseDate(b.date);
      if (da == null && db == null) return 0;
      if (da == null) return -1;
      if (db == null) return 1;
      return da.compareTo(db);
    });
    return copy;
  }

  DateTime? _parseDate(String raw) {
    final DateTime? direct = DateTime.tryParse(raw);
    if (direct != null) return DateTime(direct.year, direct.month, direct.day);
    if (RegExp(r'^\d{1,2}-\d{1,2}$').hasMatch(raw)) {
      final parts = raw.split('-');
      final m = int.tryParse(parts[0]) ?? 1;
      final d = int.tryParse(parts[1]) ?? 1;
      final now = DateTime.now();
      return DateTime(now.year, m, d);
    }
    return null;
  }

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
            'Token 使用趋势',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
        ),
        const Spacer(),
        _buildViewModeButtons(),
        const SizedBox(width: 16),
        if (widget.viewMode == AnalyticsViewMode.range)
          AnalyticsDateRangePicker(
            dateRange: widget.dateRange,
            onDateRangeChanged: widget.onDateRangeChanged,
          ),
      ],
    );
  }

  Widget _buildViewModeButtons() {
    return Row(
      children: AnalyticsViewMode.values.map((mode) {
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
        height: 320,
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
    final double xInterval = _computeXLabelInterval(_sortedData.length).toDouble();

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
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
                reservedSize: 30,
                interval: xInterval,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _sortedData.length) {
                    final date = _sortedData[index].date;
                    final label = _formatXAxisLabel(widget.viewMode, date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: WebTheme.getSecondaryTextColor(context),
                          fontSize: 12,
                        ),
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
          minX: 0,
          maxX: (_sortedData.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            // 输入Token线
            LineChartBarData(
              spots: _getInputSpots(),
              isCurved: true,
              color: const Color(0xFF3B82F6),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.3),
                    const Color(0xFF3B82F6).withOpacity(0.0),
                  ],
                ),
              ),
            ),
            // 输出Token线
            LineChartBarData(
              spots: _getOutputSpots(),
              isCurved: true,
              color: const Color(0xFF8B5CF6),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.3),
                    const Color(0xFF8B5CF6).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => WebTheme.getCardColor(context),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final dataIndex = spot.x.toInt();
                  if (dataIndex >= 0 && dataIndex < _sortedData.length) {
                    final data = _sortedData[dataIndex];
                    
                    return LineTooltipItem(
                      '${data.date}\n输入: ${data.inputTokens.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} tokens\n输出: ${data.outputTokens.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} tokens',
                      TextStyle(
                        color: WebTheme.getTextColor(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }
                  return null;
                }).where((item) => item != null).cast<LineTooltipItem>().toList();
              },
            ),
            touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
              setState(() {
                if (response == null || response.lineBarSpots == null) {
                  touchedIndex = -1;
                } else {
                  touchedIndex = response.lineBarSpots!.first.x.toInt();
                }
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final List<TokenUsageData> dataList = _sortedData;
    final currentData = dataList.isNotEmpty ? dataList.last : null;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          color: const Color(0xFF3B82F6),
          label: '输入Token',
          value: currentData != null ? '${(currentData.inputTokens / 1000).toStringAsFixed(0)}K' : '0K',
        ),
        const SizedBox(width: 32),
        _buildLegendItem(
          color: const Color(0xFF8B5CF6),
          label: '输出Token',
          value: currentData != null ? '${(currentData.outputTokens / 1000).toStringAsFixed(0)}K' : '0K',
        ),
        const SizedBox(width: 32),
        _buildLegendItem(
          color: Theme.of(context).primaryColor,
          label: '总计',
          value: currentData != null ? '${(currentData.totalTokens / 1000).toStringAsFixed(0)}K' : '0K',
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WebTheme.getTextColor(context),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getInputSpots() {
    final List<TokenUsageData> dataList = _sortedData;
    return dataList.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.inputTokens.toDouble());
    }).toList();
  }

  List<FlSpot> _getOutputSpots() {
    final List<TokenUsageData> dataList = _sortedData;
    return dataList.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.outputTokens.toDouble());
    }).toList();
  }

  double _getMaxY() {
    final List<TokenUsageData> dataList = _sortedData;
    if (dataList.isEmpty) return 100000;
    
    final maxInput = dataList.map((d) => d.inputTokens).reduce((a, b) => a > b ? a : b);
    final maxOutput = dataList.map((d) => d.outputTokens).reduce((a, b) => a > b ? a : b);
    final max = maxInput > maxOutput ? maxInput : maxOutput;
    
    // 添加20%的padding，并保证最小正数上限，避免全零导致maxY=0
    final withPadding = (max * 1.2).ceilToDouble();
    return withPadding <= 0 ? 1000 : withPadding;
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

  // 控制底部x轴标签密度，避免挤在一起
  int _computeXLabelInterval(int length) {
    if (length <= 10) return 1;
    if (length <= 20) return 2;
    if (length <= 40) return 4;
    return (length / 10).ceil();
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

  String _formatXAxisLabel(AnalyticsViewMode mode, String raw) {
    switch (mode) {
      case AnalyticsViewMode.monthly:
        // 期望显示 MM
        final parts = raw.split('-');
        if (parts.length >= 2) {
          return parts[1];
        }
        return raw;
      case AnalyticsViewMode.daily:
      case AnalyticsViewMode.range:
      case AnalyticsViewMode.cumulative:
        // 期望显示 MM-dd
        // 支持 'yyyy-MM-dd' / 'yyyy-MM' / 'MM-dd'
        if (RegExp(r'^\d{4}-\d{1,2}-\d{1,2}$').hasMatch(raw)) {
          return raw.substring(raw.length - 5);
        }
        if (RegExp(r'^\d{4}-\d{1,2}$').hasMatch(raw)) {
          final parts = raw.split('-');
          return '${parts[1].padLeft(2, '0')}-01';
        }
        if (RegExp(r'^\d{1,2}-\d{1,2}$').hasMatch(raw)) {
          final parts = raw.split('-');
          return '${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';
        }
        final parts2 = raw.split('-');
        if (parts2.length >= 3) {
          return '${parts2[1]}-${parts2[2].padLeft(2, '0')}';
        }
        return raw;
    }
  }


}
