import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:ainoval/models/setting_group.dart';
import 'package:ainoval/blocs/setting/setting_bloc.dart';
import 'package:ainoval/screens/editor/widgets/novel_setting_group_dialog.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:ainoval/screens/editor/managers/editor_layout_manager.dart';
import 'package:ainoval/widgets/common/floating_card.dart';
import 'package:ainoval/utils/web_theme.dart';


/// 浮动设定组选择管理器
class FloatingNovelSettingGroupSelectionDialog {
  static bool _isShowing = false;

  /// 显示浮动设定组选择卡片
  static void show({
    required BuildContext context,
    required String novelId,
    required Function(String groupId, String groupName) onGroupSelected,
  }) {
    if (_isShowing) {
      hide();
    }

    // 获取布局信息
    final layoutManager = Provider.of<EditorLayoutManager>(context, listen: false);
    final sidebarWidth = layoutManager.isEditorSidebarVisible ? layoutManager.editorSidebarWidth : 0.0;

    AppLogger.d('FloatingNovelSettingGroupSelectionDialog', '显示浮动卡片，侧边栏宽度: $sidebarWidth');

    // 计算卡片大小
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = (screenSize.width * 0.3).clamp(400.0, 600.0);
    final cardHeight = (screenSize.height * 0.6).clamp(400.0, 600.0);

    // 获取当前的 Provider 实例
    final settingBloc = context.read<SettingBloc>();

    FloatingCard.show(
      context: context,
      position: FloatingCardPosition(
        left: sidebarWidth + 16.0,
        top: 80.0,
      ),
      config: FloatingCardConfig(
        width: cardWidth,
        height: cardHeight,
        showCloseButton: false,
        enableBackgroundTap: false,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeOutCubic,
        borderRadius: BorderRadius.circular(12),
        padding: EdgeInsets.zero,
      ),
      child: MultiProvider(
        providers: [
          Provider<EditorLayoutManager>.value(value: layoutManager),
          BlocProvider<SettingBloc>.value(value: settingBloc),
        ],
        child: _NovelSettingGroupSelectionDialogContent(
          novelId: novelId,
          onGroupSelected: onGroupSelected,
          onCancel: hide,
        ),
      ),
      onClose: hide,
    );

    _isShowing = true;
  }

  /// 隐藏浮动卡片
  static void hide() {
    if (_isShowing) {
      FloatingCard.hide();
      _isShowing = false;
    }
  }

  /// 检查是否正在显示
  static bool get isShowing => _isShowing;
}

/// 小说设定组选择对话框内容
/// 
/// 用于选择现有设定组或创建新设定组
class _NovelSettingGroupSelectionDialogContent extends StatefulWidget {
  final String novelId;
  final Function(String groupId, String groupName) onGroupSelected;
  final VoidCallback onCancel;
  
  const _NovelSettingGroupSelectionDialogContent({
    Key? key,
    required this.novelId,
    required this.onGroupSelected,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<_NovelSettingGroupSelectionDialogContent> createState() => _NovelSettingGroupSelectionDialogContentState();
}

class _NovelSettingGroupSelectionDialogContentState extends State<_NovelSettingGroupSelectionDialogContent> {
  @override
  void initState() {
    super.initState();
    // 加载设定组列表
    context.read<SettingBloc>().add(LoadSettingGroups(widget.novelId));
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 5,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择设定组',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 设定组列表
            BlocBuilder<SettingBloc, SettingState>(
              builder: (context, state) {
                if (state.groupsStatus == SettingStatus.loading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (state.groupsStatus == SettingStatus.failure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        '加载设定组失败：${state.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                
                if (state.groupsStatus == SettingStatus.success && state.groups.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        '没有可用的设定组，请创建新设定组',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                
                if (state.groupsStatus == SettingStatus.success) {
                  return SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: state.groups.length,
                      itemBuilder: (context, index) {
                        final group = state.groups[index];
                        return ListTile(
                          title: Text(group.name),
                          subtitle: group.description != null && group.description!.isNotEmpty
                              ? Text(
                                  group.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          leading: Icon(
                            Icons.folder_outlined,
                            color: group.isActiveContext == true
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          onTap: () {
                            // 正确关闭浮动卡片，而不是使用Navigator.pop()
                            // 使用Future.microtask确保回调在对话框处理之后执行
                            Future.microtask(() {
                              // 关闭浮动卡片
                              FloatingNovelSettingGroupSelectionDialog.hide();
                              // 延迟调用回调
                              Future.delayed(Duration.zero, () {
                                widget.onGroupSelected(group.id!, group.name);
                              });
                            });
                          },
                        );
                      },
                    ),
                  );
                }
                
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('请加载设定组'),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('创建新设定组'),
                  onPressed: () {
                    _showCreateGroupDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WebTheme.getPrimaryColor(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, 
                      vertical: 10,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('取消'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 显示创建设定组对话框
  void _showCreateGroupDialog(BuildContext context) {
    FloatingNovelSettingGroupDialog.show(
      context: context,
      novelId: widget.novelId,
      onSave: (SettingGroup group) {
        AppLogger.i('NovelSettingGroupSelectionDialog', '创建设定组：${group.name}');
        
        // 保存设定组
        context.read<SettingBloc>().add(CreateSettingGroup(
          novelId: widget.novelId,
          group: group,
        ));
        
        // 监听状态变化，找到新创建的设定组，但不要直接调用导航回调
        final settingBloc = context.read<SettingBloc>();
        late final subscription;
        subscription = settingBloc.stream.listen((state) {
          if (state.groupsStatus == SettingStatus.success) {
            // 检查是否有新添加的设定组
            final newGroup = state.groups.where((g) => g.name == group.name).lastOrNull;
            if (newGroup != null && newGroup.id != null) {
              subscription.cancel(); // 先停止监听
              
              // 只显示成功提示，不执行选择回调，让用户手动选择
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('设定组 "${newGroup.name}" 创建成功！'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
              
              // 刷新当前对话框的设定组列表
              if (context.mounted) {
                context.read<SettingBloc>().add(LoadSettingGroups(widget.novelId));
              }
            }
          }
          
          if (state.groupsStatus == SettingStatus.failure) {
            subscription.cancel();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('创建设定组失败：${state.error}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        });
        
        // 一段时间后如果没有成功，取消订阅
        Future.delayed(const Duration(seconds: 10), () {
          subscription.cancel();
        });
      },
    );
  }
} 