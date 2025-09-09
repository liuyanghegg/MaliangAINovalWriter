import 'package:equatable/equatable.dart';
import '../../models/chat_models.dart';
import '../../models/user_ai_model_config_model.dart';
import '../../models/ai_request_models.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

// 初始状态
class ChatInitial extends ChatState {}

// 加载会话列表中
class ChatSessionsLoading extends ChatState {}

// 会话列表加载完成
class ChatSessionsLoaded extends ChatState {
  const ChatSessionsLoaded({
    required this.sessions,
    this.error,
  });

  final List<ChatSession> sessions;
  final String? error;

  @override
  List<Object?> get props => [sessions, error];

  ChatSessionsLoaded copyWith({
    List<ChatSession>? sessions,
    String? error,
    bool clearError = false,
  }) {
    return ChatSessionsLoaded(
      sessions: sessions ?? this.sessions,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// 加载单个会话中
class ChatSessionLoading extends ChatState {}

// 会话激活状态
class ChatSessionActive extends ChatState {
  const ChatSessionActive({
    required this.session,
    required this.context,
    this.messages = const [],
    this.selectedModel,

    this.isGenerating = false,
    this.isLoadingHistory = false,
    this.error,
    this.cachedSettings = const [],
    this.cachedSettingGroups = const [],
    this.cachedSnippets = const [],
    this.isLoadingContextData = false,
    this.configUpdateTimestamp,
  });

  final ChatSession session;
  final ChatContext context;
  final List<ChatMessage> messages;
  final UserAIModelConfigModel? selectedModel;

  final bool isGenerating;
  final bool isLoadingHistory;
  final String? error;
  
  // 缓存的上下文数据
  final List<dynamic> cachedSettings;      // NovelSettingItem列表
  final List<dynamic> cachedSettingGroups; // SettingGroup列表
  final List<dynamic> cachedSnippets;      // NovelSnippet列表
  final bool isLoadingContextData;
  final DateTime? configUpdateTimestamp;   // 配置更新时间戳，用于触发UI重建

  @override
  List<Object?> get props => [
        session,
        context,
        messages,
        selectedModel,
        isGenerating,
        isLoadingHistory,
        error,
        cachedSettings,
        cachedSettingGroups,
        cachedSnippets,
        isLoadingContextData,
        configUpdateTimestamp,
      ];

  ChatSessionActive copyWith({
    ChatSession? session,
    ChatContext? context,
    List<ChatMessage>? messages,
    Object? selectedModel = const Object(),

    bool? isGenerating,
    bool? isLoadingHistory,
    String? error,
    bool clearError = false,
    List<dynamic>? cachedSettings,
    List<dynamic>? cachedSettingGroups,
    List<dynamic>? cachedSnippets,
    bool? isLoadingContextData,
    DateTime? configUpdateTimestamp,
  }) {
    UserAIModelConfigModel? updatedSelectedModel;
    if (selectedModel is UserAIModelConfigModel?){
        updatedSelectedModel = selectedModel;
    } else {
        updatedSelectedModel = this.selectedModel;
    }

    return ChatSessionActive(
      session: session ?? this.session,
      context: context ?? this.context,
      messages: messages ?? this.messages,
      selectedModel: updatedSelectedModel,

      isGenerating: isGenerating ?? this.isGenerating,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: clearError ? null : error ?? this.error,
      cachedSettings: cachedSettings ?? this.cachedSettings,
      cachedSettingGroups: cachedSettingGroups ?? this.cachedSettingGroups,
      cachedSnippets: cachedSnippets ?? this.cachedSnippets,
      isLoadingContextData: isLoadingContextData ?? this.isLoadingContextData,
      configUpdateTimestamp: configUpdateTimestamp ?? this.configUpdateTimestamp,
    );
  }
}

// 错误状态
class ChatError extends ChatState {
  const ChatError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
} 