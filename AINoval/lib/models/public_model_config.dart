import 'package:json_annotation/json_annotation.dart';
import '../utils/date_time_parser.dart';

part 'public_model_config.g.dart';

/// 公共模型配置详细信息模型
@JsonSerializable()
class PublicModelConfigDetails {
  /// 配置ID
  final String? id;
  
  /// 提供商名称
  final String provider;
  
  /// 模型ID
  final String modelId;
  
  /// 模型显示名称
  final String? displayName;
  
  /// 是否启用
  final bool? enabled;
  
  /// API Endpoint
  final String? apiEndpoint;
  
  /// 整体验证状态
  final bool? isValidated;
  
  /// API Key池状态摘要 (格式: "有效数量/总数量")
  final String? apiKeyPoolStatus;
  
  /// API Key池详情
  final List<ApiKeyStatus>? apiKeyStatuses;
  
  /// 授权功能列表 - 使用自定义转换
  @JsonKey(fromJson: _enabledFeaturesFromJson, toJson: _enabledFeaturesToJson)
  final List<String>? enabledForFeatures;
  
  /// 积分汇率乘数
  final double? creditRateMultiplier;
  
  /// 最大并发请求数
  final int? maxConcurrentRequests;
  
  /// 每日请求限制
  final int? dailyRequestLimit;
  
  /// 每小时请求限制
  final int? hourlyRequestLimit;
  
  /// 优先级
  final int? priority;
  
  /// 描述
  final String? description;
  
  /// 标签
  final List<String>? tags;
  
  /// 创建时间 - 使用自定义转换
  @JsonKey(fromJson: _parseDateTime, toJson: _dateTimeToJson)
  final DateTime? createdAt;
  
  /// 更新时间 - 使用自定义转换
  @JsonKey(fromJson: _parseDateTime, toJson: _dateTimeToJson)
  final DateTime? updatedAt;
  
  /// 创建者用户ID
  final String? createdBy;
  
  /// 最后修改者用户ID
  final String? updatedBy;
  
  /// 定价信息
  final PricingInfo? pricingInfo;
  
  /// 使用统计信息
  final UsageStatistics? usageStatistics;

  PublicModelConfigDetails({
    this.id,
    required this.provider,
    required this.modelId,
    this.displayName,
    this.enabled,
    this.apiEndpoint,
    this.isValidated,
    this.apiKeyPoolStatus,
    this.apiKeyStatuses,
    this.enabledForFeatures,
    this.creditRateMultiplier,
    this.maxConcurrentRequests,
    this.dailyRequestLimit,
    this.hourlyRequestLimit,
    this.priority,
    this.description,
    this.tags,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.pricingInfo,
    this.usageStatistics,
  });

  factory PublicModelConfigDetails.fromJson(Map<String, dynamic> json) =>
      _$PublicModelConfigDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$PublicModelConfigDetailsToJson(this);

  /// 自定义转换函数：从后端枚举转换为字符串列表
  static List<String>? _enabledFeaturesFromJson(dynamic json) {
    if (json == null) return null;
    if (json is List) {
      return json.map((item) {
        if (item is String) {
          return item;
        } else if (item is Map && item.containsKey('name')) {
          // 处理枚举对象 {name: "AI_CHAT", ordinal: 0}
          return item['name'] as String;
        } else {
          // 直接转换为字符串
          return item.toString();
        }
      }).toList();
    }
    return null;
  }

  /// 自定义转换函数：从字符串列表转换为JSON
  static List<String>? _enabledFeaturesToJson(List<String>? features) {
    return features;
  }

  /// 自定义时间解析函数：使用date_time_parser.dart
  static DateTime? _parseDateTime(dynamic json) {
    if (json == null) return null;
    try {
      return parseBackendDateTime(json);
    } catch (e) {
      return null;
    }
  }

  /// 自定义时间序列化函数
  static String? _dateTimeToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}

/// API Key状态（不包含API Key值）
@JsonSerializable()
class ApiKeyStatus {
  /// 是否验证通过
  final bool? isValid;
  
  /// 验证错误信息
  final String? validationError;
  
  /// 最近验证时间 - 使用自定义转换
  @JsonKey(fromJson: _parseDateTime, toJson: _dateTimeToJson)
  final DateTime? lastValidatedAt;
  
  /// 备注
  final String? note;

  ApiKeyStatus({
    this.isValid,
    this.validationError,
    this.lastValidatedAt,
    this.note,
  });

  factory ApiKeyStatus.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyStatusFromJson(json);

  Map<String, dynamic> toJson() => _$ApiKeyStatusToJson(this);

  /// 自定义时间解析函数：使用date_time_parser.dart
  static DateTime? _parseDateTime(dynamic json) {
    if (json == null) return null;
    try {
      return parseBackendDateTime(json);
    } catch (e) {
      return null;
    }
  }

  /// 自定义时间序列化函数
  static String? _dateTimeToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}

/// API Key状态（包含API Key值）- 仅供管理员使用
@JsonSerializable()
class ApiKeyWithStatus {
  /// API Key值
  final String? apiKey;
  
  /// 是否验证通过
  final bool? isValid;
  
  /// 验证错误信息
  final String? validationError;
  
  /// 最近验证时间 - 使用自定义转换
  @JsonKey(fromJson: _parseDateTime, toJson: _dateTimeToJson)
  final DateTime? lastValidatedAt;
  
  /// 备注
  final String? note;

  ApiKeyWithStatus({
    this.apiKey,
    this.isValid,
    this.validationError,
    this.lastValidatedAt,
    this.note,
  });

  factory ApiKeyWithStatus.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyWithStatusFromJson(json);

  Map<String, dynamic> toJson() => _$ApiKeyWithStatusToJson(this);

  /// 自定义时间解析函数：使用date_time_parser.dart
  static DateTime? _parseDateTime(dynamic json) {
    if (json == null) return null;
    try {
      return parseBackendDateTime(json);
    } catch (e) {
      return null;
    }
  }

  /// 自定义时间序列化函数
  static String? _dateTimeToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}

/// 定价信息
@JsonSerializable()
class PricingInfo {
  /// 模型名称
  final String? modelName;
  
  /// 输入token价格（每1000个token的美元价格）
  final double? inputPricePerThousandTokens;
  
  /// 输出token价格（每1000个token的美元价格）
  final double? outputPricePerThousandTokens;
  
  /// 统一价格（如果输入输出使用相同价格）
  final double? unifiedPricePerThousandTokens;
  
  /// 最大上下文token数
  final int? maxContextTokens;
  
  /// 是否支持流式输出
  final bool? supportsStreaming;
  
  /// 定价数据更新时间 - 使用自定义转换
  @JsonKey(fromJson: _parseDateTime, toJson: _dateTimeToJson)
  final DateTime? pricingUpdatedAt;
  
  /// 是否有定价数据
  final bool? hasPricingData;

  PricingInfo({
    this.modelName,
    this.inputPricePerThousandTokens,
    this.outputPricePerThousandTokens,
    this.unifiedPricePerThousandTokens,
    this.maxContextTokens,
    this.supportsStreaming,
    this.pricingUpdatedAt,
    this.hasPricingData,
  });

  factory PricingInfo.fromJson(Map<String, dynamic> json) =>
      _$PricingInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PricingInfoToJson(this);

  /// 自定义时间解析函数：使用date_time_parser.dart
  static DateTime? _parseDateTime(dynamic json) {
    if (json == null) return null;
    try {
      return parseBackendDateTime(json);
    } catch (e) {
      return null;
    }
  }

  /// 自定义时间序列化函数
  static String? _dateTimeToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}

/// 使用统计信息
@JsonSerializable()
class UsageStatistics {
  /// 总请求数
  final int? totalRequests;
  
  /// 总输入token数
  final int? totalInputTokens;
  
  /// 总输出token数
  final int? totalOutputTokens;
  
  /// 总token数
  final int? totalTokens;
  
  /// 总成本
  final double? totalCost;
  
  /// 平均每请求成本
  final double? averageCostPerRequest;
  
  /// 平均每token成本
  final double? averageCostPerToken;
  
  /// 最近30天请求数
  final int? last30DaysRequests;
  
  /// 最近30天成本
  final double? last30DaysCost;
  
  /// 是否有使用数据
  final bool? hasUsageData;

  UsageStatistics({
    this.totalRequests,
    this.totalInputTokens,
    this.totalOutputTokens,
    this.totalTokens,
    this.totalCost,
    this.averageCostPerRequest,
    this.averageCostPerToken,
    this.last30DaysRequests,
    this.last30DaysCost,
    this.hasUsageData,
  });

  factory UsageStatistics.fromJson(Map<String, dynamic> json) =>
      _$UsageStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$UsageStatisticsToJson(this);
}

/// 公共模型配置请求模型
@JsonSerializable()
class PublicModelConfigRequest {
  /// 提供商名称
  final String provider;
  
  /// 模型ID
  final String modelId;
  
  /// 模型显示名称
  final String? displayName;
  
  /// 是否启用
  final bool? enabled;
  
  /// API Key列表
  final List<ApiKeyRequest>? apiKeys;
  
  /// API Endpoint
  final String? apiEndpoint;
  
  /// 授权功能列表
  final List<String>? enabledForFeatures;
  
  /// 积分汇率乘数
  final double? creditRateMultiplier;
  
  /// 最大并发请求数
  final int? maxConcurrentRequests;
  
  /// 每日请求限制
  final int? dailyRequestLimit;
  
  /// 每小时请求限制
  final int? hourlyRequestLimit;
  
  /// 优先级
  final int? priority;
  
  /// 描述
  final String? description;
  
  /// 标签
  final List<String>? tags;

  PublicModelConfigRequest({
    required this.provider,
    required this.modelId,
    this.displayName,
    this.enabled,
    this.apiKeys,
    this.apiEndpoint,
    this.enabledForFeatures,
    this.creditRateMultiplier,
    this.maxConcurrentRequests,
    this.dailyRequestLimit,
    this.hourlyRequestLimit,
    this.priority,
    this.description,
    this.tags,
  });

  factory PublicModelConfigRequest.fromJson(Map<String, dynamic> json) =>
      _$PublicModelConfigRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PublicModelConfigRequestToJson(this);
}

/// API Key请求
@JsonSerializable()
class ApiKeyRequest {
  /// API Key
  final String apiKey;
  
  /// 备注
  final String? note;

  ApiKeyRequest({
    required this.apiKey,
    this.note,
  });

  factory ApiKeyRequest.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ApiKeyRequestToJson(this);
}

/// 公共模型配置详细信息模型（包含API Keys）- 仅供管理员使用
@JsonSerializable()
class PublicModelConfigWithKeys {
  /// 配置ID
  final String? id;
  
  /// 提供商名称
  final String provider;
  
  /// 模型ID
  final String modelId;
  
  /// 模型显示名称
  final String? displayName;
  
  /// 是否启用
  final bool? enabled;
  
  /// API Endpoint
  final String? apiEndpoint;
  
  /// 整体验证状态
  final bool? isValidated;
  
  /// API Key池状态摘要 (格式: "有效数量/总数量")
  final String? apiKeyPoolStatus;
  
  /// API Key池详情（包含实际的Key值）
  final List<ApiKeyWithStatus>? apiKeyStatuses;
  
  /// 授权功能列表 - 使用自定义转换
  @JsonKey(fromJson: _enabledFeaturesFromJson, toJson: _enabledFeaturesToJson)
  final List<String>? enabledForFeatures;
  
  /// 积分汇率乘数
  final double? creditRateMultiplier;
  
  /// 最大并发请求数
  final int? maxConcurrentRequests;
  
  /// 每日请求限制
  final int? dailyRequestLimit;
  
  /// 每小时请求限制
  final int? hourlyRequestLimit;
  
  /// 优先级
  final int? priority;
  
  /// 描述
  final String? description;
  
  /// 标签
  final List<String>? tags;
  
  /// 创建时间 - 使用自定义转换
  @JsonKey(fromJson: _parseDateTime, toJson: _dateTimeToJson)
  final DateTime? createdAt;
  
  /// 更新时间 - 使用自定义转换
  @JsonKey(fromJson: _parseDateTime, toJson: _dateTimeToJson)
  final DateTime? updatedAt;
  
  /// 创建者用户ID
  final String? createdBy;
  
  /// 最后修改者用户ID
  final String? updatedBy;
  
  /// 定价信息
  final PricingInfo? pricingInfo;
  
  /// 使用统计信息
  final UsageStatistics? usageStatistics;

  PublicModelConfigWithKeys({
    this.id,
    required this.provider,
    required this.modelId,
    this.displayName,
    this.enabled,
    this.apiEndpoint,
    this.isValidated,
    this.apiKeyPoolStatus,
    this.apiKeyStatuses,
    this.enabledForFeatures,
    this.creditRateMultiplier,
    this.maxConcurrentRequests,
    this.dailyRequestLimit,
    this.hourlyRequestLimit,
    this.priority,
    this.description,
    this.tags,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.pricingInfo,
    this.usageStatistics,
  });

  factory PublicModelConfigWithKeys.fromJson(Map<String, dynamic> json) =>
      _$PublicModelConfigWithKeysFromJson(json);

  Map<String, dynamic> toJson() => _$PublicModelConfigWithKeysToJson(this);

  /// 自定义转换函数：从后端枚举转换为字符串列表
  static List<String>? _enabledFeaturesFromJson(dynamic json) {
    if (json == null) return null;
    if (json is List) {
      return json.map((item) {
        if (item is String) {
          return item;
        } else if (item is Map && item.containsKey('name')) {
          // 处理枚举对象 {name: "AI_CHAT", ordinal: 0}
          return item['name'] as String;
        } else {
          // 直接转换为字符串
          return item.toString();
        }
      }).toList();
    }
    return null;
  }

  /// 自定义转换函数：从字符串列表转换为JSON
  static List<String>? _enabledFeaturesToJson(List<String>? features) {
    return features;
  }

  /// 自定义时间解析函数：使用date_time_parser.dart
  static DateTime? _parseDateTime(dynamic json) {
    if (json == null) return null;
    try {
      return parseBackendDateTime(json);
    } catch (e) {
      return null;
    }
  }

  /// 自定义时间序列化函数
  static String? _dateTimeToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}

/// 公共模型响应DTO（对应后端的PublicModelResponseDto）
/// 只包含向前端暴露的安全信息，不含API Keys等敏感数据
@JsonSerializable()
class PublicModel {
  /// 模型ID
  final String id;

  /// 提供商 (如: openai, anthropic, google等)
  final String provider;

  /// 模型标识符 (如: gpt-4, claude-3-sonnet)
  final String modelId;

  /// 显示名称
  final String displayName;

  /// 模型描述
  final String? description;

  /// 积分倍率 (如: 1.0 表示标准倍率, 1.5 表示1.5倍积分)
  final double? creditRateMultiplier;

  /// 支持的AI功能列表
  final List<String>? supportedFeatures;

  /// 模型标签 (如: ["快速", "高质量", "多语言"])
  final List<String>? tags;

  /// 性能指标
  final PerformanceMetrics? performanceMetrics;

  /// 限制信息
  final LimitationInfo? limitations;

  /// 优先级 (用于前端排序)
  final int? priority;

  /// 是否推荐使用
  final bool? recommended;

  PublicModel({
    required this.id,
    required this.provider,
    required this.modelId,
    required this.displayName,
    this.description,
    this.creditRateMultiplier,
    this.supportedFeatures,
    this.tags,
    this.performanceMetrics,
    this.limitations,
    this.priority,
    this.recommended,
  });

  factory PublicModel.fromJson(Map<String, dynamic> json) =>
      _$PublicModelFromJson(json);

  Map<String, dynamic> toJson() => _$PublicModelToJson(this);

  /// 获取格式化的积分倍率显示文本
  String get creditMultiplierDisplay {
    if (creditRateMultiplier == null) return '';
    if (creditRateMultiplier! == 1.0) return '';
    return '${creditRateMultiplier!.toStringAsFixed(1)}x积分';
  }

  /// 是否为公共模型（总是返回true，用于区分私有模型）
  bool get isPublic => true;
}

/// 性能指标
@JsonSerializable()
class PerformanceMetrics {
  /// 平均响应时间（毫秒）
  final int? averageResponseTimeMs;

  /// 吞吐量（每分钟请求数）
  final int? throughputPerMinute;

  /// 可用性百分比
  final double? availabilityPercentage;

  /// 质量评分（1-10）
  final double? qualityScore;

  PerformanceMetrics({
    this.averageResponseTimeMs,
    this.throughputPerMinute,
    this.availabilityPercentage,
    this.qualityScore,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$PerformanceMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceMetricsToJson(this);
}

/// 限制信息
@JsonSerializable()
class LimitationInfo {
  /// 最大上下文长度
  final int? maxContextLength;

  /// 每分钟请求限制
  final int? requestsPerMinute;

  /// 每小时请求限制
  final int? requestsPerHour;

  /// 每日请求限制
  final int? requestsPerDay;

  /// 是否支持流式输出
  final bool? supportsStreaming;

  LimitationInfo({
    this.maxContextLength,
    this.requestsPerMinute,
    this.requestsPerHour,
    this.requestsPerDay,
    this.supportsStreaming,
  });

  factory LimitationInfo.fromJson(Map<String, dynamic> json) =>
      _$LimitationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LimitationInfoToJson(this);
}