part of 'novel_import_bloc.dart';

/// 小说导入事件基类
abstract class NovelImportEvent extends Equatable {
  const NovelImportEvent();

  @override
  List<Object?> get props => [];
}

/// 第一步：上传文件获取预览
class UploadFileForPreview extends NovelImportEvent {
  const UploadFileForPreview();
}

/// 第二步：获取导入预览
class GetImportPreview extends NovelImportEvent {
  const GetImportPreview({
    required this.previewSessionId,
    this.customTitle,
    this.chapterLimit,
    this.enableSmartContext = true,
    this.enableAISummary = false,
    this.aiConfigId,
    this.previewChapterCount = 10,
    required this.fileName,
  });

  final String previewSessionId;
  final String? customTitle;
  final int? chapterLimit;
  final bool enableSmartContext;
  final bool enableAISummary;
  final String? aiConfigId;
  final int previewChapterCount;
  final String fileName;

  @override
  List<Object?> get props => [
        previewSessionId,
        customTitle,
        chapterLimit,
        enableSmartContext,
        enableAISummary,
        aiConfigId,
        previewChapterCount,
        fileName,
      ];
}

/// 第三步：确认并开始导入
class ConfirmAndStartImport extends NovelImportEvent {
  const ConfirmAndStartImport({
    required this.previewSessionId,
    required this.finalTitle,
    this.selectedChapterIndexes,
    this.enableSmartContext = true,
    this.enableAISummary = false,
    this.aiConfigId,
  });

  final String previewSessionId;
  final String finalTitle;
  final List<int>? selectedChapterIndexes;
  final bool enableSmartContext;
  final bool enableAISummary;
  final String? aiConfigId;

  @override
  List<Object?> get props => [
        previewSessionId,
        finalTitle,
        selectedChapterIndexes,
        enableSmartContext,
        enableAISummary,
        aiConfigId,
      ];
}

/// 导入状态更新事件
class ImportStatusUpdate extends NovelImportEvent {
  const ImportStatusUpdate({
    required this.status,
    required this.message,
    required this.jobId,
    this.progress,
    this.currentStep,
    this.processedChapters,
    this.totalChapters,
  });

  final String status;
  final String message;
  final String jobId;
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

/// 重置导入状态
class ResetImportState extends NovelImportEvent {
  const ResetImportState();
}

/// 清理预览会话
class CleanupPreviewSession extends NovelImportEvent {
  const CleanupPreviewSession({
    required this.previewSessionId,
  });

  final String previewSessionId;

  @override
  List<Object?> get props => [previewSessionId];
}

/// 传统导入小说文件事件（向后兼容）
class ImportNovelFile extends NovelImportEvent {
  const ImportNovelFile();
} 