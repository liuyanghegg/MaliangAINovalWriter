import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_bloc.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_state.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_event.dart';
import 'package:ainoval/models/prompt_models.dart';
// removed duplicate import
import 'package:ainoval/utils/logger.dart';
import 'package:ainoval/screens/prompt/widgets/prompt_content_editor.dart';
import 'package:ainoval/screens/prompt/widgets/prompt_properties_editor.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

/// 提示词详情视图
class PromptDetailView extends StatefulWidget {
  const PromptDetailView({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<PromptDetailView> createState() => _PromptDetailViewState();
}

class _PromptDetailViewState extends State<PromptDetailView>
    with TickerProviderStateMixin {
  static const String _tag = 'PromptDetailView';
  
  late TabController _tabController;

  // 名称输入框控制器
  final TextEditingController _nameController = TextEditingController();

  // 是否处于已编辑但未保存状态
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final isDark = WebTheme.isDarkMode(context); // unused
    
    return Container(
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: BlocConsumer<PromptNewBloc, PromptNewState>(
        listener: (context, state) {
          // 当选中的提示词发生变化时，更新名称控制器
          if (state.selectedPrompt != null) {
            _nameController.text = state.selectedPrompt!.name;
            _isEdited = false;
          }
        },
        builder: (context, state) {
          final prompt = state.selectedPrompt;
          
          // 确保在非编辑状态下名称与当前提示词保持同步，避免首次点击时显示为空
          if (prompt != null && !_isEdited && _nameController.text != prompt.name) {
            _nameController.text = prompt.name;
          }
          
          if (prompt == null) {
            return _buildEmptyView();
          }

          return Column(
            children: [
              // 顶部标题栏
              _buildTopBar(context, prompt, state),
              
              // 标签栏
              _buildTabBar(),
              
              // 内容区域
              Expanded(
                child: Container(
                  color: WebTheme.getSurfaceColor(context),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      PromptContentEditor(prompt: prompt),
                      PromptPropertiesEditor(prompt: prompt),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建顶部标题栏
  Widget _buildTopBar(BuildContext context, UserPromptInfo prompt, PromptNewState state) {
    final isDark = WebTheme.isDarkMode(context);
    final isSystemDefault = prompt.id.startsWith('system_default_');
    final isPublicTemplate = prompt.id.startsWith('public_');
    final isReadOnly = isSystemDefault || isPublicTemplate;
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        border: Border(
          bottom: BorderSide(
            color: isDark ? WebTheme.darkGrey200 : WebTheme.grey200,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // 返回按钮（仅在窄屏幕显示）
          if (widget.onBack != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? WebTheme.darkGrey200 : WebTheme.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: widget.onBack,
                  child: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: isDark ? WebTheme.darkGrey600 : WebTheme.grey700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // 模板标题
          Expanded(
            child: TextField(
              controller: _nameController,
              style: WebTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: WebTheme.getTextColor(context),
                height: 1.2,
              ),
              decoration: WebTheme.getBorderlessInputDecoration(
                hintText: '输入模板名称...',
                context: context,
              ),
              cursorColor: WebTheme.getTextColor(context),
              maxLines: 1,
              readOnly: isReadOnly,
              onChanged: (value) {
                setState(() {
                  _isEdited = true;
                });
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 操作按钮
          _buildActionButtons(context, prompt, state),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context, UserPromptInfo prompt, PromptNewState state) {
    // final isDark = WebTheme.isDarkMode(context); // unused
    final isSystemDefault = prompt.id.startsWith('system_default_');
    final isPublicTemplate = prompt.id.startsWith('public_');
    final canSetDefault = !isSystemDefault && !isPublicTemplate;
    final canEdit = !isSystemDefault && !isPublicTemplate;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 复制按钮
        _buildIconButton(
          icon: Icons.copy_outlined,
          tooltip: '复制模板',
          onPressed: () {
            context.read<PromptNewBloc>().add(CopyPromptTemplate(
              templateId: prompt.id,
            ));
          },
        ),
        
        const SizedBox(width: 8),
        
        // 收藏按钮
        _buildIconButton(
          icon: prompt.isFavorite ? Icons.star : Icons.star_outline,
          tooltip: prompt.isFavorite ? '取消收藏' : '收藏',
          onPressed: () {
            context.read<PromptNewBloc>().add(ToggleFavoriteStatus(
              promptId: prompt.id,
              isFavorite: !prompt.isFavorite,
            ));
          },
        ),
        
        if (canSetDefault) ...[
          const SizedBox(width: 8),
          // 设为默认按钮
          _buildIconButton(
            icon: prompt.isDefault ? Icons.bookmark : Icons.bookmark_outline,
            tooltip: prompt.isDefault ? '已是默认' : '设为默认',
            onPressed: prompt.isDefault
                ? null
                : () {
                    final featureType = state.selectedFeatureType;
                    if (featureType != null) {
                      context.read<PromptNewBloc>().add(SetDefaultTemplate(
                        promptId: prompt.id,
                        featureType: featureType,
                      ));
                    }
                  },
          ),
        ],
        
        if (!isSystemDefault && !isPublicTemplate) ...[
          const SizedBox(width: 8),
          // 删除按钮
          _buildIconButton(
            icon: Icons.delete_outline,
            tooltip: '删除',
            onPressed: () => _showDeleteConfirmDialog(context, prompt),
          ),
        ],
        
        // 保存按钮（系统/公共模板不显示）
        if (canEdit && (_isEdited || state.isUpdating)) ...[
          const SizedBox(width: 8),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: WebTheme.grey900,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: state.isUpdating ? null : () => _saveChanges(context, prompt),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.isUpdating)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: WebTheme.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.save,
                          size: 14,
                          color: WebTheme.white,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        state.isUpdating ? '保存中...' : '保存',
                        style: WebTheme.labelSmall.copyWith(
                          color: WebTheme.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  /// 构建统一的图标按钮
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final isDark = WebTheme.isDarkMode(context);
    
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? WebTheme.darkGrey200 : WebTheme.grey100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onPressed,
            child: Icon(
              icon,
              size: 16,
              color: onPressed != null 
                  ? (isDark ? WebTheme.darkGrey600 : WebTheme.grey700)
                  : (isDark ? WebTheme.darkGrey400 : WebTheme.grey400),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建标签栏
  Widget _buildTabBar() {
    final isDark = WebTheme.isDarkMode(context);
    
    return Container(
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        border: Border(
          bottom: BorderSide(
            color: isDark ? WebTheme.darkGrey200 : WebTheme.grey200,
            width: 1.0,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: WebTheme.getPrimaryColor(context),
        unselectedLabelColor: WebTheme.getSecondaryTextColor(context),
        indicatorColor: WebTheme.getPrimaryColor(context),
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined, size: 18),
                const SizedBox(width: 8),
                const Text('内容编辑'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_outlined, size: 18),
                const SizedBox(width: 8),
                const Text('属性设置'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空视图
  Widget _buildEmptyView() {
    return Container(
      color: WebTheme.getSurfaceColor(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: WebTheme.getPrimaryColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 48,
                color: WebTheme.getPrimaryColor(context).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '选择一个提示词模板',
              style: WebTheme.headlineSmall.copyWith(
                color: WebTheme.getTextColor(context),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                '在左侧列表中选择一个提示词模板以查看和编辑详情。\n您可以修改模板内容、设置属性、添加标签等。',
                style: WebTheme.bodyMedium.copyWith(
                  color: WebTheme.getSecondaryTextColor(context),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeatureIcon(Icons.edit_outlined, '编辑内容'),
                const SizedBox(width: 24),
                _buildFeatureIcon(Icons.settings_outlined, '设置属性'),
                const SizedBox(width: 24),
                _buildFeatureIcon(Icons.label_outline, '管理标签'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建功能图标
  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: WebTheme.isDarkMode(context) 
                ? WebTheme.darkGrey200.withOpacity(0.5)
                : WebTheme.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: 20,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: WebTheme.getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context, UserPromptInfo prompt) {
    // final isDark = WebTheme.isDarkMode(context); // unused
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WebTheme.getSurfaceColor(context),
        title: Text(
          '确认删除',
          style: WebTheme.titleMedium.copyWith(
            color: WebTheme.getTextColor(context),
          ),
        ),
        content: Text(
          '确定要删除提示词模板 "${prompt.name}" 吗？此操作无法撤销。',
          style: WebTheme.bodyMedium.copyWith(
            color: WebTheme.getTextColor(context, isPrimary: false),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: WebTheme.getSecondaryTextColor(context),
            ),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PromptNewBloc>().add(DeletePrompt(
                promptId: prompt.id,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WebTheme.error,
              foregroundColor: WebTheme.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 保存更改
  void _saveChanges(BuildContext context, UserPromptInfo prompt) {
    if (_nameController.text.trim().isEmpty) {
      TopToast.warning(context, '模板名称不能为空');
      return;
    }

    final request = UpdatePromptTemplateRequest(
      name: _nameController.text.trim(),
    );

    context.read<PromptNewBloc>().add(UpdatePromptDetails(
      promptId: prompt.id,
      request: request,
    ));

    setState(() {
      _isEdited = false;
    });

    AppLogger.i(_tag, '保存提示词模板更改: ${prompt.id}');
  }
} 