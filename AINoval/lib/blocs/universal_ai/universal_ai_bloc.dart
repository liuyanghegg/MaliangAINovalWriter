import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:ainoval/services/api_service/repositories/universal_ai_repository.dart';
import 'package:ainoval/models/ai_request_models.dart';
import 'package:ainoval/utils/logger.dart';
import 'universal_ai_event.dart';
import 'universal_ai_state.dart';

/// 通用AI请求BLoC
class UniversalAIBloc extends Bloc<UniversalAIEvent, UniversalAIState> {
  final UniversalAIRepository _repository;
  StreamSubscription? _streamSubscription;

  UniversalAIBloc({
    required UniversalAIRepository repository,
  })  : _repository = repository,
        super(const UniversalAIInitial()) {
    on<SendAIRequestEvent>(_onSendAIRequest);
    on<SendAIStreamRequestEvent>(_onSendAIStreamRequest);
    on<PreviewAIRequestEvent>(_onPreviewAIRequest);
    on<EstimateCostEvent>(_onEstimateCost);
    on<StopStreamRequestEvent>(_onStopStreamRequest);
    on<ClearResponseEvent>(_onClearResponse);
    on<ResetStateEvent>(_onResetState);
  }

  /// 处理发送AI请求事件（非流式）
  Future<void> _onSendAIRequest(
    SendAIRequestEvent event,
    Emitter<UniversalAIState> emit,
  ) async {
    try {
      emit(const UniversalAILoading(message: '正在发送请求...'));
      
      AppLogger.d('UniversalAIBloc', '发送非流式AI请求: ${event.request.requestType}');
      
      final response = await _repository.sendRequest(event.request);
      
      emit(UniversalAISuccess(response: response));
      
      AppLogger.d('UniversalAIBloc', '非流式AI请求完成');
    } catch (e, stackTrace) {
      AppLogger.e('UniversalAIBloc', '发送AI请求失败', e, stackTrace);
      emit(UniversalAIError(
        message: '请求失败: ${e.toString()}',
        details: stackTrace.toString(),
      ));
    }
  }

  /// 处理发送流式AI请求事件
  Future<void> _onSendAIStreamRequest(
    SendAIStreamRequestEvent event,
    Emitter<UniversalAIState> emit,
  ) async {
    try {
      // 先取消之前的流式请求
      await _streamSubscription?.cancel();
      
      emit(const UniversalAILoading(message: '正在连接AI服务...'));
      
      AppLogger.d('UniversalAIBloc', '开始流式AI请求: ${event.request.requestType}');
      
      StringBuffer buffer = StringBuffer();
      int tokenCount = 0;
      bool isStreamCompleted = false;
      
      final stream = _repository.streamRequest(event.request);
      
      // 🚀 使用 emit.forEach 确保在事件处理器内部处理完整个流
      await emit.forEach<UniversalAIResponse>(
        stream,
        onData: (response) {
          // 🚀 检查是否收到结束信号
          if (response.finishReason != null) {
            AppLogger.i('UniversalAIBloc', '收到流式生成结束信号: ${response.finishReason}');
            isStreamCompleted = true;
            
            // 🚀 立即返回成功状态，不再发送流式状态
            return UniversalAISuccess(
              response: UniversalAIResponse(
                id: response.id,
                requestType: event.request.requestType,
                content: buffer.toString(),
                finishReason: response.finishReason,
                model: response.model,
                createdAt: response.createdAt,
                metadata: response.metadata,
              ),
              isStreaming: false, // 标记为非流式状态
            );
          }
          
          // 🚀 只有在未完成时才累积内容
          if (!isStreamCompleted && response.content.isNotEmpty) {
            buffer.write(response.content);
            tokenCount += response.tokenUsage?.completionTokens ?? 1;
            
            //AppLogger.v('UniversalAIBloc', '收到流式响应片段，长度: ${response.content.length}');
            
            return UniversalAIStreaming(
              partialResponse: buffer.toString(),
              tokenCount: tokenCount,
            );
          }
          
          // 🚀 如果已完成或内容为空，保持当前状态
          return emit.isDone ? const UniversalAIInitial() : const UniversalAIStreaming(partialResponse: '');
        },
        onError: (error, stackTrace) {
          AppLogger.e('UniversalAIBloc', '流式AI请求错误', error, stackTrace);
          return UniversalAIError(
            message: '流式请求失败: ${error.toString()}',
            details: stackTrace.toString(),
          );
        },
      );
      
      // 🚀 如果流正常结束但没有收到结束信号，手动发出成功状态
      if (!isStreamCompleted && !emit.isDone) {
        AppLogger.d('UniversalAIBloc', '流式AI请求完成（无结束信号）');
        emit(UniversalAISuccess(
          response: UniversalAIResponse(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            requestType: event.request.requestType,
            content: buffer.toString(),
            finishReason: 'stop',
          ),
          isStreaming: false,
        ));
      }
      
    } catch (e, stackTrace) {
      AppLogger.e('UniversalAIBloc', '流式AI请求失败', e, stackTrace);
      emit(UniversalAIError(
        message: '流式请求失败: ${e.toString()}',
        details: stackTrace.toString(),
      ));
    }
  }

  /// 处理预览AI请求事件
  Future<void> _onPreviewAIRequest(
    PreviewAIRequestEvent event,
    Emitter<UniversalAIState> emit,
  ) async {
    try {
      emit(const UniversalAILoading(message: '正在生成预览...'));
      
      AppLogger.d('UniversalAIBloc', '预览AI请求: ${event.request.requestType}');
      
      final previewResponse = await _repository.previewRequest(event.request);
      
      emit(UniversalAIPreviewSuccess(
        previewResponse: previewResponse,
        request: event.request,
      ));
      
      AppLogger.d('UniversalAIBloc', '预览生成完成');
    } catch (e, stackTrace) {
      AppLogger.e('UniversalAIBloc', '预览AI请求失败', e, stackTrace);
      emit(UniversalAIError(
        message: '预览失败: ${e.toString()}',
        details: stackTrace.toString(),
      ));
    }
  }

  /// 🚀 新增：处理积分预估事件
  Future<void> _onEstimateCost(
    EstimateCostEvent event,
    Emitter<UniversalAIState> emit,
  ) async {
    try {
      emit(const UniversalAILoading(message: '正在预估积分成本...'));
      
      AppLogger.d('UniversalAIBloc', '预估AI请求积分成本: ${event.request.requestType}');
      
      final costEstimation = await _repository.estimateCost(event.request);
      
      if (costEstimation.success) {
        emit(UniversalAICostEstimationSuccess(
          costEstimation: costEstimation,
          request: event.request,
        ));
        
        AppLogger.d('UniversalAIBloc', '积分预估完成: ${costEstimation.estimatedCost}积分');
      } else {
        emit(UniversalAIError(
          message: costEstimation.errorMessage ?? '积分预估失败',
          canRetry: true,
        ));
      }
    } catch (e, stackTrace) {
      AppLogger.e('UniversalAIBloc', '积分预估失败', e, stackTrace);
      emit(UniversalAIError(
        message: '积分预估失败: ${e.toString()}',
        details: stackTrace.toString(),
        canRetry: true,
      ));
    }
  }

  /// 处理停止流式请求事件
  Future<void> _onStopStreamRequest(
    StopStreamRequestEvent event,
    Emitter<UniversalAIState> emit,
  ) async {
    AppLogger.d('UniversalAIBloc', '停止流式请求');
    
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    
    // 保留当前的部分响应
    String? partialResponse;
    if (state is UniversalAIStreaming) {
      partialResponse = (state as UniversalAIStreaming).partialResponse;
    }
    
    emit(UniversalAICancelled(partialResponse: partialResponse));
  }

  /// 处理清除响应事件
  Future<void> _onClearResponse(
    ClearResponseEvent event,
    Emitter<UniversalAIState> emit,
  ) async {
    AppLogger.d('UniversalAIBloc', '清除响应');
    emit(const UniversalAIInitial());
  }

  /// 处理重置状态事件
  Future<void> _onResetState(
    ResetStateEvent event,
    Emitter<UniversalAIState> emit,
  ) async {
    AppLogger.d('UniversalAIBloc', '重置状态');
    
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    
    emit(const UniversalAIInitial());
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
} 