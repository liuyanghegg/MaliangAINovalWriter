// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novel_snippet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NovelSnippet _$NovelSnippetFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'NovelSnippet',
      json,
      ($checkedConvert) {
        final val = NovelSnippet(
          id: $checkedConvert('id', (v) => v as String),
          userId: $checkedConvert('userId', (v) => v as String),
          novelId: $checkedConvert('novelId', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          initialGenerationInfo: $checkedConvert(
              'initialGenerationInfo',
              (v) => v == null
                  ? null
                  : InitialGenerationInfo.fromJson(v as Map<String, dynamic>)),
          tags: $checkedConvert('tags',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          category: $checkedConvert('category', (v) => v as String?),
          notes: $checkedConvert('notes', (v) => v as String?),
          metadata: $checkedConvert('metadata',
              (v) => SnippetMetadata.fromJson(v as Map<String, dynamic>)),
          isFavorite: $checkedConvert('isFavorite', (v) => v as bool),
          status: $checkedConvert('status', (v) => v as String),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          createdAt:
              $checkedConvert('createdAt', (v) => parseBackendDateTime(v)),
          updatedAt:
              $checkedConvert('updatedAt', (v) => parseBackendDateTime(v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$NovelSnippetToJson(NovelSnippet instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'userId': instance.userId,
    'novelId': instance.novelId,
    'title': instance.title,
    'content': instance.content,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'initialGenerationInfo', instance.initialGenerationInfo?.toJson());
  writeNotNull('tags', instance.tags);
  writeNotNull('category', instance.category);
  writeNotNull('notes', instance.notes);
  val['metadata'] = instance.metadata.toJson();
  val['isFavorite'] = instance.isFavorite;
  val['status'] = instance.status;
  val['version'] = instance.version;
  val['createdAt'] = NovelSnippet._dateTimeToJson(instance.createdAt);
  val['updatedAt'] = NovelSnippet._dateTimeToJson(instance.updatedAt);
  return val;
}

InitialGenerationInfo _$InitialGenerationInfoFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'InitialGenerationInfo',
      json,
      ($checkedConvert) {
        final val = InitialGenerationInfo(
          sourceChapterId:
              $checkedConvert('sourceChapterId', (v) => v as String?),
          sourceSceneId: $checkedConvert('sourceSceneId', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$InitialGenerationInfoToJson(
    InitialGenerationInfo instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('sourceChapterId', instance.sourceChapterId);
  writeNotNull('sourceSceneId', instance.sourceSceneId);
  return val;
}

SnippetMetadata _$SnippetMetadataFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SnippetMetadata',
      json,
      ($checkedConvert) {
        final val = SnippetMetadata(
          wordCount: $checkedConvert('wordCount', (v) => (v as num).toInt()),
          characterCount:
              $checkedConvert('characterCount', (v) => (v as num).toInt()),
          viewCount: $checkedConvert('viewCount', (v) => (v as num).toInt()),
          sortWeight: $checkedConvert('sortWeight', (v) => (v as num).toInt()),
          lastViewedAt: $checkedConvert(
              'lastViewedAt', (v) => SnippetMetadata._parseOptionalDateTime(v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SnippetMetadataToJson(SnippetMetadata instance) {
  final val = <String, dynamic>{
    'wordCount': instance.wordCount,
    'characterCount': instance.characterCount,
    'viewCount': instance.viewCount,
    'sortWeight': instance.sortWeight,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('lastViewedAt',
      SnippetMetadata._optionalDateTimeToJson(instance.lastViewedAt));
  return val;
}

NovelSnippetHistory _$NovelSnippetHistoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'NovelSnippetHistory',
      json,
      ($checkedConvert) {
        final val = NovelSnippetHistory(
          id: $checkedConvert('id', (v) => v as String),
          snippetId: $checkedConvert('snippetId', (v) => v as String),
          userId: $checkedConvert('userId', (v) => v as String),
          operationType: $checkedConvert('operationType', (v) => v as String),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          beforeTitle: $checkedConvert('beforeTitle', (v) => v as String?),
          afterTitle: $checkedConvert('afterTitle', (v) => v as String?),
          beforeContent: $checkedConvert('beforeContent', (v) => v as String?),
          afterContent: $checkedConvert('afterContent', (v) => v as String?),
          changeDescription:
              $checkedConvert('changeDescription', (v) => v as String?),
          createdAt:
              $checkedConvert('createdAt', (v) => parseBackendDateTime(v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$NovelSnippetHistoryToJson(NovelSnippetHistory instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'snippetId': instance.snippetId,
    'userId': instance.userId,
    'operationType': instance.operationType,
    'version': instance.version,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('beforeTitle', instance.beforeTitle);
  writeNotNull('afterTitle', instance.afterTitle);
  writeNotNull('beforeContent', instance.beforeContent);
  writeNotNull('afterContent', instance.afterContent);
  writeNotNull('changeDescription', instance.changeDescription);
  val['createdAt'] = NovelSnippetHistory._dateTimeToJson(instance.createdAt);
  return val;
}

SnippetPageResult<T> _$SnippetPageResultFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    $checkedCreate(
      'SnippetPageResult',
      json,
      ($checkedConvert) {
        final val = SnippetPageResult<T>(
          content: $checkedConvert(
              'content', (v) => (v as List<dynamic>).map(fromJsonT).toList()),
          page: $checkedConvert('page', (v) => (v as num).toInt()),
          size: $checkedConvert('size', (v) => (v as num).toInt()),
          totalElements:
              $checkedConvert('totalElements', (v) => (v as num).toInt()),
          totalPages: $checkedConvert('totalPages', (v) => (v as num).toInt()),
          hasNext: $checkedConvert('hasNext', (v) => v as bool),
          hasPrevious: $checkedConvert('hasPrevious', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$SnippetPageResultToJson<T>(
  SnippetPageResult<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'content': instance.content.map(toJsonT).toList(),
      'page': instance.page,
      'size': instance.size,
      'totalElements': instance.totalElements,
      'totalPages': instance.totalPages,
      'hasNext': instance.hasNext,
      'hasPrevious': instance.hasPrevious,
    };

CreateSnippetRequest _$CreateSnippetRequestFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'CreateSnippetRequest',
      json,
      ($checkedConvert) {
        final val = CreateSnippetRequest(
          novelId: $checkedConvert('novelId', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          sourceChapterId:
              $checkedConvert('sourceChapterId', (v) => v as String?),
          sourceSceneId: $checkedConvert('sourceSceneId', (v) => v as String?),
          tags: $checkedConvert('tags',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          category: $checkedConvert('category', (v) => v as String?),
          notes: $checkedConvert('notes', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$CreateSnippetRequestToJson(
    CreateSnippetRequest instance) {
  final val = <String, dynamic>{
    'novelId': instance.novelId,
    'title': instance.title,
    'content': instance.content,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('sourceChapterId', instance.sourceChapterId);
  writeNotNull('sourceSceneId', instance.sourceSceneId);
  writeNotNull('tags', instance.tags);
  writeNotNull('category', instance.category);
  writeNotNull('notes', instance.notes);
  return val;
}

UpdateSnippetContentRequest _$UpdateSnippetContentRequestFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'UpdateSnippetContentRequest',
      json,
      ($checkedConvert) {
        final val = UpdateSnippetContentRequest(
          snippetId: $checkedConvert('snippetId', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          changeDescription:
              $checkedConvert('changeDescription', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$UpdateSnippetContentRequestToJson(
    UpdateSnippetContentRequest instance) {
  final val = <String, dynamic>{
    'snippetId': instance.snippetId,
    'content': instance.content,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('changeDescription', instance.changeDescription);
  return val;
}

UpdateSnippetTitleRequest _$UpdateSnippetTitleRequestFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'UpdateSnippetTitleRequest',
      json,
      ($checkedConvert) {
        final val = UpdateSnippetTitleRequest(
          snippetId: $checkedConvert('snippetId', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          changeDescription:
              $checkedConvert('changeDescription', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$UpdateSnippetTitleRequestToJson(
    UpdateSnippetTitleRequest instance) {
  final val = <String, dynamic>{
    'snippetId': instance.snippetId,
    'title': instance.title,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('changeDescription', instance.changeDescription);
  return val;
}

UpdateSnippetFavoriteRequest _$UpdateSnippetFavoriteRequestFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'UpdateSnippetFavoriteRequest',
      json,
      ($checkedConvert) {
        final val = UpdateSnippetFavoriteRequest(
          snippetId: $checkedConvert('snippetId', (v) => v as String),
          isFavorite: $checkedConvert('isFavorite', (v) => v as bool),
        );
        return val;
      },
    );

Map<String, dynamic> _$UpdateSnippetFavoriteRequestToJson(
        UpdateSnippetFavoriteRequest instance) =>
    <String, dynamic>{
      'snippetId': instance.snippetId,
      'isFavorite': instance.isFavorite,
    };

RevertSnippetVersionRequest _$RevertSnippetVersionRequestFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'RevertSnippetVersionRequest',
      json,
      ($checkedConvert) {
        final val = RevertSnippetVersionRequest(
          snippetId: $checkedConvert('snippetId', (v) => v as String),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          changeDescription:
              $checkedConvert('changeDescription', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$RevertSnippetVersionRequestToJson(
    RevertSnippetVersionRequest instance) {
  final val = <String, dynamic>{
    'snippetId': instance.snippetId,
    'version': instance.version,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('changeDescription', instance.changeDescription);
  return val;
}
