// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionPlan',
      json,
      ($checkedConvert) {
        final val = SubscriptionPlan(
          id: $checkedConvert('id', (v) => v as String?),
          planName: $checkedConvert('planName', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String?),
          price: $checkedConvert('price', (v) => (v as num).toDouble()),
          currency: $checkedConvert('currency', (v) => v as String),
          billingCycle: $checkedConvert(
              'billingCycle', (v) => $enumDecode(_$BillingCycleEnumMap, v)),
          roleId: $checkedConvert('roleId', (v) => v as String?),
          creditsGranted:
              $checkedConvert('creditsGranted', (v) => (v as num?)?.toInt()),
          active: $checkedConvert('active', (v) => v as bool? ?? true),
          recommended:
              $checkedConvert('recommended', (v) => v as bool? ?? false),
          priority:
              $checkedConvert('priority', (v) => (v as num?)?.toInt() ?? 0),
          features:
              $checkedConvert('features', (v) => v as Map<String, dynamic>?),
          trialDays:
              $checkedConvert('trialDays', (v) => (v as num?)?.toInt() ?? 0),
          maxUsers:
              $checkedConvert('maxUsers', (v) => (v as num?)?.toInt() ?? -1),
          createdAt: $checkedConvert('createdAt',
              (v) => v == null ? null : DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updatedAt',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionPlanToJson(SubscriptionPlan instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['planName'] = instance.planName;
  writeNotNull('description', instance.description);
  val['price'] = instance.price;
  val['currency'] = instance.currency;
  val['billingCycle'] = _$BillingCycleEnumMap[instance.billingCycle]!;
  writeNotNull('roleId', instance.roleId);
  writeNotNull('creditsGranted', instance.creditsGranted);
  val['active'] = instance.active;
  val['recommended'] = instance.recommended;
  val['priority'] = instance.priority;
  writeNotNull('features', instance.features);
  val['trialDays'] = instance.trialDays;
  val['maxUsers'] = instance.maxUsers;
  writeNotNull('createdAt', instance.createdAt?.toIso8601String());
  writeNotNull('updatedAt', instance.updatedAt?.toIso8601String());
  return val;
}

const _$BillingCycleEnumMap = {
  BillingCycle.monthly: 'MONTHLY',
  BillingCycle.quarterly: 'QUARTERLY',
  BillingCycle.yearly: 'YEARLY',
  BillingCycle.lifetime: 'LIFETIME',
};

UserSubscription _$UserSubscriptionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'UserSubscription',
      json,
      ($checkedConvert) {
        final val = UserSubscription(
          id: $checkedConvert('id', (v) => v as String?),
          userId: $checkedConvert('userId', (v) => v as String),
          planId: $checkedConvert('planId', (v) => v as String),
          startDate: $checkedConvert('startDate',
              (v) => v == null ? null : DateTime.parse(v as String)),
          endDate: $checkedConvert(
              'endDate', (v) => v == null ? null : DateTime.parse(v as String)),
          status: $checkedConvert(
              'status', (v) => $enumDecode(_$SubscriptionStatusEnumMap, v)),
          autoRenewal:
              $checkedConvert('autoRenewal', (v) => v as bool? ?? false),
          paymentMethod: $checkedConvert('paymentMethod', (v) => v as String?),
          transactionId: $checkedConvert('transactionId', (v) => v as String?),
          creditsUsed:
              $checkedConvert('creditsUsed', (v) => (v as num?)?.toInt() ?? 0),
          totalCredits:
              $checkedConvert('totalCredits', (v) => (v as num?)?.toInt() ?? 0),
          canceledAt: $checkedConvert('canceledAt',
              (v) => v == null ? null : DateTime.parse(v as String)),
          cancelReason: $checkedConvert('cancelReason', (v) => v as String?),
          trialEndDate: $checkedConvert('trialEndDate',
              (v) => v == null ? null : DateTime.parse(v as String)),
          isTrial: $checkedConvert('isTrial', (v) => v as bool? ?? false),
          createdAt: $checkedConvert('createdAt',
              (v) => v == null ? null : DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updatedAt',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$UserSubscriptionToJson(UserSubscription instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['userId'] = instance.userId;
  val['planId'] = instance.planId;
  writeNotNull('startDate', instance.startDate?.toIso8601String());
  writeNotNull('endDate', instance.endDate?.toIso8601String());
  val['status'] = _$SubscriptionStatusEnumMap[instance.status]!;
  val['autoRenewal'] = instance.autoRenewal;
  writeNotNull('paymentMethod', instance.paymentMethod);
  writeNotNull('transactionId', instance.transactionId);
  val['creditsUsed'] = instance.creditsUsed;
  val['totalCredits'] = instance.totalCredits;
  writeNotNull('canceledAt', instance.canceledAt?.toIso8601String());
  writeNotNull('cancelReason', instance.cancelReason);
  writeNotNull('trialEndDate', instance.trialEndDate?.toIso8601String());
  val['isTrial'] = instance.isTrial;
  writeNotNull('createdAt', instance.createdAt?.toIso8601String());
  writeNotNull('updatedAt', instance.updatedAt?.toIso8601String());
  return val;
}

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.active: 'ACTIVE',
  SubscriptionStatus.trial: 'TRIAL',
  SubscriptionStatus.canceled: 'CANCELED',
  SubscriptionStatus.expired: 'EXPIRED',
  SubscriptionStatus.suspended: 'SUSPENDED',
  SubscriptionStatus.refunded: 'REFUNDED',
};

SubscriptionStatistics _$SubscriptionStatisticsFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SubscriptionStatistics',
      json,
      ($checkedConvert) {
        final val = SubscriptionStatistics(
          totalPlans: $checkedConvert('totalPlans', (v) => (v as num).toInt()),
          activePlans:
              $checkedConvert('activePlans', (v) => (v as num).toInt()),
          totalSubscriptions:
              $checkedConvert('totalSubscriptions', (v) => (v as num).toInt()),
          activeSubscriptions:
              $checkedConvert('activeSubscriptions', (v) => (v as num).toInt()),
          trialSubscriptions:
              $checkedConvert('trialSubscriptions', (v) => (v as num).toInt()),
          monthlyRevenue:
              $checkedConvert('monthlyRevenue', (v) => (v as num).toDouble()),
          yearlyRevenue:
              $checkedConvert('yearlyRevenue', (v) => (v as num).toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$SubscriptionStatisticsToJson(
        SubscriptionStatistics instance) =>
    <String, dynamic>{
      'totalPlans': instance.totalPlans,
      'activePlans': instance.activePlans,
      'totalSubscriptions': instance.totalSubscriptions,
      'activeSubscriptions': instance.activeSubscriptions,
      'trialSubscriptions': instance.trialSubscriptions,
      'monthlyRevenue': instance.monthlyRevenue,
      'yearlyRevenue': instance.yearlyRevenue,
    };
