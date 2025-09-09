import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/admin/admin_models.dart';
import '../../../blocs/admin/admin_bloc.dart';
import '../../../utils/web_theme.dart';

class RoleManagementTable extends StatelessWidget {
  final List<AdminRole> roles;

  const RoleManagementTable({
    super.key,
    required this.roles,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: WebTheme.getCardColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: WebTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WebTheme.getTextColor(context).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '角色管理',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.getTextColor(context),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh, color: WebTheme.getTextColor(context)),
                      onPressed: () => context.read<AdminBloc>().add(LoadRoles()),
                      tooltip: '刷新角色列表',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '总计: ${roles.length} 个角色',
                      style: TextStyle(
                        color: WebTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 数据表格
          if (roles.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 80,
                headingRowHeight: 56,
                headingRowColor: MaterialStateColor.resolveWith(
                  (states) => WebTheme.getCardColor(context),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      '角色名称',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: WebTheme.getTextColor(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '显示名称',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: WebTheme.getTextColor(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '描述',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: WebTheme.getTextColor(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '权限',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: WebTheme.getTextColor(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '状态',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: WebTheme.getTextColor(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '优先级',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: WebTheme.getTextColor(context),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '操作',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: WebTheme.getTextColor(context),
                      ),
                    ),
                  ),
                ],
                rows: roles.map((role) => DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleTypeColor(role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getRoleTypeIcon(role),
                              size: 16,
                              color: _getRoleTypeColor(role),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              role.roleName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: WebTheme.getTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        role.displayName,
                        style: TextStyle(color: WebTheme.getTextColor(context)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          role.description ?? '无描述',
                          style: TextStyle(color: WebTheme.getSecondaryTextColor(context)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: role.permissions.take(3).map((permission) => 
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: WebTheme.getTextColor(context).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                permission,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: WebTheme.getSecondaryTextColor(context),
                                ),
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    ),
                    DataCell(_buildStatusChip(context, role.enabled)),
                    DataCell(
                      Text(
                        '优先级: ${role.priority}',
                        style: TextStyle(color: WebTheme.getSecondaryTextColor(context)),
                      ),
                    ),
                    DataCell(_buildActionButtons(context, role)),
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
                      Icons.security_outlined,
                      size: 64,
                      color: WebTheme.getSecondaryTextColor(context).withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无角色数据',
                      style: TextStyle(
                        fontSize: 16,
                        color: WebTheme.getSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateRoleDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('创建第一个角色'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WebTheme.getTextColor(context),
                        foregroundColor: WebTheme.getBackgroundColor(context),
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

  Color _getRoleTypeColor(AdminRole role) {
    final roleName = role.roleName;
    if (roleName.startsWith('SYSTEM_')) {
      return Colors.orange;
    } else if (roleName.startsWith('ADMIN')) {
      return Colors.red;
    } else if (roleName.startsWith('USER')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  IconData _getRoleTypeIcon(AdminRole role) {
    final roleName = role.roleName;
    if (roleName.startsWith('SYSTEM_')) {
      return Icons.admin_panel_settings;
    } else if (roleName.startsWith('ADMIN')) {
      return Icons.manage_accounts;
    } else if (roleName.startsWith('USER')) {
      return Icons.person;
    } else {
      return Icons.group;
    }
  }

  Widget _buildActionButtons(BuildContext context, AdminRole role) {
    final isSystemRole = role.roleName.startsWith('SYSTEM_');
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 编辑角色
        IconButton(
          icon: Icon(
            Icons.edit,
            size: 18,
            color: isSystemRole 
                ? WebTheme.getSecondaryTextColor(context).withOpacity(0.5)
                : WebTheme.getTextColor(context),
          ),
          onPressed: isSystemRole ? null : () => _showEditRoleDialog(context, role),
          tooltip: isSystemRole ? '系统角色不可编辑' : '编辑角色',
          visualDensity: VisualDensity.compact,
        ),
        // 查看权限
        IconButton(
          icon: Icon(Icons.visibility, size: 18, color: WebTheme.getTextColor(context)),
          onPressed: () => _showPermissionsDialog(context, role),
          tooltip: '查看权限',
          visualDensity: VisualDensity.compact,
        ),
        // 删除
        if (!isSystemRole)
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: () => _showDeleteConfirmDialog(context, role),
            tooltip: '删除角色',
            visualDensity: VisualDensity.compact,
            color: Colors.red.shade700,
          ),
      ],
    );
  }

  void _showCreateRoleDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('创建角色功能开发中...')),
    );
  }

  void _showEditRoleDialog(BuildContext context, AdminRole role) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑角色功能开发中...')),
    );
  }

  void _showPermissionsDialog(BuildContext context, AdminRole role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WebTheme.getCardColor(context),
        title: Text(
          '${role.displayName} - 权限详情',
          style: TextStyle(color: WebTheme.getTextColor(context)),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '权限列表:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: WebTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              if (role.permissions.isNotEmpty)
                ...role.permissions.map((permission) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          permission,
                          style: TextStyle(color: WebTheme.getTextColor(context)),
                        ),
                      ),
                    ],
                  ),
                ))
              else
                Text(
                  '无权限配置',
                  style: TextStyle(color: WebTheme.getSecondaryTextColor(context)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '关闭',
              style: TextStyle(color: WebTheme.getTextColor(context)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, AdminRole role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: WebTheme.getCardColor(context),
        title: Text(
          '确认删除',
          style: TextStyle(color: WebTheme.getTextColor(context)),
        ),
        content: Text(
          '确定要删除角色 "${role.displayName}" 吗？此操作不可撤销。',
          style: TextStyle(color: WebTheme.getTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '取消',
              style: TextStyle(color: WebTheme.getSecondaryTextColor(context)),
            ),
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

    if (confirmed == true && context.mounted) {
      // TODO: 实现删除角色API调用
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('删除角色功能开发中...'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}