import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/admin/admin_models.dart';

class CreditOperationDialog extends StatefulWidget {
  final AdminUser user;
  final bool isAdd; // true为添加积分，false为扣减积分

  const CreditOperationDialog({
    super.key,
    required this.user,
    required this.isAdd,
  });

  @override
  State<CreditOperationDialog> createState() => _CreditOperationDialogState();
}

class _CreditOperationDialogState extends State<CreditOperationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isAdd ? '添加积分' : '扣减积分',
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
              // 用户信息
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
                            '当前积分: ${widget.user.credits}',
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

              // 积分数量输入
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: '积分数量',
                  hintText: '请输入${widget.isAdd ? "添加" : "扣减"}的积分数量',
                  prefixIcon: const Icon(Icons.monetization_on),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入积分数量';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return '请输入有效的积分数量';
                  }
                  if (!widget.isAdd && amount > widget.user.credits) {
                    return '扣减积分不能超过用户当前积分';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 操作原因输入
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: '操作原因',
                  hintText: '请输入${widget.isAdd ? "添加" : "扣减"}积分的原因',
                  prefixIcon: const Icon(Icons.note),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入操作原因';
                  }
                  if (value.trim().length < 5) {
                    return '操作原因至少需要5个字符';
                  }
                  return null;
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
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isAdd 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
          ),
          child: Text(
            widget.isAdd ? '添加积分' : '扣减积分',
            style: TextStyle(
              color: widget.isAdd 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onError,
            ),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() == true) {
      final amount = int.parse(_amountController.text);
      final reason = _reasonController.text.trim();
      
      Navigator.of(context).pop({
        'amount': amount,
        'reason': reason,
      });
    }
  }
} 