import 'package:flutter/material.dart';
import 'package:ainoval/models/preset_models.dart';
import 'package:ainoval/models/ai_request_models.dart';
import 'package:ainoval/models/prompt_models.dart';
import 'package:ainoval/services/ai_preset_service.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:ainoval/utils/web_theme.dart';

/// 预设下拉框组件
class PresetDropdown extends StatefulWidget {
  /// 当前AI功能类型
  final AIRequestType requestType;
  
  /// 当前表单数据
  final UniversalAIRequest? currentRequest;
  
  /// 预设选择回调
  final Function(AIPromptPreset preset)? onPresetSelected;
  
  /// 预设创建回调
  final Function(AIPromptPreset preset)? onPresetCreated;
  
  /// 预设更新回调
  final Function(AIPromptPreset preset)? onPresetUpdated;

  const PresetDropdown({
    super.key,
    required this.requestType,
    this.currentRequest,
    this.onPresetSelected,
    this.onPresetCreated,
    this.onPresetUpdated,
  });

  @override
  State<PresetDropdown> createState() => _PresetDropdownState();
}

class _PresetDropdownState extends State<PresetDropdown> {
  final AIPresetService _presetService = AIPresetService();
  final String _tag = 'PresetDropdown';
  
  OverlayEntry? _overlayEntry;
  final GlobalKey _buttonKey = GlobalKey();
  
  List<AIPromptPreset> _recentPresets = [];
  List<AIPromptPreset> _favoritePresets = [];
  List<AIPromptPreset> _recommendedPresets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  /// 加载预设数据
  Future<void> _loadPresets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final featureType = _getFeatureTypeString();
      
      // 使用新的统一接口获取功能预设列表
      final presetListResponse = await _presetService.getFeaturePresetList(featureType);

      setState(() {
        _recentPresets = presetListResponse.recentUsed.map((item) => item.preset).toList();
        _favoritePresets = presetListResponse.favorites.map((item) => item.preset).toList();
        _recommendedPresets = presetListResponse.recommended.map((item) => item.preset).toList();
        _isLoading = false;
      });

      AppLogger.d(_tag, '预设数据加载完成: 最近${_recentPresets.length}个, 收藏${_favoritePresets.length}个, 推荐${_recommendedPresets.length}个');
    } catch (e) {
      AppLogger.e(_tag, '加载预设数据失败', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 获取功能类型字符串
  String _getFeatureTypeString() {
    // 🚀 映射AIRequestType到AIFeatureType，然后使用标准方法
    final aiFeatureType = _mapRequestTypeToFeatureType(widget.requestType);
    return aiFeatureType.toApiString();
  }

  /// 映射AIRequestType到AIFeatureType
  AIFeatureType _mapRequestTypeToFeatureType(AIRequestType requestType) {
    switch (requestType) {
      case AIRequestType.expansion:
        return AIFeatureType.textExpansion;
      case AIRequestType.generation:
        return AIFeatureType.novelGeneration;
      case AIRequestType.refactor:
        return AIFeatureType.textRefactor;
      case AIRequestType.summary:
        return AIFeatureType.textSummary;
      case AIRequestType.sceneSummary:
        return AIFeatureType.sceneToSummary;
      case AIRequestType.chat:
        return AIFeatureType.aiChat;
      case AIRequestType.sceneBeat:
        return AIFeatureType.sceneBeatGeneration;
      case AIRequestType.novelCompose:
        return AIFeatureType.novelCompose;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _buttonKey,
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? WebTheme.darkGrey100 
              : WebTheme.white,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
                ? WebTheme.darkGrey300 
                : WebTheme.grey300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              'Presets',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  /// 切换下拉框显示/隐藏
  void _toggleDropdown() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _showDropdown();
    }
  }

  /// 显示下拉框
  void _showDropdown() {
    final RenderBox? renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 透明背景，点击关闭
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          // 下拉框内容
          Positioned(
            left: position.dx,
            top: position.dy + size.height + 4,
            width: 280,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surface,
              shadowColor: Colors.black.withOpacity(0.15),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: _buildDropdownContent(),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 移除下拉框
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 构建下拉框内容
  Widget _buildDropdownContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 头部操作
        _buildHeaderActions(),
        
        if (_favoritePresets.isNotEmpty || _recentPresets.isNotEmpty || _recommendedPresets.isNotEmpty)
          const Divider(height: 1),
        
        // 预设列表
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 收藏预设
                if (_favoritePresets.isNotEmpty) ...[
                  _buildPresetSection('收藏预设', _favoritePresets),
                  if (_recentPresets.isNotEmpty || _recommendedPresets.isNotEmpty) const Divider(height: 1),
                ],
                
                // 最近使用
                if (_recentPresets.isNotEmpty) ...[
                  _buildPresetSection('最近使用', _recentPresets),
                  if (_recommendedPresets.isNotEmpty) const Divider(height: 1),
                ],
                
                // 推荐预设
                if (_recommendedPresets.isNotEmpty)
                  _buildPresetSection('推荐预设', _recommendedPresets),
                
                // 空状态
                if (_favoritePresets.isEmpty && _recentPresets.isEmpty && _recommendedPresets.isEmpty)
                  _buildEmptyState(),
              ],
            ),
          ),
        ),
        
        const Divider(height: 1),
        
        // 底部操作
        _buildFooterActions(),
      ],
    );
  }

  /// 构建头部操作
  Widget _buildHeaderActions() {
    return Column(
      children: [
        // New Preset
        _buildActionItem(
          icon: Icons.add,
          title: 'New Preset',
          subtitle: null,
          onTap: _handleNewPreset,
        ),
        
        // Update Preset (仅当有当前请求时显示)
        if (widget.currentRequest != null)
          _buildActionItem(
            icon: Icons.edit_outlined,
            title: 'Update Preset',
            subtitle: null,
            onTap: _handleUpdatePreset,
            enabled: false, // 暂时禁用，需要选择现有预设
          ),
        
        // Create Preset
        if (widget.currentRequest != null)
          _buildActionItem(
            icon: Icons.bookmark_add,
            title: 'Create Preset',
            subtitle: null,
            onTap: _handleCreatePreset,
          ),
      ],
    );
  }

  /// 构建底部操作
  Widget _buildFooterActions() {
    return _buildActionItem(
      icon: Icons.settings,
      title: 'Manage Presets',
      subtitle: null,
      onTap: _handleManagePresets,
    );
  }

  /// 构建操作项
  Widget _buildActionItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: enabled 
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: enabled 
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建预设分组
  Widget _buildPresetSection(String title, List<AIPromptPreset> presets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: WebTheme.getPrimaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...presets.map((preset) => _buildPresetItem(preset)).toList(),
      ],
    );
  }

  /// 构建预设项
  Widget _buildPresetItem(AIPromptPreset preset) {
    return InkWell(
      onTap: () => _handlePresetSelected(preset),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 收藏图标
            if (preset.isFavorite)
              Icon(
                Icons.favorite,
                size: 14,
                color: Colors.red.shade400,
              )
            else
              const SizedBox(width: 14),
            
            const SizedBox(width: 8),
            
            // 预设信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.presetName ?? '未命名预设',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (preset.presetDescription != null)
                    Text(
                      preset.presetDescription!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            
            // 使用次数
            if (preset.useCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${preset.useCount}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: WebTheme.getPrimaryColor(context),
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(
            Icons.bookmark_outline,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无预设',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建第一个预设来快速重用配置',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 事件处理器
  void _handleNewPreset() {
    _removeOverlay();
    _showPresetNameDialog(isUpdate: false);
  }

  void _handleUpdatePreset() {
    _removeOverlay();
    // TODO: 实现更新现有预设功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('更新预设功能即将推出')),
    );
  }

  void _handleCreatePreset() {
    _removeOverlay();
    _showPresetNameDialog(isUpdate: false);
  }

  void _handleManagePresets() {
    _removeOverlay();
    // TODO: 导航到预设管理页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('预设管理页面即将推出')),
    );
  }

  void _handlePresetSelected(AIPromptPreset preset) {
    _removeOverlay();
    widget.onPresetSelected?.call(preset);
    
    // 记录预设使用（通过应用预设方法，它会自动记录使用）
    _presetService.applyPreset(preset.presetId).catchError((e) {
      AppLogger.w(_tag, '记录预设使用失败', e);
      return preset; // 返回原始预设对象
    });
    
    AppLogger.i(_tag, '预设已选择: ${preset.presetName}');
  }

  /// 显示预设名称输入对话框
  void _showPresetNameDialog({required bool isUpdate}) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUpdate ? '更新预设' : '创建预设'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '预设名称',
                hintText: '输入预设名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '输入预设描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop();
                _createPreset(name, descController.text.trim());
              }
            },
            child: Text(isUpdate ? '更新' : '创建'),
          ),
        ],
      ),
    );
  }

  /// 创建预设
  Future<void> _createPreset(String name, String description) async {
    if (widget.currentRequest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法创建预设：缺少表单数据')),
      );
      return;
    }

    try {
      final request = CreatePresetRequest(
        presetName: name,
        presetDescription: description.isNotEmpty ? description : null,
        request: widget.currentRequest!,
      );

      final preset = await _presetService.createPreset(request);
      
      widget.onPresetCreated?.call(preset);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('预设 "$name" 创建成功')),
      );

      // 重新加载预设列表
      _loadPresets();

      AppLogger.i(_tag, '预设创建成功: $name');
    } catch (e) {
      AppLogger.e(_tag, '创建预设失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建预设失败: $e')),
      );
    }
  }
} 