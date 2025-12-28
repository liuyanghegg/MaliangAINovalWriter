import 'package:ainoval/models/chat_models.dart';
import 'package:ainoval/models/ai_request_models.dart';

/// 聊天仓库接口
///
/// 定义与聊天相关的所有API操作
abstract class ChatRepository {
  /// 获取用户的所有会话
  Stream<ChatSession> fetchUserSessions(String userId, {String? novelId});

  /// 创建新的聊天会话
  Future<ChatSession> createSession({
    required String userId,
    required String novelId,
    String? modelName,
    Map<String, dynamic>? metadata,
  });

  /// 获取特定会话详情（包含AI配置）
  Future<ChatSession> getSession(String userId, String sessionId, {String? novelId});
  
  /// 获取会话的AI配置
  Future<UniversalAIRequest?> getSessionAIConfig(String userId, String sessionId, {String? novelId});

  /// 更新会话信息
  Future<ChatSession> updateSession({
    required String userId,
    required String sessionId,
    required Map<String, dynamic> updates,
    String? novelId,
  });

  /// 删除会话
  Future<void> deleteSession(String userId, String sessionId, {String? novelId});

  /// 发送消息并获取响应
  /// 返回完整的 AI ChatMessage 对象
  Future<ChatMessage> sendMessage({
    required String userId,
    required String sessionId,
    required String content,
    UniversalAIRequest? config,
    Map<String, dynamic>? metadata,
    String? configId,
    String? novelId,
  });

  /// 流式发送消息并获取响应
  /// 流式返回 AI ChatMessage 对象片段
  Stream<ChatMessage> streamMessage({
    required String userId,
    required String sessionId,
    required String content,
    UniversalAIRequest? config,
    Map<String, dynamic>? metadata,
    String? configId,
    String? novelId,
  });

  /// 获取会话消息历史
  Stream<ChatMessage> getMessageHistory(String userId, String sessionId,
      {int limit = 100, String? novelId});

  /// 获取特定消息
  Future<ChatMessage> getMessage(String userId, String messageId);

  /// 删除消息
  Future<void> deleteMessage(String userId, String messageId);

  /// 获取会话消息数量
  Future<int> countSessionMessages(String sessionId);

  /// 获取用户会话数量
  Future<int> countUserSessions(String userId, {String? novelId});
}
