import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../models/chat_models.dart';
import '../../models/user_ai_model_config_model.dart';
import '../../utils/logger.dart';
import '../../widgets/common/top_toast.dart';
import 'widgets/chat_input.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/context_panel.dart';
import 'widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    Key? key,
    required this.novelId,
    this.chapterId,
  }) : super(key: key);
  final String novelId;
  final String? chapterId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isContextPanelExpanded = false;

  @override
  void initState() {
    super.initState();
    // 加载聊天会话列表
    context.read<ChatBloc>().add(LoadChatSessions(novelId: widget.novelId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 滚动到底部
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // 发送消息
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<ChatBloc>().add(SendMessage(content: message));
      _messageController.clear();

      // 延迟滚动到底部，等待消息添加到列表
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  // 切换上下文面板
  void _toggleContextPanel() {
    setState(() {
      _isContextPanelExpanded = !_isContextPanelExpanded;
    });
  }

  // 创建新会话
  void _createNewSession() {
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建新会话'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入会话标题',
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              context.read<ChatBloc>().add(CreateChatSession(
                    title: value,
                    novelId: widget.novelId,
                    chapterId: widget.chapterId,
                  ));
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final title = titleController.text.trim();

              if (title.isNotEmpty) {
                context.read<ChatBloc>().add(CreateChatSession(
                      title: title,
                      novelId: widget.novelId,
                      chapterId: widget.chapterId,
                    ));
                Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  // 选择会话
  void _selectSession(String sessionId) {
    context.read<ChatBloc>().add(SelectChatSession(sessionId: sessionId, novelId: widget.novelId));
  }

  // 执行操作
  void _executeAction(MessageAction action) {
    context.read<ChatBloc>().add(ExecuteAction(action: action));

    // 显示操作执行提示
    TopToast.info(context, '执行操作: ${action.label}');
  }

  /// 🚀 检查消息列表中是否有正在流式传输的消息
  bool _hasStreamingMessage(List<dynamic> messages) {
    return messages.any((message) => message.status == 'streaming' || message.status?.toString() == 'MessageStatus.streaming');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      // 使用 surfaceContainerLow 作为基础背景色
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        // AppBar 背景色
        backgroundColor: colorScheme.surfaceContainer,
        // 移除默认阴影，让边框控制分割
        elevation: 0,
        // 底部边框
        shape: Border(
            bottom: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.5),
                width: 1.0)),
        title: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            String titleText = 'AI 聊天助手'; // 默认标题
            if (state is ChatSessionActive) {
              titleText = state.session.title; // 活动会话标题
            } else if (state is ChatSessionsLoaded) {
              // 可以考虑在列表视图显示不同的标题
              titleText = '聊天会话';
            }
            return Text(
              titleText,
              style: TextStyle(
                // 统一标题样式
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            );
          },
        ),
        centerTitle: false, // 标题居左
        // AppBar 操作按钮颜色
        iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        actions: [
          // 新建会话按钮
          IconButton(
            icon: const Icon(Icons.add_comment_outlined), // 换图标
            tooltip: '新建会话',
            onPressed: _createNewSession,
          ),
          // 上下文面板切换按钮
          IconButton(
            // 根据状态改变图标，增加视觉反馈
            icon: Icon(_isContextPanelExpanded
                ? Icons.info_rounded
                : Icons.info_outline_rounded),
            tooltip: _isContextPanelExpanded ? '关闭上下文' : '打开上下文',
            // 可以根据状态改变颜色
            color: _isContextPanelExpanded
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            onPressed: _toggleContextPanel,
          ),
          // 会话列表按钮 (如果希望保留在 AppBar 中)
          IconButton(
            icon: const Icon(Icons.menu_open_rounded), // 换图标
            tooltip: '会话列表',
            onPressed: _showSessionsDialog,
          ),
          /* PopupMenuButton<String>( // 或者继续用 PopupMenu
               icon: const Icon(Icons.more_vert_rounded),
               onSelected: (value) {
                 if (value == 'sessions') {
                   _showSessionsDialog();
                 }
                 // TODO: 添加其他菜单项，如删除会话、重命名等
               },
               itemBuilder: (context) => [
                 const PopupMenuItem(
                   value: 'sessions',
                   child: ListTile(leading: Icon(Icons.list_alt_rounded), title: Text('会话列表')),
                 ),
                 // Add other options here...
               ],
             ), */
          const SizedBox(width: 8), // 右边距
        ],
      ),
      // 使用 SafeArea 避免内容与系统 UI 重叠
      body: SafeArea(
        child: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            // --- SnackBar 错误提示 (样式不变) ---
            if (state is ChatSessionsLoaded && state.error != null) {
              TopToast.error(context, state.error!);
            }
            if (state is ChatSessionActive && state.error != null) {
              TopToast.error(context, state.error!);
            }
            // --- 滚动逻辑 ---
            if (state is ChatSessionActive && !state.isLoadingHistory) {
              // 当新消息添加或流式更新时，滚动到底部
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            }
          },
          // --- buildWhen 优化检查 ---
          buildWhen: (previous, current) {
            // 允许从加载状态转换
            if ((previous is ChatSessionsLoading ||
                    previous is ChatSessionLoading) &&
                (current is ChatSessionsLoaded ||
                    current is ChatSessionActive)) {
              return true;
            }
            // 允许错误和初始状态
            if (current is ChatError || current is ChatInitial) return true;
            // 在 ChatSessionActive 内更新的条件
            if (previous is ChatSessionActive && current is ChatSessionActive) {
              return previous.session.id != current.session.id || // 会话切换
                  previous.messages != current.messages || // 消息变化 (浅比较)
                  previous.isGenerating != current.isGenerating ||
                  previous.isLoadingHistory != current.isLoadingHistory ||
                  previous.error != current.error ||
                  previous.selectedModel?.id !=
                      current.selectedModel?.id; // 模型变化
            }
            // 在 ChatSessionsLoaded 内更新的条件
            if (previous is ChatSessionsLoaded &&
                current is ChatSessionsLoaded) {
              return previous.sessions != current.sessions || // 列表变化
                  previous.error != current.error;
            }
            // 从活动会话返回列表
            if (previous is ChatSessionActive &&
                current is ChatSessionsLoaded) {
              return true;
            }
            // 从列表进入活动会话
            if (previous is ChatSessionsLoaded &&
                current is ChatSessionActive) {
              return true;
            }

            // 其他情况，如果类型不同则重建
            return previous.runtimeType != current.runtimeType;
          },
          builder: (context, state) {
            AppLogger.d('ChatScreen builder',
                'Building UI for state: ${state.runtimeType}');
            // --- 加载状态 ---
            if (state is ChatSessionsLoading || state is ChatSessionLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // --- 列表或活动会话 ---
            // 修改：不再直接显示列表，主界面始终是聊天视图
            // 会话列表通过 AppBar 按钮或侧边栏显示
            else if (state is ChatSessionActive ||
                state is ChatSessionsLoaded ||
                state is ChatInitial) {
              // 如果当前是列表状态且有会话，可以自动选择第一个或上次的会话
              // 这里简化处理：如果 state 不是 ChatSessionActive，则显示提示或空状态
              if (state is ChatSessionActive) {
                return _buildChatView(state);
              } else {
                // 显示初始/空状态视图，提示用户选择或创建会话
                return _buildInitialEmptyState();
              }
            }
            // (旧的 _buildSessionsList 调用被移除或移到对话框/侧边栏)
            // else if (state is ChatSessionsLoaded) { ... }

            // --- 错误状态 ---
            else if (state is ChatError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    // 改进错误显示
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: colorScheme.error, size: 48),
                      const SizedBox(height: 16),
                      Text('出现错误',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: colorScheme.error)),
                      const SizedBox(height: 8),
                      Text(state.message,
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: colorScheme.onErrorContainer)),
                      const SizedBox(height: 16),
                      // 可以添加重试按钮
                      /* ElevatedButton.icon(
                           onPressed: () {
                               // 根据错误类型决定重试哪个操作
                               if (state.message.contains("加载会话列表失败")) {
                                  context.read<ChatBloc>().add(LoadChatSessions(novelId: widget.novelId));
                               } else if (state.message.contains("加载消息失败")){
                                  // 需要知道当前会话 ID 来重试加载消息
                               }
                           },
                           icon: Icon(Icons.refresh_rounded),
                           label: Text("重试"),
                           style: ElevatedButton.styleFrom(foregroundColor: colorScheme.onError, backgroundColor: colorScheme.error),
                        )*/
                    ],
                  ),
                ),
              );
            }
            // --- 其他未处理状态 ---
            else {
              // 可以返回一个更通用的空状态或加载指示器
              return _buildInitialEmptyState();
            }
          },
        ),
      ),
    );
  }

  // 构建初始空状态视图
  Widget _buildInitialEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined,
                size: 64, color: colorScheme.secondary), // 使用不同图标
            const SizedBox(height: 24),
            Text(
              '选择或创建会话',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '开始与 AI 助手聊天吧！',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
                // 并排显示按钮
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    // 打开列表按钮
                    onPressed: _showSessionsDialog,
                    icon: const Icon(Icons.list_alt_rounded),
                    label: const Text('选择已有对话'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(
                          color: colorScheme.outline.withOpacity(0.8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    // 创建新会话按钮
                    onPressed: _createNewSession,
                    icon: const Icon(Icons.add_comment_outlined),
                    label: const Text('创建新对话'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: colorScheme.onPrimary,
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ])
          ],
        ),
      ),
    );
  }

  // 构建会话列表 - 从主 builder 移出，现在只用于对话框或侧边栏
  // (这里保留，适配对话框使用)
  Widget _buildSessionsListForDialog(ChatSessionsLoaded state) {
    final sessions = state.sessions;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.maxFinite,
      // 根据内容调整高度，限制最大高度
      // height: sessions.isEmpty ? 150 : (sessions.length * 60.0 + (state.error != null ? 40 : 0)).clamp(150.0, 400.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 高度自适应内容
        children: [
          // 显示错误
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 16, right: 16),
              child: Text(state.error!,
                  style: TextStyle(color: colorScheme.error)),
            ),
          // 列表或空状态
          Flexible(
            // 使用 Flexible 允许列表在 Column 内滚动
            child: sessions.isEmpty
                ? const Center(
                    child: Padding(
                    // 改进空列表提示
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Text('没有找到任何对话记录'),
                  ))
                : ListView.builder(
                    shrinkWrap: true, // 在 Column 中需要
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      // 获取当前活动会话 ID
                      String? activeSessionId;
                      final currentState = context.read<ChatBloc>().state;
                      if (currentState is ChatSessionActive) {
                        activeSessionId = currentState.session.id;
                      }
                      final bool isSelected = session.id == activeSessionId;

                      return ListTile(
                        leading: Icon(
                          // 图标指示
                          isSelected
                              ? Icons.chat_bubble_rounded
                              : Icons.chat_bubble_outline_rounded,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          session.title,
                          style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                        ),
                        subtitle: Text(
                          '更新于: ${DateFormat('yyyy-MM-dd HH:mm').format(session.lastUpdatedAt)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.8)),
                        ),
                        selected: isSelected,
                        selectedTileColor:
                            colorScheme.primaryContainer.withOpacity(0.1),
                        onTap: () {
                          _selectSession(session.id);
                          Navigator.pop(context); // Close dialog
                        },
                        // 可以添加删除按钮
                        /* trailing: IconButton(
                          icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              onPressed: () {
                                 // TODO: 确认删除逻辑
                                 // context.read<ChatBloc>().add(DeleteChatSession(sessionId: session.id));
                              },
                              tooltip: '删除会话',
                           ), */
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 构建聊天视图 (样式调整)
  Widget _buildChatView(ChatSessionActive state) {
    final UserAIModelConfigModel? currentChatModel = state.selectedModel;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // 聊天主界面
        Expanded(
          // 根据上下文面板状态调整 flex 比例
          flex: _isContextPanelExpanded ? 3 : 5, // 主聊天区域占比更大
          // 使用 Container 设置背景色
          child: Container(
            color: colorScheme.surface, // 主聊天区域背景色
            child: Column(
              children: [
                // 历史加载指示器（保持不变）
                if (state.isLoadingHistory)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                // 可以考虑在此处显示持久的错误信息（如果不用 SnackBar）
                /* if (state.error != null && !state.isLoadingHistory)
                    Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       color: colorScheme.errorContainer,
                       child: Row(children: [
                         Icon(Icons.error_outline, color: colorScheme.onErrorContainer, size: 16),
                         SizedBox(width: 8),
                         Expanded(child: Text(state.error!, style: TextStyle(color: colorScheme.onErrorContainer))),
                       ]),
                    ), */
                // 消息列表
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    // 增加上下内边距，左右在 Bubble 中处理
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    itemCount: state.messages.length +
                        (state.isGenerating && !state.isLoadingHistory && !_hasStreamingMessage(state.messages) ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 🚀 只有在没有流式消息且正在生成时才显示TypingIndicator
                      if (state.isGenerating &&
                          !state.isLoadingHistory &&
                          !_hasStreamingMessage(state.messages) &&
                          index == state.messages.length) {
                        return const TypingIndicator();
                      }

                      final message = state.messages[index];
                      // 🚀 所有消息都使用ChatMessageBubble，包括streaming状态的消息
                      return ChatMessageBubble(
                        message: message,
                        onActionSelected: _executeAction, // 动作回调
                      );
                    },
                  ),
                ),

                // 输入区域 (ChatInput 已在上面修改)
                ChatInput(
                  controller: _messageController,
                  onSend: _sendMessage,
                  isGenerating: state.isGenerating,
                  onCancel: () {
                    context.read<ChatBloc>().add(const CancelOngoingRequest());
                  },
                  initialModel: currentChatModel,
                  onModelSelected: (selectedModel) {
                    if (selectedModel != null &&
                        selectedModel.id != currentChatModel?.id) {
                      context.read<ChatBloc>().add(UpdateChatModel(
                            sessionId: state.session.id,
                            modelConfigId: selectedModel.id,
                          ));
                      AppLogger.i('ChatScreen',
                          'Model selected event dispatched: ${selectedModel.id} for session ${state.session.id}');
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        // 上下文面板 (ContextPanel 已在上面修改)
        if (_isContextPanelExpanded)
          Expanded(
            flex: 2, // 上下文面板 flex 比例
            child: ContextPanel(
              context: state.context,
              onClose: _toggleContextPanel,
            ),
          ),
      ],
    );
  }

  // 显示会话列表对话框 (样式调整)
  void _showSessionsDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // 对话框样式
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        backgroundColor: colorScheme.surfaceContainerHigh, // 背景色
        titlePadding:
            const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 10),
        contentPadding: const EdgeInsets.only(bottom: 8), // 调整内容边距
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        title: Text('选择对话',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        content: BlocBuilder<ChatBloc, ChatState>(
          // 监听会话列表相关状态
          buildWhen: (prev, curr) =>
              curr is ChatSessionsLoaded ||
              curr is ChatSessionsLoading ||
              curr is ChatSessionActive,
          builder: (context, state) {
            // 尝试从 Bloc 获取当前的会话列表状态
            ChatSessionsLoaded? listState;
            if (state is ChatSessionsLoaded) {
              listState = state;
            } else if (state is ChatSessionActive) {
              // 如果当前是活动会话，也需要显示列表，需要能从ChatBloc获取到完整列表
              // 这要求 ChatBloc 在 ChatSessionActive 状态下仍然持有 sessions 列表
              // 或者在这里触发一次 LoadChatSessions (但不推荐，可能导致状态混乱)
              // 更好的方式是修改 Bloc，使其在 Active 状态下也能提供列表
              // 暂时假设可以获取到 (如果不行，对话框内容需要调整)
              // listState = context.read<ChatBloc>().getAllSessionsState(); // 假设有这个方法
            }

            if (listState != null) {
              // 使用更新后的列表构建方法
              return _buildSessionsListForDialog(listState);
            } else if (state is ChatSessionsLoading) {
              // 处理加载状态
              return const SizedBox(
                height: 150, // 固定高度
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              // 处理其他未能获取列表的状态
              return const SizedBox(
                  height: 100, child: Center(child: Text('无法加载会话列表')));
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 先关闭对话框
              _createNewSession(); // 再打开创建对话框
            },
            style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold)),
            child: const Text('新建对话'),
          ),
        ],
      ),
    );
  }
}
