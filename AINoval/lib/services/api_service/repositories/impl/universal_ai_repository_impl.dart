import 'package:ainoval/models/ai_request_models.dart';
import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/services/api_service/base/api_exception.dart';
import 'package:ainoval/services/api_service/base/sse_client.dart';
import 'package:ainoval/services/api_service/repositories/universal_ai_repository.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:ainoval/utils/date_time_parser.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';

/// 通用AI请求仓库实现
class UniversalAIRepositoryImpl implements UniversalAIRepository {
  final ApiClient apiClient;
  final String _tag = 'UniversalAIRepository';

  UniversalAIRepositoryImpl({required this.apiClient});

  @override
  Future<UniversalAIResponse> sendRequest(UniversalAIRequest request) async {
    try {
      AppLogger.d(_tag, '发送AI请求: ${request.requestType.value}');
      
      final response = await apiClient.post(
        '/ai/universal/process',
        data: request.toApiJson(),
      );
      
      return UniversalAIResponse.fromJson(response);
    } catch (e) {
      AppLogger.e(_tag, '发送AI请求失败', e);
      rethrow;
    }
  }

  @override
  Stream<UniversalAIResponse> streamRequest(UniversalAIRequest request) {
    try {
      AppLogger.d(_tag, '发送流式AI请求: ${request.requestType.value}');
      
      // 🚀 使用SseClient替代ApiClient，复用剧情推演的流式处理逻辑
      return SseClient().streamEvents<UniversalAIResponse>(
        path: '/ai/universal/stream',
        method: SSERequestType.POST,
        body: request.toApiJson(),
        parser: (json) {
          // 🚀 修复：优先检查是否是结束标记
          if (json is Map<String, dynamic>) {
            final finishReason = json['finishReason'] as String?;
            final isComplete = json['isComplete'] as bool? ?? false;
            final content = json['content'] as String? ?? '';
            
            // 🚀 如果有结束信号，立即返回结束响应
            if (finishReason != null || isComplete || content == '}') {
              AppLogger.i(_tag, '检测到流式生成结束信号: finishReason=$finishReason, isComplete=$isComplete, content="$content"');
              return UniversalAIResponse(
                id: json['id'] as String? ?? 'stream_end_${DateTime.now().millisecondsSinceEpoch}',
                requestType: request.requestType,
                content: '',  // 结束信号内容为空
                finishReason: finishReason ?? 'stop',
              );
            }
          }
          
          // 🚀 复用剧情推演的错误处理逻辑
          // 首先检查是否是已知的错误格式
          if (json is Map<String, dynamic> && json.containsKey('code') && json.containsKey('message')) {
            final errorMessage = json['message'] as String? ?? 'Unknown server error';
            final errorCodeString = json['code'] as String?;
            final errorCode = int.tryParse(errorCodeString ?? '') ?? -1;
            AppLogger.e(_tag, '服务器返回已知错误格式: code=${json['code']}, message=$errorMessage');
            
            // 🚀 专门处理积分不足错误
            if (errorCodeString == 'INSUFFICIENT_CREDITS') {
              throw InsufficientCreditsException(errorMessage);
            }
            
            throw ApiException(errorCode, errorMessage);
          }
          // 检查是否包含 'error' 字段（兼容旧的或不同的错误格式）
          else if (json is Map<String, dynamic> && json['error'] != null) {
            final errorMessage = json['error'] as String? ?? 'Unknown server error';
            AppLogger.e(_tag, '服务器返回错误字段: $errorMessage');
            throw ApiException(-1, errorMessage);
          }
          
          //AppLogger.v(_tag, '收到流式响应数据: $json');
          
          // 🚀 后端现在返回的是标准的ServerSentEvent<UniversalAIResponseDto>格式
          // 直接解析UniversalAIResponseDto
          try {
            return UniversalAIResponse.fromJson(json);
          } catch (e) {
            AppLogger.e(_tag, '解析UniversalAIResponse失败: $e, json: $json');
            
            // 🚀 fallback：如果解析失败，尝试从基本字段构建响应
            if (json is Map<String, dynamic>) {
              // 处理缺失字段的兼容性
              final content = json['content'] as String? ?? '';
              final id = json['id'] as String? ?? 'stream_${DateTime.now().millisecondsSinceEpoch}';
              final requestType = json['requestType'] as String? ?? request.requestType.value;
              final model = json['model'] as String?;
              final finishReason = json['finishReason'] as String?;
              final createdAtValue = json['createdAt'];
              final metadata = json['metadata'] as Map<String, dynamic>? ?? <String, dynamic>{};
              
              // 解析AI请求类型
              final aiRequestType = AIRequestType.values.firstWhere(
                (type) => type.value == requestType,
                orElse: () => request.requestType,
              );
              
              // 🚀 使用parseBackendDateTime处理createdAt字段
              DateTime? createdAt;
              if (createdAtValue != null) {
                try {
                  createdAt = parseBackendDateTime(createdAtValue);
                } catch (e) {
                  AppLogger.w(_tag, '解析createdAt失败，使用当前时间: $e');
                  createdAt = DateTime.now();
                }
              }
              
              return UniversalAIResponse(
                id: id,
                requestType: aiRequestType,
                content: content,
                model: model,
                finishReason: finishReason,
                createdAt: createdAt,
                metadata: metadata,
              );
            }
            
            // 抛出更具体的解析异常
            throw ApiException(-1, '解析响应失败: $e');
          }
        },
        eventName: 'message', // 🚀 与后端保持一致的事件名
        connectionId: 'universal_ai_${request.requestType.value}_${DateTime.now().millisecondsSinceEpoch}',
      ).where((response) {
        // 🚀 修复：不要过滤掉结束信号（即使content为空但有finishReason的响应）
        if (response.finishReason != null) {
          AppLogger.i(_tag, '保留结束信号: finishReason=${response.finishReason}');
          return true;
        }
        // 🚀 只过滤掉既没有内容也没有结束信号的响应
        return response.content.isNotEmpty;
      });
    } catch (e) {
      AppLogger.e(_tag, '发送流式AI请求失败', e);
      return Stream.error(Exception('流式AI请求失败: ${e.toString()}'));
    }
  }

  @override
  Future<UniversalAIPreviewResponse> previewRequest(UniversalAIRequest request) async {
    try {
      AppLogger.d(_tag, '预览AI请求: ${request.requestType.value}');
      
      final response = await apiClient.post(
        '/ai/universal/preview',
        data: request.toApiJson(),
      );
      
      return UniversalAIPreviewResponse.fromJson(response);
    } catch (e) {
      AppLogger.e(_tag, '预览AI请求失败', e);
      rethrow;
    }
  }

  @override
  Future<CostEstimationResponse> estimateCost(UniversalAIRequest request) async {
    try {
      AppLogger.d(_tag, '预估AI请求积分成本: ${request.requestType.value}');
      
      final response = await apiClient.post(
        '/ai/universal/estimate-cost',
        data: request.toApiJson(),
      );
      
      final costResponse = CostEstimationResponse.fromJson(response);
      
      AppLogger.d(_tag, '积分预估完成 - 预估成本: ${costResponse.estimatedCost}积分, 模型: ${costResponse.modelName}');
      return costResponse;
    } catch (e) {
      AppLogger.e(_tag, '预估AI请求积分成本失败', e);
      rethrow;
    }
  }
} 