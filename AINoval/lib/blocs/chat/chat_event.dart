import 'package:equatable/equatable.dart';
import '../../models/chat_models.dart';
import '../../models/ai_request_models.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

// 加载聊天会话列表
class LoadChatSessions extends ChatEvent {
  const LoadChatSessions({required this.novelId});
  final String novelId;

  @override
  List<Object?> get props => [novelId];
}

// 创建新的聊天会话
class CreateChatSession extends ChatEvent {
  const CreateChatSession({
    required this.title,
    required this.novelId,
    this.chapterId,
    this.metadata,
  });
  final String title;
  final String novelId;
  final String? chapterId;
  final Map<String, dynamic>? metadata;
  @override
  List<Object?> get props => [title, novelId, chapterId];
}

// 选择聊天会话
class SelectChatSession extends ChatEvent {
  const SelectChatSession({required this.sessionId, this.novelId});
  final String sessionId;
  final String? novelId;

  @override
  List<Object?> get props => [sessionId, novelId];
}

// 发送消息
class SendMessage extends ChatEvent {
  // <<< Add configId field

  // <<< Modify existing constructor
  const SendMessage({required this.content, this.configId});
  final String content;
  final String? configId;

  @override
  List<Object?> get props => [content, configId]; // <<< Add configId to props
}

// 加载更多消息
class LoadMoreMessages extends ChatEvent {
  const LoadMoreMessages();
}

// 更新聊天标题
class UpdateChatTitle extends ChatEvent {
  const UpdateChatTitle({required this.newTitle});
  final String newTitle;

  @override
  List<Object?> get props => [newTitle];
}

// 执行操作
class ExecuteAction extends ChatEvent {
  const ExecuteAction({required this.action});
  final MessageAction action;

  @override
  List<Object?> get props => [action];
}

// 删除聊天会话
class DeleteChatSession extends ChatEvent {
  const DeleteChatSession({required this.sessionId});
  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

// 取消正在进行的请求
class CancelOngoingRequest extends ChatEvent {
  const CancelOngoingRequest();
}

class UpdateActiveChatConfig extends ChatEvent {
  const UpdateActiveChatConfig({required this.configId});
  final String? configId;
  @override
  List<Object?> get props => [configId];
}

// 更新聊天上下文
class UpdateChatContext extends ChatEvent {
  const UpdateChatContext({required this.context});
  final ChatContext context;

  @override
  List<Object?> get props => [context];
}

// 更新聊天模型
class UpdateChatModel extends ChatEvent {
  // Pass the ID, Bloc will resolve the model

  const UpdateChatModel({
    required this.sessionId,
    required this.modelConfigId,
  });
  final String sessionId;
  final String modelConfigId;

  @override
  List<Object?> get props => [sessionId, modelConfigId];
}

// 加载设定和片段数据
class LoadContextData extends ChatEvent {
  const LoadContextData({required this.novelId});
  final String novelId;

  @override
  List<Object?> get props => [novelId];
}

// 缓存设定数据
class CacheSettingsData extends ChatEvent {
  const CacheSettingsData({
    required this.novelId,
    required this.settings,
    required this.settingGroups,
  });
  final String novelId;
  final List<dynamic> settings;  // 使用dynamic避免循环导入
  final List<dynamic> settingGroups;

  @override
  List<Object?> get props => [novelId, settings, settingGroups];
}

// 缓存片段数据
class CacheSnippetsData extends ChatEvent {
  const CacheSnippetsData({
    required this.novelId,
    required this.snippets,
  });
  final String novelId;
  final List<dynamic> snippets;  // 使用dynamic避免循环导入

  @override
  List<Object?> get props => [novelId, snippets];
}

// 🚀 新增：更新聊天配置
class UpdateChatConfiguration extends ChatEvent {
  const UpdateChatConfiguration({
    required this.sessionId,
    required this.config,
  });
  
  final String sessionId;
  final UniversalAIRequest config;

  @override
  List<Object?> get props => [sessionId, config];
}
