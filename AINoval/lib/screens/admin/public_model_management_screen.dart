import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../../config/provider_icons.dart';
import '../../models/public_model_config.dart';
import '../../services/api_service/repositories/impl/admin_repository_impl.dart';
import '../../utils/logger.dart';
import '../../utils/web_theme.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_indicator.dart';
import 'widgets/add_public_model_dialog.dart';
import 'widgets/edit_public_model_dialog.dart';
import 'widgets/public_model_provider_group_card.dart';
import 'widgets/validation_results_dialog.dart';
import '../../widgets/common/top_toast.dart';

/// 公共模型管理页面
/// 提供完整的公共AI模型配置管理功能，包括：
/// - 按供应商分组显示所有可用提供商
/// - 在每个提供商分组下显示已配置的公共模型
/// - 添加/编辑/删除模型配置
/// - API Key池管理
/// - 模型验证和状态管理
class PublicModelManagementScreen extends StatefulWidget {
  const PublicModelManagementScreen({Key? key}) : super(key: key);

  @override
  State<PublicModelManagementScreen> createState() => _PublicModelManagementScreenState();
}

/// 公共模型管理内容主体，可以在不同布局中复用
class PublicModelManagementBody extends StatefulWidget {
  const PublicModelManagementBody({Key? key}) : super(key: key);

  @override
  State<PublicModelManagementBody> createState() => _PublicModelManagementBodyState();
}

class _PublicModelManagementScreenState extends State<PublicModelManagementScreen> {
  final GlobalKey<_PublicModelManagementBodyState> _bodyKey = GlobalKey<_PublicModelManagementBodyState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: WebTheme.getBackgroundColor(context),
        foregroundColor: WebTheme.getTextColor(context),
        title: Text(
          '公共模型管理',
          style: TextStyle(color: WebTheme.getTextColor(context)),
        ),
        actions: [
          IconButton(
            onPressed: () => _bodyKey.currentState?._refreshData(),
            icon: Icon(Icons.refresh, color: WebTheme.getTextColor(context)),
            tooltip: '刷新',
          ),
          IconButton(
            onPressed: () => _showAddModelDialog(context),
            icon: Icon(Icons.add, color: WebTheme.getTextColor(context)),
            tooltip: '添加模型',
          ),
        ],
      ),
      backgroundColor: WebTheme.getBackgroundColor(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: PublicModelManagementBody(key: _bodyKey),
        ),
      ),
    );
  }

  void _showAddModelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddPublicModelDialog(
        onSuccess: () => _bodyKey.currentState?._refreshData(),
      ),
    );
  }
}

class _PublicModelManagementBodyState extends State<PublicModelManagementBody> {
  List<PublicModelConfigDetails> _modelConfigs = [];
  List<String> _availableProviders = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filterValue = 'all';
  Map<String, bool> _expandedProviders = {};
  
  late final AdminRepositoryImpl _adminRepository;
  final String _tag = 'PublicModelManagementScreen';

  // 缓存机制
  DateTime? _lastLoadTime;
  static const Duration _cacheValidDuration = Duration(minutes: 3);
  bool _isInitialLoad = true;

  bool get _shouldRefreshConfigs {
    if (_lastLoadTime == null || _isInitialLoad) return true;
    return DateTime.now().difference(_lastLoadTime!) > _cacheValidDuration;
  }

  @override
  void initState() {
    super.initState();
    _adminRepository = AdminRepositoryImpl();
    _loadData();
  }

  Future<void> _loadData() async {
    // 先加载可用供应商，然后加载模型配置
    await _loadAvailableProviders();
    await _loadModelConfigs();
  }

  Future<void> _loadAvailableProviders() async {
    if (!mounted) return;
    
    // 开始加载可用供应商

    try {
      AppLogger.d(_tag, '开始加载可用供应商列表');
      final providers = await _adminRepository.getAvailableProviders();
      
      if (mounted) {
        setState(() {
          _availableProviders = providers;
          // 默认展开所有供应商
          for (final provider in providers) {
            _expandedProviders[provider] ??= true;
          }
        });
        
        AppLogger.d(_tag, '成功加载 ${providers.length} 个供应商');
      }
    } catch (e) {
      AppLogger.e(_tag, '加载供应商列表失败', e);
      // 忽略加载状态更新，无需标记供应商加载中
    }
  }

  Future<void> _loadModelConfigs() async {
    if (!_shouldRefreshConfigs) {
      AppLogger.d(_tag, '使用缓存数据，跳过重新加载');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      AppLogger.d(_tag, '开始加载公共模型配置列表');
      _lastLoadTime = DateTime.now();
      _isInitialLoad = false;
      
      final configs = await _adminRepository.getPublicModelConfigDetails();
      
      AppLogger.d(_tag, '📊 原始配置数据: ${configs.length} 个');
      for (int i = 0; i < configs.length && i < 3; i++) {
        final config = configs[i];
        AppLogger.d(_tag, '📊 配置 $i: provider=${config.provider}, modelId=${config.modelId}, enabled=${config.enabled}, id=${config.id}');
      }
      
      if (mounted) {
        setState(() {
          _modelConfigs = configs;
          _isLoading = false;
        });

        // 提示：可为公共模型打标签以用于后端选择策略（示例："jsonify"/"cheap"/"fast"）
        // - jsonify：适配“文本→JSON结构化工具”阶段优先选择
        // - cheap：成本优先
        // - fast：时延优先
        // 管理员可在“编辑模型”中为配置添加上述 tags，后端会在第二阶段依据标签和 priority 挑选。
        
        AppLogger.d(_tag, '✅ 成功加载 ${configs.length} 个公共模型配置，界面状态已更新');
        
        // 检查分组结果
        final grouped = _groupConfigsByProvider();
        AppLogger.d(_tag, '📊 分组结果: ${grouped.length} 个供应商，${grouped.values.expand((list) => list).length} 个配置');
        grouped.forEach((provider, configList) {
          AppLogger.d(_tag, '📊 供应商 $provider: ${configList.length} 个配置');
        });
      }
    } catch (e, stackTrace) {
      AppLogger.e(_tag, '加载公共模型配置失败', e);
      AppLogger.e(_tag, '错误堆栈', stackTrace);
      if (mounted) {
        setState(() {
          _error = '加载公共模型配置失败: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _handleFilterChange(String value) {
    setState(() {
      _filterValue = value;
    });
  }

  void _handleToggleProvider(String provider) {
    setState(() {
      _expandedProviders[provider] = !(_expandedProviders[provider] ?? true);
    });
  }

  Future<void> _handleValidate(String configId) async {
    try {
      AppLogger.d(_tag, '开始验证模型配置: $configId');
      
      TopToast.info(context, '正在验证模型配置...');
      
      final withKeys = await _adminRepository.validatePublicModelConfigAndFetchWithKeys(configId);
      
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ValidationResultsDialog(config: withKeys),
      );
      
      AppLogger.d(_tag, '模型配置验证成功: $configId');
      _refreshData();
    } catch (e) {
      AppLogger.e(_tag, '模型配置验证失败', e);
      TopToast.error(context, '验证失败: ${e.toString()}');
    }
  }

  Future<void> _handleToggleStatus(String configId, bool enabled) async {
    try {
      AppLogger.d(_tag, '切换模型配置状态: $configId -> $enabled');
      
      await _adminRepository.togglePublicModelConfigStatus(configId, enabled);
      
      TopToast.success(context, enabled ? '模型已启用' : '模型已禁用');
      
      AppLogger.d(_tag, '模型配置状态切换成功: $configId');
      _refreshData();
    } catch (e) {
      AppLogger.e(_tag, '切换模型配置状态失败', e);
      TopToast.error(context, '操作失败: ${e.toString()}');
    }
  }

  void _handleEdit(String configId) {
    final config = _modelConfigs.firstWhereOrNull((c) => c.id == configId);
    if (config == null) return;

    showDialog(
      context: context,
      builder: (context) => EditPublicModelDialog(
        config: config,
        onSuccess: _refreshData,
      ),
    );
  }

  void _handleCopy(String configId) {
    final config = _modelConfigs.firstWhereOrNull((c) => c.id == configId);
    if (config == null) return;

    showDialog(
      context: context,
      builder: (context) => AddPublicModelDialog(
        onSuccess: _refreshData,
        selectedProvider: config.provider,
        sourceConfig: config, // 传递源配置用于复制
      ),
    );
  }

  void _handleDelete(String configId) {
    final config = _modelConfigs.firstWhereOrNull((c) => c.id == configId);
    if (config == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WebTheme.getCardColor(context),
        title: Text(
          '确认删除',
          style: TextStyle(color: WebTheme.getTextColor(context)),
        ),
        content: Text(
          '确定要删除模型配置 "${config.displayName ?? config.modelId}" 吗？此操作不可恢复。',
          style: TextStyle(color: WebTheme.getTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: WebTheme.getTextColor(context))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteModelConfig(configId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteModelConfig(String configId) async {
    try {
      AppLogger.d(_tag, '开始删除模型配置: $configId');
      
      TopToast.info(context, '正在删除模型配置...');
      
      await _adminRepository.deletePublicModelConfig(configId);
      
      TopToast.success(context, '模型配置删除成功');
      
      AppLogger.d(_tag, '模型配置删除成功: $configId');
      _refreshData();
    } catch (e) {
      AppLogger.e(_tag, '删除模型配置失败', e);
      TopToast.error(context, '删除失败: ${e.toString()}');
    }
  }

  void _handleAddModel(String provider) {
    showDialog(
      context: context,
      builder: (context) => AddPublicModelDialog(
        onSuccess: _refreshData,
        selectedProvider: provider,
      ),
    );
  }

  void _refreshData() {
    _lastLoadTime = null; // 使缓存失效
    _loadData();
  }

  // 按提供商分组配置 - 显示所有可用提供商
  Map<String, List<PublicModelConfigDetails>> _groupConfigsByProvider() {
    final Map<String, List<PublicModelConfigDetails>> grouped = {};
    
    // 首先为所有可用提供商创建空列表
    for (final provider in _availableProviders) {
      grouped[provider] = [];
    }
    
    // 然后将配置分组到对应的提供商
    for (final config in _modelConfigs) {
      final provider = config.provider;
      if (grouped.containsKey(provider)) {
        grouped[provider]!.add(config);
      } else {
        // 如果配置的提供商不在可用列表中，也要显示
        grouped[provider] = [config];
      }
    }
    
    // 应用搜索和过滤
    if (_searchQuery.isNotEmpty || _filterValue != 'all') {
      final filteredGrouped = <String, List<PublicModelConfigDetails>>{};
      
      for (final entry in grouped.entries) {
        final provider = entry.key;
        final configs = entry.value;
        
        // 检查提供商名称是否匹配搜索
        final providerMatches = _searchQuery.isEmpty ||
            provider.toLowerCase().contains(_searchQuery) ||
            ProviderIcons.getProviderDisplayName(provider).toLowerCase().contains(_searchQuery);
        
        // 过滤配置
        final filteredConfigs = configs.where((config) {
          final matchesSearch = _searchQuery.isEmpty ||
              (config.displayName?.toLowerCase().contains(_searchQuery) ?? false) ||
              config.modelId.toLowerCase().contains(_searchQuery);

          bool matchesFilter = true;
          if (_filterValue == 'enabled') {
            matchesFilter = config.enabled == true;
          } else if (_filterValue == 'disabled') {
            matchesFilter = config.enabled != true;
          } else if (_filterValue == 'validated') {
            matchesFilter = config.isValidated == true;
          } else if (_filterValue == 'unvalidated') {
            matchesFilter = config.isValidated != true;
          }

          return matchesSearch && matchesFilter;
        }).toList();
        
        // 如果提供商匹配搜索或者有匹配的配置，则显示该提供商
        if (providerMatches || filteredConfigs.isNotEmpty) {
          filteredGrouped[provider] = filteredConfigs;
        }
      }
      
      return filteredGrouped;
    }
    
    return grouped;
  }

  // 获取提供商信息
  Map<String, dynamic> _getProviderInfo(String provider) {
    return {
      'name': ProviderIcons.getProviderDisplayName(provider),
      'description': _getProviderDescription(provider),
      'color': ProviderIcons.getProviderColor(provider),
    };
  }

  // 获取提供商描述
  String _getProviderDescription(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return 'Advanced language models for various applications';
      case 'anthropic':
        return 'Constitutional AI models focused on safety';
      case 'google':
      case 'gemini':
        return 'Gemini models and PaLM-based systems';
      case 'openrouter':
        return 'Unified API for multiple AI models';
      case 'ollama':
        return 'Local AI models runner';
      case 'microsoft':
      case 'azure':
        return 'Microsoft Azure OpenAI Service';
      case 'meta':
      case 'llama':
        return 'Large Language Model Meta AI';
      case 'deepseek':
        return 'DeepSeek AI language models';
      case 'zhipu':
      case 'glm':
        return 'GLM and ChatGLM models';
      case 'qwen':
      case 'tongyi':
        return 'Alibaba Tongyi Qianwen models';
      case 'doubao':
      case 'bytedance':
        return 'ByteDance Doubao AI models';
      case 'mistral':
        return 'Mistral AI language models';
      case 'perplexity':
        return 'Perplexity AI search and reasoning';
      case 'huggingface':
      case 'hf':
        return 'Hugging Face model hub and inference';
      case 'stability':
        return 'Stability AI generative models';
      case 'xai':
      case 'grok':
        return 'xAI Grok conversational AI';
      case 'siliconcloud':
      case 'siliconflow':
        return 'SiliconCloud AI model services';
      default:
        return 'AI model provider';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索和过滤头部
        _buildHeader(),

        // 内容区域
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
        color: WebTheme.getCardColor(context),
        border: Border(
          bottom: BorderSide(
            color: WebTheme.getBorderColor(context),
          ),
        ),
      ),
      child: Column(
        children: [
          // 搜索框
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: _handleSearch,
                  style: TextStyle(color: WebTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: '搜索模型或提供商...',
                    hintStyle: TextStyle(color: WebTheme.getSecondaryTextColor(context)),
                    prefixIcon: Icon(Icons.search, color: WebTheme.getSecondaryTextColor(context)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: WebTheme.getBorderColor(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: WebTheme.getTextColor(context)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // 过滤下拉框
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: WebTheme.getBorderColor(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _filterValue,
                  onChanged: (value) => _handleFilterChange(value!),
                  dropdownColor: WebTheme.getCardColor(context),
                  style: TextStyle(color: WebTheme.getTextColor(context)),
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('全部')),
                    DropdownMenuItem(value: 'enabled', child: Text('已启用')),
                    DropdownMenuItem(value: 'disabled', child: Text('已禁用')),
                    DropdownMenuItem(value: 'validated', child: Text('已验证')),
                    DropdownMenuItem(value: 'unvalidated', child: Text('未验证')),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 刷新按钮
              IconButton(
                onPressed: _refreshData,
                icon: Icon(Icons.refresh, color: WebTheme.getTextColor(context)),
                tooltip: '刷新',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 统计信息
          Row(
            children: [
              _buildStatChip(
                '总配置: ${_modelConfigs.length}',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '供应商: ${_availableProviders.length}',
                Colors.green,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '已启用: ${_modelConfigs.where((c) => c.enabled == true).length}',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildContent() {
    AppLogger.d(_tag, '🎨 构建内容: isLoading=$_isLoading, modelConfigs.length=${_modelConfigs.length}, availableProviders.length=${_availableProviders.length}, error=$_error');
    
    if (_isLoading && _modelConfigs.isEmpty) {
      AppLogger.d(_tag, '🎨 显示加载指示器');
      return const Center(child: LoadingIndicator());
    }

    if (_error != null && _modelConfigs.isEmpty && _availableProviders.isEmpty) {
      AppLogger.d(_tag, '🎨 显示错误视图: $_error');
      return ErrorView(
        error: _error!,
        onRetry: _refreshData,
      );
    }

    final groupedConfigs = _groupConfigsByProvider();
    AppLogger.d(_tag, '🎨 分组配置: ${groupedConfigs.length} 个供应商');

    if (groupedConfigs.isEmpty) {
      AppLogger.d(_tag, '🎨 显示空状态 (搜索: $_searchQuery, 过滤: $_filterValue)');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterValue != 'all'
                  ? '没有找到匹配的供应商或模型配置'
                  : '暂无可用的AI供应商',
              style: TextStyle(
                fontSize: 16,
                color: WebTheme.getSecondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            // 添加调试信息
            if (_modelConfigs.isNotEmpty || _availableProviders.isNotEmpty)
              Column(
                children: [
                  Text(
                    '调试信息: 模型配置=${_modelConfigs.length}, 供应商=${_availableProviders.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  Text(
                    '搜索="$_searchQuery", 过滤="$_filterValue"',
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (_searchQuery.isEmpty && _filterValue == 'all')
              ElevatedButton.icon(
                onPressed: () => _handleAddModel(''),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加公共模型'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WebTheme.getTextColor(context),
                  foregroundColor: WebTheme.getBackgroundColor(context),
                ),
              ),
          ],
        ),
      );
    }

    AppLogger.d(_tag, '🎨 显示供应商列表: ${groupedConfigs.length} 个');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedConfigs.length,
      itemBuilder: (context, index) {
        final provider = groupedConfigs.keys.elementAt(index);
        final configs = groupedConfigs[provider]!;
        final providerInfo = _getProviderInfo(provider);
        final isExpanded = _expandedProviders[provider] ?? true;

        AppLogger.d(_tag, '🎨 构建供应商卡片 $index: $provider (${configs.length} 个配置)');

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PublicModelProviderGroupCard(
            provider: provider,
            providerName: providerInfo['name'],
            description: providerInfo['description'],
            configs: configs,
            isExpanded: isExpanded,
            onToggleExpanded: () => _handleToggleProvider(provider),
            onAddModel: () => _handleAddModel(provider),
            onValidate: _handleValidate,
            onEdit: _handleEdit,
            onDelete: _handleDelete,
            onToggleStatus: _handleToggleStatus,
            onCopy: _handleCopy,
          ),
        );
      },
    );
  }
}