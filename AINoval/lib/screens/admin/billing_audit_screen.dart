import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:ainoval/utils/web_theme.dart';
import 'package:ainoval/models/admin/billing_models.dart';
import 'package:ainoval/services/api_service/repositories/impl/admin/billing_repository_impl.dart';

class BillingAuditScreen extends StatefulWidget {
  const BillingAuditScreen({super.key});

  @override
  State<BillingAuditScreen> createState() => _BillingAuditScreenState();
}

class _BillingAuditScreenState extends State<BillingAuditScreen> {
  late BillingRepositoryImpl _repo;
  int _page = 0;
  final int _size = 20;
  String? _status;
  String? _userId;
  bool _loading = false;
  List<CreditTransactionModel> _items = const [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _repo = GetIt.instance<BillingRepositoryImpl>();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    try {
      final results = await Future.wait([
        _repo.listTransactions(page: _page, size: _size, status: _status, userId: _userId),
        _repo.countTransactions(status: _status, userId: _userId),
      ]);
      setState(() {
        _items = results[0] as List<CreditTransactionModel>;
        _total = results[1] as int;
      });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _reverse(CreditTransactionModel tx) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('输入冲正原因'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '原因...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('确认')),
        ],
      );
    });
    if (reason == null || reason.isEmpty) return;
    await _repo.reverse(tx.traceId, operatorUserId: 'admin', reason: reason);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: WebTheme.getBackgroundColor(context),
        foregroundColor: WebTheme.getTextColor(context),
        title: Text('计费审计', style: TextStyle(color: WebTheme.getTextColor(context))),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: '状态'),
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('全部')),
                    DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
                    DropdownMenuItem(value: 'FAILED', child: Text('FAILED')),
                    DropdownMenuItem(value: 'DEDUCTED', child: Text('DEDUCTED')),
                    DropdownMenuItem(value: 'COMPENSATED', child: Text('COMPENSATED')),
                  ],
                  onChanged: (v) { setState(() { _status = v; _page = 0; }); _load(); },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(labelText: '用户ID'),
                  onSubmitted: (v) { setState(() { _userId = v.trim().isEmpty ? null : v.trim(); _page = 0; }); _load(); },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('TraceID')),
                          DataColumn(label: Text('User')),
                          DataColumn(label: Text('Model')),
                          DataColumn(label: Text('Feature')),
                          DataColumn(label: Text('In/Out')),
                          DataColumn(label: Text('Credits')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: _items.map((tx) {
                          final model = [tx.provider ?? '-', tx.modelId ?? '-'].where((e) => e != '-').join(':');
                          final io = '${tx.inputTokens ?? 0}/${tx.outputTokens ?? 0}';
                          final canReverse = tx.status == 'DEDUCTED' || tx.status == 'COMPENSATED';
                          return DataRow(cells: [
                            DataCell(Text(tx.traceId, overflow: TextOverflow.ellipsis)),
                            DataCell(Text(tx.userId ?? '-')),
                            DataCell(Text(model.isEmpty ? '-' : model)),
                            DataCell(Text(tx.featureType ?? '-')),
                            DataCell(Text(io)),
                            DataCell(Text('${tx.creditsDeducted ?? 0}')),
                            DataCell(Text(tx.status)),
                            DataCell(Row(children: [
                              if (canReverse) ElevatedButton.icon(onPressed: () => _reverse(tx), icon: const Icon(Icons.undo), label: const Text('冲正')),
                            ])),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('共 $_total 条'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _page > 0 ? () { setState(() { _page--; }); _load(); } : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${_page + 1}'),
                IconButton(
                  onPressed: ((_page + 1) * _size) < _total ? () { setState(() { _page++; }); _load(); } : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


