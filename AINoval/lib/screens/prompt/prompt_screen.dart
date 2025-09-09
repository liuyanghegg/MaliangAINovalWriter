import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_bloc.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_state.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_event.dart';
import 'package:ainoval/screens/prompt/widgets/prompt_list_view.dart';
import 'package:ainoval/screens/prompt/widgets/prompt_detail_view.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

/// 统一提示词管理屏幕
class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  static const String _tag = 'PromptScreen';
  
  // 左栏默认宽度，与编辑器侧边栏保持一致
  double _leftPanelWidth = 280;
  static const double _minLeftPanelWidth = 220;
  static const double _maxLeftPanelWidth = 400;
  static const double _resizeHandleWidth = 4;

  @override
  void initState() {
    super.initState();
    AppLogger.i(_tag, '初始化提示词管理屏幕');
    
    // 首次进入时加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromptNewBloc>().add(const LoadAllPromptPackages());
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
        // appBar: AppBar(
        //   title: const Text('提示词管理'),
        //   actions: [
        //     const ThemeToggleButton(),
        //     const SizedBox(width: 16),
        //   ],
        // ),
        body: BlocConsumer<PromptNewBloc, PromptNewState>(
          listener: (context, state) {
            // 显示错误信息
            if (state.errorMessage != null) {
              TopToast.error(context, state.errorMessage!);
            }
          },
          builder: (context, state) {
            return _buildMainContent(context, state);
          },
        ),
      ),
    );
  }

  /// 构建主要内容
  Widget _buildMainContent(BuildContext context, PromptNewState state) {
    // 在窄屏幕上使用单栏显示
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 800;

    if (isNarrowScreen) {
      return _buildNarrowScreenLayout(context, state);
    } else {
      return _buildWideScreenLayout(context, state);
    }
  }

  /// 窄屏幕布局（单栏显示）
  Widget _buildNarrowScreenLayout(BuildContext context, PromptNewState state) {
    if (state.viewMode == PromptViewMode.detail && state.selectedPrompt != null) {
      return PromptDetailView(
        onBack: () {
          context.read<PromptNewBloc>().add(const ToggleViewMode());
        },
      );
    } else {
      return PromptListView(
        onPromptSelected: (promptId, featureType) {
          context.read<PromptNewBloc>().add(SelectPrompt(
            promptId: promptId,
            featureType: featureType,
          ));
        },
      );
    }
  }

  /// 宽屏幕布局（左右分栏）
  Widget _buildWideScreenLayout(BuildContext context, PromptNewState state) {
    return Row(
      children: [
        // 左栏：提示词列表
        SizedBox(
          width: _leftPanelWidth,
          child: PromptListView(
            onPromptSelected: (promptId, featureType) {
              context.read<PromptNewBloc>().add(SelectPrompt(
                promptId: promptId,
                featureType: featureType,
              ));
            },
          ),
        ),

        // 拖拽调整手柄
        _buildResizeHandle(),

        // 右栏：提示词详情
        Expanded(
          child: state.selectedPrompt != null
              ? const PromptDetailView()
              : _buildEmptyDetailView(),
        ),
      ],
    );
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
  Widget _buildEmptyDetailView() {
    return Container(
      color: WebTheme.getSurfaceColor(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              '选择一个提示词模板',
              style: WebTheme.headlineSmall.copyWith(
                color: WebTheme.getTextColor(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '在左侧列表中选择一个提示词模板以查看和编辑详情',
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