import 'package:flutter/material.dart';

import '../../../models/preset_models.dart';
import '../../../services/ai_preset_service.dart';
import '../../../utils/logger.dart';
import '../../../widgets/common/loading_indicator.dart';
import 'user_preset_card.dart';
import 'add_user_preset_dialog.dart';
import 'edit_user_preset_dialog.dart';

/// 用户预设管理面板
class UserPresetManagementPanel extends StatefulWidget {
  const UserPresetManagementPanel({Key? key}) : super(key: key);

  @override
  State<UserPresetManagementPanel> createState() => _UserPresetManagementPanelState();
}

class _UserPresetManagementPanelState extends State<UserPresetManagementPanel>
    with TickerProviderStateMixin {
  final AIPresetService _presetService = AIPresetService();
  late TabController _tabController;
  
  List<AIPromptPreset> _presets = [];
  List<AIPromptPreset> _selectedPresets = [];
  bool _isLoading = true;
  bool _batchMode = false;
  String? _error;
  String _searchQuery = '';
  String _currentTab = 'ALL';

  static const List<String> _tabs = ['ALL', 'CHAT', 'SCENE_GENERATION', 'CONTINUATION', 'SUMMARY', 'OUTLINE', 'FAVORITES'];
  static const Map<String, String> _tabLabels = {
    'ALL': '全部预设',
    'CHAT': 'AI聊天',
    'SCENE_GENERATION': '场景生成',
    'CONTINUATION': '续写',
    'SUMMARY': '总结',
    'OUTLINE': '大纲',
    'FAVORITES': '收藏夹',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadPresets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentTab = _tabs[_tabController.index];
        _selectedPresets.clear();
        _batchMode = false;
      });
      _loadPresets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_button, size: 24),
              const SizedBox(width: 8),
              const Text(
                '我的预设库',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddPresetDialog,
                icon: const Icon(Icons.add),
                label: const Text('新建预设'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // 搜索框
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _loadPresets();
                  },
                  decoration: InputDecoration(
                    hintText: '搜索我的预设...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 批量操作开关
              if (_presets.isNotEmpty) ...[
                FilterChip(
                  label: Text('批量操作${_batchMode ? ' (${_selectedPresets.length})' : ''}'),
                  selected: _batchMode,
                  onSelected: (selected) {
                    setState(() {
                      _batchMode = selected;
                      if (!selected) {
                        _selectedPresets.clear();
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
              
              // 批量操作按钮
              if (_batchMode && _selectedPresets.isNotEmpty) ...[
                PopupMenuButton<String>(
                  onSelected: (value) => _handleBatchAction(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'favorite',
                      child: Row(
                        children: [
                          Icon(Icons.favorite, size: 18),
                          SizedBox(width: 8),
                          Text('添加到收藏'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.file_download, size: 18),
                          SizedBox(width: 8),
                          Text('导出预设'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('批量删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.more_vert),
                    label: const Text('批量操作'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // 导入按钮
              TextButton.icon(
                onPressed: _showImportDialog,
                icon: const Icon(Icons.file_upload),
                label: const Text('导入'),
              ),
              
              // 刷新按钮
              IconButton(
                onPressed: _loadPresets,
                icon: const Icon(Icons.refresh),
                tooltip: '刷新',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: _tabs.map((tab) => Tab(
          text: _tabLabels[tab],
        )).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPresets,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_presets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_button,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无预设',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '创建您的第一个AI提示预设',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddPresetDialog,
              icon: const Icon(Icons.add),
              label: const Text('新建预设'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: _tabs.map((tab) => _buildPresetList()).toList(),
    );
  }

  Widget _buildPresetList() {
    final filteredPresets = _getFilteredPresets();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: filteredPresets.length,
        itemBuilder: (context, index) {
          final preset = filteredPresets[index];
          return UserPresetCard(
            preset: preset,
            isSelected: _selectedPresets.contains(preset),
            batchMode: _batchMode,
            onTap: () => _onPresetCardTap(preset),
            onEdit: () => _showEditPresetDialog(preset),
            onFavorite: () => _togglePresetFavorite(preset),
            onDelete: () => _deletePreset(preset),
            onUse: () => _usePreset(preset),
            onSelectionChanged: (selected) => _onPresetSelectionChanged(preset, selected),
          );
        },
      ),
    );
  }

  List<AIPromptPreset> _getFilteredPresets() {
    List<AIPromptPreset> filteredPresets = List.from(_presets);
    
    // 根据标签页筛选
    if (_currentTab != 'ALL') {
      if (_currentTab == 'FAVORITES') {
        filteredPresets = filteredPresets.where((p) => p.isFavorite == true).toList();
      } else {
        filteredPresets = filteredPresets.where((p) => p.aiFeatureType == _currentTab).toList();
      }
    }
    
    // 根据搜索条件筛选
    if (_searchQuery.isNotEmpty) {
      filteredPresets = filteredPresets.where((preset) {
        final query = _searchQuery.toLowerCase();
        return (preset.presetName ?? '').toLowerCase().contains(query) ||
               (preset.presetDescription?.toLowerCase().contains(query) ?? false) ||
               ((preset.systemPrompt ?? '').toLowerCase().contains(query)) ||
               ((preset.userPrompt ?? '').toLowerCase().contains(query));
      }).toList();
    }
    
    return filteredPresets;
  }

  // 数据加载
  Future<void> _loadPresets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final presets = await _presetService.getUserPresets(featureType: 'AI_CHAT');
      
      setState(() {
        _presets = presets;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('加载用户预设失败', e.toString());
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // 事件处理
  void _onPresetCardTap(AIPromptPreset preset) {
    if (_batchMode) {
      _onPresetSelectionChanged(preset, !_selectedPresets.contains(preset));
    } else {
      _showPresetDetails(preset);
    }
  }

  void _onPresetSelectionChanged(AIPromptPreset preset, bool selected) {
    setState(() {
      if (selected) {
        _selectedPresets.add(preset);
      } else {
        _selectedPresets.remove(preset);
      }
    });
  }

  // 对话框显示
  void _showAddPresetDialog() {
    showDialog(
      context: context,
      builder: (context) => AddUserPresetDialog(
        onSuccess: _loadPresets,
      ),
    );
  }

  void _showEditPresetDialog(AIPromptPreset preset) {
    showDialog(
      context: context,
      builder: (context) => EditUserPresetDialog(
        preset: preset,
        onSuccess: _loadPresets,
      ),
    );
  }

  void _showPresetDetails(AIPromptPreset preset) {
    // TODO: 实现预设详情对话框
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查看预设详情: ${preset.presetName}')),
    );
  }

  void _showImportDialog() {
    // TODO: 实现导入预设对话框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导入功能开发中...')),
    );
  }

  // 操作方法
  Future<void> _togglePresetFavorite(AIPromptPreset preset) async {
    try {
      await _presetService.toggleFavorite(preset.presetId);
      
      final action = preset.isFavorite ? '取消收藏' : '添加到收藏';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('预设 "${preset.presetName}" $action成功')),
      );
      _loadPresets();
    } catch (e) {
      AppLogger.error('收藏操作失败', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('收藏操作失败: ${e.toString()}')),
      );
    }
  }

  Future<void> _deletePreset(AIPromptPreset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除预设 "${preset.presetName}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _presetService.deletePreset(preset.presetId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('预设 "${preset.presetName}" 删除成功')),
      );
      _loadPresets();
    } catch (e) {
      AppLogger.error('删除预设失败', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: ${e.toString()}')),
      );
    }
  }

  void _usePreset(AIPromptPreset preset) {
    // TODO: 实现使用预设功能，跳转到对应的AI功能页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('使用预设: ${preset.presetName}')),
    );
  }

  // 批量操作
  Future<void> _handleBatchAction(String action) async {
    if (_selectedPresets.isEmpty) return;

    switch (action) {
      case 'favorite':
        await _batchFavoritePresets();
        break;
      case 'export':
        await _batchExportPresets();
        break;
      case 'delete':
        await _batchDeletePresets();
        break;
    }
  }

  Future<void> _batchFavoritePresets() async {
    try {
      for (final preset in _selectedPresets) {
        await _presetService.toggleFavorite(preset.presetId);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已收藏 ${_selectedPresets.length} 个预设')),
      );
      
      setState(() {
        _selectedPresets.clear();
        _batchMode = false;
      });
      _loadPresets();
    } catch (e) {
      AppLogger.error('批量收藏预设失败', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('批量收藏失败: ${e.toString()}')),
      );
    }
  }

  Future<void> _batchExportPresets() async {
    try {
      // TODO: 实现批量导出功能
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出 ${_selectedPresets.length} 个预设功能开发中...')),
      );
      
      setState(() {
        _selectedPresets.clear();
        _batchMode = false;
      });
    } catch (e) {
      AppLogger.error('批量导出预设失败', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('批量导出失败: ${e.toString()}')),
      );
    }
  }

  Future<void> _batchDeletePresets() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认批量删除'),
        content: Text('确定要删除选中的 ${_selectedPresets.length} 个预设吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      for (final preset in _selectedPresets) {
        await _presetService.deletePreset(preset.presetId);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 ${_selectedPresets.length} 个预设')),
      );
      
      setState(() {
        _selectedPresets.clear();
        _batchMode = false;
      });
      _loadPresets();
    } catch (e) {
      AppLogger.error('批量删除预设失败', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('批量删除失败: ${e.toString()}')),
      );
    }
  }
}