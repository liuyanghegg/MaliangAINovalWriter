import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/models/preset_models.dart';
import 'package:ainoval/services/ai_preset_service.dart';
import 'package:ainoval/widgets/common/preset_item_with_tags.dart';
import 'package:ainoval/utils/logger.dart';

/// 预设列表示例页面
/// 展示如何使用新的统一预设接口和显示标签
class PresetListExampleScreen extends StatefulWidget {
  final String featureType;
  final String? novelId;

  const PresetListExampleScreen({
    Key? key,
    required this.featureType,
    this.novelId,
  }) : super(key: key);

  @override
  State<PresetListExampleScreen> createState() => _PresetListExampleScreenState();
}

class _PresetListExampleScreenState extends State<PresetListExampleScreen> {
  static const String _tag = 'PresetListExampleScreen';
  
  final _presetService = AIPresetService();
  PresetListResponse? _presetListResponse;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  /// 加载预设数据
  Future<void> _loadPresets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      AppLogger.i(_tag, '开始加载功能预设列表: ${widget.featureType}');
      
      final response = await _presetService.getFeaturePresetList(
        widget.featureType,
        novelId: widget.novelId,
      );

      setState(() {
        _presetListResponse = response;
        _isLoading = false;
      });

      AppLogger.i(_tag, '预设列表加载成功: 总共${response.totalCount}个预设');
    } catch (e) {
      AppLogger.e(_tag, '加载预设列表失败', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('预设列表 - ${widget.featureType}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPresets,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.5),
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
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPresets,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_presetListResponse == null || _presetListResponse!.totalCount == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无预设',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPresets,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 收藏预设
          if (_presetListResponse!.favorites.isNotEmpty) ...[
            _buildSectionHeader('收藏预设', _presetListResponse!.favorites.length),
            const SizedBox(height: 8),
            ..._presetListResponse!.favorites.map(_buildPresetItem),
            const SizedBox(height: 24),
          ],

          // 最近使用预设
          if (_presetListResponse!.recentUsed.isNotEmpty) ...[
            _buildSectionHeader('最近使用', _presetListResponse!.recentUsed.length),
            const SizedBox(height: 8),
            ..._presetListResponse!.recentUsed.map(_buildPresetItem),
            const SizedBox(height: 24),
          ],

          // 推荐预设
          if (_presetListResponse!.recommended.isNotEmpty) ...[
            _buildSectionHeader('推荐预设', _presetListResponse!.recommended.length),
            const SizedBox(height: 8),
            ..._presetListResponse!.recommended.map(_buildPresetItem),
          ],
        ],
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: WebTheme.getPrimaryColor(context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              color: WebTheme.getPrimaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建预设项
  Widget _buildPresetItem(PresetItemWithTag presetItem) {
    return PresetItemWithTags(
      presetItem: presetItem,
      onTap: () => _onPresetTapped(presetItem),
      onFavoriteToggle: () => _onFavoriteToggle(presetItem),
    );
  }

  /// 预设被点击
  void _onPresetTapped(PresetItemWithTag presetItem) {
    AppLogger.i(_tag, '预设被选择: ${presetItem.preset.presetName}');
    
    // 显示预设详情或应用预设
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(presetItem.preset.presetName ?? '预设详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${presetItem.preset.presetId}'),
            const SizedBox(height: 8),
            Text('标签: ${presetItem.getTags().join(', ')}'),
            const SizedBox(height: 8),
            if (presetItem.preset.presetDescription?.isNotEmpty == true)
              Text('描述: ${presetItem.preset.presetDescription}'),
            const SizedBox(height: 8),
            Text('使用次数: ${presetItem.preset.useCount}'),
            const SizedBox(height: 8),
            Text('最后使用: ${presetItem.preset.lastUsedAt?.toString() ?? '未使用'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyPreset(presetItem);
            },
            child: const Text('应用预设'),
          ),
        ],
      ),
    );
  }

  /// 切换收藏状态
  Future<void> _onFavoriteToggle(PresetItemWithTag presetItem) async {
    try {
      AppLogger.i(_tag, '切换收藏状态: ${presetItem.preset.presetId}');
      
      // 调用收藏切换API
      await _presetService.toggleFavorite(presetItem.preset.presetId);
      
      // 重新加载数据
      await _loadPresets();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(presetItem.preset.isFavorite ? '已取消收藏' : '已添加收藏'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      AppLogger.e(_tag, '切换收藏状态失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 应用预设
  Future<void> _applyPreset(PresetItemWithTag presetItem) async {
    try {
      AppLogger.i(_tag, '应用预设: ${presetItem.preset.presetId}');
      
      // 调用应用预设API（会自动记录使用）
      await _presetService.applyPreset(presetItem.preset.presetId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('预设应用成功'),
          backgroundColor: Colors.green,
        ),
      );
      
      // 重新加载数据以更新最近使用状态
      await _loadPresets();
    } catch (e) {
      AppLogger.e(_tag, '应用预设失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('应用失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}