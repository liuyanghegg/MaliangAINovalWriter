import 'package:flutter/material.dart';
import 'package:ainoval/models/user_ai_model_config_model.dart';
import 'package:ainoval/screens/editor/widgets/menu_builder.dart';
import '../../../config/provider_icons.dart';

/// 模型提供商分组卡片
/// 显示提供商信息和其下的模型列表
class ModelProviderGroupCard extends StatelessWidget {
  const ModelProviderGroupCard({
    super.key,
    required this.provider,
    required this.providerName,
    required this.description,
    required this.icon,
    required this.color,
    required this.configs,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onAddModel,
    required this.onSetDefault,
    required this.onValidate,
    required this.onEdit,
    required this.onDelete,
  });

  final String provider;
  final String providerName;
  final String description;
  final IconData icon;
  final Color color;
  final List<UserAIModelConfigModel> configs;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onAddModel;
  final Function(String) onSetDefault;
  final Function(String) onValidate;
  final Function(String) onEdit;
  final Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 统计验证状态
    final verifiedCount = configs.where((c) => c.isValidated).length;
    final totalCount = configs.length;
    
    // 查找在当前提供商组内的默认模型
    final defaultConfig = configs.firstWhere(
      (c) => c.isDefault,
      orElse: () => UserAIModelConfigModel.empty(),
    );
    
    // 只有当默认模型真正在当前组内时才显示
    final hasDefaultInThisGroup = defaultConfig.id.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 提供商头部
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 提供商图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ProviderIcons.getProviderIconForContext(
                      provider,
                      iconSize: IconSize.large,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 提供商信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerName,
                           style: theme.textTheme.titleMedium?.copyWith(
                             fontWeight: FontWeight.bold,
                             color: theme.colorScheme.onSurface,
                           ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 右侧状态信息（根据HTML样式改进）
                  _buildRightSideInfo(context, verifiedCount, totalCount, defaultConfig, hasDefaultInThisGroup),
                ],
              ),
            ),
          ),

          // 分隔线
          if (isExpanded)
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withOpacity(0.2),
              indent: 16,
              endIndent: 16,
            ),

          // 模型列表
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 模型项列表
                  ...configs.map((config) => _buildModelItem(context, config)),
                  
                  const SizedBox(height: 12),
                  
                  // 添加模型按钮
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAddModel,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加模型'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  // 构建右侧状态信息，参考HTML结构
  Widget _buildRightSideInfo(BuildContext context, int verifiedCount, int totalCount, 
      UserAIModelConfigModel defaultConfig, bool hasDefaultInThisGroup) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 桌面端显示（sm及以上）
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = MediaQuery.of(context).size.width < 640;
              
              if (isSmallScreen) {
                // 移动端简化显示
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$verifiedCount/$totalCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildChevronIcon(isDark),
                  ],
                );
              } else {
                // 桌面端完整显示
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 状态显示
                    Text(
                      '$verifiedCount/$totalCount 已启用',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // 默认模型显示（只有当前组有默认模型时才显示）
                     if (hasDefaultInThisGroup)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          color: theme.colorScheme.surface,
                        ),
                        child: Text(
                          '默认: ${defaultConfig.alias}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    
                    const SizedBox(width: 8),
                    
                    _buildChevronIcon(isDark),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // 构建Chevron图标
  Widget _buildChevronIcon(bool isDark) {
    return AnimatedRotation(
      turns: isExpanded ? 0.25 : 0, // 90度旋转
      duration: const Duration(milliseconds: 200),
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
      ),
    );
  }

  Widget _buildModelItem(BuildContext context, UserAIModelConfigModel config) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config.isDefault
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: config.isDefault
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 模型状态图标
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: config.isValidated
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: config.isValidated
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              config.isValidated ? Icons.check_circle : Icons.access_time,
              color: config.isValidated ? Colors.green : Colors.orange,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),

          // 模型信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      config.alias,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (config.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '默认',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  config.modelName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // 价格信息（模拟数据）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$0.03',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '输入',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$0.06',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '输出',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '每千标记',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 操作按钮
          MenuBuilder.buildModelMenu(
            context: context,
            configId: config.id,
            isValidated: config.isValidated,
            isDefault: config.isDefault,
            onValidate: (configId) async => onValidate(configId),
            onSetDefault: (configId) async => onSetDefault(configId),
            onEdit: (configId) async => onEdit(configId),
            onDelete: (configId) async => onDelete(configId),
            width: 180,
            align: 'right',
          ),
        ],
      ),
    );
  }
} 