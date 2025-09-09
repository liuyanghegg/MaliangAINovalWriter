import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/setting_generation/setting_generation_bloc.dart';
import '../../../blocs/setting_generation/setting_generation_event.dart';
import '../../../blocs/setting_generation/setting_generation_state.dart';
import '../../../models/unified_ai_model.dart';
import '../../../models/strategy_template_info.dart';
import '../../../models/setting_generation_session.dart';
import '../../../widgets/common/model_display_selector.dart';
import '../../../blocs/ai_config/ai_config_bloc.dart';
import 'strategy_selector_dropdown.dart';

/// 生成控制面板
class GenerationControlPanel extends StatefulWidget {
  final String? initialPrompt;
  final UnifiedAIModel? selectedModel;
  final String? initialStrategy;
  final Function(String prompt, String strategy, String modelConfigId)? onGenerationStart;

  const GenerationControlPanel({
    Key? key,
    this.initialPrompt,
    this.selectedModel,
    this.initialStrategy,
    this.onGenerationStart,
  }) : super(key: key);

  @override
  State<GenerationControlPanel> createState() => _GenerationControlPanelState();
}

class _GenerationControlPanelState extends State<GenerationControlPanel> {
  late TextEditingController _promptController;
  late TextEditingController _adjustmentController;
  UnifiedAIModel? _selectedModel;
  StrategyTemplateInfo? _selectedStrategy;
  // 防抖计时器，降低输入频率带来的状态分发与重建
  Timer? _adjustmentDebounce;
  // 🔧 新增：跟踪当前活动的会话ID，用于检测会话切换
  String? _currentActiveSessionId;
  // 🔧 新增：跟踪用户是否手动修改了原始创意，避免覆盖用户输入
  bool _userHasModifiedPrompt = false;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.initialPrompt ?? '');
    _adjustmentController = TextEditingController();
    // 注意：_selectedStrategy 将在策略加载完成后根据 widget.initialStrategy 设置

    // 获取用户默认模型配置
    final defaultConfig = context.read<AiConfigBloc>().state.defaultConfig ??
        (context.read<AiConfigBloc>().state.validatedConfigs.isNotEmpty
            ? context.read<AiConfigBloc>().state.validatedConfigs.first
            : null);

    _selectedModel = widget.selectedModel ??
        (defaultConfig != null ? PrivateAIModel(defaultConfig) : null);

    // 🔧 新增：在初始化时同步当前活动会话的原始创意
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentState = context.read<SettingGenerationBloc>().state;
        _handleActiveSessionChange(currentState);
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _adjustmentController.dispose();
    _adjustmentDebounce?.cancel();
    super.dispose();
  }

  /// 🔧 新增：处理活动会话变化，自动填充原始创意
  void _handleActiveSessionChange(SettingGenerationState state) {
    String? activeSessionId;
    SettingGenerationSession? activeSession;

    // 从不同状态中提取活动会话信息
    if (state is SettingGenerationReady) {
      activeSessionId = state.activeSessionId;
      if (activeSessionId != null) {
        try {
          activeSession = state.sessions.firstWhere(
            (s) => s.sessionId == activeSessionId,
          );
        } catch (e) {
          activeSession = state.sessions.isNotEmpty ? state.sessions.first : null;
        }
      }
    } else if (state is SettingGenerationInProgress) {
      activeSessionId = state.activeSessionId;
      activeSession = state.activeSession;
    } else if (state is SettingGenerationCompleted) {
      activeSessionId = state.activeSessionId;
      activeSession = state.activeSession;
    } else if (state is SettingGenerationError) {
      activeSessionId = state.activeSessionId;
      if (activeSessionId != null) {
        try {
          activeSession = state.sessions.firstWhere(
            (s) => s.sessionId == activeSessionId,
          );
        } catch (e) {
          activeSession = state.sessions.isNotEmpty ? state.sessions.first : null;
        }
      }
    }

    // 检测会话是否发生变化
    if (_currentActiveSessionId != activeSessionId && activeSession != null) {
      _currentActiveSessionId = activeSessionId;
      
      // 🎯 核心功能：将历史记录的原始提示词填充到原始创意输入框
      final newPrompt = activeSession.initialPrompt;
      
      // 🔧 智能填充：只有在用户未手动修改原始创意时才自动填充
      // 或者当前输入框为空时总是填充
      final shouldUpdatePrompt = !_userHasModifiedPrompt || _promptController.text.trim().isEmpty;
      
      if (newPrompt.isNotEmpty && _promptController.text != newPrompt && shouldUpdatePrompt) {
        if (mounted) {
          setState(() {
            _promptController.text = newPrompt;
            // 重置用户修改标记，因为这是系统自动填充
            _userHasModifiedPrompt = false;
          });
        }
        
        // 📝 记录日志用于调试
        print('🔄 历史记录切换 - 原始创意已更新: ${newPrompt.substring(0, newPrompt.length > 50 ? 50 : newPrompt.length)}${newPrompt.length > 50 ? "..." : ""}');
      } else if (_userHasModifiedPrompt && newPrompt.isNotEmpty) {
        // 📝 用户已修改，不覆盖但记录日志
        print('🛡️ 历史记录切换 - 检测到用户已修改原始创意，跳过自动填充以保护用户输入');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocListener<SettingGenerationBloc, SettingGenerationState>(
      listener: (context, state) {
        // 🔧 新增：监听活动会话变化，自动填充原始创意
        _handleActiveSessionChange(state);
      },
      child: Card(
        elevation: 0,
        color: isDark 
            ? const Color(0xFF1F2937).withOpacity(0.5) 
            : const Color(0xFFF9FAFB).withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark 
                ? const Color(0xFF1F2937) 
                : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '创作控制台',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // 🔧 修复：自适应高度，紧凑布局
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 提示词输入区域
                      BlocBuilder<SettingGenerationBloc, SettingGenerationState>(
                        builder: (context, state) {
                          return _buildPromptInput(state);
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // 策略选择器
                      _buildStrategySelector(),
                      const SizedBox(height: 16),
                      
                      // 模型选择器
                      _buildModelSelector(),
                      const SizedBox(height: 24), // 适度间距
                      
                      // 操作按钮
                      BlocBuilder<SettingGenerationBloc, SettingGenerationState>(
                        builder: (context, state) {
                          return _buildActionButtons(state);
                        },
                      ),
                      const SizedBox(height: 16), // 底部留白
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptInput(SettingGenerationState state) {
    final hasGeneratedSettings = state is SettingGenerationInProgress ||
        state is SettingGenerationCompleted;

    if (!hasGeneratedSettings) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '你的核心想法',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            decoration: InputDecoration(
              hintText: '例如：一个发生在赛博朋克都市的侦探故事',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            // 🔧 修复：设置合理的行数范围，避免布局问题
            maxLines: 5,
            minLines: 2,
            textInputAction: TextInputAction.newline,
            onChanged: (value) {
              // 🔧 新增：标记用户已手动修改原始创意
              _userHasModifiedPrompt = true;
            },
          ),
        ],
      );
    } else {
      // 🔧 修复：生成完成后显示两个输入框 - 原始提示词和调整提示词
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 原始提示词（只读显示，可以编辑用于新建生成）
          Text(
            '原始创意',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            decoration: InputDecoration(
              hintText: '例如：一个发生在赛博朋克都市的侦探故事',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            // 🎯 自适应行数：根据内容长度调整，最多3行
            maxLines: 3,
            minLines: 1,
            textInputAction: TextInputAction.newline,
            onChanged: (value) {
              // 🔧 新增：标记用户已手动修改原始创意
              _userHasModifiedPrompt = true;
            },
          ),
          const SizedBox(height: 16),
          // 调整提示词
          Text(
            '调整设定',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _adjustmentController,
            decoration: InputDecoration(
              hintText: '例如：将背景改为蒸汽朋克风格',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            // 🔧 修复：设置合理的行数范围，避免布局问题
            maxLines: 4,
            minLines: 2,
            textInputAction: TextInputAction.newline,
            onChanged: (value) {
              // 250ms 防抖，避免每个字符都触发 BLoC 更新与重建
              _adjustmentDebounce?.cancel();
              _adjustmentDebounce = Timer(const Duration(milliseconds: 250), () {
                if (!mounted) return;
                context.read<SettingGenerationBloc>().add(
                  UpdateAdjustmentPromptEvent(_adjustmentController.text),
                );
              });
            },
          ),
        ],
      );
    }
  }

  Widget _buildStrategySelector() {
    return BlocBuilder<SettingGenerationBloc, SettingGenerationState>(
      builder: (context, state) {
        List<StrategyTemplateInfo> strategies = []; // 策略列表
        bool isLoading = false;
        
        if (state is SettingGenerationReady) {
          strategies = state.strategies;
        } else if (state is SettingGenerationInProgress) {
          strategies = state.strategies;
        } else if (state is SettingGenerationCompleted) {
          strategies = state.strategies;
        } else {
          isLoading = true;
        }

        // 🔧 修复：根据 initialStrategy 初始化选中的策略
        if (_selectedStrategy == null && strategies.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              StrategyTemplateInfo? initialSelected;
              if (widget.initialStrategy != null) {
                // 根据名称查找策略
                initialSelected = strategies.firstWhere(
                  (s) => s.name == widget.initialStrategy,
                  orElse: () => strategies.first,
                );
              } else {
                initialSelected = strategies.first;
              }
              setState(() {
                _selectedStrategy = initialSelected;
              });
            }
          });
        }

        // 确保当前选中的策略在可用列表中
        if (_selectedStrategy != null && !strategies.contains(_selectedStrategy)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && strategies.isNotEmpty) {
              setState(() {
                _selectedStrategy = strategies.first;
              });
            }
          });
        }

        return StrategySelectorDropdown(
          strategies: strategies,
          selectedStrategy: _selectedStrategy,
          isLoading: isLoading || strategies.isEmpty,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedStrategy = value;
              });
            }
          },
        );
      },
    );
  }

  Widget _buildModelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI模型',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 8),
        ModelDisplaySelector(
          selectedModel: _selectedModel,
          onModelSelected: (model) {
            setState(() {
              _selectedModel = model;
            });
          },
          size: ModelDisplaySize.medium,
          height: 60, // 扩大一倍高度 (36px * 2)
          showIcon: true,
          showTags: true,
          showSettingsButton: false,
          placeholder: '选择AI模型',
        ),
      ],
    );
  }

  Widget _buildActionButtons(SettingGenerationState state) {
    final hasGeneratedSettings = state is SettingGenerationInProgress ||
        state is SettingGenerationCompleted;
    final isGenerating = state is SettingGenerationInProgress && state.isGenerating;

    if (!hasGeneratedSettings) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isGenerating || _selectedModel == null || _promptController.text.trim().isEmpty
              ? null
              : () {
                  final prompt = _promptController.text.trim();
                  final strategy = _selectedStrategy;
                  final modelConfigId = _selectedModel!.id;
                  
                  if (strategy != null) {
                    // 通知主屏幕更新参数 - 传递策略名称用于显示
                    widget.onGenerationStart?.call(prompt, strategy.name, modelConfigId);
                    
                    final model = _selectedModel!;
                    final bool usePublic = model.isPublic;
                    final String? publicProvider = usePublic ? model.provider : null;
                    final String? publicModelId = usePublic ? model.modelId : null;

                    context.read<SettingGenerationBloc>().add(
                      StartGenerationEvent(
                        initialPrompt: prompt,
                        promptTemplateId: strategy.promptTemplateId, // 🔧 修复：使用策略ID而非名称
                        modelConfigId: modelConfigId,
                        usePublicTextModel: usePublic,
                        textPhasePublicProvider: publicProvider,
                        textPhasePublicModelId: publicModelId,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isGenerating
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('生成中...'),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    const Text('生成设定'),
                  ],
                ),
        ),
      );
    } else {
      // 🔧 修复：生成完成后的按钮逻辑
      return Column(
        children: [
          // 新建生成按钮 - 基于当前配置重新生成
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isGenerating || _selectedModel == null
                  ? null
                  : () {
                      // 使用原始提示词和当前配置重新生成
                      final prompt = _promptController.text.trim();
                      final strategy = _selectedStrategy;
                      final modelConfigId = _selectedModel!.id;
                      
                      if (prompt.isNotEmpty && strategy != null) {
                        // 通知主屏幕更新参数 - 传递策略名称用于显示
                        widget.onGenerationStart?.call(prompt, strategy.name, modelConfigId);
                        
                      final model = _selectedModel!;
                      final bool usePublic = model.isPublic;
                      final String? publicProvider = usePublic ? model.provider : null;
                      final String? publicModelId = usePublic ? model.modelId : null;

                      context.read<SettingGenerationBloc>().add(
                        StartGenerationEvent(
                          initialPrompt: prompt,
                          promptTemplateId: strategy.promptTemplateId,
                          modelConfigId: modelConfigId,
                          usePublicTextModel: usePublic,
                          textPhasePublicProvider: publicProvider,
                          textPhasePublicModelId: publicModelId,
                        ),
                      );
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  const Text('新建生成'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 调整生成按钮行
          // Row(
          //   children: [
          //     // --- 调整生成按钮（改为基于会话整体调整） ---
          //     Expanded(
          //       child: ElevatedButton(
          //         onPressed: isGenerating || _selectedModel == null || _adjustmentController.text.trim().isEmpty
          //             ? null
          //             : () {
          //                 final prompt = _adjustmentController.text.trim();
          //                 final modelConfigId = _selectedModel!.id;

          //                 // 读取当前活跃会话ID
          //                 final currentState = context.read<SettingGenerationBloc>().state;
          //                 String? sessionId;
          //                 if (currentState is SettingGenerationInProgress) {
          //                   sessionId = currentState.activeSessionId;
          //                 } else if (currentState is SettingGenerationCompleted) {
          //                   sessionId = currentState.activeSessionId;
          //                 }

          //                 if (sessionId != null && sessionId.isNotEmpty) {
          //                   // 推测当前策略模板ID（若可获取）
          //                   String? promptTemplateId;
          //                   final state = context.read<SettingGenerationBloc>().state;
          //                   if (state is SettingGenerationInProgress) {
          //                     promptTemplateId = state.activeSession.metadata['promptTemplateId'] as String?;
          //                   } else if (state is SettingGenerationCompleted) {
          //                     promptTemplateId = state.activeSession.metadata['promptTemplateId'] as String?;
          //                   }
          //                   // 优先使用当前选择的策略模板ID
          //                   if (_selectedStrategy != null) {
          //                     promptTemplateId = _selectedStrategy!.promptTemplateId;
          //                   }
          //                   context.read<SettingGenerationBloc>().add(
          //                     AdjustGenerationEvent(
          //                       sessionId: sessionId,
          //                       adjustmentPrompt: prompt,
          //                       modelConfigId: modelConfigId,
          //                       promptTemplateId: promptTemplateId,
          //                     ),
          //                   );
          //                 }
          //               },
          //         style: ElevatedButton.styleFrom(
          //           padding: const EdgeInsets.symmetric(vertical: 10),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(8),
          //           ),
          //         ),
          //         child: Row(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             Icon(
          //               Icons.refresh,
          //               size: 14,
          //               color: Theme.of(context).colorScheme.onPrimary,
          //             ),
          //             const SizedBox(width: 4),
          //             const Text('调整生成', style: TextStyle(fontSize: 12)),
          //           ],
          //         ),
          //       ),
          //     ),

          //     const SizedBox(width: 8),

          //     // --- 创建分支按钮 ---
          //     Expanded(
          //       child: Tooltip(
          //         message: '基于当前设定和调整提示词创建新的历史记录',
          //         child: ElevatedButton(
          //           onPressed: isGenerating || _selectedModel == null || _adjustmentController.text.trim().isEmpty
          //               ? null
          //               : () {
          //                   final prompt = _adjustmentController.text.trim();
          //                   final strategy = _selectedStrategy;
          //                   final modelConfigId = _selectedModel!.id;

          //                   if (strategy != null) {
          //                     // 通知主屏幕更新参数 - 传递策略名称用于显示
          //                     widget.onGenerationStart?.call(prompt, strategy.name, modelConfigId);

          //                     // 创建分支
          //                     context.read<SettingGenerationBloc>().add(
          //                       StartGenerationEvent(
          //                         initialPrompt: prompt,
          //                         promptTemplateId: strategy.promptTemplateId, // 🔧 修复：使用策略ID而非名称
          //                         modelConfigId: modelConfigId,
          //                       ),
          //                     );
          //                   }
          //                 },
          //           style: ElevatedButton.styleFrom(
          //             padding: const EdgeInsets.symmetric(vertical: 10),
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(8),
          //             ),
          //           ),
          //           child: Row(
          //             mainAxisAlignment: MainAxisAlignment.center,
          //             children: [
          //               Icon(
          //                 Icons.call_split,
          //                 size: 14,
          //                 color: Theme.of(context).colorScheme.onPrimary,
          //               ),
          //               const SizedBox(width: 4),
          //               const Text('创建分支', style: TextStyle(fontSize: 12)),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      );
    }
  }
}
