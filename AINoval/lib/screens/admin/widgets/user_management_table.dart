import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/admin/admin_models.dart';
import '../../../blocs/admin/admin_bloc.dart';
import 'credit_operation_dialog.dart';
import 'user_edit_dialog.dart';

class UserManagementTable extends StatelessWidget {
  final List<AdminUser> users;

  const UserManagementTable({
    super.key,
    required this.users,
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
                  '用户管理',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => context.read<AdminBloc>().add(LoadUsers()),
                      tooltip: '刷新用户列表',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '总计: ${users.length} 用户',
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
          // 数据表格
          if (users.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 80,
                headingRowHeight: 56,
                columns: const [
                  DataColumn(
                    label: Text(
                      '用户名',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '邮箱',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '状态',
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
                      '角色',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '创建时间',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '操作',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: users.map((user) => DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.username,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (user.displayName != null && user.displayName!.isNotEmpty)
                            Text(
                              user.displayName!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      SelectableText(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    DataCell(_buildStatusChip(context, user.accountStatus)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatCredits(user.credits),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: user.roles.take(2).map((role) => Chip(
                            label: Text(
                              role,
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          )).toList(),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        user.createdAt.toString().substring(0, 10),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    DataCell(_buildActionButtons(context, user)),
                  ],
                )).toList(),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无用户数据',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'ACTIVE':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        label = '活跃';
        break;
      case 'SUSPENDED':
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange.shade700;
        icon = Icons.pause_circle;
        label = '暂停';
        break;
      case 'DISABLED':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        label = '禁用';
        break;
      case 'PENDING_VERIFICATION':
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue.shade700;
        icon = Icons.pending;
        label = '待验证';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey.shade700;
        icon = Icons.help;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCredits(int credits) {
    if (credits >= 1000000) {
      return '${(credits / 1000000).toStringAsFixed(1)}M';
    } else if (credits >= 1000) {
      return '${(credits / 1000).toStringAsFixed(1)}K';
    } else {
      return credits.toString();
    }
  }

  Widget _buildActionButtons(BuildContext context, AdminUser user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 编辑用户信息
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () => _showEditUserDialog(context, user),
          tooltip: '编辑用户信息',
          visualDensity: VisualDensity.compact,
        ),
        // 添加积分
        IconButton(
          icon: const Icon(Icons.add_circle, size: 18),
          onPressed: () => _showCreditDialog(context, user, true),
          tooltip: '添加积分',
          visualDensity: VisualDensity.compact,
          color: Colors.green.shade700,
        ),
        // 扣减积分
        IconButton(
          icon: const Icon(Icons.remove_circle, size: 18),
          onPressed: () => _showCreditDialog(context, user, false),
          tooltip: '扣减积分',
          visualDensity: VisualDensity.compact,
          color: Colors.red.shade700,
        ),
        // 更多操作
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18),
          onSelected: (value) => _handleMenuAction(context, user, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'toggle_status',
              child: ListTile(
                leading: Icon(Icons.swap_horiz, size: 18),
                title: Text('切换状态'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'assign_role',
              child: ListTile(
                leading: Icon(Icons.security, size: 18),
                title: Text('分配角色'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'view_details',
              child: ListTile(
                leading: Icon(Icons.info, size: 18),
                title: Text('查看详情'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditUserDialog(BuildContext context, AdminUser user) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UserEditDialog(user: user),
    );

    if (result != null && context.mounted) {
      context.read<AdminBloc>().add(UpdateUserInfo(
        userId: user.id,
        email: result['email'],
        displayName: result['displayName'],
        accountStatus: result['accountStatus'],
      ));
    }
  }

  void _showCreditDialog(BuildContext context, AdminUser user, bool isAdd) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreditOperationDialog(user: user, isAdd: isAdd),
    );

    if (result != null && context.mounted) {
      final amount = result['amount'] as int;
      final reason = result['reason'] as String;
      
      if (isAdd) {
        context.read<AdminBloc>().add(AddCreditsToUser(
          userId: user.id,
          amount: amount,
          reason: reason,
        ));
      } else {
        context.read<AdminBloc>().add(DeductCreditsFromUser(
          userId: user.id,
          amount: amount,
          reason: reason,
        ));
      }

      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isAdd ? "添加" : "扣减"}积分操作已提交'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleMenuAction(BuildContext context, AdminUser user, String action) {
    switch (action) {
      case 'toggle_status':
        final newStatus = user.accountStatus == 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
        context.read<AdminBloc>().add(UpdateUserStatus(
          userId: user.id,
          status: newStatus,
        ));
        break;
      case 'assign_role':
        _showAssignRoleDialog(context, user);
        break;
      case 'view_details':
        _showUserDetailsDialog(context, user);
        break;
    }
  }

  void _showAssignRoleDialog(BuildContext context, AdminUser user) {
    // TODO: 实现角色分配对话框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('角色分配功能开发中...')),
    );
  }

  void _showUserDetailsDialog(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('用户详情 - ${user.username}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('用户ID', user.id),
              _buildDetailRow('用户名', user.username),
              _buildDetailRow('邮箱', user.email),
              _buildDetailRow('显示名称', user.displayName ?? '-'),
              _buildDetailRow('账户状态', user.accountStatus),
              _buildDetailRow('积分余额', user.credits.toString()),
              _buildDetailRow('角色', user.roles.join(', ')),
              _buildDetailRow('创建时间', user.createdAt.toString()),
              _buildDetailRow('更新时间', user.updatedAt?.toString() ?? '-'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }
} 