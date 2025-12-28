import 'package:flutter/material.dart';
import 'package:ainoval/utils/web_theme.dart';

class AnalyticsDateRangePicker extends StatelessWidget {
  final DateTimeRange? dateRange;
  final Function(DateTimeRange?)? onDateRangeChanged;
  final String? placeholder;

  const AnalyticsDateRangePicker({
    super.key,
    this.dateRange,
    this.onDateRangeChanged,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDateRangePicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: WebTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: WebTheme.getBorderColor(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              _getDisplayText(),
              style: TextStyle(
                fontSize: 12,
                color: WebTheme.getTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (dateRange == null) {
      return placeholder ?? '选择日期范围';
    }
    
    final startDate = _formatDate(dateRange!.start);
    final endDate = _formatDate(dateRange!.end);
    return '$startDate ~ $endDate';
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 1);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: dateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
              surface: WebTheme.getCardColor(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeChanged?.call(picked);
    }
  }
}

class AnalyticsDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime?)? onDateChanged;
  final String? placeholder;

  const AnalyticsDatePicker({
    super.key,
    this.selectedDate,
    this.onDateChanged,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDatePicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: WebTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: WebTheme.getBorderColor(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: WebTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              selectedDate != null 
                  ? _formatDate(selectedDate!)
                  : placeholder ?? '选择日期',
              style: TextStyle(
                fontSize: 12,
                color: WebTheme.getTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
              surface: WebTheme.getCardColor(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateChanged?.call(picked);
    }
  }
}

