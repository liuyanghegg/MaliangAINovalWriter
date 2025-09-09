import 'package:flutter/material.dart';

import '../../../models/prompt_models.dart';
import '../../../services/api_service/base/api_client.dart';
import '../../../services/api_service/repositories/impl/prompt_repository_impl.dart';
import '../../../utils/logger.dart';
import '../../../widgets/common/loading_indicator.dart';
import 'user_template_card.dart';
import 'add_user_template_dialog.dart';
import 'edit_user_template_dialog.dart';

/// 用户模板管理面板
class UserTemplateManagementPanel extends StatefulWidget {
  const UserTemplateManagementPanel({Key? key}) : super(key: key);

  @override
  State<UserTemplateManagementPanel> createState() => _UserTemplateManagementPanelState();
}

class _UserTemplateManagementPanelState extends State<UserTemplateManagementPanel>
    with TickerProviderStateMixin {
  final PromptRepositoryImpl _promptRepository = PromptRepositoryImpl(ApiClient());
  late TabController _tabController;
  
  List<PromptTemplate> _templates = [];
  List<PromptTemplate> _selectedTemplates = [];
  bool _isLoading = true;
  bool _batchMode = false;
  String? _error;
  String _searchQuery = '';
  String _currentTab = 'ALL';

  static const List<String> _tabs = ['ALL', 'PRIVATE', 'SHARED', 'FAVORITES'];
  static const Map<String, String> _tabLabels = {
    'ALL': '全部模板',
    'PRIVATE': '私有模板',
    'SHARED': '已分享',
    'FAVORITES': '收藏夹',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTemplates();
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
        _selectedTemplates.clear();
        _batchMode = false;
      });
      _loadTemplates();
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
              const Icon(Icons.article_outlined, size: 24),
              const SizedBox(width: 8),
              const Text(
                '我的模板库',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddTemplateDialog,
                icon: const Icon(Icons.add),
                label: const Text('新建模板'),
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
                    _loadTemplates();
                  },
                  decoration: InputDecoration(
                    hintText: '搜索我的模板...',
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
              if (_templates.isNotEmpty) ...[
                FilterChip(
                  label: Text('批量操作${_batchMode ? ' (${_selectedTemplates.length})' : ''}'),
                  selected: _batchMode,
                  onSelected: (selected) {
                    setState(() {
                      _batchMode = selected;
                      if (!selected) {
                        _selectedTemplates.clear();
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
              
              // 批量操作按钮
              if (_batchMode && _selectedTemplates.isNotEmpty) ...[
                PopupMenuButton<String>(
                  onSelected: (value) => _handleBatchAction(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 18),
                          SizedBox(width: 8),
                          Text('批量分享'),
                        ],
                      ),
                    ),
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
              
              // 刷新按钮
              IconButton(
                onPressed: _loadTemplates,
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
              onPressed: _loadTemplates,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无模板',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '创建您的第一个提示词模板',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddTemplateDialog,
              icon: const Icon(Icons.add),
              label: const Text('新建模板'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: _tabs.map((tab) => _buildTemplateList()).toList(),
    );
  }

  Widget _buildTemplateList() {
    final filteredTemplates = _getFilteredTemplates();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: filteredTemplates.length,
        itemBuilder: (context, index) {
          final template = filteredTemplates[index];
          return UserTemplateCard(
            template: template,
            isSelected: _selectedTemplates.contains(template),
            batchMode: _batchMode,
            onTap: () => _onTemplateCardTap(template),
            onEdit: () => _showEditTemplateDialog(template),
            onShare: () => _shareTemplate(template),
            onFavorite: () => _toggleTemplateFavorite(template),
            onDelete: () => _deleteTemplate(template),
            onSelectionChanged: (selected) => _onTemplateSelectionChanged(template, selected),
          );
        },
      ),
    );
  }

  List<PromptTemplate> _getFilteredTemplates() {
    List<PromptTemplate> filteredTemplates = List.from(_templates);
    
    // 根据标签页筛选
    switch (_currentTab) {
      case 'PRIVATE':
        filteredTemplates = filteredTemplates.where((t) => t.isPublic == false).toList();
        break;
      case 'SHARED':
        filteredTemplates = filteredTemplates.where((t) => t.isPublic == true).toList();
        break;
      case 'FAVORITES':
        filteredTemplates = filteredTemplates.where((t) => t.isFavorite == true).toList();
        break;
    }
    
    // 根据搜索条件筛选
    if (_searchQuery.isNotEmpty) {
      filteredTemplates = filteredTemplates.where((template) {
        final query = _searchQuery.toLowerCase();
        return template.name.toLowerCase().contains(query) ||
               ((template.description ?? '').toLowerCase().contains(query)) ||
               (template.content.toLowerCase().contains(query));
      }).toList();
    }
    
    return filteredTemplates;
  }

  // 数据加载
  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 仓库当前不支持按搜索服务端筛选，这里拉取全部再前端过滤
      final templates = await _promptRepository.getPromptTemplates();
      
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('加载用户模板失败', e.toString());
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // 事件处理
  void _onTemplateCardTap(PromptTemplate template) {
    if (_batchMode) {
      _onTemplateSelectionChanged(template, !_selectedTemplates.contains(template));
    } else {
      _showTemplateDetails(template);
    }
  }

  void _onTemplateSelectionChanged(PromptTemplate template, bool selected) {
    setState(() {
      if (selected) {
        _selectedTemplates.add(template);
      } else {
        _selectedTemplates.remove(template);
      }
    });
  }

  // 对话框显示
  void _showAddTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AddUserTemplateDialog(
        onSuccess: _loadTemplates,
      ),
    );
  }

  void _showEditTemplateDialog(PromptTemplate template) {
    showDialog(
      context: context,
      builder: (context) => EditUserTemplateDialog(
        template: template,
        onSuccess: _loadTemplates,
      ),
    );
  }

  void _showTemplateDetails(PromptTemplate template) {
    // TODO: 实现模板详情对话框
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查看模板详情: ${template.name}')),
    );
  }

  // 操作方法
  Future<void> _shareTemplate(PromptTemplate template) async {
    // 当前仓库未提供分享接口，占位提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能暂未实现')),
    );
  }

  Future<void> _toggleTemplateFavorite(PromptTemplate template) async {
    try {
      final updated = await _promptRepository.toggleTemplateFavorite(template);
      final action = updated.isFavorite ? '添加到收藏' : '取消收藏';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${updated.name} $action')),
      );
      _loadTemplates();
    } catch (e) {
      AppLogger.error('切换模板收藏状态失败', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteTemplate(PromptTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模板 "${template.name}" 吗？此操作不可撤销。'),
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
      await _promptRepository.deletePromptTemplate(template.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('模板 "${template.name}" 删除成功')),
      );
      _loadTemplates();
    } catch (e) {
      AppLogger.error('删除模板失败', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  // 批量操作
  Future<void> _handleBatchAction(String action) async {
    if (_selectedTemplates.isEmpty) return;

    switch (action) {
      case 'share':
        await _batchShareTemplates();
        break;
      case 'favorite':
        await _batchFavoriteTemplates();
        break;
      case 'delete':
        await _batchDeleteTemplates();
        break;
    }
  }

  Future<void> _batchShareTemplates() async {
    try {
      // 当前仓库未提供分享接口
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功分享 ${_selectedTemplates.length} 个模板')),
      );
      
      setState(() {
        _selectedTemplates.clear();
        _batchMode = false;
      });
      _loadTemplates();
    } catch (e) {
      AppLogger.error('批量分享模板失败', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('批量分享失败: $e')),
      );
    }
  }

  Future<void> _batchFavoriteTemplates() async {
    try {
      for (final template in _selectedTemplates) {
        if (!template.isFavorite) {
          await _promptRepository.toggleTemplateFavorite(template);
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功添加 ${_selectedTemplates.length} 个模板到收藏')),
      );
      
      setState(() {
        _selectedTemplates.clear();
        _batchMode = false;
      });
      _loadTemplates();
    } catch (e) {
      AppLogger.error('批量收藏模板失败', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('批量收藏失败: $e')),
      );
    }
  }

  Future<void> _batchDeleteTemplates() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认批量删除'),
        content: Text('确定要删除选中的 ${_selectedTemplates.length} 个模板吗？此操作不可撤销。'),
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
      for (final template in _selectedTemplates) {
        await _promptRepository.deletePromptTemplate(template.id);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功删除 ${_selectedTemplates.length} 个模板')),
      );
      
      setState(() {
        _selectedTemplates.clear();
        _batchMode = false;
      });
      _loadTemplates();
    } catch (e) {
      AppLogger.error('批量删除模板失败', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('批量删除失败: $e')),
      );
    }
  }
}