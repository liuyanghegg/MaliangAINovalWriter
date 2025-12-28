import 'package:flutter/material.dart';

class AdminDataTable extends StatelessWidget {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final List<VoidCallback>? actions;
  final List<String>? actionLabels;

  const AdminDataTable({
    super.key,
    required this.title,
    required this.headers,
    required this.rows,
    this.actions,
    this.actionLabels,
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
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (actions != null && actionLabels != null)
                  Row(
                    children: List.generate(
                      actions!.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ElevatedButton(
                          onPressed: actions![index],
                          child: Text(actionLabels![index]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 数据表格
          if (rows.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: headers
                    .map((header) => DataColumn(
                          label: Text(
                            header,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ))
                    .toList(),
                rows: rows
                    .map((row) => DataRow(
                          cells: row
                              .map((cell) => DataCell(Text(cell)))
                              .toList(),
                        ))
                    .toList(),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  '暂无数据',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 