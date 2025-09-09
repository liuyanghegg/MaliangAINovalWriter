import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../utils/date_time_parser.dart';

part 'subscription_models.g.dart';

/// 订阅计划模型
@JsonSerializable()
class SubscriptionPlan extends Equatable {
  final String? id;
  final String planName;
  final String? description;
  final double price;
  final String currency;
  final BillingCycle billingCycle;
  final String? roleId;
  final int? creditsGranted;
  final bool active;
  final bool recommended;
  final int priority;
  final Map<String, dynamic>? features;
  final int trialDays;
  final int maxUsers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionPlan({
    this.id,
    required this.planName,
    this.description,
    required this.price,
    required this.currency,
    required this.billingCycle,
    this.roleId,
    this.creditsGranted,
    this.active = true,
    this.recommended = false,
    this.priority = 0,
    this.features,
    this.trialDays = 0,
    this.maxUsers = -1,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    // 兼容后端字段可能为空或类型不一致（如 BigDecimal 序列化为字符串）
    final dynamic priceRaw = json['price'];
    final double parsedPrice = priceRaw is num
        ? priceRaw.toDouble()
        : (priceRaw is String ? double.tryParse(priceRaw) ?? 0.0 : 0.0);

    final dynamic priorityRaw = json['priority'];
    final int parsedPriority = priorityRaw is num
        ? priorityRaw.toInt()
        : (priorityRaw is String ? int.tryParse(priorityRaw) ?? 0 : 0);

    final dynamic creditsRaw = json['creditsGranted'];
    final int? parsedCredits = creditsRaw == null
        ? null
        : (creditsRaw is num
            ? creditsRaw.toInt()
            : (creditsRaw is String ? int.tryParse(creditsRaw) : null));

    final dynamic activeRaw = json['active'];
    final bool parsedActive = activeRaw is bool
        ? activeRaw
        : (activeRaw is String ? activeRaw.toLowerCase() == 'true' : true);

    final dynamic recommendedRaw = json['recommended'];
    final bool parsedRecommended = recommendedRaw is bool
        ? recommendedRaw
        : (recommendedRaw is String ? recommendedRaw.toLowerCase() == 'true' : false);

    final featuresRaw = json['features'];
    final Map<String, dynamic>? parsedFeatures =
        featuresRaw is Map<String, dynamic> ? featuresRaw : null;

    return SubscriptionPlan(
      id: json['id'] as String?,
      planName: (json['planName'] as String?) ?? '未命名套餐',
      description: json['description'] as String?,
      price: parsedPrice,
      currency: (json['currency'] as String?) ?? 'CNY',
      billingCycle: _parseBillingCycle(json['billingCycle']),
      roleId: json['roleId'] as String?,
      creditsGranted: parsedCredits,
      active: parsedActive,
      recommended: parsedRecommended,
      priority: parsedPriority,
      features: parsedFeatures,
      trialDays: ((json['trialDays'] is String)
              ? int.tryParse(json['trialDays'])
              : (json['trialDays'] as num?))
              ?.toInt() ?? 0,
      maxUsers: ((json['maxUsers'] is String)
              ? int.tryParse(json['maxUsers'])
              : (json['maxUsers'] as num?))
              ?.toInt() ?? -1,
      createdAt: json['createdAt'] != null ? parseBackendDateTime(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? parseBackendDateTime(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => _$SubscriptionPlanToJson(this);

  @override
  List<Object?> get props => [
        id,
        planName,
        description,
        price,
        currency,
        billingCycle,
        roleId,
        creditsGranted,
        active,
        recommended,
        priority,
        features,
        trialDays,
        maxUsers,
        createdAt,
        updatedAt,
      ];

  /// 获取月度等价价格
  double get monthlyEquivalentPrice {
    switch (billingCycle) {
      case BillingCycle.monthly:
        return price;
      case BillingCycle.quarterly:
        return price / 3;
      case BillingCycle.yearly:
        return price / 12;
      case BillingCycle.lifetime:
        return price / 120; // 假设10年使用期
    }
  }

  /// 获取计费周期显示文本
  String get billingCycleText {
    switch (billingCycle) {
      case BillingCycle.monthly:
        return '月付';
      case BillingCycle.quarterly:
        return '季付';
      case BillingCycle.yearly:
        return '年付';
      case BillingCycle.lifetime:
        return '终身';
    }
  }

  /// 获取格式化价格
  String get formattedPrice {
    return '$currency ${price.toStringAsFixed(2)}';
  }

  /// 解析BillingCycle枚举
  static BillingCycle _parseBillingCycle(dynamic value) {
    if (value == null) return BillingCycle.monthly;
    
    final stringValue = value.toString().toUpperCase();
    switch (stringValue) {
      case 'MONTHLY':
        return BillingCycle.monthly;
      case 'QUARTERLY':
        return BillingCycle.quarterly;
      case 'YEARLY':
        return BillingCycle.yearly;
      case 'LIFETIME':
        return BillingCycle.lifetime;
      default:
        return BillingCycle.monthly;
    }
  }

  /// 创建副本
  SubscriptionPlan copyWith({
    String? id,
    String? planName,
    String? description,
    double? price,
    String? currency,
    BillingCycle? billingCycle,
    String? roleId,
    int? creditsGranted,
    bool? active,
    bool? recommended,
    int? priority,
    Map<String, dynamic>? features,
    int? trialDays,
    int? maxUsers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      planName: planName ?? this.planName,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      roleId: roleId ?? this.roleId,
      creditsGranted: creditsGranted ?? this.creditsGranted,
      active: active ?? this.active,
      recommended: recommended ?? this.recommended,
      priority: priority ?? this.priority,
      features: features ?? this.features,
      trialDays: trialDays ?? this.trialDays,
      maxUsers: maxUsers ?? this.maxUsers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 计费周期枚举
enum BillingCycle {
  @JsonValue('MONTHLY')
  monthly,
  @JsonValue('QUARTERLY')
  quarterly,
  @JsonValue('YEARLY')
  yearly,
  @JsonValue('LIFETIME')
  lifetime,
}

/// 用户订阅模型
@JsonSerializable()
class UserSubscription extends Equatable {
  final String? id;
  final String userId;
  final String planId;
  final DateTime? startDate;
  final DateTime? endDate;
  final SubscriptionStatus status;
  final bool autoRenewal;
  final String? paymentMethod;
  final String? transactionId;
  final int creditsUsed;
  final int totalCredits;
  final DateTime? canceledAt;
  final String? cancelReason;
  final DateTime? trialEndDate;
  final bool isTrial;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserSubscription({
    this.id,
    required this.userId,
    required this.planId,
    this.startDate,
    this.endDate,
    required this.status,
    this.autoRenewal = false,
    this.paymentMethod,
    this.transactionId,
    this.creditsUsed = 0,
    this.totalCredits = 0,
    this.canceledAt,
    this.cancelReason,
    this.trialEndDate,
    this.isTrial = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      planId: json['planId'] as String,
      startDate: json['startDate'] != null ? parseBackendDateTime(json['startDate']) : null,
      endDate: json['endDate'] != null ? parseBackendDateTime(json['endDate']) : null,
      status: _parseSubscriptionStatus(json['status']),
      autoRenewal: json['autoRenewal'] as bool? ?? false,
      paymentMethod: json['paymentMethod'] as String?,
      transactionId: json['transactionId'] as String?,
      creditsUsed: (json['creditsUsed'] as num?)?.toInt() ?? 0,
      totalCredits: (json['totalCredits'] as num?)?.toInt() ?? 0,
      canceledAt: json['canceledAt'] != null ? parseBackendDateTime(json['canceledAt']) : null,
      cancelReason: json['cancelReason'] as String?,
      trialEndDate: json['trialEndDate'] != null ? parseBackendDateTime(json['trialEndDate']) : null,
      isTrial: json['isTrial'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? parseBackendDateTime(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? parseBackendDateTime(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => _$UserSubscriptionToJson(this);

  @override
  List<Object?> get props => [
        id,
        userId,
        planId,
        startDate,
        endDate,
        status,
        autoRenewal,
        paymentMethod,
        transactionId,
        creditsUsed,
        totalCredits,
        canceledAt,
        cancelReason,
        trialEndDate,
        isTrial,
        createdAt,
        updatedAt,
      ];

  /// 获取剩余积分
  int get remainingCredits => (totalCredits - creditsUsed).clamp(0, totalCredits);

  /// 检查订阅是否有效
  bool get isValid {
    final now = DateTime.now();
    return (status == SubscriptionStatus.active || status == SubscriptionStatus.trial) &&
           (endDate == null || endDate!.isAfter(now));
  }

  /// 检查是否即将过期（7天内）
  bool get isExpiringSoon {
    if (endDate == null) return false;
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    return endDate!.isBefore(sevenDaysLater) && endDate!.isAfter(now);
  }

  /// 解析SubscriptionStatus枚举
  static SubscriptionStatus _parseSubscriptionStatus(dynamic value) {
    if (value == null) return SubscriptionStatus.active;
    
    final stringValue = value.toString().toUpperCase();
    switch (stringValue) {
      case 'ACTIVE':
        return SubscriptionStatus.active;
      case 'TRIAL':
        return SubscriptionStatus.trial;
      case 'CANCELED':
        return SubscriptionStatus.canceled;
      case 'EXPIRED':
        return SubscriptionStatus.expired;
      case 'SUSPENDED':
        return SubscriptionStatus.suspended;
      case 'REFUNDED':
        return SubscriptionStatus.refunded;
      default:
        return SubscriptionStatus.active;
    }
  }

  /// 获取状态显示文本
  String get statusText {
    switch (status) {
      case SubscriptionStatus.active:
        return '活跃';
      case SubscriptionStatus.trial:
        return '试用期';
      case SubscriptionStatus.canceled:
        return '已取消';
      case SubscriptionStatus.expired:
        return '已过期';
      case SubscriptionStatus.suspended:
        return '暂停';
      case SubscriptionStatus.refunded:
        return '已退款';
    }
  }
}

/// 订阅状态枚举
enum SubscriptionStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('TRIAL')
  trial,
  @JsonValue('CANCELED')
  canceled,
  @JsonValue('EXPIRED')
  expired,
  @JsonValue('SUSPENDED')
  suspended,
  @JsonValue('REFUNDED')
  refunded,
}

/// 订阅统计信息
@JsonSerializable()
class SubscriptionStatistics extends Equatable {
  final int totalPlans;
  final int activePlans;
  final int totalSubscriptions;
  final int activeSubscriptions;
  final int trialSubscriptions;
  final double monthlyRevenue;
  final double yearlyRevenue;

  const SubscriptionStatistics({
    required this.totalPlans,
    required this.activePlans,
    required this.totalSubscriptions,
    required this.activeSubscriptions,
    required this.trialSubscriptions,
    required this.monthlyRevenue,
    required this.yearlyRevenue,
  });

  factory SubscriptionStatistics.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionStatisticsToJson(this);

  @override
  List<Object?> get props => [
        totalPlans,
        activePlans,
        totalSubscriptions,
        activeSubscriptions,
        trialSubscriptions,
        monthlyRevenue,
        yearlyRevenue,
      ];
} 