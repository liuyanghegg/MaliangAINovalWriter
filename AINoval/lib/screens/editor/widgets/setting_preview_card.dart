import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/models/novel_setting_item.dart';
import 'package:ainoval/models/setting_type.dart';
import 'package:ainoval/models/setting_group.dart';
import 'package:ainoval/blocs/setting/setting_bloc.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:ainoval/screens/editor/widgets/novel_setting_detail.dart';

/// 设定信息预览卡片组件
/// 显示设定的基本信息（分类、名称、设定组、图片、描述）
class SettingPreviewCard extends StatefulWidget {
  final String settingId;
  final String novelId;
  final Offset position;
  final VoidCallback? onClose;

  const SettingPreviewCard({
    Key? key,
    required this.settingId,
    required this.novelId,
    required this.position,
    this.onClose,
  }) : super(key: key);

  @override
  State<SettingPreviewCard> createState() => _SettingPreviewCardState();
}

class _SettingPreviewCardState extends State<SettingPreviewCard> with TickerProviderStateMixin {
  static const String _tag = 'SettingPreviewCard';
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  NovelSettingItem? _settingItem;
  SettingGroup? _settingGroup;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _loadSettingData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 加载设定数据
  void _loadSettingData() {
    try {
      final settingBloc = context.read<SettingBloc>();
      final state = settingBloc.state;
      
      // 查找设定条目
      _settingItem = state.items.firstWhere(
        (item) => item.id == widget.settingId,
        orElse: () => NovelSettingItem(name: ''),
      );
      
      if (_settingItem != null) {
        // 查找设定组
        _settingGroup = state.groups.firstWhere(
          (group) => group.itemIds?.any((item) => item == widget.settingId) == true,
          orElse: () => SettingGroup(name: ''),
        );
      }
      
      setState(() {
        _isLoading = false;
      });
      
      AppLogger.d(_tag, '设定数据加载完成: ${_settingItem?.name ?? "未找到"}');
      
    } catch (e) {
      AppLogger.e(_tag, '加载设定数据失败', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 获取设定类型图标
  IconData _getTypeIcon() {
    if (_settingItem?.type == null) return Icons.article;
    
    final settingType = SettingType.fromValue(_settingItem!.type!);
    switch (settingType) {
      case SettingType.character:
        return Icons.person;
      case SettingType.location:
        return Icons.place;
      case SettingType.item:
        return Icons.inventory_2;
      case SettingType.lore:
        return Icons.public;
      case SettingType.event:
        return Icons.event;
      case SettingType.concept:
        return Icons.auto_awesome;
      case SettingType.faction:
        return Icons.groups;
      case SettingType.creature:
        return Icons.pets;
      case SettingType.magicSystem:
        return Icons.auto_fix_high;
      case SettingType.technology:
        return Icons.science;
      case SettingType.culture:
        return Icons.emoji_people;
      case SettingType.history:
        return Icons.history;
      case SettingType.organization:
        return Icons.apartment;
      case SettingType.worldview:
        return Icons.public;
      case SettingType.pleasurePoint:
        return Icons.whatshot;
      case SettingType.anticipationHook:
        return Icons.bolt;
      case SettingType.theme:
        return Icons.category;
      case SettingType.tone:
        return Icons.tonality;
      case SettingType.style:
        return Icons.brush;
      case SettingType.trope:
        return Icons.theater_comedy;
      case SettingType.plotDevice:
        return Icons.schema;
      case SettingType.powerSystem:
        return Icons.flash_on;
      case SettingType.timeline:
        return Icons.timeline;
      case SettingType.religion:
        return Icons.account_balance;
      case SettingType.politics:
        return Icons.gavel;
      case SettingType.economy:
        return Icons.attach_money;
      case SettingType.geography:
        return Icons.map;
      default:
        return Icons.article;
    }
  }

  /// 获取设定类型显示名称
  String _getTypeDisplayName() {
    if (_settingItem?.type == null) return '其他';
    return SettingType.fromValue(_settingItem!.type!).displayName;
  }

  /// 处理标题点击
  void _handleTitleTap() {
    AppLogger.d(_tag, '点击设定标题，打开详情卡片: ${_settingItem?.name}');
    
    // 关闭当前预览卡片
    _close();
    
    // 延迟一小段时间后打开详情卡片，确保预览卡片完全关闭
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _settingItem != null) {
        FloatingNovelSettingDetail.show(
          context: context,
          itemId: _settingItem!.id,
          novelId: widget.novelId,
          groupId: _settingGroup?.id,
          isEditing: false,
          onSave: (item, groupId) {
            // 保存成功后可以做一些处理
            AppLogger.i(_tag, '设定详情保存成功: ${item.name}');
          },
          onCancel: () {
            // 取消操作
            AppLogger.d(_tag, '设定详情编辑取消');
          },
        );
      }
    });
  }

  /// 关闭卡片
  void _close() {
    _animationController.reverse().then((_) {
      widget.onClose?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDark = WebTheme.isDarkMode(context);
    
    // 计算卡片位置，确保不超出屏幕边界
    const cardWidth = 320.0;
    const cardHeight = 200.0;
    
    double left = widget.position.dx;
    double top = widget.position.dy;
    
    // 调整水平位置
    if (left + cardWidth > screenSize.width) {
      left = screenSize.width - cardWidth - 16;
    }
    if (left < 16) {
      left = 16;
    }
    
    // 调整垂直位置
    if (top + cardHeight > screenSize.height) {
      top = widget.position.dy - cardHeight - 10; // 显示在鼠标上方
    }
    if (top < 16) {
      top = 16;
    }

    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
                shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
                child: Container(
                  width: cardWidth,
                  constraints: const BoxConstraints(
                    maxHeight: cardHeight,
                  ),
                  decoration: BoxDecoration(
                    color: WebTheme.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? WebTheme.darkGrey700 : WebTheme.grey300,
                      width: 1.5,
                    ),
                  ),
                  child: _buildCardContent(isDark),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建卡片内容
  Widget _buildCardContent(bool isDark) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_settingItem == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 32,
                color: WebTheme.getSecondaryTextColor(context),
              ),
              const SizedBox(height: 8),
              Text(
                '设定不存在',
                style: TextStyle(
                  fontSize: 14,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 头部区域
        _buildHeader(isDark),
        
        // 分隔线
        Container(
          height: 1,
          color: isDark ? WebTheme.darkGrey800 : WebTheme.grey200,
        ),
        
        // 内容区域
        Flexible(
          child: _buildContent(isDark),
        ),
      ],
    );
  }

  /// 构建头部区域
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 设定图片或类型图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? WebTheme.darkGrey800 : WebTheme.grey100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? WebTheme.darkGrey700 : WebTheme.grey300,
                width: 1,
              ),
            ),
            child: _settingItem!.imageUrl != null && _settingItem!.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(
                      _settingItem!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          _getTypeIcon(),
                          size: 24,
                          color: WebTheme.getTextColor(context),
                        );
                      },
                    ),
                  )
                : Icon(
                    _getTypeIcon(),
                    size: 24,
                    color: WebTheme.getTextColor(context),
                  ),
          ),
          
          const SizedBox(width: 12),
          
          // 设定信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 设定名称（可点击）
                GestureDetector(
                  onTap: _handleTitleTap,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      _settingItem!.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: WebTheme.getTextColor(context),
                        decoration: TextDecoration.underline,
                        decorationColor: WebTheme.getTextColor(context).withOpacity(0.3),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // 类型和设定组
                Row(
                  children: [
                    // 设定类型
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: WebTheme.getTextColor(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getTypeDisplayName(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: WebTheme.getTextColor(context),
                        ),
                      ),
                    ),
                    
                    if (_settingGroup != null) ...[
                      const SizedBox(width: 8),
                      // 设定组
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: WebTheme.getSecondaryTextColor(context).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _settingGroup!.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: WebTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // 关闭按钮
          GestureDetector(
            onTap: _close,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 描述内容
          if (_settingItem!.description != null && _settingItem!.description!.isNotEmpty) ...[
            Text(
              '描述',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: WebTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                _settingItem!.description!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else if (_settingItem!.content != null && _settingItem!.content!.isNotEmpty) ...[
            Text(
              '内容',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: WebTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                _settingItem!.content!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: WebTheme.getSecondaryTextColor(context),
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            Center(
              child: Text(
                '暂无描述',
                style: TextStyle(
                  fontSize: 13,
                  color: WebTheme.getSecondaryTextColor(context).withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          // 提示文本
          Text(
            '点击标题查看详情',
            style: TextStyle(
              fontSize: 11,
              color: WebTheme.getSecondaryTextColor(context).withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
} 