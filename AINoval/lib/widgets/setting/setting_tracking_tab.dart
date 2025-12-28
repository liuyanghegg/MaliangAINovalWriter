import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ainoval/models/novel_setting_item.dart';
import 'package:ainoval/models/ai_context_tracking.dart';
import 'package:ainoval/blocs/setting/setting_bloc.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

/// 设定追踪配置标签页
class SettingTrackingTab extends StatefulWidget {
  final NovelSettingItem settingItem;
  final String novelId;
  final Function(NovelSettingItem) onItemUpdated;

  const SettingTrackingTab({
    Key? key,
    required this.settingItem,
    required this.novelId,
    required this.onItemUpdated,
  }) : super(key: key);

  @override
  State<SettingTrackingTab> createState() => _SettingTrackingTabState();
}

class _SettingTrackingTabState extends State<SettingTrackingTab> {
  late NameAliasTracking _nameAliasTracking;
  late AIContextTracking _aiContextTracking;
  late SettingReferenceUpdate _referenceUpdatePolicy;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameAliasTracking = widget.settingItem.nameAliasTracking;
    _aiContextTracking = widget.settingItem.aiContextTracking;
    _referenceUpdatePolicy = widget.settingItem.referenceUpdatePolicy;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = WebTheme.isDarkMode(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 名称/别名追踪设置
          _buildNameAliasTrackingSection(isDark),
          
          const SizedBox(height: 16),
          
          // AI上下文追踪设置
          _buildAIContextTrackingSection(isDark),
          
          const SizedBox(height: 16),
          
          // 引用更新策略设置
          _buildReferenceUpdateSection(isDark),
          
          const SizedBox(height: 20),
          
          // 保存按钮
          if (_hasChanges) _buildSaveButton(isDark),
        ],
      ),
    );
  }

  /// 构建名称/别名追踪设置区域
  Widget _buildNameAliasTrackingSection(bool isDark) {
    return _buildSettingSection(
      title: '名称/别名追踪',
      description: '控制是否通过名称和别名来追踪此设定条目',
      icon: Icons.label,
      iconColor: Colors.blue,
      child: Column(
        children: NameAliasTracking.values.map((option) {
          return _buildRadioTile<NameAliasTracking>(
            value: option,
            groupValue: _nameAliasTracking,
            title: option.displayName,
            description: option.description,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _nameAliasTracking = value;
                  _hasChanges = true;
                });
              }
            },
            isDark: isDark,
          );
        }).toList(),
      ),
    );
  }

  /// 构建AI上下文追踪设置区域
  Widget _buildAIContextTrackingSection(bool isDark) {
    return _buildSettingSection(
      title: 'AI上下文',
      description: '控制此设定条目如何包含在AI上下文中',
      icon: Icons.psychology,
      iconColor: Colors.purple,
      child: Column(
        children: AIContextTracking.values.map((option) {
          return _buildRadioTile<AIContextTracking>(
            value: option,
            groupValue: _aiContextTracking,
            title: option.displayName,
            description: option.description,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _aiContextTracking = value;
                  _hasChanges = true;
                });
              }
            },
            isDark: isDark,
            isRecommended: option == AIContextTracking.detected,
          );
        }).toList(),
      ),
    );
  }

  /// 构建引用更新策略设置区域
  Widget _buildReferenceUpdateSection(bool isDark) {
    return _buildSettingSection(
      title: '引用更新策略',
      description: '当修改此设定时，如何处理引用此设定的其他内容',
      icon: Icons.update,
      iconColor: Colors.orange,
      child: Column(
        children: SettingReferenceUpdate.values.map((option) {
          return _buildRadioTile<SettingReferenceUpdate>(
            value: option,
            groupValue: _referenceUpdatePolicy,
            title: option.displayName,
            description: option.description,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _referenceUpdatePolicy = value;
                  _hasChanges = true;
                });
              }
            },
            isDark: isDark,
            isRecommended: option == SettingReferenceUpdate.ask,
          );
        }).toList(),
      ),
    );
  }

  /// 构建设置区域的通用框架
  Widget _buildSettingSection({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    final isDark = WebTheme.isDarkMode(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? WebTheme.darkGrey100 : WebTheme.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? WebTheme.darkGrey700 : WebTheme.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题区域
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: WebTheme.getTextColor(context),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: WebTheme.getSecondaryTextColor(context),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 选项内容
          child,
        ],
      ),
    );
  }

  /// 构建单选按钮瓦片
  Widget _buildRadioTile<T>({
    required T value,
    required T groupValue,
    required String title,
    required String description,
    required ValueChanged<T?> onChanged,
    required bool isDark,
    bool isRecommended = false,
  }) {
    final isSelected = value == groupValue;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? (isDark ? WebTheme.darkGrey700 : Colors.blue.withOpacity(0.1))
            : WebTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
              ? Colors.blue
              : (isDark ? WebTheme.darkGrey600 : WebTheme.grey300),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 单选按钮
              Radio<T>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: Colors.blue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              
              const SizedBox(width: 12),
              
              // 内容区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected 
                                ? Colors.blue
                                : WebTheme.getTextColor(context),
                          ),
                        ),
                        
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '推荐',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: WebTheme.getSecondaryTextColor(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? WebTheme.darkGrey800 : WebTheme.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? WebTheme.darkGrey700 : WebTheme.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '保存更改',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: WebTheme.getTextColor(context),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '您的追踪配置已修改，点击保存以应用更改。',
            style: TextStyle(
              fontSize: 13,
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              // 重置按钮
              TextButton(
                onPressed: _isSaving ? null : _resetChanges,
                child: Text(
                  '重置',
                  style: TextStyle(
                    color: WebTheme.getSecondaryTextColor(context),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 保存按钮
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('保存中...'),
                          ],
                        )
                      : Text('保存更改'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 重置更改
  void _resetChanges() {
    setState(() {
      _nameAliasTracking = widget.settingItem.nameAliasTracking;
      _aiContextTracking = widget.settingItem.aiContextTracking;
      _referenceUpdatePolicy = widget.settingItem.referenceUpdatePolicy;
      _hasChanges = false;
    });
    
    TopToast.info(context, '已重置所有更改');
  }

  /// 保存更改
  Future<void> _saveChanges() async {
    if (widget.settingItem.id == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // 更新设定项目
      final updatedItem = widget.settingItem.copyWith(
        nameAliasTracking: _nameAliasTracking,
        aiContextTracking: _aiContextTracking,
        referenceUpdatePolicy: _referenceUpdatePolicy,
      );
      
      // 先更新本地状态
      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });
      
      // 立即通知父组件
      widget.onItemUpdated(updatedItem);
      
      // 显示成功提示
      TopToast.success(context, '追踪配置已保存');
      
      // 异步保存到后端，不阻塞UI
      _saveToBackendAsync(updatedItem);
      
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      TopToast.error(context, '保存失败: ${e.toString()}');
    }
  }
  
  /// 异步保存到后端
  Future<void> _saveToBackendAsync(NovelSettingItem updatedItem) async {
    try {
      // 通过BLoC更新后端
      context.read<SettingBloc>().add(UpdateSettingItem(
        novelId: widget.novelId,
        itemId: widget.settingItem.id!,
        item: updatedItem,
      ));
    } catch (e) {
      // 静默处理错误，不干扰用户体验
    }
  }
}