import 'package:ainoval/models/ai_request_models.dart';
import 'package:equatable/equatable.dart';

/// 通用AI请求事件基类
abstract class UniversalAIEvent extends Equatable {
  const UniversalAIEvent();

  @override
  List<Object?> get props => [];
}

/// 发送AI请求事件（非流式）
class SendAIRequestEvent extends UniversalAIEvent {
  const SendAIRequestEvent(this.request);

  final UniversalAIRequest request;

  @override
  List<Object?> get props => [request];
}

/// 发送流式AI请求事件
class SendAIStreamRequestEvent extends UniversalAIEvent {
  const SendAIStreamRequestEvent(this.request);

  final UniversalAIRequest request;

  @override
  List<Object?> get props => [request];
}

/// 预览AI请求事件
class PreviewAIRequestEvent extends UniversalAIEvent {
  const PreviewAIRequestEvent(this.request);

  final UniversalAIRequest request;

  @override
  List<Object?> get props => [request];
}

/// 停止流式请求事件
class StopStreamRequestEvent extends UniversalAIEvent {
  const StopStreamRequestEvent();
}

/// 清除响应事件
class ClearResponseEvent extends UniversalAIEvent {
  const ClearResponseEvent();
}

/// 重置状态事件
class ResetStateEvent extends UniversalAIEvent {
  const ResetStateEvent();
}

/// 🚀 新增：积分预估事件
class EstimateCostEvent extends UniversalAIEvent {
  const EstimateCostEvent(this.request);

  final UniversalAIRequest request;

  @override
  List<Object?> get props => [request];
} 