import 'package:flutter/material.dart';
import 'dart:async';

import '../../models/prompt_models.dart';
import '../../services/api_service/repositories/impl/admin_repository_impl.dart';
import '../../utils/logger.dart';
import '../../services/api_service/repositories/impl/admin_repository_templates_extension.dart';
import '../../widgets/common/loading_indicator.dart';
import 'widgets/public_template_card.dart';
import 'widgets/add_official_template_dialog.dart';
import 'widgets/template_statistics_dialog.dart';
import 'widgets/template_details_dialog.dart'; // Added import for TemplateDetailsDialog
import 'widgets/edit_template_dialog.dart';

/// 公共模板管理页面
class PublicTemplatesManagementScreen extends StatefulWidget {
  const PublicTemplatesManagementScreen({Key? key}) : super(key: key);

  @override
  State<PublicTemplatesManagementScreen> createState() => _PublicTemplatesManagementScreenState();
}

class _PublicTemplatesManagementScreenState extends State<PublicTemplatesManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return const PublicTemplatesManagementBody();
  }
}

/// 公共模板管理页面主体
class PublicTemplatesManagementBody extends StatefulWidget {
  const PublicTemplatesManagementBody({Key? key}) : super(key: key);

  @override
  State<PublicTemplatesManagementBody> createState() => _PublicTemplatesManagementBodyState();
}

class _PublicTemplatesManagementBodyState extends State<PublicTemplatesManagementBody>
    with TickerProviderStateMixin {
  final AdminRepositoryImpl _adminRepository = AdminRepositoryImpl();
  late TabController _tabController;
  
  List<PromptTemplate> _templates = [];
  List<PromptTemplate> _selectedTemplates = [];
  bool _isLoading = true;
  bool _batchMode = false;
  String? _error;
  String _searchQuery = '';
  String _currentTab = 'ALL';
  AIFeatureType? _filterFeatureType;
  bool? _filterVerified;
  bool? _filterIsPublic;
  String _sortOption = 'LATEST';
  int _pageSize = 30;
  int _currentPage = 1;
  Timer? _searchDebounce;

  static const List<String> _tabs = ['ALL', 'OFFICIAL', 'USER_SUBMITTED', 'PENDING_REVIEW'];
  static const Map<String, String> _tabLabels = {
    'ALL': '全部模板',
    'OFFICIAL': '官方模板',
    'USER_SUBMITTED': '用户提交',
    'PENDING_REVIEW': '待审核',
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
    _searchDebounce?.cancel();
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
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
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
      child: Row(
        children: [
          // 搜索框
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 400), () {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 1;
                  });
                  _loadTemplates();
                });
              },
              decoration: InputDecoration(
                hintText: '搜索模板名称或描述...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(width: 16),

          // 功能类型筛选
          SizedBox(
            width: 280,
            child: DropdownButtonFormField<AIFeatureType?>(
              value: _filterFeatureType,
              decoration: InputDecoration(
                labelText: '功能类型',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<AIFeatureType?>(
                  value: null,
                  child: Text('全部类型'),
                ),
                ..._buildFeatureTypeOptions(),
              ],
              onChanged: (value) {
                setState(() {
                  _filterFeatureType = value;
                  _currentPage = 1;
                });
              },
            ),
          ),

          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<bool?>(
              value: _filterVerified,
              decoration: InputDecoration(
                labelText: '认证',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem<bool?>(value: null, child: Text('全部')),
                DropdownMenuItem<bool?>(value: true, child: Text('认证')),
                DropdownMenuItem<bool?>(value: false, child: Text('未认证')),
              ],
              onChanged: (v) {
                setState(() {
                  _filterVerified = v;
                  _currentPage = 1;
                });
              },
            ),
          ),

          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<bool?>(
              value: _filterIsPublic,
              decoration: InputDecoration(
                labelText: '可见性',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem<bool?>(value: null, child: Text('全部')),
                DropdownMenuItem<bool?>(value: true, child: Text('公开')),
                DropdownMenuItem<bool?>(value: false, child: Text('私有')),
              ],
              onChanged: (v) {
                setState(() {
                  _filterIsPublic = v;
                  _currentPage = 1;
                });
              },
            ),
          ),

          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              value: _sortOption,
              decoration: InputDecoration(
                labelText: '排序',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'LATEST', child: Text('最新')),
                DropdownMenuItem(value: 'MOST_USED', child: Text('使用最多')),
                DropdownMenuItem(value: 'RATING', child: Text('评分最高')),
              ],
              onChanged: (v) {
                setState(() {
                  _sortOption = v ?? 'LATEST';
                  _currentPage = 1;
                });
              },
            ),
          ),
          
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
            ElevatedButton.icon(
              onPressed: _batchPublish,
              icon: const Icon(Icons.publish),
              label: const Text('批量发布'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _batchSetVerified,
              icon: const Icon(Icons.verified),
              label: const Text('批量认证'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // 添加官方模板按钮
          ElevatedButton.icon(
            onPressed: _showAddOfficialTemplateDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加官方模板'),
          ),
          
          const SizedBox(width: 8),
          
          // 刷新按钮
          IconButton(
            onPressed: _loadTemplates,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
          
          // 统计按钮
          IconButton(
            onPressed: _showStatisticsDialog,
            icon: const Icon(Icons.analytics),
            tooltip: '查看统计',
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
              '当前筛选条件下没有找到模板',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddOfficialTemplateDialog,
              icon: const Icon(Icons.add),
              label: const Text('添加官方模板'),
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
    final visibleCount = (_currentPage * _pageSize).clamp(0, filteredTemplates.length);
    final items = filteredTemplates.take(visibleCount).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final template = items[index];
                return PublicTemplateCard(
                  template: template,
                  isSelected: _selectedTemplates.contains(template),
                  batchMode: _batchMode,
                  onTap: () => _onTemplateCardTap(template),
                  onEdit: () => _showEditTemplateDialog(template),
                  onDuplicate: () => _duplicatePublicTemplate(template),
                  onReview: () => _showTemplateReviewDialog(template),
                  onPublish: () => _publishTemplate(template),
                  onSetVerified: () => _setTemplateVerified(template),
                  onDelete: () => _deleteTemplate(template),
                  onSelectionChanged: (selected) => _onTemplateSelectionChanged(template, selected),
                );
              },
            ),
          ),
          if (visibleCount < filteredTemplates.length)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentPage += 1;
                  });
                },
                icon: const Icon(Icons.expand_more),
                label: Text('加载更多（${filteredTemplates.length - visibleCount}）'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _duplicatePublicTemplate(PromptTemplate template) async {
    final controller = TextEditingController(text: '${template.name} (复制)');
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('复制模板'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '新模板名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;

    try {
      final now = DateTime.now();
      // 使用增强模板模型创建，以便包含 userId 等关键字段
      final enhanced = _convertToEnhancedTemplate(template).copyWith(
        id: '',
        name: newName,
        createdAt: now,
        updatedAt: now,
        usageCount: 0,
        favoriteCount: 0,
        isFavorite: false,
        isDefault: false,
        shareCode: null,
        // 复制来源
        authorId: template.authorId ?? (template.isPublic ? 'system' : null),
      );

      await _adminRepository.createOfficialEnhancedTemplate(enhanced);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已复制为新模板: ${enhanced.name}')),
        );
        _loadTemplates();
      }
    } catch (e) {
      AppLogger.e('PublicTemplatesManagement', '复制模板失败', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('复制失败: $e')),
        );
      }
    }
  }

  List<PromptTemplate> _getFilteredTemplates() {
    List<PromptTemplate> filteredTemplates = List.from(_templates);
    
    // 注意：标签页筛选现在主要在API调用层面完成
    // OFFICIAL -> getVerifiedTemplates() 获取已验证模板
    // USER_SUBMITTED -> getPublicTemplates() 获取所有公共模板（用户提交的）
    // PENDING_REVIEW -> getPendingTemplates() 获取待审核模板
    // ALL -> getPublicTemplates() 获取所有公共模板
    
    // 根据搜索条件筛选
    if (_searchQuery.isNotEmpty) {
      filteredTemplates = filteredTemplates.where((template) {
        final query = _searchQuery.toLowerCase();
        return template.name.toLowerCase().contains(query) ||
               (template.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 功能类型筛选
    if (_filterFeatureType != null) {
      filteredTemplates = filteredTemplates
          .where((t) => t.featureType == _filterFeatureType)
          .toList();
    }

    // 认证筛选
    if (_filterVerified != null) {
      filteredTemplates = filteredTemplates.where((t) => t.isVerified == _filterVerified).toList();
    }

    // 可见性筛选
    if (_filterIsPublic != null) {
      filteredTemplates = filteredTemplates.where((t) => t.isPublic == _filterIsPublic).toList();
    }

    // 排序
    switch (_sortOption) {
      case 'MOST_USED':
        filteredTemplates.sort((a, b) => (b.useCount ?? 0).compareTo(a.useCount ?? 0));
        break;
      case 'RATING':
        filteredTemplates.sort((a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));
        break;
      case 'LATEST':
      default:
        filteredTemplates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }

    return filteredTemplates;
  }

  List<DropdownMenuItem<AIFeatureType>> _buildFeatureTypeOptions() {
    final Set<AIFeatureType> featureTypes =
        _templates.map((t) => t.featureType).toSet();
    final Map<AIFeatureType, String> labels = {
      AIFeatureType.textExpansion: '文本扩写',
      AIFeatureType.textRefactor: '文本润色',
      AIFeatureType.textSummary: '文本总结',
      AIFeatureType.sceneToSummary: '场景转摘要',
      AIFeatureType.summaryToScene: '摘要转场景',
      AIFeatureType.aiChat: 'AI对话',
      AIFeatureType.novelGeneration: '小说生成',
      AIFeatureType.professionalFictionContinuation: '专业续写',
      AIFeatureType.sceneBeatGeneration: '场景节拍生成',
    };

    final List<AIFeatureType> sorted = featureTypes.toList()
      ..sort((a, b) => (labels[a] ?? a.name).compareTo(labels[b] ?? b.name));

    return sorted
        .map((ft) => DropdownMenuItem<AIFeatureType>(
              value: ft,
              child: Text(labels[ft] ?? ft.name),
            ))
        .toList();
  }

  // 数据加载
  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<PromptTemplate> templates;

      switch (_currentTab) {
        case 'OFFICIAL':
          templates = await _adminRepository.getVerifiedTemplates();
          break;
        case 'PENDING_REVIEW':
          templates = await _adminRepository.getPendingTemplates();
          break;
        case 'USER_SUBMITTED':
          templates = await _adminRepository.getAllUserTemplates(
            page: 0,
            size: 100, // 暂时设置较大值，后续可以实现真正的分页
            search: _searchQuery.isEmpty ? null : _searchQuery,
          );
          break;
        case 'ALL':
        default:
          templates = await _adminRepository.getPublicTemplates(
            search: _searchQuery.isEmpty ? null : _searchQuery,
          );
          break;
      }

      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('PublicTemplatesManagement', '加载模板失败', e);
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
  void _showAddOfficialTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AddOfficialTemplateDialog(
        onSuccess: _loadTemplates,
      ),
    );
  }

  void _showEditTemplateDialog(PromptTemplate template) {
    showDialog(
      context: context,
      builder: (context) => EditTemplateDialog(
        template: template,
        onSuccess: _loadTemplates,
      ),
    );
  }

  /// 将PromptTemplate转换为EnhancedUserPromptTemplate
  EnhancedUserPromptTemplate _convertToEnhancedTemplate(PromptTemplate template) {
    return EnhancedUserPromptTemplate(
      id: template.id,
      userId: template.authorId ?? '',
      name: template.name,
      description: template.description,
      featureType: template.featureType,
      systemPrompt: '', // PromptTemplate没有单独的systemPrompt字段
      userPrompt: template.content,
      tags: template.templateTags ?? [],
      categories: [],
      isPublic: template.isPublic,
      shareCode: null,
      isFavorite: template.isFavorite,
      isDefault: template.isDefault,
      usageCount: template.useCount?.toInt() ?? 0,
      rating: template.averageRating ?? 0.0,
      ratingCount: template.ratingCount ?? 0,
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
      lastUsedAt: null,
      isVerified: template.isVerified,
      authorId: template.authorId,
      version: 1,
      language: 'zh',
      favoriteCount: 0,
      reviewedAt: null,
      reviewedBy: null,
      reviewComment: null,
    );
  }

  void _showTemplateReviewDialog(PromptTemplate template) {
    // TODO: 实现PromptTemplate的审核对话框
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('模板审核功能开发中: ${template.name}')),
    );
  }

  void _showTemplateDetails(PromptTemplate template) {
    // 将PromptTemplate转换为EnhancedUserPromptTemplate以兼容现有对话框
    final enhancedTemplate = _convertToEnhancedTemplate(template);
    
    showDialog(
      context: context,
      builder: (context) => TemplateDetailsDialog(
        template: enhancedTemplate,
      ),
    );
  }

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => TemplateStatisticsDialog(),
    );
  }

  // 操作方法
  Future<void> _publishTemplate(PromptTemplate template) async {
    try {
      await _adminRepository.publishTemplate(template.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('模板 "${template.name}" 发布成功')),
      );
      _loadTemplates();
    } catch (e) {
      AppLogger.e('PublicTemplatesManagement', '发布模板失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发布失败: $e')),
      );
    }
  }

  Future<void> _setTemplateVerified(PromptTemplate template) async {
    try {
      await _adminRepository.setTemplateVerified(template.id, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('模板 "${template.name}" 已设为认证')),
      );
      _loadTemplates();
    } catch (e) {
      AppLogger.e('PublicTemplatesManagement', '设置模板认证失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('设置认证失败: $e')),
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
      await _adminRepository.deleteTemplate(template.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('模板 "${template.name}" 删除成功')),
      );
      _loadTemplates();
    } catch (e) {
      AppLogger.e('PublicTemplatesManagement', '删除模板失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  // 批量操作
  Future<void> _batchPublish() async {
    if (_selectedTemplates.isEmpty) return;

    try {
      for (final template in _selectedTemplates) {
        await _adminRepository.publishTemplate(template.id);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功发布 ${_selectedTemplates.length} 个模板')),
      );
      
      setState(() {
        _selectedTemplates.clear();
        _batchMode = false;
      });
      _loadTemplates();
    } catch (e) {
      AppLogger.e('PublicTemplatesManagement', '批量发布模板失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('批量发布失败: $e')),
      );
    }
  }

  Future<void> _batchSetVerified() async {
    if (_selectedTemplates.isEmpty) return;

    try {
      for (final template in _selectedTemplates) {
        await _adminRepository.setTemplateVerified(template.id, true);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功设置 ${_selectedTemplates.length} 个模板为认证')),
      );
      
      setState(() {
        _selectedTemplates.clear();
        _batchMode = false;
      });
      _loadTemplates();
    } catch (e) {
      AppLogger.e('PublicTemplatesManagement', '批量设置模板认证失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('批量设置认证失败: $e')),
      );
    }
  }
}