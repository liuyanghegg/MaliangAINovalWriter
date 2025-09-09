// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_model_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicModelConfigDetails _$PublicModelConfigDetailsFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PublicModelConfigDetails',
      json,
      ($checkedConvert) {
        final val = PublicModelConfigDetails(
          id: $checkedConvert('id', (v) => v as String?),
          provider: $checkedConvert('provider', (v) => v as String),
          modelId: $checkedConvert('modelId', (v) => v as String),
          displayName: $checkedConvert('displayName', (v) => v as String?),
          enabled: $checkedConvert('enabled', (v) => v as bool?),
          apiEndpoint: $checkedConvert('apiEndpoint', (v) => v as String?),
          isValidated: $checkedConvert('isValidated', (v) => v as bool?),
          apiKeyPoolStatus:
              $checkedConvert('apiKeyPoolStatus', (v) => v as String?),
          apiKeyStatuses: $checkedConvert(
              'apiKeyStatuses',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => ApiKeyStatus.fromJson(e as Map<String, dynamic>))
                  .toList()),
          enabledForFeatures: $checkedConvert('enabledForFeatures',
              (v) => PublicModelConfigDetails._enabledFeaturesFromJson(v)),
          creditRateMultiplier: $checkedConvert(
              'creditRateMultiplier', (v) => (v as num?)?.toDouble()),
          maxConcurrentRequests: $checkedConvert(
              'maxConcurrentRequests', (v) => (v as num?)?.toInt()),
          dailyRequestLimit:
              $checkedConvert('dailyRequestLimit', (v) => (v as num?)?.toInt()),
          hourlyRequestLimit: $checkedConvert(
              'hourlyRequestLimit', (v) => (v as num?)?.toInt()),
          priority: $checkedConvert('priority', (v) => (v as num?)?.toInt()),
          description: $checkedConvert('description', (v) => v as String?),
          tags: $checkedConvert('tags',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          createdAt: $checkedConvert(
              'createdAt', (v) => PublicModelConfigDetails._parseDateTime(v)),
          updatedAt: $checkedConvert(
              'updatedAt', (v) => PublicModelConfigDetails._parseDateTime(v)),
          createdBy: $checkedConvert('createdBy', (v) => v as String?),
          updatedBy: $checkedConvert('updatedBy', (v) => v as String?),
          pricingInfo: $checkedConvert(
              'pricingInfo',
              (v) => v == null
                  ? null
                  : PricingInfo.fromJson(v as Map<String, dynamic>)),
          usageStatistics: $checkedConvert(
              'usageStatistics',
              (v) => v == null
                  ? null
                  : UsageStatistics.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$PublicModelConfigDetailsToJson(
    PublicModelConfigDetails instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['provider'] = instance.provider;
  val['modelId'] = instance.modelId;
  writeNotNull('displayName', instance.displayName);
  writeNotNull('enabled', instance.enabled);
  writeNotNull('apiEndpoint', instance.apiEndpoint);
  writeNotNull('isValidated', instance.isValidated);
  writeNotNull('apiKeyPoolStatus', instance.apiKeyPoolStatus);
  writeNotNull('apiKeyStatuses',
      instance.apiKeyStatuses?.map((e) => e.toJson()).toList());
  writeNotNull(
      'enabledForFeatures',
      PublicModelConfigDetails._enabledFeaturesToJson(
          instance.enabledForFeatures));
  writeNotNull('creditRateMultiplier', instance.creditRateMultiplier);
  writeNotNull('maxConcurrentRequests', instance.maxConcurrentRequests);
  writeNotNull('dailyRequestLimit', instance.dailyRequestLimit);
  writeNotNull('hourlyRequestLimit', instance.hourlyRequestLimit);
  writeNotNull('priority', instance.priority);
  writeNotNull('description', instance.description);
  writeNotNull('tags', instance.tags);
  writeNotNull('createdAt',
      PublicModelConfigDetails._dateTimeToJson(instance.createdAt));
  writeNotNull('updatedAt',
      PublicModelConfigDetails._dateTimeToJson(instance.updatedAt));
  writeNotNull('createdBy', instance.createdBy);
  writeNotNull('updatedBy', instance.updatedBy);
  writeNotNull('pricingInfo', instance.pricingInfo?.toJson());
  writeNotNull('usageStatistics', instance.usageStatistics?.toJson());
  return val;
}

ApiKeyStatus _$ApiKeyStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ApiKeyStatus',
      json,
      ($checkedConvert) {
        final val = ApiKeyStatus(
          isValid: $checkedConvert('isValid', (v) => v as bool?),
          validationError:
              $checkedConvert('validationError', (v) => v as String?),
          lastValidatedAt: $checkedConvert(
              'lastValidatedAt', (v) => ApiKeyStatus._parseDateTime(v)),
          note: $checkedConvert('note', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ApiKeyStatusToJson(ApiKeyStatus instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('isValid', instance.isValid);
  writeNotNull('validationError', instance.validationError);
  writeNotNull('lastValidatedAt',
      ApiKeyStatus._dateTimeToJson(instance.lastValidatedAt));
  writeNotNull('note', instance.note);
  return val;
}

ApiKeyWithStatus _$ApiKeyWithStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ApiKeyWithStatus',
      json,
      ($checkedConvert) {
        final val = ApiKeyWithStatus(
          apiKey: $checkedConvert('apiKey', (v) => v as String?),
          isValid: $checkedConvert('isValid', (v) => v as bool?),
          validationError:
              $checkedConvert('validationError', (v) => v as String?),
          lastValidatedAt: $checkedConvert(
              'lastValidatedAt', (v) => ApiKeyWithStatus._parseDateTime(v)),
          note: $checkedConvert('note', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ApiKeyWithStatusToJson(ApiKeyWithStatus instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('apiKey', instance.apiKey);
  writeNotNull('isValid', instance.isValid);
  writeNotNull('validationError', instance.validationError);
  writeNotNull('lastValidatedAt',
      ApiKeyWithStatus._dateTimeToJson(instance.lastValidatedAt));
  writeNotNull('note', instance.note);
  return val;
}

PricingInfo _$PricingInfoFromJson(Map<String, dynamic> json) => $checkedCreate(
      'PricingInfo',
      json,
      ($checkedConvert) {
        final val = PricingInfo(
          modelName: $checkedConvert('modelName', (v) => v as String?),
          inputPricePerThousandTokens: $checkedConvert(
              'inputPricePerThousandTokens', (v) => (v as num?)?.toDouble()),
          outputPricePerThousandTokens: $checkedConvert(
              'outputPricePerThousandTokens', (v) => (v as num?)?.toDouble()),
          unifiedPricePerThousandTokens: $checkedConvert(
              'unifiedPricePerThousandTokens', (v) => (v as num?)?.toDouble()),
          maxContextTokens:
              $checkedConvert('maxContextTokens', (v) => (v as num?)?.toInt()),
          supportsStreaming:
              $checkedConvert('supportsStreaming', (v) => v as bool?),
          pricingUpdatedAt: $checkedConvert(
              'pricingUpdatedAt', (v) => PricingInfo._parseDateTime(v)),
          hasPricingData: $checkedConvert('hasPricingData', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PricingInfoToJson(PricingInfo instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('modelName', instance.modelName);
  writeNotNull(
      'inputPricePerThousandTokens', instance.inputPricePerThousandTokens);
  writeNotNull(
      'outputPricePerThousandTokens', instance.outputPricePerThousandTokens);
  writeNotNull(
      'unifiedPricePerThousandTokens', instance.unifiedPricePerThousandTokens);
  writeNotNull('maxContextTokens', instance.maxContextTokens);
  writeNotNull('supportsStreaming', instance.supportsStreaming);
  writeNotNull('pricingUpdatedAt',
      PricingInfo._dateTimeToJson(instance.pricingUpdatedAt));
  writeNotNull('hasPricingData', instance.hasPricingData);
  return val;
}

UsageStatistics _$UsageStatisticsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'UsageStatistics',
      json,
      ($checkedConvert) {
        final val = UsageStatistics(
          totalRequests:
              $checkedConvert('totalRequests', (v) => (v as num?)?.toInt()),
          totalInputTokens:
              $checkedConvert('totalInputTokens', (v) => (v as num?)?.toInt()),
          totalOutputTokens:
              $checkedConvert('totalOutputTokens', (v) => (v as num?)?.toInt()),
          totalTokens:
              $checkedConvert('totalTokens', (v) => (v as num?)?.toInt()),
          totalCost:
              $checkedConvert('totalCost', (v) => (v as num?)?.toDouble()),
          averageCostPerRequest: $checkedConvert(
              'averageCostPerRequest', (v) => (v as num?)?.toDouble()),
          averageCostPerToken: $checkedConvert(
              'averageCostPerToken', (v) => (v as num?)?.toDouble()),
          last30DaysRequests: $checkedConvert(
              'last30DaysRequests', (v) => (v as num?)?.toInt()),
          last30DaysCost:
              $checkedConvert('last30DaysCost', (v) => (v as num?)?.toDouble()),
          hasUsageData: $checkedConvert('hasUsageData', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$UsageStatisticsToJson(UsageStatistics instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('totalRequests', instance.totalRequests);
  writeNotNull('totalInputTokens', instance.totalInputTokens);
  writeNotNull('totalOutputTokens', instance.totalOutputTokens);
  writeNotNull('totalTokens', instance.totalTokens);
  writeNotNull('totalCost', instance.totalCost);
  writeNotNull('averageCostPerRequest', instance.averageCostPerRequest);
  writeNotNull('averageCostPerToken', instance.averageCostPerToken);
  writeNotNull('last30DaysRequests', instance.last30DaysRequests);
  writeNotNull('last30DaysCost', instance.last30DaysCost);
  writeNotNull('hasUsageData', instance.hasUsageData);
  return val;
}

PublicModelConfigRequest _$PublicModelConfigRequestFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PublicModelConfigRequest',
      json,
      ($checkedConvert) {
        final val = PublicModelConfigRequest(
          provider: $checkedConvert('provider', (v) => v as String),
          modelId: $checkedConvert('modelId', (v) => v as String),
          displayName: $checkedConvert('displayName', (v) => v as String?),
          enabled: $checkedConvert('enabled', (v) => v as bool?),
          apiKeys: $checkedConvert(
              'apiKeys',
              (v) => (v as List<dynamic>?)
                  ?.map(
                      (e) => ApiKeyRequest.fromJson(e as Map<String, dynamic>))
                  .toList()),
          apiEndpoint: $checkedConvert('apiEndpoint', (v) => v as String?),
          enabledForFeatures: $checkedConvert('enabledForFeatures',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          creditRateMultiplier: $checkedConvert(
              'creditRateMultiplier', (v) => (v as num?)?.toDouble()),
          maxConcurrentRequests: $checkedConvert(
              'maxConcurrentRequests', (v) => (v as num?)?.toInt()),
          dailyRequestLimit:
              $checkedConvert('dailyRequestLimit', (v) => (v as num?)?.toInt()),
          hourlyRequestLimit: $checkedConvert(
              'hourlyRequestLimit', (v) => (v as num?)?.toInt()),
          priority: $checkedConvert('priority', (v) => (v as num?)?.toInt()),
          description: $checkedConvert('description', (v) => v as String?),
          tags: $checkedConvert('tags',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PublicModelConfigRequestToJson(
    PublicModelConfigRequest instance) {
  final val = <String, dynamic>{
    'provider': instance.provider,
    'modelId': instance.modelId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('displayName', instance.displayName);
  writeNotNull('enabled', instance.enabled);
  writeNotNull('apiKeys', instance.apiKeys?.map((e) => e.toJson()).toList());
  writeNotNull('apiEndpoint', instance.apiEndpoint);
  writeNotNull('enabledForFeatures', instance.enabledForFeatures);
  writeNotNull('creditRateMultiplier', instance.creditRateMultiplier);
  writeNotNull('maxConcurrentRequests', instance.maxConcurrentRequests);
  writeNotNull('dailyRequestLimit', instance.dailyRequestLimit);
  writeNotNull('hourlyRequestLimit', instance.hourlyRequestLimit);
  writeNotNull('priority', instance.priority);
  writeNotNull('description', instance.description);
  writeNotNull('tags', instance.tags);
  return val;
}

ApiKeyRequest _$ApiKeyRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ApiKeyRequest',
      json,
      ($checkedConvert) {
        final val = ApiKeyRequest(
          apiKey: $checkedConvert('apiKey', (v) => v as String),
          note: $checkedConvert('note', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ApiKeyRequestToJson(ApiKeyRequest instance) {
  final val = <String, dynamic>{
    'apiKey': instance.apiKey,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('note', instance.note);
  return val;
}

PublicModelConfigWithKeys _$PublicModelConfigWithKeysFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PublicModelConfigWithKeys',
      json,
      ($checkedConvert) {
        final val = PublicModelConfigWithKeys(
          id: $checkedConvert('id', (v) => v as String?),
          provider: $checkedConvert('provider', (v) => v as String),
          modelId: $checkedConvert('modelId', (v) => v as String),
          displayName: $checkedConvert('displayName', (v) => v as String?),
          enabled: $checkedConvert('enabled', (v) => v as bool?),
          apiEndpoint: $checkedConvert('apiEndpoint', (v) => v as String?),
          isValidated: $checkedConvert('isValidated', (v) => v as bool?),
          apiKeyPoolStatus:
              $checkedConvert('apiKeyPoolStatus', (v) => v as String?),
          apiKeyStatuses: $checkedConvert(
              'apiKeyStatuses',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      ApiKeyWithStatus.fromJson(e as Map<String, dynamic>))
                  .toList()),
          enabledForFeatures: $checkedConvert('enabledForFeatures',
              (v) => PublicModelConfigWithKeys._enabledFeaturesFromJson(v)),
          creditRateMultiplier: $checkedConvert(
              'creditRateMultiplier', (v) => (v as num?)?.toDouble()),
          maxConcurrentRequests: $checkedConvert(
              'maxConcurrentRequests', (v) => (v as num?)?.toInt()),
          dailyRequestLimit:
              $checkedConvert('dailyRequestLimit', (v) => (v as num?)?.toInt()),
          hourlyRequestLimit: $checkedConvert(
              'hourlyRequestLimit', (v) => (v as num?)?.toInt()),
          priority: $checkedConvert('priority', (v) => (v as num?)?.toInt()),
          description: $checkedConvert('description', (v) => v as String?),
          tags: $checkedConvert('tags',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          createdAt: $checkedConvert(
              'createdAt', (v) => PublicModelConfigWithKeys._parseDateTime(v)),
          updatedAt: $checkedConvert(
              'updatedAt', (v) => PublicModelConfigWithKeys._parseDateTime(v)),
          createdBy: $checkedConvert('createdBy', (v) => v as String?),
          updatedBy: $checkedConvert('updatedBy', (v) => v as String?),
          pricingInfo: $checkedConvert(
              'pricingInfo',
              (v) => v == null
                  ? null
                  : PricingInfo.fromJson(v as Map<String, dynamic>)),
          usageStatistics: $checkedConvert(
              'usageStatistics',
              (v) => v == null
                  ? null
                  : UsageStatistics.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$PublicModelConfigWithKeysToJson(
    PublicModelConfigWithKeys instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['provider'] = instance.provider;
  val['modelId'] = instance.modelId;
  writeNotNull('displayName', instance.displayName);
  writeNotNull('enabled', instance.enabled);
  writeNotNull('apiEndpoint', instance.apiEndpoint);
  writeNotNull('isValidated', instance.isValidated);
  writeNotNull('apiKeyPoolStatus', instance.apiKeyPoolStatus);
  writeNotNull('apiKeyStatuses',
      instance.apiKeyStatuses?.map((e) => e.toJson()).toList());
  writeNotNull(
      'enabledForFeatures',
      PublicModelConfigWithKeys._enabledFeaturesToJson(
          instance.enabledForFeatures));
  writeNotNull('creditRateMultiplier', instance.creditRateMultiplier);
  writeNotNull('maxConcurrentRequests', instance.maxConcurrentRequests);
  writeNotNull('dailyRequestLimit', instance.dailyRequestLimit);
  writeNotNull('hourlyRequestLimit', instance.hourlyRequestLimit);
  writeNotNull('priority', instance.priority);
  writeNotNull('description', instance.description);
  writeNotNull('tags', instance.tags);
  writeNotNull('createdAt',
      PublicModelConfigWithKeys._dateTimeToJson(instance.createdAt));
  writeNotNull('updatedAt',
      PublicModelConfigWithKeys._dateTimeToJson(instance.updatedAt));
  writeNotNull('createdBy', instance.createdBy);
  writeNotNull('updatedBy', instance.updatedBy);
  writeNotNull('pricingInfo', instance.pricingInfo?.toJson());
  writeNotNull('usageStatistics', instance.usageStatistics?.toJson());
  return val;
}

PublicModel _$PublicModelFromJson(Map<String, dynamic> json) => $checkedCreate(
      'PublicModel',
      json,
      ($checkedConvert) {
        final val = PublicModel(
          id: $checkedConvert('id', (v) => v as String),
          provider: $checkedConvert('provider', (v) => v as String),
          modelId: $checkedConvert('modelId', (v) => v as String),
          displayName: $checkedConvert('displayName', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String?),
          creditRateMultiplier: $checkedConvert(
              'creditRateMultiplier', (v) => (v as num?)?.toDouble()),
          supportedFeatures: $checkedConvert('supportedFeatures',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          tags: $checkedConvert('tags',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          performanceMetrics: $checkedConvert(
              'performanceMetrics',
              (v) => v == null
                  ? null
                  : PerformanceMetrics.fromJson(v as Map<String, dynamic>)),
          limitations: $checkedConvert(
              'limitations',
              (v) => v == null
                  ? null
                  : LimitationInfo.fromJson(v as Map<String, dynamic>)),
          priority: $checkedConvert('priority', (v) => (v as num?)?.toInt()),
          recommended: $checkedConvert('recommended', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PublicModelToJson(PublicModel instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'provider': instance.provider,
    'modelId': instance.modelId,
    'displayName': instance.displayName,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('description', instance.description);
  writeNotNull('creditRateMultiplier', instance.creditRateMultiplier);
  writeNotNull('supportedFeatures', instance.supportedFeatures);
  writeNotNull('tags', instance.tags);
  writeNotNull('performanceMetrics', instance.performanceMetrics?.toJson());
  writeNotNull('limitations', instance.limitations?.toJson());
  writeNotNull('priority', instance.priority);
  writeNotNull('recommended', instance.recommended);
  return val;
}

PerformanceMetrics _$PerformanceMetricsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PerformanceMetrics',
      json,
      ($checkedConvert) {
        final val = PerformanceMetrics(
          averageResponseTimeMs: $checkedConvert(
              'averageResponseTimeMs', (v) => (v as num?)?.toInt()),
          throughputPerMinute: $checkedConvert(
              'throughputPerMinute', (v) => (v as num?)?.toInt()),
          availabilityPercentage: $checkedConvert(
              'availabilityPercentage', (v) => (v as num?)?.toDouble()),
          qualityScore:
              $checkedConvert('qualityScore', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PerformanceMetricsToJson(PerformanceMetrics instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('averageResponseTimeMs', instance.averageResponseTimeMs);
  writeNotNull('throughputPerMinute', instance.throughputPerMinute);
  writeNotNull('availabilityPercentage', instance.availabilityPercentage);
  writeNotNull('qualityScore', instance.qualityScore);
  return val;
}

LimitationInfo _$LimitationInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LimitationInfo',
      json,
      ($checkedConvert) {
        final val = LimitationInfo(
          maxContextLength:
              $checkedConvert('maxContextLength', (v) => (v as num?)?.toInt()),
          requestsPerMinute:
              $checkedConvert('requestsPerMinute', (v) => (v as num?)?.toInt()),
          requestsPerHour:
              $checkedConvert('requestsPerHour', (v) => (v as num?)?.toInt()),
          requestsPerDay:
              $checkedConvert('requestsPerDay', (v) => (v as num?)?.toInt()),
          supportsStreaming:
              $checkedConvert('supportsStreaming', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$LimitationInfoToJson(LimitationInfo instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('maxContextLength', instance.maxContextLength);
  writeNotNull('requestsPerMinute', instance.requestsPerMinute);
  writeNotNull('requestsPerHour', instance.requestsPerHour);
  writeNotNull('requestsPerDay', instance.requestsPerDay);
  writeNotNull('supportsStreaming', instance.supportsStreaming);
  return val;
}
