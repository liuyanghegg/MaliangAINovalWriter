import 'package:json_annotation/json_annotation.dart';
import 'package:ainoval/utils/date_time_parser.dart';

part 'novel_snippet.g.dart';

/// 小说片段模型
@JsonSerializable()
class NovelSnippet {
  final String id;
  final String userId;
  final String novelId;
  final String title;
  final String content;
  final InitialGenerationInfo? initialGenerationInfo;
  final List<String>? tags;
  final String? category;
  final String? notes;
  final SnippetMetadata metadata;
  final bool isFavorite;
  final String status;
  final int version;
  
  @JsonKey(fromJson: parseBackendDateTime, toJson: _dateTimeToJson)
  final DateTime createdAt;
  
  @JsonKey(fromJson: parseBackendDateTime, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  const NovelSnippet({
    required this.id,
    required this.userId,
    required this.novelId,
    required this.title,
    required this.content,
    this.initialGenerationInfo,
    this.tags,
    this.category,
    this.notes,
    required this.metadata,
    required this.isFavorite,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NovelSnippet.fromJson(Map<String, dynamic> json) =>
      _$NovelSnippetFromJson(json);

  Map<String, dynamic> toJson() => _$NovelSnippetToJson(this);

  static String _dateTimeToJson(DateTime dateTime) => dateTime.toIso8601String();

  NovelSnippet copyWith({
    String? id,
    String? userId,
    String? novelId,
    String? title,
    String? content,
    InitialGenerationInfo? initialGenerationInfo,
    List<String>? tags,
    String? category,
    String? notes,
    SnippetMetadata? metadata,
    bool? isFavorite,
    String? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NovelSnippet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      novelId: novelId ?? this.novelId,
      title: title ?? this.title,
      content: content ?? this.content,
      initialGenerationInfo: initialGenerationInfo ?? this.initialGenerationInfo,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      isFavorite: isFavorite ?? this.isFavorite,
      status: status ?? this.status,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 初始生成信息
@JsonSerializable()
class InitialGenerationInfo {
  final String? sourceChapterId;
  final String? sourceSceneId;

  const InitialGenerationInfo({
    this.sourceChapterId,
    this.sourceSceneId,
  });

  factory InitialGenerationInfo.fromJson(Map<String, dynamic> json) =>
      _$InitialGenerationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$InitialGenerationInfoToJson(this);
}

/// 片段元数据
@JsonSerializable()
class SnippetMetadata {
  final int wordCount;
  final int characterCount;
  final int viewCount;
  final int sortWeight;
  
  @JsonKey(fromJson: _parseOptionalDateTime, toJson: _optionalDateTimeToJson)
  final DateTime? lastViewedAt;

  const SnippetMetadata({
    required this.wordCount,
    required this.characterCount,
    required this.viewCount,
    required this.sortWeight,
    this.lastViewedAt,
  });

  factory SnippetMetadata.fromJson(Map<String, dynamic> json) =>
      _$SnippetMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$SnippetMetadataToJson(this);
  
  static DateTime? _parseOptionalDateTime(dynamic value) {
    return value == null ? null : parseBackendDateTime(value);
  }
  
  static String? _optionalDateTimeToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}

/// 小说片段历史记录
@JsonSerializable()
class NovelSnippetHistory {
  final String id;
  final String snippetId;
  final String userId;
  final String operationType;
  final int version;
  final String? beforeTitle;
  final String? afterTitle;
  final String? beforeContent;
  final String? afterContent;
  final String? changeDescription;
  
  @JsonKey(fromJson: parseBackendDateTime, toJson: _dateTimeToJson)
  final DateTime createdAt;

  const NovelSnippetHistory({
    required this.id,
    required this.snippetId,
    required this.userId,
    required this.operationType,
    required this.version,
    this.beforeTitle,
    this.afterTitle,
    this.beforeContent,
    this.afterContent,
    this.changeDescription,
    required this.createdAt,
  });

  factory NovelSnippetHistory.fromJson(Map<String, dynamic> json) =>
      _$NovelSnippetHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$NovelSnippetHistoryToJson(this);
  
  static String _dateTimeToJson(DateTime dateTime) => dateTime.toIso8601String();
}

/// 分页结果包装类
@JsonSerializable(genericArgumentFactories: true)
class SnippetPageResult<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const SnippetPageResult({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory SnippetPageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$SnippetPageResultFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$SnippetPageResultToJson(this, toJsonT);
}

/// 创建片段请求
@JsonSerializable()
class CreateSnippetRequest {
  final String novelId;
  final String title;
  final String content;
  final String? sourceChapterId;
  final String? sourceSceneId;
  final List<String>? tags;
  final String? category;
  final String? notes;

  const CreateSnippetRequest({
    required this.novelId,
    required this.title,
    required this.content,
    this.sourceChapterId,
    this.sourceSceneId,
    this.tags,
    this.category,
    this.notes,
  });

  factory CreateSnippetRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateSnippetRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSnippetRequestToJson(this);
}

/// 更新片段内容请求
@JsonSerializable()
class UpdateSnippetContentRequest {
  final String snippetId;
  final String content;
  final String? changeDescription;

  const UpdateSnippetContentRequest({
    required this.snippetId,
    required this.content,
    this.changeDescription,
  });

  factory UpdateSnippetContentRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateSnippetContentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateSnippetContentRequestToJson(this);
}

/// 更新片段标题请求
@JsonSerializable()
class UpdateSnippetTitleRequest {
  final String snippetId;
  final String title;
  final String? changeDescription;

  const UpdateSnippetTitleRequest({
    required this.snippetId,
    required this.title,
    this.changeDescription,
  });

  factory UpdateSnippetTitleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateSnippetTitleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateSnippetTitleRequestToJson(this);
}

/// 更新收藏状态请求
@JsonSerializable()
class UpdateSnippetFavoriteRequest {
  final String snippetId;
  final bool isFavorite;

  const UpdateSnippetFavoriteRequest({
    required this.snippetId,
    required this.isFavorite,
  });

  factory UpdateSnippetFavoriteRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateSnippetFavoriteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateSnippetFavoriteRequestToJson(this);
}

/// 回退版本请求
@JsonSerializable()
class RevertSnippetVersionRequest {
  final String snippetId;
  final int version;
  final String? changeDescription;

  const RevertSnippetVersionRequest({
    required this.snippetId,
    required this.version,
    this.changeDescription,
  });

  factory RevertSnippetVersionRequest.fromJson(Map<String, dynamic> json) =>
      _$RevertSnippetVersionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RevertSnippetVersionRequestToJson(this);
} 