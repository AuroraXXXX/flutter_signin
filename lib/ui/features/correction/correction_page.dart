import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../domain/models/attendance_record.dart';
import '../../app_store.dart';
import '../../core/cupertino_picker_sheet.dart';
import '../../core/formatters.dart';

class CorrectionPage extends SignalWidget {
  const CorrectionPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) => _CorrectionForm(
    key: const PageStorageKey('correction-form'),
    store: store,
    records: store.records.value,
  );
}

class _CorrectionForm extends StatefulWidget {
  const _CorrectionForm({
    super.key,
    required this.store,
    required this.records,
  });

  final AppStore store;
  final List<AttendanceRecord> records;

  @override
  State<_CorrectionForm> createState() => _CorrectionFormState();
}

class _CorrectionFormState extends State<_CorrectionForm> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _date;
  TimeOfDay? _firstTime;
  TimeOfDay? _lastTime;
  final _noteController = TextEditingController();
  String? _error;
  bool _isSaving = false;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('补签管理')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildCalendar(context),
          const SizedBox(height: 20),
          Text('补签信息', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('日期'),
                    subtitle: Text(
                      _date == null ? '请选择日期' : formatDate(_date!),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.login),
                    title: const Text('首次时间'),
                    subtitle: Text(
                      _firstTime == null
                          ? '请选择时间'
                          : _firstTime!.format(context),
                    ),
                    onTap: _date == null ? null : () => _pickTime(first: true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout),
                    title: const Text('末次时间'),
                    subtitle: Text(
                      _lastTime == null ? '请选择时间' : _lastTime!.format(context),
                    ),
                    onTap: _date == null ? null : () => _pickTime(first: false),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: '备注（可选）'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _error!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: const Icon(Icons.save),
                      label: Text(_isSaving ? '保存中…' : '保存补签'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '绿色表示签到正常，红色表示签到时间或有效工时异常。未来日期不可选择。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = firstDay.weekday - DateTime.monday;
    final count = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final currentMonth = DateTime(_today.year, _today.month);
    final canGoNext = _month.isBefore(currentMonth);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: '上个月',
                  onPressed: _month.year == 2000 && _month.month == 1
                      ? null
                      : _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${_month.year}年${_month.month}月',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  tooltip: '下个月',
                  onPressed: canGoNext ? _nextMonth : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Row(
              children: ['一', '二', '三', '四', '五', '六', '日']
                  .map((day) => Expanded(child: Center(child: Text(day))))
                  .toList(),
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: count,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 42,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - leading + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox();
                }
                final date = DateTime(_month.year, _month.month, dayNumber);
                return _CalendarDay(
                  date: date,
                  record: _recordFor(date),
                  selected: _sameDate(date, _date),
                  disabled: date.isAfter(_today),
                  onTap: () => _selectDate(date),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  AttendanceRecord? _recordFor(DateTime date) {
    for (final record in widget.records) {
      if (_sameDate(record.date, date)) return record;
    }
    return null;
  }

  void _selectDate(DateTime date) {
    if (date.isAfter(_today)) return;
    final record = _recordFor(date);
    setState(() {
      _date = date;
      _error = null;
      _firstTime = record == null
          ? null
          : TimeOfDay.fromDateTime(record.firstCheckIn);
      _lastTime = record == null
          ? null
          : TimeOfDay.fromDateTime(record.lastCheckIn);
      _noteController.text = record?.note ?? '';
    });
  }

  Future<void> _pickTime({required bool first}) async {
    final value = await showCupertinoTimePicker(
      context: context,
      initialTime: first
          ? (_firstTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_lastTime ?? const TimeOfDay(hour: 18, minute: 0)),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (first) {
        _firstTime = value;
      } else {
        _lastTime = value;
      }
      _error = null;
    });
  }

  Future<void> _submit() async {
    final date = _date;
    final firstTime = _firstTime;
    final lastTime = _lastTime;
    if (date == null || firstTime == null || lastTime == null) {
      setState(() => _error = '请选择日期、首次时间和末次时间');
      return;
    }
    final first = _combine(date, firstTime);
    final last = _combine(date, lastTime);
    if (last.isBefore(first)) {
      setState(() => _error = '末次时间不能早于首次时间');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final existing = _recordFor(date);
      await widget.store.saveManualRecord(
        AttendanceRecord(
          id: existing?.id,
          date: date,
          firstCheckIn: first,
          lastCheckIn: last,
          note: _noteController.text.trim(),
          attendanceSource: AttendanceSource.resign,
        ),
      );
      if (!mounted) return;
      setState(() {
        _date = null;
        _firstTime = null;
        _lastTime = null;
        _noteController.clear();
        _error = null;
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('补签保存成功，表单已清空')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = error.toString().contains('UNIQUE constraint failed')
            ? '该日期已经存在签到记录'
            : '保存失败：$error';
      });
    }
  }

  void _previousMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1));

  DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  bool _sameDate(DateTime? first, DateTime? second) =>
      first != null &&
      second != null &&
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.record,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final DateTime date;
  final AttendanceRecord? record;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normal = record == null || _isNormal(record!, context);
    final statusColor = record == null
        ? scheme.onSurface
        : normal
        ? Colors.green
        : scheme.error;
    final background = record == null
        ? null
        : statusColor.withValues(alpha: 0.14);
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: scheme.primary, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: disabled
                  ? scheme.onSurface.withValues(alpha: 0.25)
                  : statusColor,
              fontWeight: record == null ? null : FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  bool _isNormal(AttendanceRecord record, BuildContext context) {
    final store = context
        .findAncestorWidgetOfExactType<_CorrectionForm>()
        ?.store;
    return store == null || store.evaluate(record).isValid;
  }
}
