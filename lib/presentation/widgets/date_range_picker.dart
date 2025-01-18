// lib/presentation/widgets/date_range_picker.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime, DateTime) onDateRangeChanged;

  const CustomDateRangePicker({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  // Các tùy chọn nhanh cho khoảng thời gian
  final List<DateRangeOption> _quickOptions = [
    DateRangeOption(
      'Hôm nay',
      () {
        final now = DateTime.now();
        return DateTimeRange(start: now, end: now);
      },
    ),
    DateRangeOption(
      'Hôm qua',
      () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: yesterday);
      },
    ),
    DateRangeOption(
      '7 ngày qua',
      () {
        final now = DateTime.now();
        final last7Days = now.subtract(const Duration(days: 6));
        return DateTimeRange(start: last7Days, end: now);
      },
    ),
    DateRangeOption(
      '30 ngày qua',
      () {
        final now = DateTime.now();
        final last30Days = now.subtract(const Duration(days: 29));
        return DateTimeRange(start: last30Days, end: now);
      },
    ),
    DateRangeOption(
      'Tháng này',
      () {
        final now = DateTime.now();
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: firstDayOfMonth, end: now);
      },
    ),
    DateRangeOption(
      'Tháng trước',
      () {
        final now = DateTime.now();
        final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
        return DateTimeRange(
            start: firstDayOfLastMonth, end: lastDayOfLastMonth);
      },
    ),
  ];

  void _showDateRangePicker() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn khoảng thời gian',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickOptions.map((option) {
                  return ActionChip(
                    label: Text(option.label),
                    onPressed: () {
                      final range = option.getRange();
                      setState(() {
                        _startDate = range.start;
                        _endDate = range.end;
                      });
                      widget.onDateRangeChanged(_startDate, _endDate);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Từ ngày'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: _endDate,
                              locale: const Locale('vi', 'VN'),
                            );
                            if (date != null) {
                              setState(() => _startDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('dd/MM/yyyy')
                                    .format(_startDate)),
                                const Icon(Icons.calendar_today, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Đến ngày'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate: DateTime.now(),
                              locale: const Locale('vi', 'VN'),
                            );
                            if (date != null) {
                              setState(() => _endDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                                const Icon(Icons.calendar_today, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      widget.onDateRangeChanged(_startDate, _endDate);
                      Navigator.pop(context);
                    },
                    child: const Text('Áp dụng'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      widget.onDateRangeChanged(_startDate, _endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showDateRangePicker,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 8),
            Text(
              '${DateFormat('dd/MM/yyyy').format(_startDate)} - '
              '${DateFormat('dd/MM/yyyy').format(_endDate)}',
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}

class DateRangeOption {
  final String label;
  final DateTimeRange Function() getRange;

  DateRangeOption(this.label, this.getRange);
}
