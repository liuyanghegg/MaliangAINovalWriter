import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/blocs/novel_import/novel_import_bloc.dart';
import 'package:ainoval/widgets/common/smart_context_toggle.dart';
import 'package:ainoval/widgets/common/model_selector.dart';
import 'package:ainoval/widgets/common/top_toast.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/models/user_ai_model_config_model.dart';

/// 三步导入对话框
/// 步骤1: 配置导入选项（书名、章节限制、智能上下文、AI摘要、模型选择等）
/// 步骤2: 上传文件并显示章节预览供确认
/// 步骤3: 确认并开始导入，显示进度
class NovelImportThreeStepDialog extends StatefulWidget {
  const NovelImportThreeStepDialog({super.key});

  @override
  State<NovelImportThreeStepDialog> createState() => _NovelImportThreeStepDialogState();
}

class _NovelImportThreeStepDialogState extends State<NovelImportThreeStepDialog> {
  late final NovelImportBloc _importBloc;
  StreamSubscription<NovelImportState>? _importSubscription;
  bool _hasDispatchedPreview = false;
  
  // 配置选项
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _chapterLimitController = TextEditingController(text: '10');
  bool _enableSmartContext = true;
  bool _enableAISummary = false;
  UserAIModelConfigModel? _selectedModel;
  Set<int> _selectedChapterIndexes = {};
  bool _importWholeBook = false;
  
  // 模型选择器覆盖层
  OverlayEntry? _modelSelectorOverlay;
  final GlobalKey _modelSelectorKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _importBloc = context.read<NovelImportBloc>();
    
    // 检查状态并在需要时重置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _importBloc.state;
      if (state is NovelImportSuccess || state is NovelImportFailure) {
        _importBloc.add(ResetImportState());
      }
    });

    // 统一监听：文件上传完成后自动触发获取预览（防重复）
    _importSubscription = _importBloc.stream.listen((state) {
      if (state is NovelImportFileUploaded) {
        if (_hasDispatchedPreview) return;
        _hasDispatchedPreview = true;
        _importBloc.add(GetImportPreview(
          previewSessionId: state.previewSessionId,
          fileName: state.fileName,
          enableSmartContext: _enableSmartContext,
          enableAISummary: _enableAISummary,
          aiConfigId: _selectedModel?.id,
        ));
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _chapterLimitController.dispose();
    _modelSelectorOverlay?.remove();
    _importSubscription?.cancel();
    
    // 清理预览会话
    final state = _importBloc.state;
    if (state is NovelImportPreviewReady) {
      _importBloc.add(CleanupPreviewSession(
        previewSessionId: state.previewResponse.previewSessionId,
      ));
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocConsumer<NovelImportBloc, NovelImportState>(
      listener: (context, state) {
        if (state is NovelImportSuccess) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (context.mounted) {
              _importBloc.add(ResetImportState());
              Navigator.of(context).pop();
              TopToast.success(context, '导入成功: ${state.message}');
            }
          });
        }
      },
      builder: (context, state) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 750,
            constraints: const BoxConstraints(
              maxHeight: 600,
              minHeight: 350,
            ),
            decoration: BoxDecoration(
              color: isDark ? WebTheme.darkGrey100 : WebTheme.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildHeader(context, state, isDark),
                Expanded(
                  child: _buildContent(context, state, isDark),
                ),
                _buildFooter(context, state, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建对话框头部
  Widget _buildHeader(BuildContext context, NovelImportState state, bool isDark) {
    final step = _getCurrentStep(state);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 标题和关闭按钮
          Row(
            children: [
              Icon(
                Icons.upload_file,
                size: 20,
                color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
              ),
              const SizedBox(width: 8),
              Text(
                '导入小说',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
                ),
              ),
              const Spacer(),
              if (state is! NovelImportInProgress && state is! NovelImportSuccess)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 步骤指示器
          _buildStepIndicator(step, isDark),
        ],
      ),
    );
  }

  /// 构建步骤指示器
  Widget _buildStepIndicator(int currentStep, bool isDark) {
    final steps = ['配置选项', '预览确认', '导入进度'];
    
    return Row(
      children: [
        for (int i = 1; i <= 3; i++) ...[
          _buildStepItem(i, currentStep, steps[i-1], isDark),
          if (i < 3) _buildStepConnector(i < currentStep, isDark),
        ],
      ],
    );
  }

  /// 构建步骤项
  Widget _buildStepItem(int step, int currentStep, String label, bool isDark) {
    final isCompleted = step < currentStep;
    final isCurrent = step == currentStep;
    
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isCurrent
                ? (isDark ? WebTheme.darkGrey800 : WebTheme.grey800)
                : Colors.transparent,
            border: Border.all(
              color: isCompleted || isCurrent
                  ? (isDark ? WebTheme.darkGrey800 : WebTheme.grey800)
                  : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check,
                    size: 12,
                    color: WebTheme.white,
                  )
                : Text(
                    step.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCurrent
                          ? WebTheme.white
                          : (isDark ? WebTheme.darkGrey500 : WebTheme.grey500),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isCurrent
                ? (isDark ? WebTheme.darkGrey800 : WebTheme.grey800)
                : (isDark ? WebTheme.darkGrey500 : WebTheme.grey500),
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// 构建步骤连接线
  Widget _buildStepConnector(bool isCompleted, bool isDark) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 15, left: 6, right: 6),
        color: isCompleted
            ? (isDark ? WebTheme.darkGrey800 : WebTheme.grey800)
            : (isDark ? WebTheme.darkGrey300 : WebTheme.grey300),
      ),
    );
  }

  /// 构建对话框内容
  Widget _buildContent(BuildContext context, NovelImportState state, bool isDark) {
    if (state is NovelImportInitial) {
      return _buildConfigurationStep(context, isDark);
    } else if (state is NovelImportUploading) {
      return _buildUploadingStep(context, state, isDark);
    } else if (state is NovelImportLoadingPreview) {
      return _buildLoadingPreviewStep(context, state, isDark);
    } else if (state is NovelImportPreviewReady) {
      return _buildPreviewStep(context, state, isDark);
    } else if (state is NovelImportInProgress) {
      return _buildProgressStep(context, state, isDark);
    } else if (state is NovelImportSuccess) {
      return _buildSuccessStep(context, state, isDark);
    } else if (state is NovelImportFailure) {
      return _buildErrorStep(context, state, isDark);
    }
    
    return _buildConfigurationStep(context, isDark);
  }

    /// 构建第一步：配置选项
  Widget _buildConfigurationStep(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 说明文字
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? WebTheme.darkGrey200 : WebTheme.grey100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDark ? WebTheme.darkGrey700 : WebTheme.grey700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '请先配置导入选项，然后上传小说文件。系统将自动识别章节结构并提供预览。',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? WebTheme.darkGrey700 : WebTheme.grey700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 标题和预览数量在同一行
          Row(
            children: [
              // 小说标题
              Expanded(
                flex: 2,
                child: _buildFormField(
                  label: '小说标题',
                  required: true,
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '请输入小说标题（可在预览时自动检测）',
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 章节限制
              Expanded(
                flex: 1,
                child: _buildFormField(
                  label: '预览章节数量',
                  required: false,
                  child: TextField(
                    controller: _chapterLimitController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '默认10章',
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          
          // 智能上下文开关
          _buildFormField(
            label: '智能上下文索引',
            required: false,
            child: SmartContextToggle(
              value: _enableSmartContext,
              onChanged: (value) {
                setState(() {
                  _enableSmartContext = value;
                });
              },
            ),
          ),
          
          const SizedBox(height: 14),
          
          // AI摘要开关 - 参考SmartContextToggle的优雅样式
          _buildFormField(
            label: 'AI自动生成摘要',
            required: false,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
                  width: 1,
                ),
                color: isDark ? WebTheme.darkGrey100 : WebTheme.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 开关和标题行
                  Row(
                    children: [
                      // 自定义开关
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _enableAISummary = !_enableAISummary;
                          });
                        },
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: _enableAISummary
                                  ? (isDark ? WebTheme.darkGrey800 : WebTheme.grey800)
                                  : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
                              width: 1.2,
                            ),
                            color: _enableAISummary 
                                ? (isDark ? WebTheme.darkGrey800 : WebTheme.grey800)
                                : Colors.transparent,
                          ),
                          child: _enableAISummary
                              ? Icon(
                                  Icons.check,
                                  size: 10,
                                  color: WebTheme.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      
                      // 标题和AI标识
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _enableAISummary = !_enableAISummary;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Text(
                                'AI自动生成摘要',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // AI智能标识
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 8,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                    const SizedBox(width: 1),
                                    Text(
                                      'AI',
                                      style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // 信息提示图标
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: isDark ? WebTheme.darkGrey500 : WebTheme.grey500,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // 描述文本
                  Text(
                    _enableAISummary 
                        ? 'AI将为每个章节生成结构化摘要，提升内容理解和检索效果'
                        : '关闭AI摘要生成，仅导入原始文本内容',
                    style: TextStyle(
                      color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
                      height: 1.3,
                      fontSize: 11,
                    ),
                  ),
                  
                  // 启用状态下的模型选择
                  if (_enableAISummary) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? WebTheme.darkGrey800 : WebTheme.grey800).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: (isDark ? WebTheme.darkGrey800 : WebTheme.grey800).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.smart_toy,
                            size: 14,
                            color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AI模型：',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ModelSelector(
                              key: _modelSelectorKey,
                              selectedModel: _selectedModel,
                              onModelSelected: (model) {
                                setState(() {
                                  _selectedModel = model;
                                });
                              },
                              compact: true,
                              showSettingsButton: false,
                              maxHeight: 2400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建表单字段
  Widget _buildFormField({
    required String label,
    required bool required,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 2),
              Text(
                '*',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  /// 构建上传中步骤
  Widget _buildUploadingStep(BuildContext context, NovelImportUploading state, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
              strokeWidth: 3,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            state.message,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载预览步骤
  Widget _buildLoadingPreviewStep(BuildContext context, NovelImportLoadingPreview state, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
              strokeWidth: 3,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            state.message,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建第二步：预览确认
  Widget _buildPreviewStep(BuildContext context, NovelImportPreviewReady state, bool isDark) {
    // 初始化标题
    if (_titleController.text.isEmpty) {
      _titleController.text = state.previewResponse.detectedTitle;
    }
    
    // 初始化章节选择
    if (_selectedChapterIndexes.isEmpty) {
              _selectedChapterIndexes = Set.from(
          List.generate(
            state.previewResponse.chapterPreviews.length.clamp(0, 10),
            (index) => index,
          ),
        );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 检测到的信息
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? WebTheme.darkGrey200 : WebTheme.grey100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '检测到的信息',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '标题：${state.previewResponse.detectedTitle}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? WebTheme.darkGrey700 : WebTheme.grey700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '章节数：${state.previewResponse.totalChapterCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? WebTheme.darkGrey700 : WebTheme.grey700,
                  ),
                ),
                if (state.previewResponse.aiEstimation?.estimatedTokens != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'AI摘要预估Token：${state.previewResponse.aiEstimation!.estimatedTokens}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? WebTheme.darkGrey700 : WebTheme.grey700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 导入整本复选框
          CheckboxListTile(
            value: _importWholeBook,
            onChanged: (value) {
              setState(() {
                _importWholeBook = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '导入整本（共 ${state.previewResponse.totalChapterCount} 章）',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
              ),
            ),
            subtitle: Text(
              '默认仅预览前 10 章，勾选后将导入完整小说内容',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
              ),
            ),
          ),
          
          const SizedBox(height: 6),
          
          // 章节选择标题和按钮行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '选择要导入的章节',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
                ),
              ),
              // 全选/取消全选按钮
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedChapterIndexes = Set.from(
                          List.generate(state.previewResponse.chapterPreviews.length, (index) => index),
                        );
                      });
                    },
                    icon: Icon(Icons.select_all, size: 14),
                    label: Text('全选', style: TextStyle(fontSize: 10)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedChapterIndexes.clear();
                      });
                    },
                    icon: Icon(Icons.deselect, size: 14),
                    label: Text('取消', style: TextStyle(fontSize: 10)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // 章节列表
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ListView.builder(
                itemCount: state.previewResponse.chapterPreviews.length,
                itemBuilder: (context, index) {
                  final chapter = state.previewResponse.chapterPreviews[index];
                  final isSelected = _selectedChapterIndexes.contains(index);
                  
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedChapterIndexes.add(index);
                        } else {
                          _selectedChapterIndexes.remove(index);
                        }
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    title: Text(
                      chapter.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
                      ),
                    ),
                    subtitle: Text(
                      '${chapter.contentPreview.length > 80 ? chapter.contentPreview.substring(0, 80) : chapter.contentPreview}...',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    activeColor: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建第三步：导入进度
  Widget _buildProgressStep(BuildContext context, NovelImportInProgress state, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: state.progress,
                    strokeWidth: 6,
                    color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
                    backgroundColor: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
                  ),
                ),
                if (state.progress != null)
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '${(state.progress! * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            state.message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
            ),
          ),
          
          if (state.currentStep != null) ...[
            const SizedBox(height: 8),
            Text(
              state.currentStep!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
              ),
            ),
          ],
          
          if (state.processedChapters != null && state.totalChapters != null) ...[
            const SizedBox(height: 16),
            Text(
              '章节进度：${state.processedChapters}/${state.totalChapters}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建成功步骤
  Widget _buildSuccessStep(BuildContext context, NovelImportSuccess state, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            child: Icon(
              Icons.check_circle,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '导入成功！',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误步骤
  Widget _buildErrorStep(BuildContext context, NovelImportFailure state, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.errorContainer,
            ),
            child: Icon(
              Icons.error,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '导入失败',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '可能的原因：',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• 文件编码不是UTF-8\n'
                  '• 文件格式不正确\n'
                  '• 文件可能已损坏\n'
                  '• 服务器暂时无法处理',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.error,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建对话框底部
  Widget _buildFooter(BuildContext context, NovelImportState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: _buildFooterButtons(context, state, isDark),
      ),
    );
  }

  /// 构建底部按钮
  List<Widget> _buildFooterButtons(BuildContext context, NovelImportState state, bool isDark) {
    if (state is NovelImportInitial) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '取消',
            style: TextStyle(
              color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _canProceedToUpload() ? () => _uploadFile() : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
            foregroundColor: WebTheme.white,
          ),
          icon: const Icon(Icons.upload_file),
          label: const Text('上传文件'),
        ),
      ];
    } else if (state is NovelImportPreviewReady) {
      return [
        TextButton(
          onPressed: () {
            _importBloc.add(ResetImportState());
          },
          child: Text(
            '重新配置',
            style: TextStyle(
              color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: (_importWholeBook || _selectedChapterIndexes.isNotEmpty)
              ? () => _startImport(state)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
            foregroundColor: WebTheme.white,
          ),
          icon: const Icon(Icons.download),
          label: const Text('开始导入'),
        ),
      ];
    } else if (state is NovelImportInProgress) {
      return [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            '最小化',
            style: TextStyle(
              color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
            ),
          ),
        ),
      ];
    } else if (state is NovelImportFailure) {
      return [
        TextButton(
          onPressed: () {
            _importBloc.add(ResetImportState());
            Navigator.of(context).pop();
          },
          child: Text(
            '关闭',
            style: TextStyle(
              color: isDark ? WebTheme.darkGrey600 : WebTheme.grey600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            _importBloc.add(ResetImportState());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
            foregroundColor: WebTheme.white,
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('重试'),
        ),
      ];
    } else if (state is NovelImportSuccess) {
      return [
        ElevatedButton(
          onPressed: () {
            _importBloc.add(ResetImportState());
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? WebTheme.darkGrey800 : WebTheme.grey800,
            foregroundColor: WebTheme.white,
          ),
          child: const Text('完成'),
        ),
      ];
    }
    
    return [];
  }

  /// 检查是否可以进行上传
  bool _canProceedToUpload() {
    if (_enableAISummary && _selectedModel == null) {
      return false;
    }
    return true;
  }

  /// 上传文件
  void _uploadFile() {
    // 重置防抖标记，开始新的上传-预览流程
    _hasDispatchedPreview = false;
    _importBloc.add(UploadFileForPreview());
  }

  /// 开始导入
  void _startImport(NovelImportPreviewReady state) {
    _importBloc.add(ConfirmAndStartImport(
      previewSessionId: state.previewResponse.previewSessionId,
      finalTitle: _titleController.text.trim().isEmpty
          ? state.previewResponse.detectedTitle
          : _titleController.text.trim(),
      selectedChapterIndexes:
          _importWholeBook ? null : _selectedChapterIndexes.toList(),
      enableSmartContext: _enableSmartContext,
      enableAISummary: _enableAISummary,
      aiConfigId: _selectedModel?.id,
    ));
  }

  /// 获取当前步骤
  int _getCurrentStep(NovelImportState state) {
    if (state is NovelImportInitial || 
        state is NovelImportUploading || 
        state is NovelImportFileUploaded ||
        state is NovelImportLoadingPreview) {
      return 1;
    } else if (state is NovelImportPreviewReady) {
      return 2;
    } else {
      return 3;
    }
  }
}

/// 显示三步导入对话框的便捷函数
void showNovelImportThreeStepDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      // 获取已经在父级创建的NovelImportBloc
      final novelImportBloc = context.read<NovelImportBloc>();
      
      // 使用BlocProvider.value包装对话框
      return BlocProvider.value(
        value: novelImportBloc,
        child: const NovelImportThreeStepDialog(),
      );
    },
  );
} 