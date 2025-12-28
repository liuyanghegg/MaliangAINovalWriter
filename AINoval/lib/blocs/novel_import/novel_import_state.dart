part of 'novel_import_bloc.dart';

/// 小说导入状态基类
abstract class NovelImportState extends Equatable {
  const NovelImportState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class NovelImportInitial extends NovelImportState {}

/// 第一步：上传文件中
class NovelImportUploading extends NovelImportState {
  const NovelImportUploading({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// 第一步完成：文件已上传
class NovelImportFileUploaded extends NovelImportState {
  const NovelImportFileUploaded({
    required this.previewSessionId,
    required this.fileName,
    required this.fileSize,
  });

  final String previewSessionId;
  final String fileName;
  final int fileSize;

  @override
  List<Object?> get props => [previewSessionId, fileName, fileSize];
}

/// 第二步：加载预览中
class NovelImportLoadingPreview extends NovelImportState {
  const NovelImportLoadingPreview({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// 第二步完成：预览准备就绪
class NovelImportPreviewReady extends NovelImportState {
  const NovelImportPreviewReady({
    required this.previewResponse,
    required this.fileName,
  });

  final ImportPreviewResponse previewResponse;
  final String fileName;

  @override
  List<Object?> get props => [previewResponse, fileName];
}

/// 第三步：导入进行中
class NovelImportInProgress extends NovelImportState {
  const NovelImportInProgress({
    required this.status,
    required this.message,
    this.jobId,
    this.progress,
    this.currentStep,
    this.processedChapters,
    this.totalChapters,
  });

  final String status;
  final String message;
  final String? jobId;
  final double? progress;
  final String? currentStep;
  final int? processedChapters;
  final int? totalChapters;

  @override
  List<Object?> get props => [
        status,
        message,
        jobId,
        progress,
        currentStep,
        processedChapters,
        totalChapters,
      ];
}

/// 导入成功
class NovelImportSuccess extends NovelImportState {
  const NovelImportSuccess({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// 导入失败
class NovelImportFailure extends NovelImportState {
  const NovelImportFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// 导入预览响应数据类
class ImportPreviewResponse {
  const ImportPreviewResponse({
    required this.previewSessionId,
    required this.detectedTitle,
    required this.totalChapterCount,
    required this.chapterPreviews,
    required this.totalWordCount,
    this.aiEstimation,
    this.warnings = const [],
  });

  final String previewSessionId;
  final String detectedTitle;
  final int totalChapterCount;
  final List<ChapterPreview> chapterPreviews;
  final int totalWordCount;
  final AIEstimation? aiEstimation;
  final List<String> warnings;

  factory ImportPreviewResponse.fromJson(Map<String, dynamic> json) {
    return ImportPreviewResponse(
      previewSessionId: json['previewSessionId'] as String,
      detectedTitle: json['detectedTitle'] as String,
      totalChapterCount: json['totalChapterCount'] as int,
      chapterPreviews: (json['chapterPreviews'] as List<dynamic>)
          .map((e) => ChapterPreview.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalWordCount: json['totalWordCount'] as int,
      aiEstimation: json['aiEstimation'] != null
          ? AIEstimation.fromJson(json['aiEstimation'] as Map<String, dynamic>)
          : null,
      warnings: json['warnings'] != null 
          ? List<String>.from(json['warnings'] as List<dynamic>)
          : const [],
    );
  }
}

/// 章节预览数据类
class ChapterPreview {
  const ChapterPreview({
    required this.chapterIndex,
    required this.title,
    required this.contentPreview,
    required this.fullContentLength,
    required this.wordCount,
    this.selected = true,
  });

  final int chapterIndex;
  final String title;
  final String contentPreview;
  final int fullContentLength;
  final int wordCount;
  final bool selected;

  factory ChapterPreview.fromJson(Map<String, dynamic> json) {
    return ChapterPreview(
      chapterIndex: json['chapterIndex'] as int,
      title: json['title'] as String,
      contentPreview: json['contentPreview'] as String,
      fullContentLength: json['fullContentLength'] as int,
      wordCount: json['wordCount'] as int,
      selected: json['selected'] as bool? ?? true,
    );
  }

  ChapterPreview copyWith({
    int? chapterIndex,
    String? title,
    String? contentPreview,
    int? fullContentLength,
    int? wordCount,
    bool? selected,
  }) {
    return ChapterPreview(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      title: title ?? this.title,
      contentPreview: contentPreview ?? this.contentPreview,
      fullContentLength: fullContentLength ?? this.fullContentLength,
      wordCount: wordCount ?? this.wordCount,
      selected: selected ?? this.selected,
    );
  }
}

/// AI估算数据类
class AIEstimation {
  const AIEstimation({
    required this.supported,
    this.estimatedTokens,
    this.estimatedCost,
    this.estimatedTimeMinutes,
    this.selectedModel,
    this.limitations,
  });

  final bool supported;
  final int? estimatedTokens;
  final double? estimatedCost;
  final int? estimatedTimeMinutes;
  final String? selectedModel;
  final String? limitations;

  factory AIEstimation.fromJson(Map<String, dynamic> json) {
    return AIEstimation(
      supported: json['supported'] as bool,
      estimatedTokens: json['estimatedTokens'] as int?,
      estimatedCost: json['estimatedCost'] as double?,
      estimatedTimeMinutes: json['estimatedTimeMinutes'] as int?,
      selectedModel: json['selectedModel'] as String?,
      limitations: json['limitations'] as String?,
    );
  }
} 