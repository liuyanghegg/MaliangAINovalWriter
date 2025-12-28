import 'dart:async';
import 'dart:convert';

import 'package:ainoval/models/ai_request_models.dart';
import 'package:ainoval/models/chat_models.dart';
import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/services/api_service/base/api_exception.dart';
import 'package:ainoval/services/api_service/base/sse_client.dart';
import 'package:ainoval/services/api_service/repositories/chat_repository.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';

/// 聊天仓库实现
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required this.apiClient,
  });

  final ApiClient apiClient;
  
  // 🚀 修改为两层缓存映射，用于存储会话的AI配置：novelId -> sessionId -> config
  static final Map<String, Map<String, UniversalAIRequest>> _cachedSessionConfigs = {};

  /// 获取聊天会话列表 (流式) - 简化版
  @override
  Stream<ChatSession> fetchUserSessions(String userId, {String? novelId}) {
    AppLogger.i('ChatRepositoryImpl', '获取用户会话流: userId=$userId, novelId=$novelId');
    // 🚀 目前先使用原有API，后续可以添加支持novelId的新API
    try {
      // TODO: 暂时使用原有API，后续可以添加新的API方法
      return apiClient.listAiChatUserSessionsStream(userId, novelId: novelId);
    } catch (e, stackTrace) {
      AppLogger.e('ChatRepositoryImpl', '发起获取用户会话流时出错 [同步]', e, stackTrace);
      return Stream.error(
          ApiExceptionHelper.fromException(e, '发起获取用户会话流失败'), stackTrace);
    }
  }

  /// 创建新的聊天会话 (非流式)
  @override
  Future<ChatSession> createSession({
    required String userId,
    required String novelId,
    String? modelName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.i('ChatRepositoryImpl',
          '创建会话: userId=$userId, novelId=$novelId, modelName=$modelName');
      final session = await apiClient.createAiChatSession(
        userId: userId,
        novelId: novelId,
        modelName: modelName,
        metadata: metadata,
      );
      AppLogger.i('ChatRepositoryImpl', '创建会话成功: sessionId=${session.id}');
      return session;
    } catch (e, stackTrace) {
      AppLogger.e('ChatRepositoryImpl',
          '创建会话失败: userId=$userId, novelId=$novelId', e, stackTrace);
      throw ApiExceptionHelper.fromException(e, '创建会话失败');
    }
  }

  /// 获取特定会话 (非流式) - 现在返回会话和AI配置的组合数据
  @override
  Future<ChatSession> getSession(String userId, String sessionId, {String? novelId}) async {
    try {
      AppLogger.i(
          'ChatRepositoryImpl', '获取会话（含AI配置）: userId=$userId, sessionId=$sessionId, novelId=$novelId');
      
      // 🚀 目前先使用原有API，后续可以添加支持novelId的新API
      final response = await apiClient.getAiChatSessionWithConfig(userId, sessionId, novelId: novelId);
      AppLogger.i('ChatRepositoryImpl', '使用传统API获取会话');
      
      final session = response['session'] as ChatSession;
      AppLogger.i('ChatRepositoryImpl',
          '获取会话成功: sessionId=$sessionId, title=${session.title}, hasAIConfig=${response["aiConfig"] != null}');
      
      // 🚀 将AI配置信息缓存到两层映射中，供后续使用
      if (response['aiConfig'] != null && session.novelId != null) {
        try {
          final configData = response['aiConfig'];
          Map<String, dynamic> configJson;
          
          if (configData is String) {
            final configString = configData as String;
            if (configString.trim().isNotEmpty && configString != '{}') {
              if (!configString.startsWith('{') || !configString.contains('"')) {
                AppLogger.w('ChatRepositoryImpl', '检测到非标准JSON格式，跳过解析');
              } else {
                try {
                  configJson = jsonDecode(configString);
                  final config = UniversalAIRequest.fromJson(configJson);
                  // 🚀 将配置缓存到两层映射中
                  _cachedSessionConfigs[session.novelId!] ??= {};
                  _cachedSessionConfigs[session.novelId!]![sessionId] = config;
                  AppLogger.i('ChatRepositoryImpl', 
                      '成功缓存会话AI配置: novelId=${session.novelId}, sessionId=$sessionId, requestType=${config.requestType.value}');
                } catch (e) {
                  AppLogger.e('ChatRepositoryImpl', '解析AI配置JSON失败: $e');
                }
              }
            }
          } else if (configData is Map<String, dynamic>) {
            try {
              final config = UniversalAIRequest.fromJson(configData);
              // 🚀 将配置缓存到两层映射中
              _cachedSessionConfigs[session.novelId!] ??= {};
              _cachedSessionConfigs[session.novelId!]![sessionId] = config;
              AppLogger.i('ChatRepositoryImpl', 
                  '成功缓存会话AI配置: novelId=${session.novelId}, sessionId=$sessionId, requestType=${config.requestType.value}');
            } catch (e) {
              AppLogger.e('ChatRepositoryImpl', '解析AI配置Map失败: $e');
            }
          }
        } catch (e) {
          AppLogger.w('ChatRepositoryImpl', '缓存AI配置失败，但不影响会话加载: $e');
        }
      }
      
      return session;
    } catch (e, stackTrace) {
      AppLogger.e('ChatRepositoryImpl',
          '获取会话失败: userId=$userId, sessionId=$sessionId, novelId=$novelId', e, stackTrace);
      throw ApiExceptionHelper.fromException(e, '获取会话失败');
    }
  }

  /// 获取会话的AI配置 (非流式) - 现在从两层缓存中获取
  @override
  Future<UniversalAIRequest?> getSessionAIConfig(String userId, String sessionId, {String? novelId}) async {
    AppLogger.i('ChatRepositoryImpl', 
        '从缓存获取会话AI配置: userId=$userId, sessionId=$sessionId, novelId=$novelId');
    
    // 🚀 从两层缓存中获取配置
    if (novelId != null) {
      final cachedConfig = _cachedSessionConfigs[novelId]?[sessionId];
      if (cachedConfig != null) {
        AppLogger.i('ChatRepositoryImpl', 
            '找到缓存的会话AI配置: novelId=$novelId, sessionId=$sessionId, requestType=${cachedConfig.requestType.value}');
        return cachedConfig;
      }
    } else {
      // 如果没有novelId，尝试在所有novel中查找
      for (final novelConfigs in _cachedSessionConfigs.values) {
        final cachedConfig = novelConfigs[sessionId];
        if (cachedConfig != null) {
          AppLogger.i('ChatRepositoryImpl', 
              '在缓存中找到会话AI配置: sessionId=$sessionId, requestType=${cachedConfig.requestType.value}');
          return cachedConfig;
        }
      }
    }
    
    AppLogger.i('ChatRepositoryImpl', 
        '缓存中没有找到会话AI配置: novelId=$novelId, sessionId=$sessionId');
    return null;
  }

  /// 获取缓存的会话配置（静态方法，供其他类使用）
  static UniversalAIRequest? getCachedSessionConfig(String sessionId, {String? novelId}) {
    if (novelId != null) {
      return _cachedSessionConfigs[novelId]?[sessionId];
    } else {
      // 如果没有novelId，尝试在所有novel中查找
      for (final novelConfigs in _cachedSessionConfigs.values) {
        final config = novelConfigs[sessionId];
        if (config != null) return config;
      }
      return null;
    }
  }

  /// 缓存会话配置（静态方法，供其他类使用）
  static void cacheSessionConfig(String sessionId, UniversalAIRequest config, {String? novelId}) {
    final targetNovelId = novelId ?? config.novelId;
    if (targetNovelId != null) {
      _cachedSessionConfigs[targetNovelId] ??= {};
      _cachedSessionConfigs[targetNovelId]![sessionId] = config;
      AppLogger.i('ChatRepositoryImpl', '缓存会话AI配置: novelId=$targetNovelId, sessionId=$sessionId');
    } else {
      AppLogger.w('ChatRepositoryImpl', '无法缓存会话配置：缺少novelId信息');
    }
  }

  /// 清除会话配置缓存
  static void clearSessionConfigCache(String sessionId, {String? novelId}) {
    if (novelId != null) {
      _cachedSessionConfigs[novelId]?.remove(sessionId);
      AppLogger.i('ChatRepositoryImpl', '清除会话AI配置缓存: novelId=$novelId, sessionId=$sessionId');
    } else {
      // 如果没有novelId，清除所有novel中的该sessionId
      for (final novelConfigs in _cachedSessionConfigs.values) {
        novelConfigs.remove(sessionId);
      }
      AppLogger.i('ChatRepositoryImpl', '清除所有小说中的会话AI配置缓存: sessionId=$sessionId');
    }
  }

  /// 清除整个小说的配置缓存
  static void clearNovelConfigCache(String novelId) {
    _cachedSessionConfigs.remove(novelId);
    AppLogger.i('ChatRepositoryImpl', '清除小说的所有AI配置缓存: novelId=$novelId');
  }

  /// 更新会话 (非流式)
  @override
  Future<ChatSession> updateSession({
    required String userId,
    required String sessionId,
    required Map<String, dynamic> updates,
    String? novelId,
  }) async {
    try {
      AppLogger.i('ChatRepositoryImpl',
          '更新会话: userId=$userId, sessionId=$sessionId, novelId=$novelId, updates=$updates');
      
      // 🚀 目前先使用原有API，后续可以添加支持novelId的新API
      final updatedSession = await apiClient.updateAiChatSession(
        userId: userId,
        sessionId: sessionId,
        updates: updates,
        novelId: novelId,
      );
      
      AppLogger.i('ChatRepositoryImpl',
          '更新会话成功: sessionId=$sessionId, title=${updatedSession.title}');
      return updatedSession;
    } catch (e, stackTrace) {
      AppLogger.e('ChatRepositoryImpl',
          '更新会话失败: userId=$userId, sessionId=$sessionId, novelId=$novelId', e, stackTrace);
      throw ApiExceptionHelper.fromException(e, '更新会话失败');
    }
  }

  /// 删除会话 (非流式)
  @override
  Future<void> deleteSession(String userId, String sessionId, {String? novelId}) async {
    try {
      AppLogger.i(
          'ChatRepositoryImpl', '删除会话: userId=$userId, sessionId=$sessionId, novelId=$novelId');
      
      // 🚀 目前先使用原有API，后续可以添加支持novelId的新API
      await apiClient.deleteAiChatSession(userId, sessionId, novelId: novelId);
      // 清除该会话的配置缓存
      clearSessionConfigCache(sessionId, novelId: novelId);
      
      AppLogger.i('ChatRepositoryImpl', '删除会话成功: sessionId=$sessionId');
    } catch (e, stackTrace) {
      AppLogger.e('ChatRepositoryImpl',
          '删除会话失败: userId=$userId, sessionId=$sessionId, novelId=$novelId', e, stackTrace);
      throw ApiExceptionHelper.fromException(e, '删除会话失败');
    }
  }

  /// 发送消息并获取响应 (非流式)
  @override
  Future<ChatMessage> sendMessage({
    required String userId,
    required String sessionId,
    required String content,
    UniversalAIRequest? config,
    Map<String, dynamic>? metadata,
    String? configId,
    String? novelId,
  }) async {
    try {
      AppLogger.i('ChatRepositoryImpl',
          '发送消息: userId=$userId, sessionId=$sessionId, novelId=$novelId, configId=$configId, hasConfig=${config != null}, contentLength=${content.length}');
      
      // 🚀 如果有配置，将配置数据添加到metadata中
      Map<String, dynamic>? finalMetadata = metadata ?? {};
      
      if (config != null) {
        // 将配置序列化到metadata中
        finalMetadata['aiConfig'] = config.toApiJson();
        AppLogger.d('ChatRepositoryImpl', '添加AI配置到metadata，配置类型: ${config.requestType.value}');
      }
      
      // 🚀 目前先使用原有API，后续可以添加支持novelId的新API
      final messageResponse = await apiClient.sendAiChatMessage(
        userId: userId,
        sessionId: sessionId,
        content: content,
        metadata: finalMetadata,
        novelId: novelId,
      );
      
      AppLogger.i('ChatRepositoryImpl',
          '收到AI响应: sessionId=$sessionId, messageId=${messageResponse.id}, contentLength=${messageResponse.content.length}');
      return messageResponse;
    } catch (e, stackTrace) {
      AppLogger.e('ChatRepositoryImpl',
          '发送消息失败: userId=$userId, sessionId=$sessionId, novelId=$novelId', e, stackTrace);
      throw ApiExceptionHelper.fromException(e, '发送消息失败');
    }
  }

  /// 流式发送消息并获取响应 - 简化版
  @override
  Stream<ChatMessage> streamMessage({
    required String userId,
    required String sessionId,
    required String content,
    UniversalAIRequest? config,
    Map<String, dynamic>? metadata,
    String? configId,
    String? novelId,
  }) {
    AppLogger.i('ChatRepositoryImpl',
        '开始流式消息: userId=$userId, sessionId=$sessionId, novelId=$novelId, configId=$configId, hasConfig=${config != null}');
    
    try {
      // 🚀 准备配置数据
      Map<String, dynamic>? configData;
      Map<String, dynamic>? finalMetadata = metadata ?? {};
      
      if (config != null) {
        // 将配置序列化
        configData = config.toApiJson();
        // 同时添加到metadata中以保持兼容性
        finalMetadata['aiConfig'] = configData;
        AppLogger.d('ChatRepositoryImpl', '添加AI配置到请求，配置类型: ${config.requestType.value}');
      }
      
      // 🚀 构建请求体，根据是否有novelId选择不同的请求格式
      Map<String, dynamic> requestBody = {
        'userId': userId,
        'sessionId': sessionId,
        'content': content,
        'metadata': finalMetadata,
      };
      
      if (novelId != null) {
        requestBody['novelId'] = novelId;
      }
      
      // 🚀 使用SSE方式发送流式消息，与后端的标准SSE格式匹配
      return SseClient().streamEvents<ChatMessage>(
        path: '/ai-chat/messages/stream',
        method: SSERequestType.POST,
        body: requestBody,
        parser: (json) {
          try {
            return ChatMessage.fromJson(json);
          } catch (e) {
            AppLogger.e('ChatRepositoryImpl', '解析ChatMessage失败: $e, json: $json');
            throw ApiException(-1, '解析聊天响应失败: $e');
          }
        },
        eventName: 'chat-message', // 🚀 使用与后端一致的事件名称
      ).where((message) {
        // 🚀 首先检查消息是否属于当前会话
        if (message.sessionId != sessionId) {
          AppLogger.v('ChatRepositoryImpl', '过滤掉其他会话的消息: sessionId=${message.sessionId}, 当前会话=$sessionId');
          return false;
        }
        
        // 🚀 过滤掉心跳信号但保留STREAM_CHUNK消息用于打字机效果
        final isHeartbeat = message.content == 'heartbeat';
        
        if (isHeartbeat) {
          AppLogger.v('ChatRepositoryImpl', '过滤掉心跳信号: sessionId=${message.sessionId}');
          return false;
        }
        
        // 🚀 保留流式块消息用于打字机效果
        if (message.status == MessageStatus.streaming) {
          //AppLogger.v('ChatRepositoryImpl', '保留流式块消息用于打字机效果: ${message.content}');
          return true;
        }
        
        // 只保留有实际ID和内容的完整消息
        final isCompleteMessage = message.id.isNotEmpty && !message.id.startsWith('temp_chunk_') && message.content.isNotEmpty;
        if (isCompleteMessage) {
          AppLogger.i('ChatRepositoryImpl', '📘 接收到完整消息: messageId=${message.id}, contentLength=${message.content.length}');
        }
        
        return isCompleteMessage;
      });
    } catch (e, stackTrace) {
      AppLogger.e('ChatRepositoryImpl', '发起流式消息请求时出错 [同步]', e, stackTrace);
      return Stream.error(
          ApiExceptionHelper.fromException(e, '发起流式消息请求失败'), stackTrace);
    }
  }

  /// 获取会话消息历史 (流式) - 简化版
  @override
  Stream<ChatMessage> getMessageHistory(
    String userId,
    String sessionId, {
    int limit = 100,
    String? novelId,
  }) {
    AppLogger.i('ChatRepositoryImpl',
        '获取消息历史流: userId=$userId, sessionId=$sessionId, novelId=$novelId, limit=$limit');
    try {
      // 🚀 目前先使用原有API，后续可以添加支持novelId的新API
          return apiClient.getAiChatMessageHistoryStream(userId, sessionId,
        limit: limit, novelId: novelId);
    } catch (e, stackTrace) {
      AppLogger.e('ChatRepositoryImpl', '发起获取消息历史流请求时出错 [同步]', e, stackTrace);
      return Stream.error(
          ApiExceptionHelper.fromException(e, '发起获取消息历史流失败'), stackTrace);
    }
  }

  /// 获取特定消息 (非流式)
  @override
  Future<ChatMessage> getMessage(String userId, String messageId) async {
    try {
      AppLogger.i(
          'ChatRepositoryImpl', '获取消息: userId=$userId, messageId=$messageId');
      final message = await apiClient.getAiChatMessage(userId, messageId);
      AppLogger.i('ChatRepositoryImpl',
          '获取消息成功: messageId=$messageId, role=${message.role}');
      return message;
    } catch (e, stackTrace) {
      AppLogger.e('ChatRepositoryImpl',
          '获取消息失败: userId=$userId, messageId=$messageId', e, stackTrace);
      throw ApiExceptionHelper.fromException(e, '获取消息失败');
    }
  }

  /// 删除消息 (非流式)
  @override
  Future<void> deleteMessage(String userId, String messageId) async {
    try {
      AppLogger.i(
          'ChatRepositoryImpl', '删除消息: userId=$userId, messageId=$messageId');
      await apiClient.deleteAiChatMessage(userId, messageId);
      AppLogger.i('ChatRepositoryImpl', '删除消息成功: messageId=$messageId');
    } catch (e, stackTrace) {
      AppLogger.e('ChatRepositoryImpl',
          '删除消息失败: userId=$userId, messageId=$messageId', e, stackTrace);
      throw ApiExceptionHelper.fromException(e, '删除消息失败');
    }
  }

  /// 获取会话消息数量 (非流式)
  @override
  Future<int> countSessionMessages(String sessionId) async {
    try {
      AppLogger.i('ChatRepositoryImpl', '统计会话消息数量: sessionId=$sessionId');
      final count = await apiClient.countAiChatSessionMessages(sessionId);
      AppLogger.i('ChatRepositoryImpl',
          '统计会话消息数量成功: sessionId=$sessionId, count=$count');
      return count;
    } catch (e, stackTrace) {
      AppLogger.e('ChatRepositoryImpl', '统计会话消息数量失败: sessionId=$sessionId', e,
          stackTrace);
      throw ApiExceptionHelper.fromException(e, '统计会话消息数量失败');
    }
  }

  /// 获取用户会话数量 (非流式)
  @override
  Future<int> countUserSessions(String userId, {String? novelId}) async {
    try {
      AppLogger.i('ChatRepositoryImpl', '统计用户会话数量: userId=$userId, novelId=$novelId');
      
      // 🚀 目前先使用原有API，后续可以添加支持novelId的新API
      final count = await apiClient.countAiChatUserSessions(userId);
      
      AppLogger.i(
          'ChatRepositoryImpl', '统计用户会话数量成功: userId=$userId, novelId=$novelId, count=$count');
      return count;
    } catch (e, stackTrace) {
      AppLogger.e(
          'ChatRepositoryImpl', '统计用户会话数量失败: userId=$userId, novelId=$novelId', e, stackTrace);
      throw ApiExceptionHelper.fromException(e, '统计用户会话数量失败');
    }
  }
}

// 辅助扩展方法，如果 ApiException 没有 fromException
extension ApiExceptionHelper on ApiException {
  static ApiException fromException(dynamic e, String defaultMessage) {
    if (e is ApiException) {
      return e;
    } else if (e is DioException) {
      // 现在可以识别 DioException 了
      final statusCode = e.response?.statusCode ?? -1;
      // 尝试获取后端返回的错误信息，如果失败则使用 DioException 的 message
      final backendMessage = _tryGetBackendMessage(e.response);
      final detailedMessage = backendMessage ?? e.message ?? defaultMessage;
      return ApiException(statusCode, '$defaultMessage: $detailedMessage');
    } else {
      return ApiException(-1, '$defaultMessage: ${e.toString()}');
    }
  }

  // 尝试从 Response 中提取后端错误信息
  static String? _tryGetBackendMessage(Response? response) {
    if (response?.data != null) {
      try {
        final data = response!.data;
        if (data is Map<String, dynamic>) {
          // 查找常见的错误消息字段
          if (data.containsKey('message') && data['message'] is String) {
            return data['message'];
          }
          if (data.containsKey('error') && data['error'] is String) {
            return data['error'];
          }
          if (data.containsKey('detail') && data['detail'] is String) {
            return data['detail'];
          }
        } else if (data is String && data.isNotEmpty) {
          return data; // 如果响应体直接是错误字符串
        }
      } catch (_) {
        // 忽略解析错误
      }
    }
    return null;
  }
}
