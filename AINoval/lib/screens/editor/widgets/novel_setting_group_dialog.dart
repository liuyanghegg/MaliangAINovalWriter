import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ainoval/models/setting_group.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:ainoval/screens/editor/managers/editor_layout_manager.dart';
import 'package:ainoval/widgets/common/floating_card.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/common/top_toast.dart';


/// 浮动设定组管理器
class FloatingNovelSettingGroupDialog {
  static bool _isShowing = false;

  /// 显示浮动设定组卡片
  static void show({
    required BuildContext context,
    required String novelId,
    SettingGroup? group, // 若为null则表示创建新组
    required Function(SettingGroup) onSave, // 保存回调
  }) {
    if (_isShowing) {
      hide();
    }

    // 获取布局信息
    final layoutManager = Provider.of<EditorLayoutManager>(context, listen: false);
    final sidebarWidth = layoutManager.isEditorSidebarVisible ? layoutManager.editorSidebarWidth : 0.0;

    AppLogger.d('FloatingNovelSettingGroupDialog', '显示浮动卡片，侧边栏宽度: $sidebarWidth');

    // 计算卡片大小
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = (screenSize.width * 0.25).clamp(400.0, 600.0);
    final cardHeight = (screenSize.height * 0.5).clamp(350.0, 500.0);

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
      child: _NovelSettingGroupDialogContent(
        novelId: novelId,
        group: group,
        onSave: (settingGroup) {
          onSave(settingGroup);
          hide();
        },
        onCancel: hide,
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

/// 小说设定组对话框内容
/// 
/// 用于创建或编辑设定组
class _NovelSettingGroupDialogContent extends StatefulWidget {
  final String novelId;
  final SettingGroup? group; // 若为null则表示创建新组
  final Function(SettingGroup) onSave; // 保存回调
  final VoidCallback onCancel; // 取消回调
  
  const _NovelSettingGroupDialogContent({
    Key? key,
    required this.novelId,
    this.group,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<_NovelSettingGroupDialogContent> createState() => _NovelSettingGroupDialogContentState();
}

class _NovelSettingGroupDialogContentState extends State<_NovelSettingGroupDialogContent> {
  final _formKey = GlobalKey<FormState>();
  
  // 表单控制器
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // 激活状态
  bool _isActiveContext = false;
  
  // 保存状态
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    
    // 若为编辑模式，填充表单
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      if (widget.group!.description != null) {
        _descriptionController.text = widget.group!.description!;
      }
      if (widget.group!.isActiveContext != null) {
        _isActiveContext = widget.group!.isActiveContext!;
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  // 保存设定组
  Future<void> _saveSettingGroup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // 构建设定组对象
      final settingGroup = SettingGroup(
        id: widget.group?.id,
        novelId: widget.novelId,
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : null,
        isActiveContext: _isActiveContext,
        itemIds: widget.group?.itemIds,
      );
      
      // 调用保存回调
      widget.onSave(settingGroup);
      
      setState(() {
        _isSaving = false;
      });
      
      // 注意：不在这里关闭对话框，因为 FloatingNovelSettingGroupDialog.show() 的 onSave 回调会调用 hide()
    } catch (e, stackTrace) {
      AppLogger.e('NovelSettingGroupDialog', '保存设定组失败', e, stackTrace);
      setState(() {
        _isSaving = false;
      });
      
      // 显示错误提示
      if (context.mounted) {
        TopToast.error(context, '保存失败: ${e.toString()}');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    final isCreating = widget.group == null;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WebTheme.darkBackground : WebTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          _buildHeader(isDark, isCreating),
          
          // 内容区域
          Expanded(
            child: _buildContent(isDark, isCreating),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isCreating) {
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              isCreating ? '创建设定组' : '编辑设定组',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: WebTheme.getTextColor(context),
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: Icon(
              Icons.close,
              size: 20,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, bool isCreating) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            isCreating ? '创建设定组' : '编辑设定组',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WebTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          
          // 表单
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 名称
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  maxLength: 30,
                  decoration: WebTheme.getBorderedInputDecoration(
                    labelText: '名称',
                    hintText: '输入设定组名称 (30 字以内)',
                    context: context,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入设定组名称';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 描述
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: WebTheme.getBorderedInputDecoration(
                    labelText: '描述',
                    hintText: '输入设定组描述（可选，200 字以内）',
                    context: context,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 激活状态
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, 
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Switch(
                        value: _isActiveContext,
                        onChanged: (value) {
                          setState(() {
                            _isActiveContext = value;
                          });
                        },
                        activeColor: WebTheme.getTextColor(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '设为活跃上下文',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: WebTheme.getTextColor(context),
                              ),
                            ),
                            Text(
                              '活跃上下文中的设定将用于AI生成和提示',
                              style: TextStyle(
                                fontSize: 12,
                                color: WebTheme.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 按钮区域
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                style: WebTheme.getSecondaryButtonStyle(context),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveSettingGroup,
                style: WebTheme.getPrimaryButtonStyle(context),
                child: _isSaving 
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: isDark ? WebTheme.darkBackground : WebTheme.lightBackground,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(isCreating ? '创建中...' : '保存中...'),
                        ],
                      )
                    : Text(isCreating ? '创建' : '保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 