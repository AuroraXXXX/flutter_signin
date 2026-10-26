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
  Widget build(BuildContext context) {
    final records = store.records.value;
    return Scaffold(
      appBar: AppBar(title: const Text('补签管理')),
      body: records.isEmpty
          ? const Center(child: Text('暂无记录，点击右下角添加补签'))
          : ListView.builder(
              key: const PageStorageKey('correction-list'),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return Card(
                  child: ListTile(
                    title: Text(formatDate(record.date)),
                    subtitle: Text(
                      '${formatTime(record.firstCheckIn)} - ${formatTime(record.lastCheckIn)}'
                      '${record.note.isEmpty ? '' : '\n${record.note}'}',
                    ),
                    isThreeLine: record.note.isNotEmpty,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEditor(context, record);
                        } else {
                          _delete(context, record);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('编辑')),
                        PopupMenuItem(value: 'delete', child: Text('删除')),
                      ],
                    ),
                    onTap: () => _openEditor(context, record),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('新增补签'),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    AttendanceRecord? record,
  ) async {
    final result = await showDialog<AttendanceRecord>(
      context: context,
      builder: (context) => AttendanceEditorDialog(record: record),
    );
    if (result == null || !context.mounted) return;
    try {
      await store.saveManualRecord(result);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('记录已保存')));
    } catch (error) {
      if (!context.mounted) return;
      final message = error.toString().contains('UNIQUE constraint failed')
          ? '该日期已经存在签到记录'
          : '保存失败：$error';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _delete(BuildContext context, AttendanceRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除签到记录？'),
        content: Text('将删除 ${formatDate(record.date)} 的记录，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await store.deleteRecord(record);
  }
}

class AttendanceEditorDialog extends SignalStatefulWidget {
  const AttendanceEditorDialog({super.key, this.record});

  final AttendanceRecord? record;

  @override
  State<AttendanceEditorDialog> createState() => _AttendanceEditorDialogState();
}

class _AttendanceEditorDialogState extends State<AttendanceEditorDialog> {
  late final Signal<DateTime> _date;
  late final Signal<TimeOfDay> _firstTime;
  late final Signal<TimeOfDay> _lastTime;
  late final TextEditingController _noteController;
  final _error = signal<String?>(null);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final record = widget.record;
    _date = signal(record?.date ?? DateTime(now.year, now.month, now.day));
    _firstTime = signal(
      record == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay.fromDateTime(record.firstCheckIn),
    );
    _lastTime = signal(
      record == null
          ? const TimeOfDay(hour: 18, minute: 0)
          : TimeOfDay.fromDateTime(record.lastCheckIn),
    );
    _noteController = TextEditingController(text: record?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    _date.dispose();
    _firstTime.dispose();
    _lastTime.dispose();
    _error.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.record == null ? '新增补签' : '编辑签到记录'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('日期'),
                subtitle: Text(formatDate(_date.value)),
                onTap: _pickDate,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.login),
                title: const Text('首次签到'),
                subtitle: Text(_firstTime.value.format(context)),
                onTap: () => _pickTime(first: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout),
                title: const Text('末次签到'),
                subtitle: Text(_lastTime.value.format(context)),
                onTap: () => _pickTime(first: false),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: '备注（可选）'),
              ),
              if (_error.value != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error.value!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }

  Future<void> _pickDate() async {
    final value = await showCupertinoDatePicker(
      context: context,
      initialDate: _date.value,
      minimumDate: DateTime(2000),
      maximumDate: DateTime.now(),
    );
    if (value != null) _date.value = value;
  }

  Future<void> _pickTime({required bool first}) async {
    final value = await showCupertinoTimePicker(
      context: context,
      initialTime: first ? _firstTime.value : _lastTime.value,
    );
    if (value == null) return;
    if (first) {
      _firstTime.value = value;
    } else {
      _lastTime.value = value;
    }
  }

  void _submit() {
    final date = _date.value;
    final first = _combine(date, _firstTime.value);
    final last = _combine(date, _lastTime.value);
    if (last.isBefore(first)) {
      _error.value = '末次签到时间不能早于首次签到时间';
      return;
    }
    Navigator.pop(
      context,
      AttendanceRecord(
        id: widget.record?.id,
        date: date,
        firstCheckIn: first,
        lastCheckIn: last,
        note: _noteController.text.trim(),
        isManual: true,
      ),
    );
  }

  DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
