import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/models/prompt_models.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_bloc.dart';
import 'package:ainoval/blocs/prompt_new/prompt_new_event.dart';

class PromptQuickEditDialog extends StatefulWidget {
  const PromptQuickEditDialog({
    super.key,
    required this.templateId,
    required this.aiFeatureType,
    this.onTemporaryPromptsSaved,
  });

  final String templateId;
  final String aiFeatureType;
  final void Function(String systemPrompt, String userPrompt)? onTemporaryPromptsSaved;

  @override
  State<PromptQuickEditDialog> createState() => _PromptQuickEditDialogState();
}

class _PromptQuickEditDialogState extends State<PromptQuickEditDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _systemController;
  late TextEditingController _userController;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _systemController = TextEditingController();
    _userController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<PromptNewBloc>().state;
      final feature = AIFeatureTypeHelper.fromApiString(widget.aiFeatureType.toUpperCase());
      final pkg = state.promptPackages[feature];
      if (pkg != null) {
        UserPromptInfo? selected;
        if (widget.templateId.startsWith('system_default_')) {
          if (pkg.systemPrompt.defaultSystemPrompt.isNotEmpty) {
            selected = UserPromptInfo(
              id: widget.templateId,
              name: '系统默认模板',
              featureType: feature,
              systemPrompt: pkg.systemPrompt.effectivePrompt,
              userPrompt: pkg.systemPrompt.defaultUserPrompt,
              createdAt: pkg.lastUpdated,
              updatedAt: pkg.lastUpdated,
            );
          }
        } else if (widget.templateId.startsWith('public_')) {
          final pid = widget.templateId.substring('public_'.length);
          final pub = pkg.publicPrompts.firstWhere(
            (e) => e.id == pid,
            orElse: () => PublicPromptInfo(
              id: '', name: '', featureType: feature, systemPrompt: '', userPrompt: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
            ),
          );
          if (pub.id.isNotEmpty) {
            selected = UserPromptInfo(
              id: widget.templateId,
              name: pub.name,
              featureType: feature,
              systemPrompt: pub.systemPrompt,
              userPrompt: pub.userPrompt,
              createdAt: pub.createdAt,
              updatedAt: pub.updatedAt,
              isPublic: true,
              isVerified: pub.isVerified,
            );
          }
        } else {
          selected = pkg.userPrompts.firstWhere(
            (e) => e.id == widget.templateId,
            orElse: () => UserPromptInfo(
              id: '', name: '', featureType: AIFeatureType.textExpansion, userPrompt: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
            ),
          );
        }

        if (selected != null && selected.id.isNotEmpty) {
          _systemController.text = selected.systemPrompt ?? '';
          _userController.text = selected.userPrompt;
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _systemController.dispose();
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: WebTheme.getSurfaceColor(context),
      child: SizedBox(
        width: 900,
        height: 640,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContentEditor(),
                  _buildPropertiesPlaceholder(),
                ],
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        border: Border(
          bottom: BorderSide(color: WebTheme.getBorderColor(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            '编辑提示词',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: WebTheme.getTextColor(context),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            color: WebTheme.getTextColor(context),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: WebTheme.getSurfaceColor(context),
        border: Border(
          bottom: BorderSide(color: WebTheme.getBorderColor(context), width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: WebTheme.getTextColor(context),
        unselectedLabelColor: WebTheme.getSecondaryTextColor(context),
        indicatorColor: WebTheme.getTextColor(context),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '内容编辑', icon: Icon(Icons.edit_outlined, size: 16)),
          Tab(text: '属性设置', icon: Icon(Icons.settings_outlined, size: 16)),
        ],
      ),
    );
  }

  Widget _buildContentEditor() {
    final isDark = WebTheme.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('系统提示词 (System Prompt)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WebTheme.getTextColor(context))),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300),
                      borderRadius: BorderRadius.circular(8),
                      color: WebTheme.getSurfaceColor(context),
                    ),
                    child: TextField(
                      controller: _systemController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12), hintText: '输入系统提示词...'),
                      onChanged: (_) => setState(() => _isEdited = true),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: WebTheme.getBorderColor(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('用户提示词 (User Prompt)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WebTheme.getTextColor(context))),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? WebTheme.darkGrey300 : WebTheme.grey300),
                      borderRadius: BorderRadius.circular(8),
                      color: WebTheme.getSurfaceColor(context),
                    ),
                    child: TextField(
                      controller: _userController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12), hintText: '输入用户提示词...'),
                      onChanged: (_) => setState(() => _isEdited = true),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesPlaceholder() {
    return Center(
      child: Text(
        '属性设置可在完整提示词页面中编辑',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: WebTheme.getBorderColor(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              widget.onTemporaryPromptsSaved?.call(
                _systemController.text.trim(),
                _userController.text.trim(),
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已临时保存当前编辑的提示词')));
            },
            child: const Text('临时保存'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isEdited ? _saveToServer : null,
            icon: const Icon(Icons.save, size: 16),
            label: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _saveToServer() {
    if (widget.templateId.startsWith('system_default_') || widget.templateId.startsWith('public_')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('系统/公共模板不可直接修改，请先复制为私有模板')));
      return;
    }

    context.read<PromptNewBloc>().add(UpdatePromptDetails(
      promptId: widget.templateId,
      request: UpdatePromptTemplateRequest(
        systemPrompt: _systemController.text.trim(),
        userPrompt: _userController.text.trim(),
      ),
    ));

    setState(() => _isEdited = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('模板已保存')));
  }
}


