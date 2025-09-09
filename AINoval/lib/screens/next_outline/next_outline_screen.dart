import 'package:ainoval/blocs/next_outline/next_outline_bloc.dart';
import 'package:ainoval/blocs/next_outline/next_outline_event.dart';
import 'package:ainoval/blocs/next_outline/next_outline_state.dart';
import 'package:ainoval/models/next_outline/next_outline_dto.dart';
import 'package:ainoval/models/user_ai_model_config_model.dart';
import 'package:ainoval/screens/next_outline/widgets/modern_config_card.dart';
import 'package:ainoval/screens/next_outline/widgets/results_grid.dart';
import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/services/api_service/repositories/editor_repository.dart';
import 'package:ainoval/services/api_service/repositories/impl/editor_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/next_outline_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/impl/user_ai_model_config_repository_impl.dart';
import 'package:ainoval/services/api_service/repositories/next_outline_repository.dart';
import 'package:ainoval/services/api_service/repositories/user_ai_model_config_repository.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/common/loading_indicator.dart';
import 'package:ainoval/widgets/common/top_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// 剧情推演屏幕 - 核心功能组件
/// 
/// 此组件负责剧情推演的完整功能流程：
/// 1. 配置生成参数（章节范围、模型选择、生成数量等）
/// 2. 调用AI服务生成多个剧情选项
/// 3. 展示生成结果并支持交互操作
/// 4. 保存选中的剧情到小说结构中
/// 
/// 设计特点：
/// - 采用纯黑白配色方案，符合现代简洁审美
/// - 使用响应式布局，适配不同屏幕尺寸
/// - 合理的间距和尺寸，避免界面拥挤
/// - 统一的视觉层次和交互反馈
class NextOutlineScreen extends StatelessWidget {
  /// 小说ID - 用于关联具体的小说项目
  final String novelId;
  
  /// 小说标题 - 用于上下文展示
  final String novelTitle;
  
  /// 切换到写作模式回调 - 完成推演后返回编辑
  final VoidCallback onSwitchToWrite;

  /// 跳转到添加模型页面的回调 - 配置新的AI模型
  final VoidCallback? onNavigateToAddModel;

  /// 跳转到配置特定模型页面的回调 - 调整模型参数
  final Function(String configId)? onConfigureModel;

  const NextOutlineScreen({
    Key? key,
    required this.novelId,
    required this.novelTitle,
    required this.onSwitchToWrite,
    this.onNavigateToAddModel,
    this.onConfigureModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final editorRepository = EditorRepositoryImpl(apiClient: apiClient);
    
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<NextOutlineRepository>(
          create: (context) => NextOutlineRepositoryImpl(
            apiClient: apiClient,
          ),
        ),
        RepositoryProvider<UserAIModelConfigRepository>(
          create: (context) => UserAIModelConfigRepositoryImpl(
            apiClient: apiClient,
          ),
        ),
      ],
      child: BlocProvider(
        create: (context) => NextOutlineBloc(
          nextOutlineRepository: context.read<NextOutlineRepository>(),
          editorRepository: editorRepository,
          userAIModelConfigRepository: context.read<UserAIModelConfigRepository>(),
        )..add(NextOutlineInitialized(novelId: novelId)),
        child: _NextOutlineScreenContent(
          novelId: novelId,
          novelTitle: novelTitle,
          onSwitchToWrite: onSwitchToWrite,
          onNavigateToAddModel: onNavigateToAddModel,
          onConfigureModel: onConfigureModel,
        ),
      ),
    );
  }
}

/// 剧情推演屏幕内容组件 - 核心业务逻辑实现
/// 
/// 此组件专注于：
/// 1. 状态管理和业务逻辑处理
/// 2. 用户界面的响应式布局
/// 3. 错误处理和用户反馈
/// 4. 组件间的数据传递和事件处理
/// 
/// 布局结构：
/// - 左侧：配置面板和AI模型选择
/// - 右侧：结果展示区域（生成的剧情选项网格）
/// - 统一的间距和视觉层次
class _NextOutlineScreenContent extends StatefulWidget {
  /// 小说ID
  final String novelId;
  
  /// 小说标题
  final String novelTitle;
  
  /// 切换到写作模式回调
  final VoidCallback onSwitchToWrite;

  /// 跳转到添加模型页面的回调
  final VoidCallback? onNavigateToAddModel;

  /// 跳转到配置特定模型页面的回调
  final Function(String configId)? onConfigureModel;

  const _NextOutlineScreenContent({
    Key? key,
    required this.novelId,
    required this.novelTitle,
    required this.onSwitchToWrite,
    this.onNavigateToAddModel,
    this.onConfigureModel,
  }) : super(key: key);

  @override
  State<_NextOutlineScreenContent> createState() => _NextOutlineScreenContentState();
}

/// 剧情推演屏幕状态管理
class _NextOutlineScreenContentState extends State<_NextOutlineScreenContent> {
  List<String> _selectedConfigIds = [];
  bool _hasInitialized = false;
  
  @override
  void initState() {
    super.initState();
  }

  /// 根据AI模型配置列表初始化选中状态
  void _initializeSelectedConfigs(List<UserAIModelConfigModel> aiModelConfigs) {
    if (!_hasInitialized && aiModelConfigs.isNotEmpty) {
      // 默认选择第一个已验证的模型配置
      final validatedConfigs = aiModelConfigs.where((config) => config.isValidated).toList();
      if (validatedConfigs.isNotEmpty && _selectedConfigIds.isEmpty) {
        _selectedConfigIds = [validatedConfigs.first.id];
        _hasInitialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用卡片颜色作为页面背景，避免多层颜色差异
      backgroundColor: WebTheme.getCardColor(context),
      body: BlocConsumer<NextOutlineBloc, NextOutlineState>(
        listenWhen: (previous, current) => 
          previous.generationStatus != current.generationStatus,
        listener: (context, state) {
          // 统一的错误处理 - 使用TopToast显示错误信息
          if (state.generationStatus == GenerationStatus.error && 
              state.errorMessage != null) {
            TopToast.error(context, state.errorMessage!);
          }
        },
        builder: (context, state) {
          // 初始化AI模型选择状态（不调用setState，直接设置状态）
          _initializeSelectedConfigs(state.aiModelConfigs);
          
          // 加载状态 - 现代简洁的加载指示器
          if (state.generationStatus == GenerationStatus.loadingChapters ||
              state.generationStatus == GenerationStatus.loadingModels) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: WebTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: WebTheme.getShadowColor(context, opacity: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const LoadingIndicator(message: '正在初始化...'),
              ),
            );
          }
          
          // 主内容区域 - 左右分栏布局
          return Container(
            constraints: const BoxConstraints(
              maxWidth: 1600, // 适应左右布局的更大宽度
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                vertical: 32, // 顶部和底部的充足间距
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 页面标题区域
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24), // 标题区域添加内边距
                    child: _buildPageHeader(context),
                  ),
                  
                  const SizedBox(height: 32), // 标题与主内容的间距
                  
                  // 左右分栏主内容区域
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左侧栏 - 表单和AI模型列表
                      Expanded(
                        flex: 2, // 左侧占比
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 配置表单面板
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(),
                              child: ModernConfigCard(
                                chapters: state.chapters,
                                aiModelConfigs: state.aiModelConfigs,
                                startChapterId: state.startChapterId,
                                endChapterId: state.endChapterId,
                                numOptions: state.numOptions,
                                authorGuidance: state.authorGuidance,
                                isGenerating: state.generationStatus == GenerationStatus.generatingInitial ||
                                             state.generationStatus == GenerationStatus.generatingSingle,
                                onStartChapterChanged: (chapterId) {
                                  context.read<NextOutlineBloc>().add(
                                    UpdateChapterRangeRequested(
                                      startChapterId: chapterId,
                                      endChapterId: state.endChapterId,
                                    ),
                                  );
                                },
                                onEndChapterChanged: (chapterId) {
                                  context.read<NextOutlineBloc>().add(
                                    UpdateChapterRangeRequested(
                                      startChapterId: state.startChapterId,
                                      endChapterId: chapterId,
                                    ),
                                  );
                                },
                                onNumOptionsChanged: (value) {
                                  // 数量变更处理 - 暂存在本地，生成时更新状态
                                },
                                onAuthorGuidanceChanged: (value) {
                                  // 引导变更处理 - 暂存在本地，生成时更新状态
                                },
                                onGenerate: (numOptions, authorGuidance, selectedConfigIds) {
                                  final request = GenerateNextOutlinesRequest(
                                    startChapterId: state.startChapterId,
                                    endChapterId: state.endChapterId,
                                    numOptions: numOptions,
                                    authorGuidance: authorGuidance,
                                    selectedConfigIds: _selectedConfigIds.isEmpty ? null : _selectedConfigIds,
                                  );
                                  
                                  context.read<NextOutlineBloc>().add(
                                    GenerateNextOutlinesRequested(request: request),
                                  );
                                },
                                onNavigateToAddModel: widget.onNavigateToAddModel,
                                onConfigureModel: widget.onConfigureModel,
                              ),
                            ),
                            
                            const SizedBox(height: 24), // 表单与AI模型列表的间距
                            
                                                                  // AI模型列表区域
                             _buildAIModelList(context, state),
                             
                             const SizedBox(height: 16),
                             
                             // AI模型选择提示
                             _buildModelSelectionHints(context, state),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16), // 左右栏间距
                      
                      // 右侧栏 - 生成结果展示
                      Expanded(
                        flex: 3, // 右侧占比更大，用于展示结果
                        child: Container(
                           width: double.infinity,
                           decoration: const BoxDecoration(),
                           padding: const EdgeInsets.all(24), // 内部间距
                           child: ResultsGrid(
                             outlineOptions: state.outlineOptions,
                             selectedOptionId: state.selectedOptionId,
                             aiModelConfigs: state.aiModelConfigs,
                             isGenerating: state.generationStatus == GenerationStatus.generatingInitial,
                             isSaving: state.generationStatus == GenerationStatus.saving,
                             onOptionSelected: (optionId) {
                               context.read<NextOutlineBloc>().add(
                                 OutlineSelected(optionId: optionId),
                               );
                             },
                             onRegenerateSingle: (optionId, configId, hint) {
                               final request = RegenerateOptionRequest(
                                 optionId: optionId,
                                 selectedConfigId: configId,
                                 regenerateHint: hint,
                               );
                               
                               context.read<NextOutlineBloc>().add(
                                 RegenerateSingleOutlineRequested(request: request),
                               );
                             },
                             onRegenerateAll: (hint) {
                               context.read<NextOutlineBloc>().add(
                                 RegenerateAllOutlinesRequested(regenerateHint: hint),
                               );
                             },
                             onSaveOutline: (optionId, insertType) {
                               final request = SaveNextOutlineRequest(
                                 outlineId: optionId,
                                 insertType: insertType,
                               );
                               
                               // 查找选中选项的索引
                               final selectedOptionIndex = state.outlineOptions.indexWhere(
                                 (option) => option.optionId == optionId
                               );
                               
                               context.read<NextOutlineBloc>().add(
                                 SaveSelectedOutlineRequested(
                                   request: request,
                                   selectedOutlineIndex: selectedOptionIndex >= 0 ? selectedOptionIndex : null,
                                 ),
                               );
                             },
                           ),
                        ),
                      ),
                    ],
                  ),
                  
                  // 底部安全间距
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建页面标题区域（可选）
  /// 提供视觉层次和上下文信息
  Widget _buildPageHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主标题
        Row(
          children: [
            Icon(
              LucideIcons.brain_circuit,
              size: 28,
              color: WebTheme.getTextColor(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '剧情推演',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: WebTheme.getTextColor(context),
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 副标题/说明
        Padding(
          padding: const EdgeInsets.only(left: 44), // 与图标对齐
          child: Text(
            '为《${widget.novelTitle}》生成多个剧情发展选项，助力创作灵感',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: WebTheme.getSecondaryTextColor(context),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

    /// 构建AI模型列表区域
  /// 独立的AI模型管理和选择界面
  Widget _buildAIModelList(BuildContext context, NextOutlineState state) {
    final allConfigs = state.aiModelConfigs;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: WebTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: WebTheme.getShadowColor(context, opacity: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和操作按钮
          Row(
            children: [
              Icon(
                LucideIcons.list_checks,
                size: 20,
                color: WebTheme.getTextColor(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI 模型选择',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
              ),
              if (widget.onNavigateToAddModel != null)
                TextButton.icon(
                  icon: Icon(
                    LucideIcons.plus,
                    size: 16,
                    color: WebTheme.getTextColor(context),
                  ),
                  label: Text(
                    '添加',
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getTextColor(context),
                    ),
                  ),
                  onPressed: widget.onNavigateToAddModel,
                  style: WebTheme.getSecondaryButtonStyle(context).copyWith(
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    minimumSize: MaterialStateProperty.all(Size.zero),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 副标题说明
          Text(
            '选择用于生成的AI模型',
            style: TextStyle(
              fontSize: 14,
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 模型列表
          if (allConfigs.isEmpty)
            _buildEmptyModelState(context)
          else
            _buildModelList(context, allConfigs),
        ],
      ),
    );
  }

  /// 构建空模型状态
  Widget _buildEmptyModelState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebTheme.getEmptyStateColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.info,
            size: 32,
            color: WebTheme.getSecondaryTextColor(context),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无可用模型',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: WebTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请添加和配置AI模型服务',
            style: TextStyle(
              fontSize: 14,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建模型列表
  Widget _buildModelList(BuildContext context, List<UserAIModelConfigModel> configs) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: configs.asMap().entries.map((entry) {
          final index = entry.key;
          final config = entry.value;
          final isSelected = _selectedConfigIds.contains(config.id);
          final isValidated = config.isValidated;
          final isLast = index == configs.length - 1;

          return Container(
            decoration: BoxDecoration(
              border: isLast ? null : Border(
                bottom: BorderSide(
                  color: WebTheme.getBorderColor(context),
                  width: 1,
                ),
              ),
            ),
            child: isValidated 
              ? _buildValidatedModelItem(context, config, isSelected)
              : _buildUnvalidatedModelItem(context, config),
          );
        }).toList(),
      ),
    );
  }

  /// 构建已验证的模型项 - 支持多选
  Widget _buildValidatedModelItem(BuildContext context, UserAIModelConfigModel config, bool isSelected) {
    return CheckboxListTile(
      title: Text(
        config.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: WebTheme.getTextColor(context),
        ),
      ),
      subtitle: Text(
        '已验证可用',
        style: TextStyle(
          fontSize: 12,
          color: WebTheme.success,
        ),
      ),
      value: isSelected,
      onChanged: (selected) {
        setState(() {
          if (selected == true) {
            _selectedConfigIds.add(config.id);
          } else {
            _selectedConfigIds.remove(config.id);
          }
        });
      },
      secondary: Icon(
        _getIconForModel(config.name),
        color: isSelected 
          ? WebTheme.getTextColor(context)
          : WebTheme.getSecondaryTextColor(context),
        size: 20,
      ),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: WebTheme.getTextColor(context),
      checkColor: WebTheme.getCardColor(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  /// 构建未验证的模型项
  Widget _buildUnvalidatedModelItem(BuildContext context, UserAIModelConfigModel config) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        _getIconForModel(config.name),
        color: WebTheme.getSecondaryTextColor(context),
        size: 20,
      ),
      title: Text(
        config.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: WebTheme.getSecondaryTextColor(context),
          fontStyle: FontStyle.italic,
        ),
      ),
      subtitle: Text(
        '需要配置验证',
        style: TextStyle(
          fontSize: 12,
          color: WebTheme.warning,
        ),
      ),
      trailing: widget.onConfigureModel != null
        ? OutlinedButton(
            onPressed: () => widget.onConfigureModel!(config.id),
            style: WebTheme.getSecondaryButtonStyle(context).copyWith(
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              minimumSize: MaterialStateProperty.all(Size.zero),
            ),
            child: Text(
              '配置',
              style: TextStyle(
                fontSize: 12,
                color: WebTheme.getTextColor(context),
              ),
            ),
          )
        : null,
      enabled: false,
    );
  }

  /// 构建模型选择提示信息
  Widget _buildModelSelectionHints(BuildContext context, NextOutlineState state) {
    if (_selectedConfigIds.isEmpty) {
      return _buildHintBox(
        context,
        '请至少选择一个AI模型',
        LucideIcons.circle_alert,
        WebTheme.error,
      );
    } else if (_selectedConfigIds.length < state.numOptions) {
      return _buildHintBox(
        context,
        '注意：选择的模型数量少于生成数量，部分模型将被重复使用',
        LucideIcons.info,
        WebTheme.warning,
      );
    }
    
    return const SizedBox.shrink();
  }

  /// 构建提示框组件
  Widget _buildHintBox(BuildContext context, String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 根据模型名称获取对应的图标
  IconData _getIconForModel(String modelName) {
    final lowerName = modelName.toLowerCase();
    if (lowerName.contains('gpt') || lowerName.contains('openai')) {
      return LucideIcons.gem;
    } else if (lowerName.contains('claude')) {
      return LucideIcons.search_code;
    } else if (lowerName.contains('gemini') || lowerName.contains('bard')) {
      return LucideIcons.brain_circuit;
    } else if (lowerName.contains('llama') || lowerName.contains('meta')) {
      return LucideIcons.flask_conical;
    } else if (lowerName.contains('mistral') || lowerName.contains('mixtral')) {
      return LucideIcons.zap;
    }
    return LucideIcons.cpu; // 默认图标
  }
}
