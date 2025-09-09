import 'package:ainoval/models/ai_request_models.dart';
import 'package:equatable/equatable.dart';

/// 通用AI请求状态基类
abstract class UniversalAIState extends Equatable {
  const UniversalAIState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class UniversalAIInitial extends UniversalAIState {
  const UniversalAIInitial();
}

/// 加载中状态
class UniversalAILoading extends UniversalAIState {
  const UniversalAILoading({
    this.progress,
    this.message,
  });

  final double? progress;
  final String? message;

  @override
  List<Object?> get props => [progress, message];
}

/// 流式响应进行中状态
class UniversalAIStreaming extends UniversalAIState {
  const UniversalAIStreaming({
    required this.partialResponse,
    this.tokenCount = 0,
  });

  final String partialResponse;
  final int tokenCount;

  @override
  List<Object?> get props => [partialResponse, tokenCount];
}

/// 请求成功状态
class UniversalAISuccess extends UniversalAIState {
  const UniversalAISuccess({
    required this.response,
    this.isStreaming = false,
  });

  final UniversalAIResponse response;
  final bool isStreaming;

  @override
  List<Object?> get props => [response, isStreaming];
}

/// 预览成功状态
class UniversalAIPreviewSuccess extends UniversalAIState {
  const UniversalAIPreviewSuccess({
    required this.previewResponse,
    required this.request,
  });

  final UniversalAIPreviewResponse previewResponse;
  final UniversalAIRequest request;

  @override
  List<Object?> get props => [previewResponse, request];
}

/// 错误状态
class UniversalAIError extends UniversalAIState {
  const UniversalAIError({
    required this.message,
    this.details,
    this.canRetry = true,
  });

  final String message;
  final String? details;
  final bool canRetry;

  @override
  List<Object?> get props => [message, details, canRetry];
}

/// 请求被取消状态
class UniversalAICancelled extends UniversalAIState {
  const UniversalAICancelled({
    this.partialResponse,
  });

  final String? partialResponse;

  @override
  List<Object?> get props => [partialResponse];
}

/// 🚀 新增：积分预估成功状态
class UniversalAICostEstimationSuccess extends UniversalAIState {
  const UniversalAICostEstimationSuccess({
    required this.costEstimation,
    required this.request,
  });

  final CostEstimationResponse costEstimation;
  final UniversalAIRequest request;

  @override
  List<Object?> get props => [costEstimation, request];
} 