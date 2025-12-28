import 'package:flutter/material.dart';
import 'package:ainoval/models/preset_models.dart';
import 'package:ainoval/services/ai_preset_service.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/utils/logger.dart';

/// 预设下拉框按钮组件
/// 替换原有的预设按钮，提供下拉框选择预设的功能
class PresetDropdownButton extends StatefulWidget {
  /// 构造函数
  const PresetDropdownButton({
    super.key,
    required this.featureType,
    this.currentPreset,
    this.onPresetSelected,
    this.onCreatePreset,
    this.onManagePresets,
    this.novelId,
    this.label = '预设',
  });

  /// AI功能类型（用于过滤预设）
  final String featureType;

  /// 当前选中的预设
  final AIPromptPreset? currentPreset;

  /// 预设选择回调
  final ValueChanged<AIPromptPreset>? onPresetSelected;

  /// 创建预设回调
  final VoidCallback? onCreatePreset;

  /// 管理预设回调
  final VoidCallback? onManagePresets;

  /// 小说ID（用于过滤预设）
  final String? novelId;

  /// 按钮标签
  final String label;

  @override
  State<PresetDropdownButton> createState() => _PresetDropdownButtonState();
}

class _PresetDropdownButtonState extends State<PresetDropdownButton> {
  final String _tag = 'PresetDropdownButton';
  
  List<AIPromptPreset> _recentPresets = [];
  List<AIPromptPreset> _favoritePresets = [];
  List<AIPromptPreset> _recommendedPresets = [];
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _buttonKey = GlobalKey();

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
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final presetService = AIPresetService();
      
      // 使用新的统一接口获取功能预设列表
      final presetListResponse = await presetService.getFeaturePresetList(
        widget.featureType,
        novelId: widget.novelId,
      );

      setState(() {
        _recentPresets = presetListResponse.recentUsed.map((item) => item.preset).toList();
        _favoritePresets = presetListResponse.favorites.map((item) => item.preset).toList();
        _recommendedPresets = presetListResponse.recommended.map((item) => item.preset).toList();
        _isLoading = false;
      });

      AppLogger.d(_tag, '预设数据加载完成: 最近${_recentPresets.length}个, 收藏${_favoritePresets.length}个, 推荐${_recommendedPresets.length}个');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppLogger.e(_tag, '加载预设数据失败', e);
    }
  }

  /// 显示下拉菜单
  void _showDropdown() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 移除下拉菜单
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 创建下拉菜单覆盖层
  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // 透明背景，点击关闭
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
            // 下拉菜单
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 2),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(6),
                color: Colors.transparent,
                child: Container(
                  width: 240, // 减小宽度使其更紧凑
                  constraints: const BoxConstraints(maxHeight: 320), // 减小最大高度
                  decoration: BoxDecoration(
                    color: WebTheme.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: WebTheme.isDarkMode(context) 
                          ? WebTheme.darkGrey300 
                          : WebTheme.grey300,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildDropdownContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建下拉菜单内容
  Widget _buildDropdownContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 当前预设（如果有）
          if (widget.currentPreset != null) ...[
            _buildSectionHeader('当前预设'),
            _buildPresetItem(
              widget.currentPreset!,
              isSelected: true,
              showCheckmark: true,
            ),
            _buildDivider(),
          ],

          // 最近使用预设
          if (_recentPresets.isNotEmpty) ...[
            _buildSectionHeader('最近使用'),
            ..._recentPresets.take(3).map((preset) => _buildPresetItem(preset)), // 减少显示数量
            if (_favoritePresets.isNotEmpty || _recommendedPresets.isNotEmpty) _buildDivider(),
          ],

          // 收藏预设
          if (_favoritePresets.isNotEmpty) ...[
            _buildSectionHeader('收藏预设'),
            ..._favoritePresets.take(3).map((preset) => _buildPresetItem(preset)), // 减少显示数量
            if (_recommendedPresets.isNotEmpty) _buildDivider(),
          ],

          // 推荐预设
          if (_recommendedPresets.isNotEmpty) ...[
            _buildSectionHeader('推荐预设'),
            ..._recommendedPresets.take(3).map((preset) => _buildPresetItem(preset)), // 减少显示数量
            _buildDivider(),
          ],

          // 空状态
          if (_recentPresets.isEmpty && _favoritePresets.isEmpty && _recommendedPresets.isEmpty && widget.currentPreset == null) ...[
            _buildEmptyState(),
            _buildDivider(),
          ],

          // 操作按钮
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4), // 减少内边距
      child: Text(
        title,
        style: WebTheme.labelSmall.copyWith(
          color: WebTheme.getSecondaryTextColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 构建预设项
  Widget _buildPresetItem(
    AIPromptPreset preset, {
    bool isSelected = false,
    bool showCheckmark = false,
  }) {
    return WebTheme.getMaterialWrapper(
      child: InkWell(
        onTap: () {
          _removeOverlay();
          widget.onPresetSelected?.call(preset);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 减少内边距
          child: Row(
            children: [
              // 预设信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible( // 使用 Flexible 而不是 Expanded 避免溢出
                          child: Text(
                            preset.displayName,
                            style: WebTheme.bodySmall.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? WebTheme.getTextColor(context, isPrimary: true)
                                  : WebTheme.getTextColor(context, isPrimary: false),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (preset.isFavorite) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.star,
                            size: 10,
                            color: Colors.amber.shade600,
                          ),
                        ],
                      ],
                    ),
                    if (preset.presetDescription != null && preset.presetDescription!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        preset.presetDescription!,
                        style: WebTheme.labelSmall.copyWith(
                          color: WebTheme.getSecondaryTextColor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // 选中标记
              if (showCheckmark) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check,
                  size: 14,
                  color: WebTheme.getTextColor(context, isPrimary: false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建分割线
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: WebTheme.isDarkMode(context) 
          ? WebTheme.darkGrey200 
          : WebTheme.grey200,
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16), // 减少内边距
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 24, // 减小图标尺寸
            color: WebTheme.getSecondaryTextColor(context),
          ),
          const SizedBox(height: 6),
          Text(
            '暂无预设',
            style: WebTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: WebTheme.getTextColor(context, isPrimary: false),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '创建第一个预设来快速重用配置',
            style: WebTheme.labelSmall.copyWith(
              color: WebTheme.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(8), // 减少内边距
      child: Row(
        children: [
          // 创建预设按钮
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                _removeOverlay();
                widget.onCreatePreset?.call();
              },
              icon: Icon(
                Icons.add,
                size: 14,
                color: WebTheme.getSecondaryTextColor(context),
              ),
              label: Text(
                '创建',
                style: WebTheme.labelSmall.copyWith(
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // 减少内边距
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // 管理预设按钮
          Expanded(
            child: TextButton.icon(
              onPressed: () {
                _removeOverlay();
                widget.onManagePresets?.call();
              },
              icon: Icon(
                Icons.settings,
                size: 14,
                color: WebTheme.getSecondaryTextColor(context),
              ),
              label: Text(
                '管理',
                style: WebTheme.labelSmall.copyWith(
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // 减少内边距
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前预设的显示名称，如果太长则截断
    String displayText = widget.currentPreset?.presetName ?? widget.label;
    if (displayText.length > 8) { // 限制显示长度避免溢出
      displayText = '${displayText.substring(0, 6)}...';
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: WebTheme.getMaterialWrapper(
        child: InkWell(
          key: _buttonKey,
          onTap: _showDropdown,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // 大幅减少内边距
            constraints: const BoxConstraints(
              minWidth: 60,
              maxWidth: 120, // 限制最大宽度避免溢出
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune,
                  size: 14, // 减小图标尺寸
                  color: WebTheme.getSecondaryTextColor(context),
                ),
                const SizedBox(width: 4),
                Flexible( // 使用 Flexible 而不是固定宽度
                  child: Text(
                    displayText,
                    style: WebTheme.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 12, // 减小图标尺寸
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 