import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/admin/subscription_models.dart';
import '../../../blocs/subscription/subscription_bloc.dart';

class SubscriptionPlanTable extends StatelessWidget {
  final List<SubscriptionPlan> plans;

  const SubscriptionPlanTable({
    super.key,
    required this.plans,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '订阅计划管理',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('创建订阅计划功能开发中...')),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('创建订阅计划'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => context.read<SubscriptionBloc>().add(LoadSubscriptionPlans()),
                      tooltip: '刷新订阅计划列表',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '总计: ${plans.length} 个计划',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 数据表格或空状态
          if (plans.isNotEmpty)
            _buildPlansTable(context)
          else
            _buildEmptyState(context),
        ],
      ),
    );
  }

  Widget _buildPlansTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 80,
        headingRowHeight: 56,
        columns: const [
          DataColumn(
            label: Text(
              '计划名称',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              '价格',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              '计费周期',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              '积分',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              '状态',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              '推荐',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              '优先级',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              '操作',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: plans.map((plan) => DataRow(
          cells: [
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    plan.planName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (plan.description != null && plan.description!.isNotEmpty)
                    Text(
                      plan.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  plan.formattedPrice,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBillingCycleColor(plan.billingCycle).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  plan.billingCycleText,
                  style: TextStyle(
                    color: _getBillingCycleColor(plan.billingCycle),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            DataCell(
              Text(
                plan.creditsGranted?.toString() ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            DataCell(_buildStatusChip(context, plan.active)),
            DataCell(
              plan.recommended
                  ? const Icon(Icons.star, color: Colors.amber, size: 18)
                  : const Icon(Icons.star_border, color: Colors.grey, size: 18),
            ),
            DataCell(
              Text(
                plan.priority.toString(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            DataCell(_buildActionButtons(context, plan)),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.subscriptions_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无订阅计划',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('创建订阅计划功能开发中...')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('创建第一个订阅计划'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: active ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            active ? '活跃' : '禁用',
            style: TextStyle(
              color: active ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBillingCycleColor(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.monthly:
        return Colors.blue;
      case BillingCycle.quarterly:
        return Colors.orange;
      case BillingCycle.yearly:
        return Colors.green;
      case BillingCycle.lifetime:
        return Colors.purple;
    }
  }

  Widget _buildActionButtons(BuildContext context, SubscriptionPlan plan) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 编辑计划
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('编辑订阅计划功能开发中...')),
            );
          },
          tooltip: '编辑计划',
          visualDensity: VisualDensity.compact,
        ),
        // 启用/禁用
        IconButton(
          icon: Icon(
            plan.active ? Icons.pause : Icons.play_arrow,
            size: 18,
          ),
          onPressed: () => _togglePlanStatus(context, plan),
          tooltip: plan.active ? '禁用计划' : '启用计划',
          visualDensity: VisualDensity.compact,
          color: plan.active ? Colors.orange.shade700 : Colors.green.shade700,
        ),
        // 删除
        IconButton(
          icon: const Icon(Icons.delete, size: 18),
          onPressed: () => _deletePlan(context, plan),
          tooltip: '删除计划',
          visualDensity: VisualDensity.compact,
          color: Colors.red.shade700,
        ),
      ],
    );
  }

  void _togglePlanStatus(BuildContext context, SubscriptionPlan plan) {
    if (plan.id != null) {
      context.read<SubscriptionBloc>().add(ToggleSubscriptionPlanStatus(
        planId: plan.id!,
        active: !plan.active,
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plan.active ? "禁用" : "启用"}计划操作已提交'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _deletePlan(BuildContext context, SubscriptionPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除订阅计划 "${plan.planName}" 吗？此操作不可撤销。'),
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

    if (confirmed == true && context.mounted && plan.id != null) {
      context.read<SubscriptionBloc>().add(DeleteSubscriptionPlan(plan.id!));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('删除订阅计划操作已提交'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 