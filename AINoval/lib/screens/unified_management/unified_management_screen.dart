import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_bloc.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_state.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_event.dart';
import 'package:ainoval/blocs/preset/preset_bloc.dart';
import 'package:ainoval/blocs/preset/preset_state.dart';
import 'package:ainoval/blocs/preset/preset_event.dart';
import 'package:ainoval/screens/prompt/widgets/prompt_list_view.dart';
import 'package:ainoval/screens/prompt/widgets/prompt_detail_view.dart';
import 'package:ainoval/screens/unified_management/widgets/preset_list_view.dart';
import 'package:ainoval/screens/unified_management/widgets/preset_detail_view.dart';
import 'package:ainoval/screens/unified_management/widgets/management_mode_switcher.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

/// 管理模式枚举
enum ManagementMode {
  /// 提示词模板管理
  prompts,
  /// 预设管理
  presets,
}

/// 统一管理屏幕 - AI模板与预设统一管理
class UnifiedManagementScreen extends StatefulWidget {
  const UnifiedManagementScreen({super.key});

  @override
  State<UnifiedManagementScreen> createState() => _UnifiedManagementScreenState();
}

class _UnifiedManagementScreenState extends State<UnifiedManagementScreen> {
  static const String _tag = 'UnifiedManagementScreen';
  
  // 当前管理模式，默认为提示词模板管理
  ManagementMode _currentMode = ManagementMode.prompts;
  
  // 左栏默认宽度，与现有提示词管理界面保持一致
  double _leftPanelWidth = 280;
  static const double _minLeftPanelWidth = 220;
  static const double _maxLeftPanelWidth = 400;
  static const double _resizeHandleWidth = 4;

  @override
  void initState() {
    super.initState();
    AppLogger.i(_tag, '初始化统一管理屏幕');
    
    // 首次进入时加载提示词数据（预设数据已在登录时预加载）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromptNewBloc>().add(const LoadAllPromptPackages());
      // 预设数据已在用户登录时通过聚合接口预加载，无需重复加载
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: isDark ? WebTheme.darkGrey50 : WebTheme.white,
        cardColor: isDark ? WebTheme.darkGrey100 : WebTheme.white,
      ),
      child: Scaffold(
        backgroundColor: isDark ? WebTheme.darkGrey50 : WebTheme.white,
        body: MultiBlocListener(
          listeners: [
            BlocListener<PromptNewBloc, PromptNewState>(
              listener: (context, state) {
                // 显示提示词相关错误信息
                if (state.errorMessage != null) {
                  TopToast.error(context, state.errorMessage!);
                }
              },
            ),
            BlocListener<PresetBloc, PresetState>(
              listener: (context, state) {
                // 显示预设相关错误信息
                if (state.hasError) {
                  TopToast.error(context, state.errorMessage!);
                }
              },
            ),
          ],
          child: _buildMainContent(context),
        ),
      ),
    );
  }

  /// 构建主要内容
  Widget _buildMainContent(BuildContext context) {
    // 在窄屏幕上使用单栏显示
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 800;

    if (isNarrowScreen) {
      return _buildNarrowScreenLayout(context);
    } else {
      return _buildWideScreenLayout(context);
    }
  }

  /// 窄屏幕布局（单栏显示）
  Widget _buildNarrowScreenLayout(BuildContext context) {
    if (_currentMode == ManagementMode.prompts) {
      return BlocBuilder<PromptNewBloc, PromptNewState>(
        builder: (context, state) {
          if (state.viewMode == PromptViewMode.detail && state.selectedPrompt != null) {
            return PromptDetailView(
              onBack: () {
                context.read<PromptNewBloc>().add(const ToggleViewMode());
              },
            );
          } else {
            return Column(
              children: [
                // 模式切换器
                _buildModeHeader(),
                // 提示词列表
                Expanded(
                  child: PromptListView(
                    onPromptSelected: (promptId, featureType) {
                      context.read<PromptNewBloc>().add(SelectPrompt(
                        promptId: promptId,
                        featureType: featureType,
                      ));
                    },
                  ),
                ),
              ],
            );
          }
        },
      );
    } else {
      // 预设管理模式
      return BlocBuilder<PresetBloc, PresetState>(
        builder: (context, state) {
          return Column(
            children: [
              // 模式切换器
              _buildModeHeader(),
              // 预设列表
              Expanded(
                child: PresetListView(
                  onPresetSelected: (presetId) {
                    // 处理预设选择
                    AppLogger.i(_tag, '选择预设: $presetId');
                  },
                ),
              ),
            ],
          );
        },
      );
    }
  }

  /// 宽屏幕布局（左右分栏）
  Widget _buildWideScreenLayout(BuildContext context) {
    return Row(
      children: [
        // 左栏：动态列表视图
        SizedBox(
          width: _leftPanelWidth,
          child: _buildLeftPanel(context),
        ),

        // 拖拽调整手柄
        _buildResizeHandle(),

        // 右栏：动态详情视图
        Expanded(
          child: _buildRightPanel(context),
        ),
      ],
    );
  }

  /// 构建左栏面板（动态内容）
  Widget _buildLeftPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        border: Border(
          right: BorderSide(
            color: WebTheme.isDarkMode(context) ? WebTheme.darkGrey200 : WebTheme.grey200,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: WebTheme.getShadowColor(context, opacity: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 模式切换器（在左栏顶部）
          _buildModeHeader(),
          
          // 动态内容区域
          Expanded(
            child: _buildDynamicContent(context),
          ),
        ],
      ),
    );
  }

  /// 构建模式切换器头部
  Widget _buildModeHeader() {
    return ManagementModeSwitcher(
      currentMode: _currentMode,
      onModeChanged: (newMode) {
        setState(() {
          _currentMode = newMode;
        });
        
        // 模式切换时的数据加载逻辑
        if (newMode == ManagementMode.prompts) {
          AppLogger.i(_tag, '切换到提示词模板管理模式');
          context.read<PromptNewBloc>().add(const LoadAllPromptPackages());
        } else {
          AppLogger.i(_tag, '切换到预设管理模式');
          // 🚀 检查是否已有聚合数据，如果没有则加载
          final presetState = context.read<PresetBloc>().state;
          if (!presetState.hasAllPresetData) {
            AppLogger.i(_tag, '预设聚合数据未加载，开始加载...');
            context.read<PresetBloc>().add(const LoadAllPresetData());
          } else {
            AppLogger.i(_tag, '预设聚合数据已缓存，直接使用');
          }
        }
      },
    );
  }

  /// 构建动态内容区域
  Widget _buildDynamicContent(BuildContext context) {
    if (_currentMode == ManagementMode.prompts) {
      // 提示词模板管理模式
      return PromptListView(
        onPromptSelected: (promptId, featureType) {
          context.read<PromptNewBloc>().add(SelectPrompt(
            promptId: promptId,
            featureType: featureType,
          ));
        },
      );
    } else {
      // 预设管理模式
      return PresetListView(
        onPresetSelected: (presetId) {
          // 处理预设选择
          AppLogger.i(_tag, '选择预设: $presetId');
        },
      );
    }
  }

  /// 构建右栏面板（动态详情视图）
  Widget _buildRightPanel(BuildContext context) {
    if (_currentMode == ManagementMode.prompts) {
      // 提示词模板详情视图
      return BlocBuilder<PromptNewBloc, PromptNewState>(
        builder: (context, state) {
          return state.selectedPrompt != null
              ? const PromptDetailView()
              : _buildEmptyDetailView('选择一个提示词模板', '在左侧列表中选择一个提示词模板以查看和编辑详情');
        },
      );
    } else {
      // 预设详情视图
      return BlocBuilder<PresetBloc, PresetState>(
        builder: (context, state) {
          return state.hasSelectedPreset
              ? const PresetDetailView()
              : _buildEmptyDetailView('选择一个预设', '在左侧列表中选择一个预设以查看和编辑详情');
        },
      );
    }
  }

  /// 构建拖拽调整手柄
  Widget _buildResizeHandle() {
    final isDark = WebTheme.isDarkMode(context);
    
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _leftPanelWidth = (_leftPanelWidth + details.delta.dx).clamp(
              _minLeftPanelWidth,
              _maxLeftPanelWidth,
            );
          });
        },
        child: Container(
          width: _resizeHandleWidth,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 1,
              color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建空白详情视图
  Widget _buildEmptyDetailView(String title, String subtitle) {
    return Container(
      color: WebTheme.getSurfaceColor(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentMode == ManagementMode.prompts 
                  ? Icons.auto_awesome_outlined 
                  : Icons.settings_suggest_outlined,
              size: 64,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: WebTheme.headlineSmall.copyWith(
                color: WebTheme.getTextColor(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: WebTheme.bodyMedium.copyWith(
                color: WebTheme.getSecondaryTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}