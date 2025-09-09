import 'dart:async';

import 'package:ainoval/models/import_status.dart';
import 'package:ainoval/models/user_ai_model_config_model.dart';
import 'package:ainoval/services/api_service/repositories/novel_repository.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

part 'novel_import_event.dart';
part 'novel_import_state.dart';

/// 小说导入Bloc - 支持新的三步导入流程
class NovelImportBloc extends Bloc<NovelImportEvent, NovelImportState> {
  /// 创建小说导入Bloc
  NovelImportBloc({required this.novelRepository})
      : super(NovelImportInitial()) {
    // 第一步：上传文件获取预览
    on<UploadFileForPreview>(_onUploadFileForPreview);
    
    // 第二步：获取导入预览
    on<GetImportPreview>(_onGetImportPreview);
    
    // 第三步：确认并开始导入
    on<ConfirmAndStartImport>(_onConfirmAndStartImport);
    
    // 导入状态更新
    on<ImportStatusUpdate>(_onImportStatusUpdate);
    
    // 重置状态
    on<ResetImportState>(_onResetImportState);
    
    // 清理预览会话
    on<CleanupPreviewSession>(_onCleanupPreviewSession);
    
    // 传统导入（向后兼容）
    on<ImportNovelFile>(_onImportNovelFile);
  }

  /// 小说仓库
  final NovelRepository novelRepository;

  /// 导入状态订阅
  StreamSubscription<ImportStatus>? _importStatusSubscription;

  /// 处理上传文件获取预览事件
  Future<void> _onUploadFileForPreview(
      UploadFileForPreview event, Emitter<NovelImportState> emit) async {
    emit(NovelImportUploading(message: '正在上传文件...'));

    try {
      // 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        emit(NovelImportInitial());
        return;
      }

      final file = result.files.first;
      final fileBytes = file.bytes;
      final fileName = file.name;

      if (fileBytes == null) {
        emit(NovelImportFailure(message: '无法读取文件数据'));
        return;
      }

      emit(NovelImportUploading(message: '正在上传文件到服务器...'));

      // 上传文件并获取预览会话ID
      final previewSessionId = await novelRepository.uploadFileForPreview(fileBytes, fileName);

      emit(NovelImportFileUploaded(
        previewSessionId: previewSessionId,
        fileName: fileName,
        fileSize: fileBytes.length,
      ));
    } catch (e) {
      AppLogger.e('NovelImportBloc', '上传文件失败', e);
      emit(NovelImportFailure(message: '上传文件失败: ${e.toString()}'));
    }
  }

  /// 处理获取导入预览事件
  Future<void> _onGetImportPreview(
      GetImportPreview event, Emitter<NovelImportState> emit) async {
    emit(NovelImportLoadingPreview(message: '正在解析文件...'));

    try {
      // 获取导入预览
      final responseData = await novelRepository.getImportPreview(
        fileSessionId: event.previewSessionId,
        customTitle: event.customTitle,
        chapterLimit: event.chapterLimit,
        enableSmartContext: event.enableSmartContext,
        enableAISummary: event.enableAISummary,
        aiConfigId: event.aiConfigId,
        previewChapterCount: event.previewChapterCount,
      );

      // 转换为ImportPreviewResponse对象
      final previewResponse = ImportPreviewResponse.fromJson(responseData);

      emit(NovelImportPreviewReady(
        previewResponse: previewResponse,
        fileName: event.fileName,
      ));
    } catch (e) {
      AppLogger.e('NovelImportBloc', '获取导入预览失败', e);
      emit(NovelImportFailure(message: '获取预览失败: ${e.toString()}'));
    }
  }

  /// 处理确认并开始导入事件
  Future<void> _onConfirmAndStartImport(
      ConfirmAndStartImport event, Emitter<NovelImportState> emit) async {
    emit(NovelImportInProgress(status: 'CONFIRMING', message: '确认导入配置...'));

    try {
      // 确认并开始导入
      final jobId = await novelRepository.confirmAndStartImport(
        previewSessionId: event.previewSessionId,
        finalTitle: event.finalTitle,
        selectedChapterIndexes: event.selectedChapterIndexes,
        enableSmartContext: event.enableSmartContext,
        enableAISummary: event.enableAISummary,
        aiConfigId: event.aiConfigId,
      );

      emit(NovelImportInProgress(
          status: 'PROCESSING', message: '开始处理...', jobId: jobId));

      // 订阅导入状态更新
      _importStatusSubscription?.cancel();
      _importStatusSubscription = novelRepository.getImportStatus(jobId).listen(
        (importStatus) {
          add(ImportStatusUpdate(
            status: importStatus.status,
            message: importStatus.message,
            jobId: jobId,
            progress: importStatus.progress,
            currentStep: importStatus.currentStep,
            processedChapters: importStatus.processedChapters,
            totalChapters: importStatus.totalChapters,
          ));
        },
        onError: (error) {
          AppLogger.e('NovelImportBloc', '监听导入状态流错误', error);
          add(ImportStatusUpdate(
            status: 'FAILED',
            message: '监听导入状态失败: ${error.toString()}',
            jobId: jobId,
          ));
        },
        onDone: () {
          AppLogger.i('NovelImportBloc', '导入状态流已关闭');
        },
      );
    } catch (e) {
      AppLogger.e('NovelImportBloc', '确认导入失败', e);
      emit(NovelImportFailure(message: '确认导入失败: ${e.toString()}'));
    }
  }

  /// 处理导入状态更新事件
  void _onImportStatusUpdate(
      ImportStatusUpdate event, Emitter<NovelImportState> emit) {
    if (event.status == 'COMPLETED') {
      emit(NovelImportSuccess(message: event.message));
      _importStatusSubscription?.cancel();
      _importStatusSubscription = null;
    } else if (event.status == 'FAILED' || event.status == 'ERROR') {
      emit(NovelImportFailure(message: event.message));
      _importStatusSubscription?.cancel();
      _importStatusSubscription = null;
    } else {
      emit(NovelImportInProgress(
        status: event.status,
        message: event.message,
        jobId: event.jobId,
        progress: event.progress,
        currentStep: event.currentStep,
        processedChapters: event.processedChapters,
        totalChapters: event.totalChapters,
      ));
    }
  }

  /// 处理清理预览会话事件
  Future<void> _onCleanupPreviewSession(
      CleanupPreviewSession event, Emitter<NovelImportState> emit) async {
    try {
      await novelRepository.cleanupPreviewSession(event.previewSessionId);
      AppLogger.i('NovelImportBloc', '预览会话已清理: ${event.previewSessionId}');
    } catch (e) {
      AppLogger.e('NovelImportBloc', '清理预览会话失败', e);
    }
  }

  /// 重置导入状态
  void _onResetImportState(
      ResetImportState event, Emitter<NovelImportState> emit) async {
    try {
      // 如果已经不是InProgress状态，不再重复取消
      if (state is! NovelImportInProgress) {
        emit(NovelImportInitial());
        return;
      }
      
      // 记录当前JobId，避免重复取消
      final currentState = state as NovelImportInProgress;
      final jobId = currentState.jobId;
      
      // 立即切换到取消中状态，防止重复操作
      emit(NovelImportInProgress(
        status: 'CANCELLING', 
        message: '正在取消导入...',
        jobId: jobId
      ));
      
      // 取消订阅
      await _importStatusSubscription?.cancel();
      _importStatusSubscription = null;
      
      // 如果有JobId，尝试取消任务
      if (jobId != null) {
        // 通知服务器取消任务
        final success = await novelRepository.cancelImport(jobId);
        AppLogger.i('NovelImportBloc', 
          '导入任务取消${success ? '成功' : '失败或已完成'}: $jobId');
      }
      
      // 重置状态
      emit(NovelImportInitial());
    } catch (e) {
      AppLogger.e('NovelImportBloc', '重置导入状态时出错', e);
      // 即使出错，也要确保状态被重置
      emit(NovelImportInitial());
    }
  }

  /// 处理传统导入小说文件事件（向后兼容）
  Future<void> _onImportNovelFile(
      ImportNovelFile event, Emitter<NovelImportState> emit) async {
    emit(NovelImportInProgress(status: 'PREPARING', message: '准备中...'));

    try {
      // 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        emit(NovelImportInitial());
        return;
      }

      final file = result.files.first;
      final fileBytes = file.bytes;
      final fileName = file.name;

      if (fileBytes == null) {
        emit(NovelImportFailure(message: '无法读取文件数据'));
        return;
      }

      emit(NovelImportInProgress(status: 'UPLOADING', message: '上传中...'));

      // 上传文件并获取任务ID
      final jobId = await novelRepository.importNovel(fileBytes, fileName);

      emit(NovelImportInProgress(
          status: 'PROCESSING', message: '处理中...', jobId: jobId));

      // 订阅导入状态更新
      _importStatusSubscription?.cancel();
      _importStatusSubscription = novelRepository.getImportStatus(jobId).listen(
        (importStatus) {
          add(ImportStatusUpdate(
            status: importStatus.status,
            message: importStatus.message,
            jobId: jobId,
          ));
        },
        onError: (error) {
          AppLogger.e('NovelImportBloc', '监听导入状态流错误', error);
          add(ImportStatusUpdate(
            status: 'FAILED',
            message: '监听导入状态失败: ${error.toString()}',
            jobId: jobId,
          ));
        },
        onDone: () {
          AppLogger.i('NovelImportBloc', '导入状态流已关闭');
        },
      );
    } catch (e) {
      AppLogger.e('NovelImportBloc', '导入小说失败', e);
      emit(NovelImportFailure(message: '导入失败: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _importStatusSubscription?.cancel();
    return super.close();
  }
}
