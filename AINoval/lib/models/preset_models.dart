import 'package:ainoval/models/ai_request_models.dart';
import 'package:ainoval/models/prompt_models.dart';
import 'package:ainoval/utils/date_time_parser.dart';
import 'dart:convert';

import 'package:ainoval/utils/logger.dart';

/// AI预设模型
class AIPromptPreset {
  /// 预设ID
  final String presetId;
  
  /// 用户ID
  final String userId;
  
  /// 预设名称
  final String? presetName;
  
  /// 预设描述
  final String? presetDescription;
  
  /// 标签列表
  final List<String>? presetTags;
  
  /// 是否收藏
  final bool isFavorite;
  
  /// 是否公开
  final bool isPublic;
  
  /// 使用次数
  final int useCount;
  
  /// 配置哈希
  final String presetHash;
  
  /// 请求数据JSON字符串
  final String requestData;
  
  /// 系统提示词
  final String systemPrompt;
  
  /// 用户提示词
  final String userPrompt;
  
  /// AI功能类型
  final String aiFeatureType;
  
  /// 关联的模板ID
  final String? templateId;
  
  /// 是否为系统预设
  final bool isSystem;
  
  /// 是否显示在快捷访问中
  final bool showInQuickAccess;
  
  /// 自定义系统提示词
  final String? customSystemPrompt;
  
  /// 自定义用户提示词
  final String? customUserPrompt;
  
  /// 是否自定义了提示词
  final bool promptCustomized;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;
  
  /// 最后使用时间
  final DateTime? lastUsedAt;

  AIPromptPreset({
    required this.presetId,
    required this.userId,
    this.presetName,
    this.presetDescription,
    this.presetTags,
    this.isFavorite = false,
    this.isPublic = false,
    this.useCount = 0,
    required this.presetHash,
    required this.requestData,
    required this.systemPrompt,
    required this.userPrompt,
    required this.aiFeatureType,
    this.templateId,
    this.isSystem = false,
    this.showInQuickAccess = false,
    this.customSystemPrompt,
    this.customUserPrompt,
    this.promptCustomized = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
  });

  /// 获取生效的系统提示词
  String get effectiveSystemPrompt {
    return (promptCustomized && customSystemPrompt != null && customSystemPrompt!.isNotEmpty)
        ? customSystemPrompt!
        : systemPrompt;
  }

  /// 获取生效的用户提示词
  String get effectiveUserPrompt {
    return (promptCustomized && customUserPrompt != null && customUserPrompt!.isNotEmpty)
        ? customUserPrompt!
        : userPrompt;
  }

  /// 获取标签列表
  List<String> get tags {
    return presetTags ?? [];
  }

  /// 🚀 新增：从requestData解析并还原为UniversalAIRequest对象
  UniversalAIRequest? get parsedRequest {
    try {
      if (requestData.isEmpty) {
        //print('⚠️ [AIPromptPreset.parsedRequest] requestData为空');
        return null;
      }

      // 解析JSON
      final Map<String, dynamic> jsonData = jsonDecode(requestData);
      //print('🔧 [AIPromptPreset.parsedRequest] 解析requestData成功，字段: ${jsonData.keys.toList()}');

      // 使用UniversalAIRequest.fromJson创建对象
      final request = UniversalAIRequest.fromJson(jsonData);
      //print('🔧 [AIPromptPreset.parsedRequest] 创建UniversalAIRequest成功');
      //print('  - requestType: ${request.requestType.value}');
      //print('  - userId: ${request.userId}');
      //print('  - novelId: ${request.novelId}');
      //print('  - sessionId: ${request.sessionId}');
      //print('  - enableSmartContext: ${request.enableSmartContext}');
      //print('  - contextSelections: ${request.contextSelections?.selectedCount ?? 0}个选择');
      //print('  - parameters: ${request.parameters.keys.toList()}');
      //print('  - parameters.enableSmartContext: ${request.parameters['enableSmartContext']}');
      //print('  - 原始JSON.enableSmartContext: ${jsonData['enableSmartContext']}');

      return request;
    } catch (e, stackTrace) {
      //print('❌ [AIPromptPreset.parsedRequest] 解析requestData失败: $e');
      //print('requestData内容: $requestData');
      //print('堆栈信息: $stackTrace');
      return null;
    }
  }

  /// 🚀 新增：检查requestData是否有效
  bool get hasValidRequestData {
    try {
      if (requestData.isEmpty) return false;
      jsonDecode(requestData);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 🚀 新增：获取预设的显示名称（优先使用presetName，否则使用默认格式）
  String get displayName {
    if (presetName != null && presetName!.isNotEmpty) {
      return presetName!;
    }
    
    // 根据功能类型生成默认名称
    final featureDisplayName = _getFeatureDisplayName(aiFeatureType);
    final timestamp = createdAt.toString().substring(0, 16);
    return '$featureDisplayName - $timestamp';
  }

  /// 获取功能类型的显示名称
  String _getFeatureDisplayName(String featureType) {
    try {
      // 🚀 使用AIFeatureTypeHelper标准方法解析，然后获取显示名称
      final aiFeatureType = AIFeatureTypeHelper.fromApiString(featureType.toUpperCase());
      return aiFeatureType.displayName;
    } catch (e) {
      AppLogger.e('AIPromptPreset', '解析功能类型失败: $e');
      return '未知类型';
    }
  }

  /// 从JSON创建对象
  factory AIPromptPreset.fromJson(Map<String, dynamic> json) {
    try {
      //print('🔧 [AIPromptPreset.fromJson] 开始解析预设JSON');
      //print('📋 预设字段: ${json.keys.toList()}');
      
      // 检查必需字段
      final presetId = json['presetId'];
      final userId = json['userId'];
      final presetHash = json['presetHash'];
      final requestData = json['requestData'];
      final systemPrompt = json['systemPrompt'];
      final userPrompt = json['userPrompt'];
      final aiFeatureType = json['aiFeatureType'];
      final createdAt = json['createdAt'];
      final updatedAt = json['updatedAt'];
      
      //print('🔍 必需字段检查:');
      //print('  - presetId: ${presetId != null ? "✅" : "❌"} ($presetId)');
      //print('  - userId: ${userId != null ? "✅" : "❌"} ($userId)');
      //print('  - presetHash: ${presetHash != null ? "✅" : "❌"} ($presetHash)');
      //print('  - requestData: ${requestData != null ? "✅" : "❌"} (长度: ${requestData?.toString().length ?? 0})');
      //print('  - systemPrompt: ${systemPrompt != null ? "✅" : "❌"} (长度: ${systemPrompt?.toString().length ?? 0})');
      //print('  - userPrompt: ${userPrompt != null ? "✅" : "❌"} (长度: ${userPrompt?.toString().length ?? 0})');
      //print('  - aiFeatureType: ${aiFeatureType != null ? "✅" : "❌"} ($aiFeatureType)');
      //print('  - createdAt: ${createdAt != null ? "✅" : "❌"} ($createdAt)');
      //print('  - updatedAt: ${updatedAt != null ? "✅" : "❌"} ($updatedAt)');
      
      // 检查可选字段
      //print('🔍 可选字段检查:');
      //print('  - presetName: ${json['presetName']}');
      //print('  - presetDescription: ${json['presetDescription']}');
      //print('  - templateId: ${json['templateId']}');
      //print('  - customSystemPrompt: ${json['customSystemPrompt']}');
      //print('  - customUserPrompt: ${json['customUserPrompt']}');
      //print('  - lastUsedAt: ${json['lastUsedAt']}');
      
      // 开始创建对象
      //print('🏗️  开始创建AIPromptPreset对象');
      
      return AIPromptPreset(
        presetId: presetId as String,
        userId: userId as String,
        presetName: json['presetName'] as String?,
        presetDescription: json['presetDescription'] as String?,
        presetTags: (json['presetTags'] as List<dynamic>?)?.cast<String>(),
        isFavorite: json['isFavorite'] as bool? ?? false,
        isPublic: json['isPublic'] as bool? ?? false,
        useCount: json['useCount'] as int? ?? 0,
        presetHash: presetHash as String? ?? presetId as String, // 如果presetHash为null，使用presetId作为默认值
        requestData: requestData as String,
        systemPrompt: systemPrompt as String,
        userPrompt: userPrompt as String,
        aiFeatureType: aiFeatureType as String,
        templateId: json['templateId'] as String?,
        isSystem: json['isSystem'] as bool? ?? false,
        showInQuickAccess: json['showInQuickAccess'] as bool? ?? false,
        customSystemPrompt: json['customSystemPrompt'] as String?,
        customUserPrompt: json['customUserPrompt'] as String?,
        promptCustomized: json['promptCustomized'] as bool? ?? false,
        createdAt: parseBackendDateTime(createdAt),
        updatedAt: parseBackendDateTime(updatedAt),
        lastUsedAt: json['lastUsedAt'] != null ? parseBackendDateTime(json['lastUsedAt']) : null,
      );
    } catch (e, stackTrace) {
      //print('❌ [AIPromptPreset.fromJson] 解析失败: $e');
      ////print('📋 JSON内容: $json');
      //print('🔍 堆栈信息: $stackTrace');
      rethrow;
    }
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'presetId': presetId,
      'userId': userId,
      'presetName': presetName,
      'presetDescription': presetDescription,
      'presetTags': presetTags,
      'isFavorite': isFavorite,
      'isPublic': isPublic,
      'useCount': useCount,
      'presetHash': presetHash,
      'requestData': requestData,
      'systemPrompt': systemPrompt,
      'userPrompt': userPrompt,
      'aiFeatureType': aiFeatureType,
      'templateId': templateId,
      'isSystem': isSystem,
      'showInQuickAccess': showInQuickAccess,
      'customSystemPrompt': customSystemPrompt,
      'customUserPrompt': customUserPrompt,
      'promptCustomized': promptCustomized,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  /// 复制并更新预设
  AIPromptPreset copyWith({
    String? presetId,
    String? userId,
    String? presetName,
    String? presetDescription,
    List<String>? presetTags,
    bool? isFavorite,
    bool? isPublic,
    int? useCount,
    String? presetHash,
    String? requestData,
    String? systemPrompt,
    String? userPrompt,
    String? aiFeatureType,
    String? templateId,
    bool? isSystem,
    bool? showInQuickAccess,
    String? customSystemPrompt,
    String? customUserPrompt,
    bool? promptCustomized,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
  }) {
    return AIPromptPreset(
      presetId: presetId ?? this.presetId,
      userId: userId ?? this.userId,
      presetName: presetName ?? this.presetName,
      presetDescription: presetDescription ?? this.presetDescription,
      presetTags: presetTags ?? this.presetTags,
      isFavorite: isFavorite ?? this.isFavorite,
      isPublic: isPublic ?? this.isPublic,
      useCount: useCount ?? this.useCount,
      presetHash: presetHash ?? this.presetHash,
      requestData: requestData ?? this.requestData,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      userPrompt: userPrompt ?? this.userPrompt,
      aiFeatureType: aiFeatureType ?? this.aiFeatureType,
      templateId: templateId ?? this.templateId,
      isSystem: isSystem ?? this.isSystem,
      showInQuickAccess: showInQuickAccess ?? this.showInQuickAccess,
      customSystemPrompt: customSystemPrompt ?? this.customSystemPrompt,
      customUserPrompt: customUserPrompt ?? this.customUserPrompt,
      promptCustomized: promptCustomized ?? this.promptCustomized,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

/// 创建预设请求
class CreatePresetRequest {
  /// 预设名称
  final String presetName;
  
  /// 预设描述
  final String? presetDescription;
  
  /// 预设标签
  final List<String>? presetTags;
  
  /// AI请求配置
  final UniversalAIRequest request;

  CreatePresetRequest({
    required this.presetName,
    this.presetDescription,
    this.presetTags,
    required this.request,
  });

  Map<String, dynamic> toJson() {
    return {
      'presetName': presetName,
      'presetDescription': presetDescription,
      'presetTags': presetTags,
      'request': request.toApiJson(),
    };
  }
}

/// 更新预设信息请求
class UpdatePresetInfoRequest {
  /// 预设名称
  final String presetName;
  
  /// 预设描述
  final String? presetDescription;
  
  /// 预设标签
  final List<String>? presetTags;

  UpdatePresetInfoRequest({
    required this.presetName,
    this.presetDescription,
    this.presetTags,
  });

  Map<String, dynamic> toJson() {
    return {
      'presetName': presetName,
      'presetDescription': presetDescription,
      'presetTags': presetTags,
    };
  }
}

/// 更新预设提示词请求
class UpdatePresetPromptsRequest {
  /// 自定义系统提示词
  final String? customSystemPrompt;
  
  /// 自定义用户提示词
  final String? customUserPrompt;

  UpdatePresetPromptsRequest({
    this.customSystemPrompt,
    this.customUserPrompt,
  });

  Map<String, dynamic> toJson() {
    return {
      'customSystemPrompt': customSystemPrompt,
      'customUserPrompt': customUserPrompt,
    };
  }
}

/// 复制预设请求
class DuplicatePresetRequest {
  /// 新预设名称
  final String newPresetName;

  DuplicatePresetRequest({
    required this.newPresetName,
  });

  Map<String, dynamic> toJson() {
    return {
      'newPresetName': newPresetName,
    };
  }
}

/// 预设统计信息
class PresetStatistics {
  /// 总预设数
  final int totalPresets;
  
  /// 收藏预设数
  final int favoritePresets;
  
  /// 最近使用预设数
  final int recentlyUsedPresets;
  
  /// 按功能类型分组的预设数
  final Map<String, int> presetsByFeatureType;
  
  /// 热门标签
  final List<String> popularTags;

  PresetStatistics({
    required this.totalPresets,
    required this.favoritePresets,
    required this.recentlyUsedPresets,
    required this.presetsByFeatureType,
    required this.popularTags,
  });

  factory PresetStatistics.fromJson(Map<String, dynamic> json) {
    return PresetStatistics(
      totalPresets: json['totalPresets'] as int? ?? 0,
      favoritePresets: json['favoritePresets'] as int? ?? 0,
      recentlyUsedPresets: json['recentlyUsedPresets'] as int? ?? 0,
      presetsByFeatureType: Map<String, int>.from(json['presetsByFeatureType'] ?? {}),
      popularTags: (json['popularTags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPresets': totalPresets,
      'favoritePresets': favoritePresets,
      'recentlyUsedPresets': recentlyUsedPresets,
      'presetsByFeatureType': presetsByFeatureType,
      'popularTags': popularTags,
    };
  }
}

/// 预设搜索参数
class PresetSearchParams {
  /// 关键词
  final String? keyword;
  
  /// 标签过滤
  final List<String>? tags;
  
  /// 功能类型过滤
  final String? featureType;
  
  /// 排序方式
  final String sortBy;

  PresetSearchParams({
    this.keyword,
    this.tags,
    this.featureType,
    this.sortBy = 'recent',
  });

  /// 转换为查询参数
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (keyword != null && keyword!.isNotEmpty) {
      params['keyword'] = keyword;
    }
    if (tags != null && tags!.isNotEmpty) {
      params['tags'] = tags;
    }
    if (featureType != null && featureType!.isNotEmpty) {
      params['featureType'] = featureType;
    }
    params['sortBy'] = sortBy;
    
    return params;
  }
}

/// 预设包 - 聚合某个功能类型的所有预设数据
class PresetPackage {
  /// 功能类型
  final String featureType;
  
  /// 系统预设列表
  final List<AIPromptPreset> systemPresets;
  
  /// 用户预设列表
  final List<AIPromptPreset> userPresets;
  
  /// 收藏预设列表
  final List<AIPromptPreset> favoritePresets;
  
  /// 快捷访问预设列表
  final List<AIPromptPreset> quickAccessPresets;
  
  /// 最近使用预设列表
  final List<AIPromptPreset> recentlyUsedPresets;
  
  /// 预设总数
  final int totalCount;
  
  /// 缓存时间戳
  final DateTime cachedAt;

  PresetPackage({
    required this.featureType,
    required this.systemPresets,
    required this.userPresets,
    required this.favoritePresets,
    required this.quickAccessPresets,
    required this.recentlyUsedPresets,
    required this.totalCount,
    required this.cachedAt,
  });

  /// 获取所有预设（去重）
  List<AIPromptPreset> get allPresets {
    final Set<String> seenIds = {};
    final List<AIPromptPreset> result = [];
    
    // 按优先级添加预设
    for (final preset in [...systemPresets, ...userPresets]) {
      if (!seenIds.contains(preset.presetId)) {
        seenIds.add(preset.presetId);
        result.add(preset);
      }
    }
    
    return result;
  }

  factory PresetPackage.fromJson(Map<String, dynamic> json) {
    try {
      //print('📦 [PresetPackage.fromJson] 解析预设包: ${json['featureType']}');
      
      return PresetPackage(
        featureType: json['featureType'] as String,
        systemPresets: (json['systemPresets'] as List<dynamic>?)
            ?.map((e) => AIPromptPreset.fromJson(e))
            .toList() ?? [],
        userPresets: (json['userPresets'] as List<dynamic>?)
            ?.map((e) => AIPromptPreset.fromJson(e))
            .toList() ?? [],
        favoritePresets: (json['favoritePresets'] as List<dynamic>?)
            ?.map((e) => AIPromptPreset.fromJson(e))
            .toList() ?? [],
        quickAccessPresets: (json['quickAccessPresets'] as List<dynamic>?)
            ?.map((e) => AIPromptPreset.fromJson(e))
            .toList() ?? [],
        recentlyUsedPresets: (json['recentlyUsedPresets'] as List<dynamic>?)
            ?.map((e) => AIPromptPreset.fromJson(e))
            .toList() ?? [],
        totalCount: json['totalCount'] as int? ?? 0,
        cachedAt: parseBackendDateTime(json['cachedAt']),
      );
    } catch (e, stackTrace) {
      //print('❌ [PresetPackage.fromJson] 解析失败: $e');
      //print('📋 JSON内容: $json');
      //print('🔍 堆栈信息: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'featureType': featureType,
      'systemPresets': systemPresets.map((e) => e.toJson()).toList(),
      'userPresets': userPresets.map((e) => e.toJson()).toList(),
      'favoritePresets': favoritePresets.map((e) => e.toJson()).toList(),
      'quickAccessPresets': quickAccessPresets.map((e) => e.toJson()).toList(),
      'recentlyUsedPresets': recentlyUsedPresets.map((e) => e.toJson()).toList(),
      'totalCount': totalCount,
      'cachedAt': cachedAt.toIso8601String(),
    };
  }
}

/// 用户预设概览 - 跨功能统计信息
class UserPresetOverview {
  /// 总预设数
  final int totalPresets;
  
  /// 系统预设数
  final int systemPresets;
  
  /// 用户预设数
  final int userPresets;
  
  /// 收藏预设数
  final int favoritePresets;
  
  /// 按功能类型分组的统计
  final Map<String, PresetTypeStats> presetsByFeatureType;
  
  /// 最近活跃的功能类型
  final List<String> recentFeatureTypes;
  
  /// 热门标签
  final List<TagStats> popularTags;
  
  /// 统计时间
  final DateTime generatedAt;

  UserPresetOverview({
    required this.totalPresets,
    required this.systemPresets,
    required this.userPresets,
    required this.favoritePresets,
    required this.presetsByFeatureType,
    required this.recentFeatureTypes,
    required this.popularTags,
    required this.generatedAt,
  });

  factory UserPresetOverview.fromJson(Map<String, dynamic> json) {
    try {
      //print('📊 [UserPresetOverview.fromJson] 开始解析概览数据');
      //print('📋 概览字段: ${json.keys.toList()}');
      
      // 解析presetsByFeatureType
      Map<String, PresetTypeStats> presetsByFeatureType = {};
      if (json['presetsByFeatureType'] != null) {
        //print('📊 解析presetsByFeatureType...');
        presetsByFeatureType = (json['presetsByFeatureType'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, PresetTypeStats.fromJson(v))) ?? {};
        //print('✅ presetsByFeatureType解析成功，包含${presetsByFeatureType.length}个功能类型');
      }
      
      // 解析popularTags
      List<TagStats> popularTags = [];
      if (json['popularTags'] != null) {
        //print('🏷️  解析popularTags，数量: ${(json['popularTags'] as List?)?.length ?? 0}');
        popularTags = (json['popularTags'] as List<dynamic>?)
            ?.map((e) => TagStats.fromJson(e))
            .toList() ?? [];
        //print('✅ popularTags解析成功，共${popularTags.length}个标签');
      }
      
      return UserPresetOverview(
        totalPresets: json['totalPresets'] as int? ?? 0,
        systemPresets: json['systemPresets'] as int? ?? 0,
        userPresets: json['userPresets'] as int? ?? 0,
        favoritePresets: json['favoritePresets'] as int? ?? 0,
        presetsByFeatureType: presetsByFeatureType,
        recentFeatureTypes: (json['recentFeatureTypes'] as List<dynamic>?)?.cast<String>() ?? [],
        popularTags: popularTags,
        generatedAt: parseBackendDateTime(json['generatedAt']),
      );
    } catch (e, stackTrace) {
      //print('❌ [UserPresetOverview.fromJson] 解析失败: $e');
      //print('📋 JSON内容: $json');
      //print('🔍 堆栈信息: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPresets': totalPresets,
      'systemPresets': systemPresets,
      'userPresets': userPresets,
      'favoritePresets': favoritePresets,
      'presetsByFeatureType': presetsByFeatureType.map((k, v) => MapEntry(k, v.toJson())),
      'recentFeatureTypes': recentFeatureTypes,
      'popularTags': popularTags.map((e) => e.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

/// 功能类型预设统计
class PresetTypeStats {
  /// 系统预设数
  final int systemCount;
  
  /// 用户预设数
  final int userCount;
  
  /// 收藏预设数
  final int favoriteCount;
  
  /// 最近使用次数
  final int recentUsageCount;

  PresetTypeStats({
    required this.systemCount,
    required this.userCount,
    required this.favoriteCount,
    required this.recentUsageCount,
  });

  factory PresetTypeStats.fromJson(Map<String, dynamic> json) {
    return PresetTypeStats(
      systemCount: json['systemCount'] as int? ?? 0,
      userCount: json['userCount'] as int? ?? 0,
      favoriteCount: json['favoriteCount'] as int? ?? 0,
      recentUsageCount: json['recentUsageCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'systemCount': systemCount,
      'userCount': userCount,
      'favoriteCount': favoriteCount,
      'recentUsageCount': recentUsageCount,
    };
  }
}

/// 标签统计
class TagStats {
  /// 标签名称
  final String tagName;
  
  /// 使用次数
  final int usageCount;

  TagStats({
    required this.tagName,
    required this.usageCount,
  });

  factory TagStats.fromJson(Map<String, dynamic> json) {
    try {
      //print('🏷️  [TagStats.fromJson] 解析标签统计: ${json}');
      
      final tagName = json['tagName'];
      if (tagName == null) {
        //print('❌ [TagStats.fromJson] tagName字段为null');
        throw Exception('tagName字段为null');
      }
      
      return TagStats(
        tagName: tagName as String,
        usageCount: json['usageCount'] as int? ?? 0,
      );
    } catch (e, stackTrace) {
      //print('❌ [TagStats.fromJson] 解析失败: $e');
      //print('📋 JSON内容: $json');
      //print('🔍 堆栈信息: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tagName': tagName,
      'usageCount': usageCount,
    };
  }
}

/// 缓存预热结果
class CacheWarmupResult {
  /// 是否成功
  final bool success;
  
  /// 预热的功能类型数量
  final int warmedFeatureTypes;
  
  /// 预热的预设数量
  final int warmedPresets;
  
  /// 耗时（毫秒）
  final int durationMs;
  
  /// 错误信息
  final String? errorMessage;

  CacheWarmupResult({
    required this.success,
    required this.warmedFeatureTypes,
    required this.warmedPresets,
    required this.durationMs,
    this.errorMessage,
  });

  factory CacheWarmupResult.fromJson(Map<String, dynamic> json) {
    return CacheWarmupResult(
      success: json['success'] as bool? ?? false,
      warmedFeatureTypes: json['warmedFeatureTypes'] as int? ?? 0,
      warmedPresets: json['warmedPresets'] as int? ?? 0,
      durationMs: json['durationMs'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'warmedFeatureTypes': warmedFeatureTypes,
      'warmedPresets': warmedPresets,
      'durationMs': durationMs,
      'errorMessage': errorMessage,
    };
  }
}

/// 聚合缓存统计
class AggregationCacheStats {
  /// 缓存命中率
  final double hitRate;
  
  /// 缓存条目数
  final int cacheEntries;
  
  /// 缓存大小（字节）
  final int cacheSizeBytes;
  
  /// 最后更新时间
  final DateTime lastUpdated;

  AggregationCacheStats({
    required this.hitRate,
    required this.cacheEntries,
    required this.cacheSizeBytes,
    required this.lastUpdated,
  });

  factory AggregationCacheStats.fromJson(Map<String, dynamic> json) {
    return AggregationCacheStats(
      hitRate: (json['hitRate'] as num?)?.toDouble() ?? 0.0,
      cacheEntries: json['cacheEntries'] as int? ?? 0,
      cacheSizeBytes: json['cacheSizeBytes'] as int? ?? 0,
      lastUpdated: parseBackendDateTime(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hitRate': hitRate,
      'cacheEntries': cacheEntries,
      'cacheSizeBytes': cacheSizeBytes,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// 用户所有预设聚合数据
/// 🚀 一次性包含用户的所有预设相关数据，避免多次API调用
class AllUserPresetData {
  /// 用户ID
  final String userId;
  
  /// 用户预设概览统计
  final UserPresetOverview overview;
  
  /// 按功能类型分组的预设包
  final Map<String, PresetPackage> packagesByFeatureType;
  
  /// 系统预设列表（所有功能类型）
  final List<AIPromptPreset> systemPresets;
  
  /// 用户预设按功能类型分组
  final Map<String, List<AIPromptPreset>> userPresetsByFeatureType;
  
  /// 收藏预设列表
  final List<AIPromptPreset> favoritePresets;
  
  /// 快捷访问预设列表
  final List<AIPromptPreset> quickAccessPresets;
  
  /// 最近使用预设列表
  final List<AIPromptPreset> recentlyUsedPresets;
  
  /// 数据生成时间戳
  final DateTime timestamp;
  
  /// 缓存时长（毫秒）
  final int cacheDuration;

  AllUserPresetData({
    required this.userId,
    required this.overview,
    required this.packagesByFeatureType,
    required this.systemPresets,
    required this.userPresetsByFeatureType,
    required this.favoritePresets,
    required this.quickAccessPresets,
    required this.recentlyUsedPresets,
    required this.timestamp,
    required this.cacheDuration,
  });

  /// 获取所有预设（去重）
  List<AIPromptPreset> get allPresets {
    final Set<String> seenIds = {};
    final List<AIPromptPreset> result = [];
    
    // 按优先级添加预设：系统预设 -> 用户预设
    for (final preset in [...systemPresets, ...userPresetsByFeatureType.values.expand((list) => list)]) {
      if (!seenIds.contains(preset.presetId)) {
        seenIds.add(preset.presetId);
        result.add(preset);
      }
    }
    
    return result;
  }

  /// 获取指定功能类型的所有预设（系统+用户）
  List<AIPromptPreset> getPresetsByFeatureType(String featureType) {
    final systemPresetsForFeature = systemPresets
        .where((preset) => preset.aiFeatureType == featureType)
        .toList();
    final userPresetsForFeature = userPresetsByFeatureType[featureType] ?? [];
    
    return [...systemPresetsForFeature, ...userPresetsForFeature];
  }

  /// 获取合并后的分组预设（系统+用户）
  Map<String, List<AIPromptPreset>> get mergedGroupedPresets {
    final Map<String, List<AIPromptPreset>> merged = {};
    
    // 先添加系统预设
    for (final preset in systemPresets) {
      final featureType = preset.aiFeatureType;
      if (!merged.containsKey(featureType)) {
        merged[featureType] = [];
      }
      merged[featureType]!.add(preset);
    }
    
    // 再添加用户预设
    userPresetsByFeatureType.forEach((featureType, presets) {
      if (!merged.containsKey(featureType)) {
        merged[featureType] = [];
      }
      merged[featureType]!.addAll(presets);
    });
    
    return merged;
  }

  factory AllUserPresetData.fromJson(Map<String, dynamic> json) {
    //print('🔧 [AllUserPresetData.fromJson] 开始解析聚合数据JSON');
    //print('📋 JSON顶层字段: ${json.keys.toList()}');
    
    try {
      // 检查必需字段
      if (json['userId'] == null) {
        throw Exception('userId字段为null');
      }
      if (json['overview'] == null) {
        throw Exception('overview字段为null');
      }
      if (json['timestamp'] == null) {
        throw Exception('timestamp字段为null');
      }
      
      //print('✅ 必需字段检查通过: userId=${json['userId']}, timestamp=${json['timestamp']}');
      
      // 解析按功能类型分组的预设包
      final packagesMap = <String, PresetPackage>{};
      if (json['packagesByFeatureType'] != null) {
        //print('📦 开始解析packagesByFeatureType');
        final packagesJson = json['packagesByFeatureType'] as Map<String, dynamic>;
        //print('📦 包含的功能类型: ${packagesJson.keys.toList()}');
        
        packagesJson.forEach((key, value) {
          try {
            //print('📦 解析功能类型: $key');
            packagesMap[key] = PresetPackage.fromJson(value);
            //print('✅ 功能类型 $key 解析成功');
          } catch (e) {
            //print('❌ 功能类型 $key 解析失败: $e');
            throw Exception('功能类型 $key 解析失败: $e');
          }
        });
      } else {
        //print('⚠️  packagesByFeatureType 为 null');
      }

      // 解析用户预设按功能类型分组
      final userPresetsGroupedMap = <String, List<AIPromptPreset>>{};
      if (json['userPresetsByFeatureType'] != null) {
        //print('👤 开始解析userPresetsByFeatureType');
        final groupedJson = json['userPresetsByFeatureType'] as Map<String, dynamic>;
        //print('👤 包含的功能类型: ${groupedJson.keys.toList()}');
        
        groupedJson.forEach((key, value) {
          try {
            //print('👤 解析用户预设功能类型: $key, 预设数量: ${(value as List).length}');
            userPresetsGroupedMap[key] = (value as List<dynamic>)
                .map((item) => AIPromptPreset.fromJson(item))
                .toList();
            //print('✅ 用户预设功能类型 $key 解析成功，共${userPresetsGroupedMap[key]!.length}个预设');
          } catch (e) {
            //print('❌ 用户预设功能类型 $key 解析失败: $e');
            throw Exception('用户预设功能类型 $key 解析失败: $e');
          }
        });
      } else {
        //print('⚠️  userPresetsByFeatureType 为 null');
      }

      // 解析overview
      UserPresetOverview overview;
      try {
        //print('📊 开始解析overview');
        overview = UserPresetOverview.fromJson(json['overview']);
        //print('✅ overview解析成功');
      } catch (e) {
        //print('❌ overview解析失败: $e');
        throw Exception('overview解析失败: $e');
      }

      // 解析各种预设列表
      List<AIPromptPreset> systemPresets = [];
      List<AIPromptPreset> favoritePresets = [];
      List<AIPromptPreset> quickAccessPresets = [];
      List<AIPromptPreset> recentlyUsedPresets = [];

      try {
        //print('🔧 开始解析systemPresets，数量: ${(json['systemPresets'] as List?)?.length ?? 0}');
        systemPresets = (json['systemPresets'] as List<dynamic>?)
            ?.map((item) => AIPromptPreset.fromJson(item))
            .toList() ?? [];
        //print('✅ systemPresets解析成功，共${systemPresets.length}个');
      } catch (e) {
        //print('❌ systemPresets解析失败: $e');
        throw Exception('systemPresets解析失败: $e');
      }

      try {
        //print('⭐ 开始解析favoritePresets，数量: ${(json['favoritePresets'] as List?)?.length ?? 0}');
        favoritePresets = (json['favoritePresets'] as List<dynamic>?)
            ?.map((item) => AIPromptPreset.fromJson(item))
            .toList() ?? [];
        //print('✅ favoritePresets解析成功，共${favoritePresets.length}个');
      } catch (e) {
        //print('❌ favoritePresets解析失败: $e');
        throw Exception('favoritePresets解析失败: $e');
      }

      try {
        //print('⚡ 开始解析quickAccessPresets，数量: ${(json['quickAccessPresets'] as List?)?.length ?? 0}');
        quickAccessPresets = (json['quickAccessPresets'] as List<dynamic>?)
            ?.map((item) => AIPromptPreset.fromJson(item))
            .toList() ?? [];
        //print('✅ quickAccessPresets解析成功，共${quickAccessPresets.length}个');
      } catch (e) {
        //print('❌ quickAccessPresets解析失败: $e');
        throw Exception('quickAccessPresets解析失败: $e');
      }

      try {
        //print('⏰ 开始解析recentlyUsedPresets，数量: ${(json['recentlyUsedPresets'] as List?)?.length ?? 0}');
        recentlyUsedPresets = (json['recentlyUsedPresets'] as List<dynamic>?)
            ?.map((item) => AIPromptPreset.fromJson(item))
            .toList() ?? [];
        //print('✅ recentlyUsedPresets解析成功，共${recentlyUsedPresets.length}个');
      } catch (e) {
        //print('❌ recentlyUsedPresets解析失败: $e');
        throw Exception('recentlyUsedPresets解析失败: $e');
      }

      //print('🎉 [AllUserPresetData.fromJson] 解析完成，创建对象');
      
      return AllUserPresetData(
        userId: json['userId'] as String,
        overview: overview,
        packagesByFeatureType: packagesMap,
        systemPresets: systemPresets,
        userPresetsByFeatureType: userPresetsGroupedMap,
        favoritePresets: favoritePresets,
        quickAccessPresets: quickAccessPresets,
        recentlyUsedPresets: recentlyUsedPresets,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        cacheDuration: json['cacheDuration'] as int? ?? 0,
      );
    } catch (e, stackTrace) {
      //print('❌ [AllUserPresetData.fromJson] 解析失败: $e');
      //print('📋 JSON内容: $json');
      //print('🔍 堆栈信息: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'overview': overview.toJson(),
      'packagesByFeatureType': packagesByFeatureType.map((k, v) => MapEntry(k, v.toJson())),
      'systemPresets': systemPresets.map((e) => e.toJson()).toList(),
      'userPresetsByFeatureType': userPresetsByFeatureType.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
      'favoritePresets': favoritePresets.map((e) => e.toJson()).toList(),
      'quickAccessPresets': quickAccessPresets.map((e) => e.toJson()).toList(),
      'recentlyUsedPresets': recentlyUsedPresets.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'cacheDuration': cacheDuration,
    };
  }
}

/// 功能预设列表响应
class PresetListResponse {
  /// 收藏的预设列表（最多5个）
  final List<PresetItemWithTag> favorites;
  
  /// 最近使用的预设列表（最多5个）
  final List<PresetItemWithTag> recentUsed;
  
  /// 推荐的预设列表（补充用，最近创建的）
  final List<PresetItemWithTag> recommended;

  const PresetListResponse({
    required this.favorites,
    required this.recentUsed,
    required this.recommended,
  });

  factory PresetListResponse.fromJson(Map<String, dynamic> json) {
    return PresetListResponse(
      favorites: (json['favorites'] as List<dynamic>?)
          ?.map((e) => PresetItemWithTag.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      recentUsed: (json['recentUsed'] as List<dynamic>?)
          ?.map((e) => PresetItemWithTag.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      recommended: (json['recommended'] as List<dynamic>?)
          ?.map((e) => PresetItemWithTag.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favorites': favorites.map((e) => e.toJson()).toList(),
      'recentUsed': recentUsed.map((e) => e.toJson()).toList(),
      'recommended': recommended.map((e) => e.toJson()).toList(),
    };
  }

  /// 获取所有预设项的扁平列表
  List<PresetItemWithTag> getAllItems() {
    return [...favorites, ...recentUsed, ...recommended];
  }

  /// 获取总数量
  int get totalCount => favorites.length + recentUsed.length + recommended.length;
}

/// 带标签的预设项
class PresetItemWithTag {
  /// 预设信息
  final AIPromptPreset preset;
  
  /// 是否收藏
  final bool isFavorite;
  
  /// 是否最近使用
  final bool isRecentUsed;
  
  /// 是否推荐项
  final bool isRecommended;

  const PresetItemWithTag({
    required this.preset,
    required this.isFavorite,
    required this.isRecentUsed,
    required this.isRecommended,
  });

  factory PresetItemWithTag.fromJson(Map<String, dynamic> json) {
    return PresetItemWithTag(
      preset: AIPromptPreset.fromJson(json['preset'] as Map<String, dynamic>),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isRecentUsed: json['isRecentUsed'] as bool? ?? false,
      isRecommended: json['isRecommended'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preset': preset.toJson(),
      'isFavorite': isFavorite,
      'isRecentUsed': isRecentUsed,
      'isRecommended': isRecommended,
    };
  }

  /// 获取标签列表
  List<String> getTags() {
    List<String> tags = [];
    if (isFavorite) tags.add('收藏');
    if (isRecentUsed) tags.add('最近使用');
    if (isRecommended) tags.add('推荐');
    return tags;
  }

  /// 获取主要标签（优先级：收藏 > 最近使用 > 推荐）
  String? getPrimaryTag() {
    if (isFavorite) return '收藏';
    if (isRecentUsed) return '最近使用';
    if (isRecommended) return '推荐';
    return null;
  }
} 