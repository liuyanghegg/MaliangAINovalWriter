import 'package:ainoval/utils/date_time_parser.dart';

class AnalyticsData {
  final int totalWords;
  final int totalTokens;
  final int functionUsageCount;
  final int writingDays;
  final int monthlyNewWords;
  final int monthlyNewTokens;
  final int consecutiveDays;
  final String mostPopularFunction;

  const AnalyticsData({
    required this.totalWords,
    required this.totalTokens,
    required this.functionUsageCount,
    required this.writingDays,
    required this.monthlyNewWords,
    required this.monthlyNewTokens,
    required this.consecutiveDays,
    required this.mostPopularFunction,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      totalWords: json['totalWords'] ?? 0,
      totalTokens: json['totalTokens'] ?? 0,
      functionUsageCount: json['functionUsageCount'] ?? 0,
      writingDays: json['writingDays'] ?? 0,
      monthlyNewWords: json['monthlyNewWords'] ?? 0,
      monthlyNewTokens: json['monthlyNewTokens'] ?? 0,
      consecutiveDays: json['consecutiveDays'] ?? 0,
      mostPopularFunction: json['mostPopularFunction'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalWords': totalWords,
      'totalTokens': totalTokens,
      'functionUsageCount': functionUsageCount,
      'writingDays': writingDays,
      'monthlyNewWords': monthlyNewWords,
      'monthlyNewTokens': monthlyNewTokens,
      'consecutiveDays': consecutiveDays,
      'mostPopularFunction': mostPopularFunction,
    };
  }
}

class TokenUsageData {
  final String date;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final Map<String, int> modelTokens; // 按模型名聚合的tokens

  const TokenUsageData({
    required this.date,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.modelTokens,
  });

  factory TokenUsageData.fromJson(Map<String, dynamic> json) {
    return TokenUsageData(
      date: json['date'] ?? '',
      inputTokens: json['inputTokens'] ?? 0,
      outputTokens: json['outputTokens'] ?? 0,
      totalTokens: json['totalTokens'] ?? 0,
      modelTokens: Map<String, int>.from(json['modelTokens'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalTokens': totalTokens,
      'modelTokens': modelTokens,
    };
  }
}

class FunctionUsageData {
  final String name;
  final int value;
  final double growth; // 增长率百分比

  const FunctionUsageData({
    required this.name,
    required this.value,
    required this.growth,
  });

  factory FunctionUsageData.fromJson(Map<String, dynamic> json) {
    return FunctionUsageData(
      name: json['name'] ?? '',
      value: json['value'] ?? 0,
      growth: (json['growth'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'growth': growth,
    };
  }
}

class ModelUsageData {
  final String modelName;
  final int percentage;
  final int totalTokens;
  final String color;

  const ModelUsageData({
    required this.modelName,
    required this.percentage,
    required this.totalTokens,
    required this.color,
  });

  factory ModelUsageData.fromJson(Map<String, dynamic> json) {
    return ModelUsageData(
      modelName: json['modelName'] ?? '',
      percentage: json['percentage'] ?? 0,
      totalTokens: json['totalTokens'] ?? 0,
      color: json['color'] ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modelName': modelName,
      'percentage': percentage,
      'totalTokens': totalTokens,
      'color': color,
    };
  }
}

class TokenUsageRecord {
  final String id;
  final DateTime timestamp;
  final int inputTokens;
  final int outputTokens;
  final String model;
  final String taskType;
  final double cost;

  const TokenUsageRecord({
    required this.id,
    required this.timestamp,
    required this.inputTokens,
    required this.outputTokens,
    required this.model,
    required this.taskType,
    required this.cost,
  });

  factory TokenUsageRecord.fromJson(Map<String, dynamic> json) {
    return TokenUsageRecord(
      id: json['id'] ?? '',
      timestamp: parseBackendDateTime(json['timestamp']),
      inputTokens: json['inputTokens'] ?? 0,
      outputTokens: json['outputTokens'] ?? 0,
      model: json['model'] ?? '',
      taskType: json['taskType'] ?? '',
      cost: (json['cost'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'model': model,
      'taskType': taskType,
      'cost': cost,
    };
  }

  int get totalTokens => inputTokens + outputTokens;
}

enum AnalyticsViewMode {
  daily,
  monthly,
  cumulative,
  range,
}

extension AnalyticsViewModeExtension on AnalyticsViewMode {
  String get displayName {
    switch (this) {
      case AnalyticsViewMode.daily:
        return '按天';
      case AnalyticsViewMode.monthly:
        return '按月';
      case AnalyticsViewMode.cumulative:
        return '累计';
      case AnalyticsViewMode.range:
        return '日期范围';
    }
  }
}
