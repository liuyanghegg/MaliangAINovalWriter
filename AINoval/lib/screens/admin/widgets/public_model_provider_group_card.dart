import 'package:flutter/material.dart';
import '../../../models/public_model_config.dart';
import '../../../models/prompt_models.dart';
import '../../../config/provider_icons.dart';
import '../../../utils/web_theme.dart';

/// 公共模型提供商分组卡片
/// 显示提供商信息和其下的公共模型列表
class PublicModelProviderGroupCard extends StatelessWidget {
  const PublicModelProviderGroupCard({
    super.key,
    required this.provider,
    required this.providerName,
    required this.description,
    required this.configs,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onAddModel,
    required this.onValidate,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onCopy,
  });

  final String provider;
  final String providerName;
  final String description;
  final List<PublicModelConfigDetails> configs;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onAddModel;
  final Function(String) onValidate;
  final Function(String) onEdit;
  final Function(String) onDelete;
  final Function(String, bool) onToggleStatus;
  final Function(String) onCopy;

  @override
  Widget build(BuildContext context) {
    final color = ProviderIcons.getProviderColor(provider);

    // 统计状态
    final enabledCount = configs.where((c) => c.enabled == true).length;
    final validatedCount = configs.where((c) => c.isValidated == true).length;
    final totalCount = configs.length;

    return Container(
      decoration: BoxDecoration(
        color: WebTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: WebTheme.getShadowColor(context, opacity: 0.1),
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
                      iconSize: IconSize.medium,
                      color: color,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // 提供商信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                providerName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: WebTheme.getTextColor(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: WebTheme.getSecondaryTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 状态统计
                        Row(
                          children: [
                            _buildStatusChip(
                              context,
                              '总计: $totalCount',
                              Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(
                              context,
                              '启用: $enabledCount',
                              Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(
                              context,
                              '已验证: $validatedCount',
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 展开/折叠图标
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: WebTheme.getSecondaryTextColor(context),
                  ),
                ],
              ),
            ),
          ),
          
          // 模型列表
          if (isExpanded) ...[
            Divider(
              height: 1,
              color: WebTheme.getBorderColor(context),
            ),
            if (configs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 48,
                        color: WebTheme.getSecondaryTextColor(context),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '该提供商暂无公共模型配置',
                        style: TextStyle(
                          fontSize: 14,
                          color: WebTheme.getSecondaryTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: onAddModel,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('添加模型'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: configs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final config = configs[index];
                  return _buildModelConfigCard(context, config);
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildModelConfigCard(BuildContext context, PublicModelConfigDetails config) {
    final color = ProviderIcons.getProviderColor(provider);
    
    return Container(
      decoration: BoxDecoration(
        color: WebTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WebTheme.getBorderColor(context),
        ),
        boxShadow: [
          BoxShadow(
            color: WebTheme.getShadowColor(context, opacity: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模型头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                  color: WebTheme.getBorderColor(context),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  config.displayName ?? config.modelId,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: WebTheme.getTextColor(context),
                                  ),
                                ),
                              ),
                              // 复制按钮
                              IconButton(
                                onPressed: () => onCopy(config.id!),
                                icon: Icon(
                                  Icons.content_copy,
                                  color: color,
                                  size: 18,
                                ),
                                tooltip: '复制配置',
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          if (config.displayName != null && config.displayName != config.modelId)
                            Text(
                              config.modelId,
                              style: TextStyle(
                                fontSize: 13,
                                color: WebTheme.getSecondaryTextColor(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 启用状态开关
                    Switch(
                      value: config.enabled ?? false,
                      onChanged: (value) => onToggleStatus(config.id!, value),
                      activeColor: color,
                      inactiveThumbColor: WebTheme.getSecondaryTextColor(context),
                      inactiveTrackColor: WebTheme.getSecondaryTextColor(context).withOpacity(0.3),
                    ),
                  ],
                ),
                
                // 描述信息
                if (config.description != null && config.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    config.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.getSecondaryTextColor(context),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // 状态标签行
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildConfigStatusChip(
                      context,
                      config.isValidated == true ? '已验证' : '未验证',
                      config.isValidated == true ? Colors.green : Colors.red,
                    ),
                    if (config.apiKeyPoolStatus != null)
                      _buildConfigStatusChip(
                        context,
                        'Keys: ${config.apiKeyPoolStatus}',
                        Colors.blue,
                      ),
                    if (config.priority != null && config.priority! > 0)
                      _buildConfigStatusChip(
                        context,
                        '优先级: ${config.priority}',
                        Colors.purple,
                      ),
                    if (config.tags != null && config.tags!.isNotEmpty)
                      ...config.tags!.take(3).map((tag) => _buildConfigStatusChip(
                        context,
                        tag,
                        Colors.orange,
                      )),
                  ],
                ),
              ],
            ),
          ),
          
          // 详细信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 功能授权
                if (config.enabledForFeatures != null && config.enabledForFeatures!.isNotEmpty) ...[
                  _buildDetailSection(
                    context,
                    '授权功能',
                    Icons.verified_user,
                    color,
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: config.enabledForFeatures!.map((feature) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Text(
                            _getFeatureDisplayName(feature),
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // 配置信息
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoGrid(context, config, color),
                    ),
                  ],
                ),
                
                // 定价信息
                if (config.pricingInfo?.hasPricingData == true) ...[
                  const SizedBox(height: 12),
                  _buildPricingInfo(context, config.pricingInfo!, color),
                ],
                
                // 使用统计
                if (config.usageStatistics?.hasUsageData == true) ...[
                  const SizedBox(height: 12),
                  _buildUsageStatistics(context, config.usageStatistics!, color),
                ],
                
                // 时间信息
                if (config.createdAt != null || config.updatedAt != null) ...[
                  const SizedBox(height: 12),
                  _buildTimeInfo(context, config),
                ],
                
                const SizedBox(height: 16),
                
                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onValidate(config.id!),
                        icon: const Icon(Icons.verified, size: 16),
                        label: const Text('验证'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onEdit(config.id!),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('编辑'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onDelete(config.id!),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('删除'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, IconData icon, Color color, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        content,
      ],
    );
  }

  Widget _buildInfoGrid(BuildContext context, PublicModelConfigDetails config, Color color) {
    final items = <Widget>[];
    
    if (config.creditRateMultiplier != null) {
      items.add(_buildInfoItem(context, '积分倍数', '${config.creditRateMultiplier}x'));
    }
    
    if (config.maxConcurrentRequests != null) {
      items.add(_buildInfoItem(context, '最大并发', 
        config.maxConcurrentRequests! > 0 ? '${config.maxConcurrentRequests}' : '无限制'));
    }
    
    if (config.dailyRequestLimit != null) {
      items.add(_buildInfoItem(context, '日限制', 
        config.dailyRequestLimit! > 0 ? '${config.dailyRequestLimit}' : '无限制'));
    }
    
    if (config.hourlyRequestLimit != null) {
      items.add(_buildInfoItem(context, '时限制', 
        config.hourlyRequestLimit! > 0 ? '${config.hourlyRequestLimit}' : '无限制'));
    }
    
    if (config.apiEndpoint != null && config.apiEndpoint!.isNotEmpty) {
      items.add(_buildInfoItem(context, 'Endpoint', config.apiEndpoint!, isUrl: true));
    }
    
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.settings, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              '配置信息',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: items,
        ),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, {bool isUrl = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: WebTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: WebTheme.getTextColor(context),
            ),
            maxLines: isUrl ? 1 : null,
            overflow: isUrl ? TextOverflow.ellipsis : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingInfo(BuildContext context, PricingInfo pricing, Color color) {
    return _buildDetailSection(
      context,
      '定价信息',
      Icons.attach_money,
      color,
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pricing.inputPricePerThousandTokens != null)
              Text(
                '输入: \$${pricing.inputPricePerThousandTokens!.toStringAsFixed(4)}/1K tokens',
                style: TextStyle(
                  fontSize: 11,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            if (pricing.outputPricePerThousandTokens != null)
              Text(
                '输出: \$${pricing.outputPricePerThousandTokens!.toStringAsFixed(4)}/1K tokens',
                style: TextStyle(
                  fontSize: 11,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            if (pricing.maxContextTokens != null)
              Text(
                '最大上下文: ${pricing.maxContextTokens!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} tokens',
                style: TextStyle(
                  fontSize: 11,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            if (pricing.supportsStreaming == true)
              Text(
                '支持流式输出',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatistics(BuildContext context, UsageStatistics usage, Color color) {
    return _buildDetailSection(
      context,
      '使用统计',
      Icons.bar_chart,
      color,
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (usage.totalRequests != null)
              Text(
                '总请求: ${usage.totalRequests}',
                style: TextStyle(
                  fontSize: 11,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            if (usage.totalCost != null)
              Text(
                '总成本: \$${usage.totalCost!.toStringAsFixed(4)}',
                style: TextStyle(
                  fontSize: 11,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            if (usage.last30DaysRequests != null)
              Text(
                '近30天请求: ${usage.last30DaysRequests}',
                style: TextStyle(
                  fontSize: 11,
                  color: WebTheme.getTextColor(context),
                ),
              ),
            if (usage.averageCostPerRequest != null)
              Text(
                '平均每请求成本: \$${usage.averageCostPerRequest!.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 11,
                  color: WebTheme.getTextColor(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context, PublicModelConfigDetails config) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: WebTheme.getSecondaryTextColor(context).withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WebTheme.getBorderColor(context)),
      ),
      child: Row(
        children: [
          if (config.createdAt != null) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '创建时间',
                    style: TextStyle(
                      fontSize: 10,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  Text(
                    formatDateTime(config.createdAt!),
                    style: TextStyle(
                      fontSize: 11,
                      color: WebTheme.getTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (config.updatedAt != null) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '更新时间',
                    style: TextStyle(
                      fontSize: 10,
                      color: WebTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  Text(
                    formatDateTime(config.updatedAt!),
                    style: TextStyle(
                      fontSize: 11,
                      color: WebTheme.getTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFeatureDisplayName(String feature) {
    try {
      final type = AIFeatureTypeHelper.fromApiString(feature.toUpperCase());
      return type.displayName;
    } catch (_) {
      return feature;
    }
  }

  String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  Widget _buildConfigStatusChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}