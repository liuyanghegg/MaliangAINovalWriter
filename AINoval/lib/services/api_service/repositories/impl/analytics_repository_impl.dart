import 'package:ainoval/models/analytics_data.dart';
import 'package:ainoval/models/prompt_models.dart';
import 'package:ainoval/services/api_service/repositories/analytics_repository.dart';
import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/utils/date_time_parser.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<AnalyticsData> getAnalyticsOverview() async {
    try {
      final response = await _apiClient.get('/analytics/overview');
      final data = response['data'] as Map<String, dynamic>;

      final rawMostPopular = data['mostPopularFunction']?.toString() ?? '';

      return AnalyticsData(
        totalWords: data['totalWords'] ?? 0,
        monthlyNewWords: data['monthlyNewWords'] ?? 0,
        totalTokens: data['totalTokens'] ?? 0,
        monthlyNewTokens: data['monthlyNewTokens'] ?? 0,
        functionUsageCount: (data['functionUsageCount'] ?? 0).toInt(),
        mostPopularFunction: _mapFunctionToDisplay(rawMostPopular).isEmpty
            ? '智能续写'
            : _mapFunctionToDisplay(rawMostPopular),
        writingDays: (data['writingDays'] ?? 0).toInt(),
        consecutiveDays: (data['consecutiveDays'] ?? 0).toInt(),
      );
    } catch (e) {
      throw Exception('Failed to load analytics overview: $e');
    }
  }

  @override
  Future<List<TokenUsageData>> getTokenUsageTrend({
    AnalyticsViewMode viewMode = AnalyticsViewMode.monthly,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'viewMode': _getViewModeString(viewMode),
      };
      
      if (startDate != null) {
        params['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        params['endDate'] = endDate.toIso8601String();
      }

      final response = await _apiClient.getWithParams('/analytics/token-usage-trend', queryParameters: params);
      final List<dynamic> data = response['data'] as List<dynamic>;

      final List<TokenUsageData> rawSeries = data.map((item) => TokenUsageData(
        date: item['date'] as String,
        inputTokens: item['inputTokens'] ?? 0,
        outputTokens: item['outputTokens'] ?? 0,
        totalTokens: (item['inputTokens'] ?? 0) + (item['outputTokens'] ?? 0),
        modelTokens: <String, int>{}, // 后端暂不返回按模型分组的数据
      )).toList();

      // 补齐缺失日期，避免仅单点数据显示突兀
      return _postProcessTokenSeries(
        rawSeries: rawSeries,
        viewMode: viewMode,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to load token usage trend: $e');
    }
  }

  @override
  Future<List<FunctionUsageData>> getFunctionUsageStats({
    required AnalyticsViewMode viewMode,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'viewMode': _getViewModeString(viewMode),
      };

      final response = await _apiClient.getWithParams('/analytics/function-usage-stats', queryParameters: params);
      final List<dynamic> data = response['data'] as List<dynamic>;
      
      return data.map((item) => FunctionUsageData(
        name: _mapFunctionToDisplay(item['function']?.toString() ?? ''),
        value: (item['count'] ?? 0).toInt(),
        growth: 0.0, // 后端暂不返回增长率数据
      )).toList();
    } catch (e) {
      throw Exception('Failed to load function usage stats: $e');
    }
  }

  @override
  Future<List<ModelUsageData>> getModelUsageStats({
    required AnalyticsViewMode viewMode,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'viewMode': _getViewModeString(viewMode),
      };

      final response = await _apiClient.getWithParams('/analytics/model-usage-stats', queryParameters: params);
      final List<dynamic> data = response['data'] as List<dynamic>;
      
      return data.map((item) => ModelUsageData(
        modelName: item['model'] as String,
        percentage: ((item['percentage'] ?? 0.0).toDouble()).round(),
        totalTokens: item['count'] ?? 0, // 使用count作为总tokens的代表
        color: _getModelColor(item['model'] as String),
      )).toList();
    } catch (e) {
      throw Exception('Failed to load model usage stats: $e');
    }
  }

  @override
  Future<List<TokenUsageRecord>> getTokenUsageRecords({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'limit': limit.toString(),
      };

      final response = await _apiClient.getWithParams('/analytics/token-usage-records', queryParameters: params);
      final List<dynamic> data = response['data'] as List<dynamic>;
      
      return data.map((item) => TokenUsageRecord(
        id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        model: item['model'] as String,
        taskType: _mapFunctionToDisplay(item['taskType']?.toString() ?? ''),
        inputTokens: item['inputTokens'] ?? 0,
        outputTokens: item['outputTokens'] ?? 0,
        cost: (item['cost'] ?? 0.0).toDouble(),
        timestamp: parseBackendDateTime(item['timestamp']),
      )).toList();
    } catch (e) {
      throw Exception('Failed to load token usage records: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getTodayTokenSummary() async {
    try {
      final response = await _apiClient.get('/analytics/today-summary');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load today token summary: $e');
    }
  }

  String _getViewModeString(AnalyticsViewMode mode) {
    switch (mode) {
      case AnalyticsViewMode.daily:
        return 'daily';
      case AnalyticsViewMode.monthly:
        return 'monthly';
      case AnalyticsViewMode.cumulative:
        return 'cumulative';
      case AnalyticsViewMode.range:
        return 'range';
    }
  }

  String _getModelColor(String model) {
    final String m = model.toLowerCase();
    if (m.contains('gpt')) return '#3B82F6';
    if (m.contains('claude')) return '#8B5CF6';
    if (m.contains('gemini')) return '#10B981';
    if (m.contains('deepseek')) return '#F59E0B';
    // 对未知模型使用稳定的哈希颜色，确保“不同的显示不同颜色”
    final List<String> palette = ['#06B6D4', '#EF4444', '#22C55E', '#F97316', '#A855F7', '#0EA5E9'];
    final int idx = model.hashCode.abs() % palette.length;
    return palette[idx];
  }

  String _mapFunctionToDisplay(String functionKey) {
    if (functionKey.isEmpty) return '';
    try {
      final feature = AIFeatureTypeHelper.fromApiString(functionKey);
      return feature.displayName;
    } catch (_) {
      return functionKey;
    }
  }

  

  // ----------
  // Token 使用趋势数据补齐逻辑
  // ----------

  List<TokenUsageData> _postProcessTokenSeries({
    required List<TokenUsageData> rawSeries,
    required AnalyticsViewMode viewMode,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (rawSeries.isEmpty) {
      // 空数据时保留为空，让前端显示“暂无数据”
      return rawSeries;
    }

    switch (viewMode) {
      case AnalyticsViewMode.daily:
      case AnalyticsViewMode.range:
        return _fillDailySeries(
          rawSeries: rawSeries,
          explicitStart: startDate,
          explicitEnd: endDate,
        );
      case AnalyticsViewMode.monthly:
        return _fillMonthlySeries(
          rawSeries: rawSeries,
          explicitStart: startDate,
          explicitEnd: endDate,
        );
      case AnalyticsViewMode.cumulative:
        // 累计模式一般由后端计算。为避免误解语义，不进行数值重算，仅在只有单点时做最小可视化填充（填充前置0）。
        if (rawSeries.length > 1) return _sortByDateString(rawSeries);
        return _fillDailySeries(
          rawSeries: rawSeries,
          explicitStart: startDate,
          explicitEnd: endDate,
          defaultWindowDays: 7,
        );
    }
  }

  List<TokenUsageData> _fillDailySeries({
    required List<TokenUsageData> rawSeries,
    DateTime? explicitStart,
    DateTime? explicitEnd,
    int defaultWindowDays = 7,
  }) {
    final List<TokenUsageData> sorted = _sortByDateString(rawSeries);

    // 解析现有最早与最晚日期
    final DateTime? firstDate = _tryParseDate(sorted.first.date);
    final DateTime? lastDate = _tryParseDate(sorted.last.date);

    // 对于仅有 MM-dd 的场景，_tryParseDate 会用当前年填充，可能导致“跨年跳跃”。为了可视化体验：
    // 若显式日期范围为空，则直接使用数据内最早/最晚的字符串顺序来确定窗口，不再随当前年错配。
    DateTime start = _normalizeToDateOnly(explicitStart ?? firstDate ?? DateTime.now());
    DateTime end = _normalizeToDateOnly(explicitEnd ?? lastDate ?? DateTime.now());

    if (sorted.length == 1 && explicitStart == null && explicitEnd == null) {
      // 仅单点数据时，默认展示 [last - (N-1)天, last] 的连续窗口
      start = _normalizeToDateOnly(end.subtract(Duration(days: defaultWindowDays - 1)));
    }

    if (end.isBefore(start)) {
      // 防御：若区间反转，交换
      final tmp = start;
      start = end;
      end = tmp;
    }

    // 建立日期到数据的索引
    final Map<String, TokenUsageData> dateToData = {
      for (final d in sorted) _formatDate(d.date, AnalyticsViewMode.daily): d,
    };

    final List<TokenUsageData> filled = [];
    DateTime cursor = start;
    while (!cursor.isAfter(end)) {
      final String key = _formatDateFromDateTime(cursor, AnalyticsViewMode.daily);
      final TokenUsageData? existing = dateToData[key];
      if (existing != null) {
        filled.add(existing);
      } else {
        filled.add(TokenUsageData(
          date: key,
          inputTokens: 0,
          outputTokens: 0,
          totalTokens: 0,
          modelTokens: const <String, int>{},
        ));
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return filled;
  }

  List<TokenUsageData> _fillMonthlySeries({
    required List<TokenUsageData> rawSeries,
    DateTime? explicitStart,
    DateTime? explicitEnd,
    int defaultWindowMonths = 6,
  }) {
    final List<TokenUsageData> sorted = _sortByDateString(rawSeries);

    // 猜测月份：将字符串解析到当月第一天
    final DateTime? firstMonth = _normalizeToMonthStart(_tryParseDate(sorted.first.date));
    final DateTime? lastMonth = _normalizeToMonthStart(_tryParseDate(sorted.last.date));

    DateTime start = explicitStart != null
        ? _normalizeToMonthStart(explicitStart)
        : (firstMonth ?? _normalizeToMonthStart(DateTime.now()));
    DateTime end = explicitEnd != null
        ? _normalizeToMonthStart(explicitEnd)
        : (lastMonth ?? _normalizeToMonthStart(DateTime.now()));

    if (sorted.length == 1 && explicitStart == null && explicitEnd == null) {
      // 仅单点数据时，默认展示最近 N 个月
      end = _normalizeToMonthStart(end);
      start = _addMonths(end, -(defaultWindowMonths - 1));
    }

    if (end.isBefore(start)) {
      final tmp = start;
      start = end;
      end = tmp;
    }

    // 索引：yyyy-MM -> 数据
    final Map<String, TokenUsageData> monthToData = {
      for (final d in sorted) _formatDate(d.date, AnalyticsViewMode.monthly): d,
    };

    final List<TokenUsageData> filled = [];
    DateTime cursor = start;
    while (!cursor.isAfter(end)) {
      final String key = _formatDateFromDateTime(cursor, AnalyticsViewMode.monthly);
      final TokenUsageData? existing = monthToData[key];
      if (existing != null) {
        filled.add(existing);
      } else {
        filled.add(TokenUsageData(
          date: key,
          inputTokens: 0,
          outputTokens: 0,
          totalTokens: 0,
          modelTokens: const <String, int>{},
        ));
      }
      cursor = _addMonths(cursor, 1);
    }

    return filled;
  }

  List<TokenUsageData> _sortByDateString(List<TokenUsageData> series) {
    final List<TokenUsageData> copy = List<TokenUsageData>.from(series);
    copy.sort((a, b) {
      final DateTime? da = _tryParseDate(a.date);
      final DateTime? db = _tryParseDate(b.date);
      if (da == null && db == null) return 0;
      if (da == null) return -1;
      if (db == null) return 1;
      return da.compareTo(db);
    });
    return copy;
  }

  DateTime? _tryParseDate(String raw) {
    // 1) 直接解析 ISO / yyyy-MM-dd / yyyy-MM
    final DateTime? direct = DateTime.tryParse(raw);
    if (direct != null) return direct;

    final now = DateTime.now();
    try {
      // 2) 显式识别 'yyyy-MM-dd'
      if (RegExp(r'^\d{4}-\d{1,2}-\d{1,2}$').hasMatch(raw)) {
        final p = raw.split('-');
        final y = int.parse(p[0]);
        final m = int.parse(p[1]);
        final d = int.parse(p[2]);
        return DateTime(y, m, d);
      }
      // 3) 显式识别 'yyyy-MM'
      if (RegExp(r'^\d{4}-\d{1,2}$').hasMatch(raw)) {
        final p = raw.split('-');
        final y = int.parse(p[0]);
        final m = int.parse(p[1]);
        return DateTime(y, m, 1);
      }
      // 4) 显式识别 'MM-dd'：视为当前年份的 月-日
      if (RegExp(r'^\d{1,2}-\d{1,2}$').hasMatch(raw)) {
        final p = raw.split('-');
        final m = int.parse(p[0]);
        final d = int.parse(p[1]);
        return DateTime(now.year, m, d);
      }
      // 5) 宽松兜底：若为两段且第一段长度为2，按 MM-dd；否则按 yyyy-MM(-dd)
      final parts = raw.split('-');
      if (parts.length == 2 && parts[0].length <= 2) {
        final m = int.tryParse(parts[0]) ?? 1;
        final d = int.tryParse(parts[1]) ?? 1;
        return DateTime(now.year, m, d);
      }
      if (parts.length >= 2) {
        final int y = int.tryParse(parts[0]) ?? now.year;
        final int m = int.tryParse(parts[1]) ?? 1;
        final int d = parts.length >= 3 ? (int.tryParse(parts[2]) ?? 1) : 1;
        return DateTime(y, m, d);
      }
    } catch (_) {}
    return null;
  }

  DateTime _normalizeToDateOnly(DateTime? dt) {
    final DateTime base = dt ?? DateTime.now();
    return DateTime(base.year, base.month, base.day);
  }

  DateTime _normalizeToMonthStart(DateTime? dt) {
    final DateTime base = dt ?? DateTime.now();
    return DateTime(base.year, base.month, 1);
  }

  DateTime _addMonths(DateTime dt, int delta) {
    final int yearDelta = (dt.month - 1 + delta) ~/ 12;
    final int newMonthIndex = (dt.month - 1 + delta) % 12;
    final int newYear = dt.year + yearDelta;
    final int newMonth = newMonthIndex + 1;
    final int day = dt.day;
    // 处理不同月份天数
    final int lastDay = DateTime(newYear, newMonth + 1, 0).day;
    final int safeDay = day > lastDay ? lastDay : day;
    return DateTime(newYear, newMonth, safeDay);
  }

  String _formatDate(String raw, AnalyticsViewMode mode) {
    final DateTime? dt = _tryParseDate(raw);
    if (dt == null) return raw;
    return _formatDateFromDateTime(dt, mode);
  }

  String _formatDateFromDateTime(DateTime dt, AnalyticsViewMode mode) {
    final int y = dt.year;
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    switch (mode) {
      case AnalyticsViewMode.daily:
      case AnalyticsViewMode.range:
      case AnalyticsViewMode.cumulative:
        return '$y-$m-$d';
      case AnalyticsViewMode.monthly:
        return '$y-$m';
    }
  }
}