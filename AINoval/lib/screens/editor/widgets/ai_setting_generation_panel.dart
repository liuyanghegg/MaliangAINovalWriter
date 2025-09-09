// import 'dart:math'; // Added for min function
import 'package:ainoval/screens/editor/widgets/floating_setting_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/models/novel_setting_item.dart';
import 'package:ainoval/models/setting_type.dart'; // Your SettingType enum
import 'package:ainoval/blocs/ai_setting_generation/ai_setting_generation_bloc.dart'; // Correct BLoC import
import 'package:ainoval/models/novel_structure.dart'; // Import for Chapter model
import 'package:ainoval/services/api_service/repositories/editor_repository.dart'; // Import EditorRepository
import 'package:ainoval/services/api_service/repositories/novel_ai_repository.dart'; // Needed for BLoC creation
import 'package:ainoval/blocs/setting/setting_bloc.dart'; 

import 'package:ainoval/utils/logger.dart';

// Removed placeholder BLoC, State, and Event definitions

class AISettingGenerationPanel extends StatelessWidget {
  final String novelId;
  final VoidCallback onClose; 
  final bool isCardMode;      
  final EditorRepository editorRepository; // Added
  final NovelAIRepository novelAIRepository; // Added

  const AISettingGenerationPanel({
    Key? key,
    required this.novelId,
    required this.onClose,
    required this.editorRepository, // Added
    required this.novelAIRepository, // Added
    this.isCardMode = false, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AISettingGenerationBloc>(
      create: (context) => AISettingGenerationBloc(
        editorRepository: editorRepository, // Changed from context.read
        novelAIRepository: novelAIRepository, // Changed from context.read
      )..add(LoadInitialDataForAISettingPanel(novelId)),
      child: AISettingGenerationView(novelId: novelId),
    );
  }
}

class AISettingGenerationView extends StatefulWidget {
  final String novelId;
  const AISettingGenerationView({Key? key, required this.novelId}) : super(key: key);

  @override
  State<AISettingGenerationView> createState() => _AISettingGenerationViewState();
}

// 章节选择项数据模型
class ChapterOption {
  final String id;
  final String title;
  final int order;
  final int globalOrder; // 全局排序序号
  final String actTitle;
  final int actOrder;
  
  ChapterOption({
    required this.id,
    required this.title,
    required this.order,
    required this.globalOrder,
    required this.actTitle,
    required this.actOrder,
  });
  
  String get displayTitle {
    final chapterTitle = title.isNotEmpty ? title : '无标题章节';
    return '第${globalOrder}章 $chapterTitle';
  }
  
  String get actDisplayTitle {
    return actTitle.isNotEmpty ? actTitle : '第${actOrder}卷';
  }
}

class _AISettingGenerationViewState extends State<AISettingGenerationView> {
  String? _selectedStartChapterId;
  String? _selectedEndChapterId;
  final List<SettingTypeOption> _settingTypeOptions = 
      SettingType.values.map((type) => SettingTypeOption(type)).toList();
  final _maxSettingsController = TextEditingController(text: '3');
  final _instructionsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  
  // 生成排序后的章节选项列表
  List<ChapterOption> _generateChapterOptions(List<Chapter> chapters, Novel? novel) {
    List<ChapterOption> options = [];
    int globalOrder = 1;
    
    if (novel == null) {
      // 回退方案：没有Novel信息时，简单排序
      chapters.sort((a, b) => a.order.compareTo(b.order));
      for (final chapter in chapters) {
        options.add(ChapterOption(
          id: chapter.id,
          title: chapter.title,
          order: chapter.order,
          globalOrder: globalOrder++,
          actTitle: '',
          actOrder: 1,
        ));
      }
    } else {
      // 有Novel信息时，按Act和章节顺序正确排序
      final sortedActs = novel.acts..sort((a, b) => a.order.compareTo(b.order));
      
      for (final act in sortedActs) {
        final sortedChapters = act.chapters..sort((a, b) => a.order.compareTo(b.order));
        
        for (final chapter in sortedChapters) {
          // 只处理在chapters列表中的章节（可能有过滤）
          if (chapters.any((c) => c.id == chapter.id)) {
            options.add(ChapterOption(
              id: chapter.id,
              title: chapter.title,
              order: chapter.order,
              globalOrder: globalOrder++,
              actTitle: act.title,
              actOrder: act.order,
            ));
          }
        }
      }
    }
    
    return options;
  }

  @override
  void dispose() {
    _maxSettingsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 0), // Changed from 24, assuming MultiAIPanelView handles top padding for header
      child: Column(
        children: [
          _buildConfigurationArea(context, theme),
          const Divider(height: 1, thickness: 1),
          Expanded(child: _buildResultsArea(context, theme)),
        ],
      ),
    );
  }

  Widget _buildConfigurationArea(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView( 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                              BlocBuilder<AISettingGenerationBloc, AISettingGenerationState>(
                builder: (context, state) {
                  List<Chapter> chapters = [];
                  Novel? novel;
                  bool isLoadingChapters = true;
                  String? chapterLoadingError;

                  if (state is AISettingGenerationDataLoaded) {
                    chapters = state.chapters;
                    novel = state.novel;
                    isLoadingChapters = false;
                  } else if (state is AISettingGenerationSuccess) {
                    chapters = state.chapters;
                    novel = state.novel;
                    isLoadingChapters = false;
                  } else if (state is AISettingGenerationFailure) {
                    chapters = state.chapters; // Might still have chapters from a previous successful load
                    novel = state.novel;
                    isLoadingChapters = false;
                    if(chapters.isEmpty) chapterLoadingError = state.error; // Only show error if no chapters displayed
                  } else if (state is AISettingGenerationLoadingChapters || state is AISettingGenerationInitial) {
                    isLoadingChapters = true;
                  } else {
                    isLoadingChapters = false; 
                  }

                  if (isLoadingChapters) { 
                    return const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ));
                  }
                  if (chapterLoadingError != null) {
                     return Center(child: Padding(
                       padding: const EdgeInsets.symmetric(vertical: 16.0),
                       child: Text('加载章节失败: $chapterLoadingError', style: TextStyle(color: theme.colorScheme.error)),
                     ));
                  }
                  if (chapters.isEmpty) {
                     return const Center(child: Padding(
                       padding: EdgeInsets.symmetric(vertical: 24.0),
                       child: Text('没有可用的章节。'),
                     ));
                  }

                  final chapterOptions = _generateChapterOptions(chapters, novel);

                  return Column(
                    children: [
                      _buildChapterDropdown(
                        context: context,
                        theme: theme,
                        label: '起始章节',
                        value: _selectedStartChapterId,
                        options: chapterOptions,
                        onChanged: (value) {
                          setState(() {
                            _selectedStartChapterId = value;
                            if (_selectedEndChapterId != null && _selectedStartChapterId != null) {
                              final startOption = chapterOptions.firstWhere((opt) => opt.id == _selectedStartChapterId);
                              final endOption = chapterOptions.firstWhere((opt) => opt.id == _selectedEndChapterId);
                              if (endOption.globalOrder < startOption.globalOrder) {
                                _selectedEndChapterId = null; 
                              }
                            }
                          });
                        },
                        validator: (value) => value == null ? '请选择起始章节' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildChapterDropdown(
                        context: context,
                        theme: theme,
                        label: '结束章节 (可选)',
                        value: _selectedEndChapterId,
                        options: chapterOptions.where((option) {
                          if (_selectedStartChapterId == null) return true;
                          final startOption = chapterOptions.firstWhere((opt) => opt.id == _selectedStartChapterId);
                          return option.globalOrder >= startOption.globalOrder;
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEndChapterId = value;
                          });
                        },
                        hasDefaultOption: true,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('希望生成的设定类型:', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _settingTypeOptions.map((option) {
                  return FilterChip(
                    label: Text(option.type.displayName, style: const TextStyle(fontSize: 12)),
                    selected: option.isSelected,
                    onSelected: (selected) {
                      setState(() {
                        option.isSelected = selected;
                      });
                    },
                    checkmarkColor: option.isSelected ? theme.colorScheme.onPrimary : null,
                   selectedColor: WebTheme.getPrimaryColor(context),
                    labelStyle: TextStyle(
                        color: option.isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodySmall?.color, 
                        fontWeight: option.isSelected ? FontWeight.bold : FontWeight.normal),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,      
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                           color: option.isSelected ? WebTheme.getPrimaryColor(context) : theme.colorScheme.outline,
                            width: 1.0,
                        ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxSettingsController,
                decoration: const InputDecoration(
                  labelText: '每类生成数量 (1-5)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return '请输入数量';
                  final num = int.tryParse(value);
                  if (num == null || num < 1 || num > 5) return '请输入1到5之间的数字';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: '其他说明或风格引导 (可选)',
                  hintText: '例如：希望角色更神秘，或侧重描写地点的历史感',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
                maxLength: 200,
              ),
              const SizedBox(height: 20),
              Center(
                child: BlocBuilder<AISettingGenerationBloc, AISettingGenerationState>(
                  builder: (context, state) {
                    bool isLoading = state is AISettingGenerationInProgress;
                    return ElevatedButton.icon(
                      icon: isLoading 
                          ? const SizedBox(width:16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: Text(isLoading ? '生成中...' : '开始生成设定'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                      ),
                      onPressed: isLoading ? null : () {
                        if (_formKey.currentState!.validate()) {
                          final selectedTypes = _settingTypeOptions
                                                  .where((opt) => opt.isSelected)
                                                  .map((opt) => opt.type.value)
                                                  .toList();
                          if (selectedTypes.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请至少选择一个设定类型'), backgroundColor: Colors.orange)
                            );
                            return;
                          }
                          if (_selectedStartChapterId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请选择起始章节'), backgroundColor: Colors.orange)
                            );
                            return;
                          }

                          context.read<AISettingGenerationBloc>().add(GenerateSettingsRequested(
                            novelId: widget.novelId,
                            startChapterId: _selectedStartChapterId!,
                            endChapterId: _selectedEndChapterId,
                            settingTypes: selectedTypes,
                            maxSettingsPerType: int.parse(_maxSettingsController.text),
                            additionalInstructions: _instructionsController.text,
                          ));
                        }
                      },
                    );
                  }
                ),
              ),
              const SizedBox(height: 12), // Add some bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterDropdown({
    required BuildContext context,
    required ThemeData theme,
    required String label,
    required String? value,
    required List<ChapterOption> options,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    bool hasDefaultOption = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        value: value,
        isExpanded: true,  // 确保下拉框内容完全显示
        icon: Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurfaceVariant),
        items: [
          if (hasDefaultOption)
            DropdownMenuItem<String>(
              value: null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                   Icon(Icons.auto_awesome, size: 18, color: WebTheme.getPrimaryColor(context)),
                    const SizedBox(width: 8),
                    Text(
                      '到最新章节 (默认)',
                      style: TextStyle(
                        color: WebTheme.getPrimaryColor(context),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...options.map((option) {
            return DropdownMenuItem<String>(
              value: option.id,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.displayTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (option.actTitle.isNotEmpty) 
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          option.actDisplayTitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
        onChanged: onChanged,
        validator: validator,
        selectedItemBuilder: (BuildContext context) {
          return [
            if (hasDefaultOption)
              Text(
                '到最新章节 (默认)',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ...options.map((option) {
              return Text(
                option.displayTitle,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              );
            }).toList(),
          ];
        },
        dropdownColor: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        menuMaxHeight: 300, // 限制下拉菜单最大高度
      ),
    );
  }

  Widget _buildResultsArea(BuildContext context, ThemeData theme) {
    return BlocBuilder<AISettingGenerationBloc, AISettingGenerationState>(
      builder: (context, state) {
        if (state is AISettingGenerationInProgress) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在分析章节并生成设定，请稍候...')
            ],
          ));
        }
        if (state is AISettingGenerationSuccess) {
          if (state.generatedSettings.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('AI未能根据您的选择生成任何设定，请尝试调整选项或章节内容后再试。', textAlign: TextAlign.center,)
            ));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: state.generatedSettings.length,
            itemBuilder: (context, index) {
              return NovelSettingItemCard(
                settingItem: state.generatedSettings[index], 
                novelId: widget.novelId,
              );
            },
          );
        }
        if (state is AISettingGenerationFailure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
                  const SizedBox(height:16),
                  Text('生成设定时出错:', style: theme.textTheme.titleMedium),
                  const SizedBox(height:8),
                  Text(state.error, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center,),
                  const SizedBox(height:16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重试'),
                    onPressed: (){
                        if (_formKey.currentState!.validate()) {
                          final selectedTypes = _settingTypeOptions
                                                  .where((opt) => opt.isSelected)
                                                  .map((opt) => opt.type.value)
                                                  .toList();
                          if (selectedTypes.isEmpty || _selectedStartChapterId == null) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请确保已选择起始章节和至少一个设定类型再重试。'), backgroundColor: Colors.orange)
                            );
                            return;
                          }
                          context.read<AISettingGenerationBloc>().add(GenerateSettingsRequested(
                            novelId: widget.novelId,
                            startChapterId: _selectedStartChapterId!,
                            endChapterId: _selectedEndChapterId,
                            settingTypes: selectedTypes,
                            maxSettingsPerType: int.parse(_maxSettingsController.text),
                            additionalInstructions: _instructionsController.text,
                          ));
                        }
                    }
                  )
                ],
              )
            ),
          );
        }
        // Initial or other states
        return const Center(child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('请选择起始章节和希望生成的设定类型，然后点击"开始生成设定"按钮。', textAlign: TextAlign.center,)
        ));
      },
    );
  }
}

class NovelSettingItemCard extends StatefulWidget {
  final NovelSettingItem settingItem;
  final String novelId;

  const NovelSettingItemCard({
    Key? key, 
    required this.settingItem,
    required this.novelId,
  }) : super(key: key);

  @override
  State<NovelSettingItemCard> createState() => _NovelSettingItemCardState();
}

class _NovelSettingItemCardState extends State<NovelSettingItemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeEnum = SettingType.fromValue(widget.settingItem.type ?? 'OTHER');
    final itemAttributes = widget.settingItem.attributes; // Store in a local variable
    final itemTags = widget.settingItem.tags; // Store in a local variable

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Softer corners
      clipBehavior: Clip.antiAlias, // Ensures content respects border radius
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
              children: [
                Expanded(
                  child: Text(
                    widget.settingItem.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(typeEnum.displayName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                  backgroundColor: _getTypeColor(typeEnum).withOpacity(0.15),
                  labelStyle: TextStyle(color: _getTypeColor(typeEnum)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(horizontal: 0.0, vertical: -2), // Compact chip
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.settingItem.description ?? '无描述',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
              maxLines: _isExpanded ? null : 3, // Show a bit more before expanding
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if ((widget.settingItem.description?.length ?? 0) > 120) // Show expand if description is somewhat long
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50,30), visualDensity: VisualDensity.compact),
                  child: Text(_isExpanded ? '收起' : '展开', style: TextStyle(fontSize: 12, color: WebTheme.getPrimaryColor(context))),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded)),
              ),
            
            if ((itemAttributes?.isNotEmpty ?? false) || (itemTags?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 6),
              Divider(thickness: 0.5, color: theme.dividerColor.withOpacity(0.5)),
              const SizedBox(height: 6),
              if (itemAttributes?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: itemAttributes!.entries.map((e) => Chip(
                      label: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    )).toList(),
                  ),
                ),
              if (itemTags?.isNotEmpty ?? false)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: itemTags!.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                    backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.6),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  )).toList(),
                ),
            ],

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('采纳到设定组', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                     foregroundColor: WebTheme.getPrimaryColor(context),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    _showAdoptDialog(context, widget.settingItem, widget.novelId);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(SettingType type) {
    switch (type) {
      case SettingType.character: return Colors.blue.shade600;
      case SettingType.location: return Colors.green.shade600;
      case SettingType.item: return Colors.orange.shade700;
      case SettingType.lore: return Colors.purple.shade600;
      case SettingType.event: return Colors.red.shade600;
      case SettingType.concept: return Colors.teal.shade600;
      case SettingType.faction: return Colors.indigo.shade600;
      case SettingType.creature: return Colors.brown.shade600;
      case SettingType.magicSystem: return Colors.cyan.shade600;
      case SettingType.technology: return Colors.blueGrey.shade600;
      case SettingType.culture: return Colors.deepOrange.shade600;
      case SettingType.history: return Colors.brown.shade600;
      case SettingType.organization: return Colors.indigo.shade600;
      case SettingType.worldview: return Colors.purple.shade600;
      case SettingType.pleasurePoint: return Colors.redAccent.shade200;
      case SettingType.anticipationHook: return Colors.teal.shade400;
      case SettingType.theme: return Colors.blueGrey.shade500;
      case SettingType.tone: return Colors.amber.shade700;
      case SettingType.style: return Colors.cyan.shade700;
      case SettingType.trope: return Colors.pink.shade400;
      case SettingType.plotDevice: return Colors.green.shade600;
      case SettingType.powerSystem: return Colors.orange.shade700;
      case SettingType.timeline: return Colors.blue.shade600;
      case SettingType.religion: return Colors.deepPurple.shade600;
      case SettingType.politics: return Colors.red.shade700;
      case SettingType.economy: return Colors.lightGreen.shade700;
      case SettingType.geography: return Colors.lightBlue.shade700;
      default: return Colors.grey.shade600;
    }
  }

  void _showAdoptDialog(BuildContext context, NovelSettingItem itemToAdopt, String novelId) {
    final settingBloc = context.read<SettingBloc>();
    
    AppLogger.i("AISettingGenerationPanel", "准备采纳设定: ${itemToAdopt.name}, 描述长度: ${itemToAdopt.description?.length ?? 0}, 标签数量: ${itemToAdopt.tags?.length ?? 0}, 属性数量: ${itemToAdopt.attributes?.length ?? 0}");

    FloatingSettingDialogs.showSettingGroupSelection(
      context: context,
      novelId: novelId,
      onGroupSelected: (groupId, groupName) { 
        // 显示操作提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('正在将 "${itemToAdopt.name}" 添加到 "$groupName"...'))
        );
        
        // 确保类型值使用正确的枚举value值
        final typeValue = itemToAdopt.type;
        
        // 准备创建的设定条目
        NovelSettingItem itemForCreation = itemToAdopt.copyWith(
          id: null, 
          isAiSuggestion: false,
          status: 'ACTIVE',
          type: typeValue, // 确保使用原始的value值
          // 明确设置content和description，确保不会丢失
          content: "",  // 不再使用content字段
          description: itemToAdopt.description,  // 保留description作为主要描述字段
          attributes: itemToAdopt.attributes,  // 确保属性被保留
          tags: itemToAdopt.tags,  // 确保标签被保留
          generatedBy: "AI设定生成器"  // 明确标记生成来源
        );
        
        // 在安全的上下文环境中创建并添加到组
        WidgetsBinding.instance.addPostFrameCallback((_) {
          settingBloc.add(CreateSettingItemAndAddToGroup(
            novelId: novelId,
            item: itemForCreation, 
            groupId: groupId, 
          ));
        });
      },
    );
  }
} 