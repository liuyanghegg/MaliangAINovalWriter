import 'package:flutter/material.dart';
import '../../../models/admin/admin_models.dart';

class UserEditDialog extends StatefulWidget {
  final AdminUser user;

  const UserEditDialog({
    super.key,
    required this.user,
  });

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _displayNameController;
  late String _selectedAccountStatus;

  final List<String> _accountStatuses = [
    'ACTIVE',
    'SUSPENDED', 
    'DISABLED',
    'PENDING_VERIFICATION',
  ];

  final Map<String, String> _statusLabels = {
    'ACTIVE': '活跃',
    'SUSPENDED': '暂停',
    'DISABLED': '禁用',
    'PENDING_VERIFICATION': '待验证',
  };

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user.email);
    _displayNameController = TextEditingController(text: widget.user.displayName ?? '');
    _selectedAccountStatus = widget.user.accountStatus;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '编辑用户信息',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用户基本信息展示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.username,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'ID: ${widget.user.id}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            '积分: ${widget.user.credits}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 邮箱输入
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '邮箱',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入邮箱';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return '请输入有效的邮箱地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 显示名称输入
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: '显示名称',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  hintText: '可选，留空则使用用户名',
                ),
              ),
              const SizedBox(height: 16),

              // 账户状态选择
              DropdownButtonFormField<String>(
                value: _selectedAccountStatus,
                decoration: const InputDecoration(
                  labelText: '账户状态',
                  prefixIcon: Icon(Icons.account_circle),
                  border: OutlineInputBorder(),
                ),
                items: _accountStatuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Row(
                      children: [
                        _getStatusIcon(status),
                        const SizedBox(width: 8),
                        Text(_statusLabels[status] ?? status),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAccountStatus = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'ACTIVE':
        return Icon(Icons.check_circle, color: Colors.green, size: 16);
      case 'SUSPENDED':
        return Icon(Icons.pause_circle, color: Colors.orange, size: 16);
      case 'DISABLED':
        return Icon(Icons.cancel, color: Colors.red, size: 16);
      case 'PENDING_VERIFICATION':
        return Icon(Icons.pending, color: Colors.blue, size: 16);
      default:
        return Icon(Icons.help, color: Colors.grey, size: 16);
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() == true) {
      final email = _emailController.text.trim();
      final displayName = _displayNameController.text.trim();
      
      // 检查是否有更改
      bool hasChanges = false;
      Map<String, dynamic> changes = {};
      
      if (email != widget.user.email) {
        hasChanges = true;
        changes['email'] = email;
      }
      
      if (displayName != (widget.user.displayName ?? '')) {
        hasChanges = true;
        changes['displayName'] = displayName.isEmpty ? null : displayName;
      }
      
      if (_selectedAccountStatus != widget.user.accountStatus) {
        hasChanges = true;
        changes['accountStatus'] = _selectedAccountStatus;
      }
      
      if (hasChanges) {
        Navigator.of(context).pop(changes);
      } else {
        Navigator.of(context).pop();
      }
    }
  }
} 