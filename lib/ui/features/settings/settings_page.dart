import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../domain/models/attendance_settings.dart';
import '../../../domain/services/attendance_csv_service.dart';
import '../../app_store.dart';
import '../../core/app_logo.dart';
import '../../core/cupertino_picker_sheet.dart';
import '../../core/formatters.dart';
import '../../core/snackbars.dart';

/// 考勤规则、数据导入导出和年度作息表管理页。
class SettingsPage extends SignalStatefulWidget {
  const SettingsPage({super.key, required this.store});

  final AppStore store;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 先编辑草稿，点击“保存”后才写入数据库和 AppStore。
  late final Signal<AttendanceSettings> _draft;
  final _isSaving = signal(false);

  @override
  void initState() {
    super.initState();
    _draft = signal(widget.store.settings.value);
  }

  @override
  void dispose() {
    _draft.dispose();
    _isSaving.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('签到设置'),
        actions: [
          TextButton(
            onPressed: _isSaving.value ? null : _save,
            child: Text(_isSaving.value ? '保存中…' : '保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _AboutAppCard(),
          const SizedBox(height: 20),
          Text('最低有效工时', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('达到该时长才算有效'),
                      Text(
                        formatMinutes(_draft.value.minimumMinutes),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _draft.value.minimumMinutes.toDouble().clamp(
                      60,
                      960,
                    ),
                    min: 60,
                    max: 960,
                    divisions: 30,
                    label: formatMinutes(_draft.value.minimumMinutes),
                    onChanged: (value) => _draft.value = _draft.value.copyWith(
                      minimumMinutes: value.round(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('签到时间范围', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('首次签到范围'),
                  subtitle: Text(
                    '${formatMinuteOfDay(_draft.value.firstWindowStart)} - '
                    '${formatMinuteOfDay(_draft.value.firstWindowEnd)}',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _editWindow(first: true),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('末次签到范围'),
                  subtitle: Text(
                    '${formatMinuteOfDay(_draft.value.lastWindowStart)} - '
                    '${formatMinuteOfDay(_draft.value.lastWindowEnd)}',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _editWindow(first: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('每日排除时段', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => _editExcludedRange(null),
                icon: const Icon(Icons.add),
                label: const Text('添加'),
              ),
            ],
          ),
          Text(
            '与签到区间重叠的部分不会计入有效工时。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (_draft.value.excludedRanges.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('暂无排除时段')),
              ),
            )
          else
            ..._draft.value.excludedRanges.indexed.map((entry) {
              final index = entry.$1;
              final range = entry.$2;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.free_breakfast),
                  title: Text(
                    '${formatMinuteOfDay(range.startMinute)} - '
                    '${formatMinuteOfDay(range.endMinute)}',
                  ),
                  onTap: () => _editExcludedRange(index),
                  trailing: IconButton(
                    tooltip: '删除',
                    onPressed: () => _removeRange(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),
          Text('签到数据', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('导出全部签到记录'),
                  subtitle: Text(
                    '共 ${widget.store.records.value.length} 条记录，CSV 格式',
                  ),
                  onTap: _exportAttendanceCsv,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('从 CSV 导入签到记录'),
                  subtitle: const Text('支持覆盖或跳过已有日期'),
                  onTap: _importAttendanceCsv,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('国家作息表', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.event_available),
                  title: Text(
                    '${widget.store.selectedHistoryMonth.value.year} 年中国作息表',
                  ),
                  subtitle: Text(_calendarStatus()),
                ),
                const Divider(height: 1),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: widget.store.isCalendarLoading.value
                          ? null
                          : () => widget.store.loadCalendarForSelectedMonth(
                              forceSync: true,
                            ),
                      icon: const Icon(Icons.sync),
                      label: const Text('在线同步'),
                    ),
                    TextButton.icon(
                      onPressed: _importJson,
                      icon: const Icon(Icons.content_paste),
                      label: const Text('粘贴 JSON 导入'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calendarStatus() {
    if (widget.store.isCalendarLoading.value) return '正在同步…';
    final calendar = widget.store.holidayCalendar.value;
    if (calendar != null &&
        calendar.year == widget.store.selectedHistoryMonth.value.year) {
      return '已加载 ${calendar.dates.length} 个特殊日期 · '
          '${formatDate(calendar.importedAt)} ${formatTime(calendar.importedAt)}';
    }
    return widget.store.calendarError.value ?? '尚未加载';
  }

  Future<void> _exportAttendanceCsv() async {
    try {
      final range = await _selectExportRange();
      if (range == null || !mounted) return;
      final now = DateTime.now();
      final fileRange = range.isAll
          ? '全部'
          : '${formatCompactDate(range.start!)}_${formatCompactDate(range.end!)}';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: '导出签到记录',
        fileName:
            '签到记录_${fileRange}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: widget.store.exportAttendanceCsv(
          startDate: range.start,
          endDate: range.end,
        ),
      );
      if (!mounted || path == null) return;
      context.showMessage('签到记录导出成功');
    } catch (error) {
      if (!mounted) return;
      context.showError('CSV 导出失败：$error');
    }
  }

  Future<_ExportRange?> _selectExportRange() async {
    final records = widget.store.records.value;
    DateTime start = DateTime.now();
    DateTime end = start;
    if (records.isNotEmpty) {
      final dates = records.map((record) => record.date).toList()
        ..sort((a, b) => a.compareTo(b));
      start = DateTime(dates.first.year, dates.first.month, dates.first.day);
      end = DateTime(dates.last.year, dates.last.month, dates.last.day);
    }
    var isAll = true;
    final result = await showDialog<_ExportRange>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('选择导出日期范围'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('导出全部记录'),
                value: isAll,
                onChanged: (value) => setState(() => isAll = value ?? true),
              ),
              if (!isAll) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('开始日期'),
                  trailing: Text(formatDate(start)),
                  onTap: () async {
                    final value = await showDatePicker(
                      context: context,
                      initialDate: start,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (value != null) setState(() => start = value);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('结束日期'),
                  trailing: Text(formatDate(end)),
                  onTap: () async {
                    final value = await showDatePicker(
                      context: context,
                      initialDate: end,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (value != null) setState(() => end = value);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (!isAll && start.isAfter(end)) return;
                Navigator.pop(
                  context,
                  _ExportRange(
                    isAll: isAll,
                    start: isAll ? null : start,
                    end: isAll ? null : end,
                  ),
                );
              },
              child: const Text('导出'),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  Future<void> _importAttendanceCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.single.bytes == null || !mounted) {
        return;
      }
      final csv = utf8.decode(
        result.files.single.bytes!,
        allowMalformed: false,
      );
      final imported = widget.store.parseAttendanceCsv(csv);
      if (imported.isEmpty) {
        throw const AttendanceCsvException('CSV 中没有签到记录');
      }
      // 先统计重复日期，再让用户选择覆盖或跳过，避免无提示地覆盖数据。
      final existing = imported.where((record) {
        return widget.store.recordFor(record.date) != null;
      }).length;
      final action = await _askImportAction(imported.length, existing);
      if (action == null || action == _ImportAction.cancel || !mounted) {
        return;
      }
      final overwrite = action == _ImportAction.overwrite;
      await widget.store.saveImportedAttendance(imported, overwrite: overwrite);
      if (!mounted) return;
      final count = overwrite ? imported.length : imported.length - existing;
      context.showMessage('CSV 导入成功：新增或更新 $count 条记录');
    } catch (error) {
      if (!mounted) return;
      context.showError('CSV 导入失败：$error');
    }
  }

  Future<_ImportAction?> _askImportAction(int total, int existing) {
    if (existing == 0) return Future.value(_ImportAction.overwrite);
    return showDialog<_ImportAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发现重复日期'),
        content: Text('CSV 共 $total 条记录，其中 $existing 条已存在。请选择处理方式。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _ImportAction.cancel),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ImportAction.skip),
            child: const Text('跳过已有'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _ImportAction.overwrite),
            child: const Text('覆盖已有'),
          ),
        ],
      ),
    );
  }

  Future<void> _importJson() async {
    final controller = TextEditingController();
    final json = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入国家作息表 JSON'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            minLines: 8,
            maxLines: 14,
            decoration: const InputDecoration(
              hintText: '粘贴 holiday-calendar 的 CN 年度 JSON 内容',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (json == null || json.trim().isEmpty || !mounted) return;
    try {
      final calendar = await widget.store.importHolidayCalendarJson(json);
      if (!mounted) return;
      context.showMessage('${calendar.year} 年作息表导入成功');
    } catch (error) {
      if (!mounted) return;
      context.showError('JSON 导入失败：$error');
    }
  }

  Future<void> _editWindow({required bool first}) async {
    final value = await showDialog<ExcludedTimeRange>(
      context: context,
      builder: (context) => TimeRangeDialog(
        title: first ? '首次签到范围' : '末次签到范围',
        initial: ExcludedTimeRange(
          startMinute: first
              ? _draft.value.firstWindowStart
              : _draft.value.lastWindowStart,
          endMinute: first
              ? _draft.value.firstWindowEnd
              : _draft.value.lastWindowEnd,
        ),
      ),
    );
    if (value == null) return;
    _draft.value = first
        ? _draft.value.copyWith(
            firstWindowStart: value.startMinute,
            firstWindowEnd: value.endMinute,
          )
        : _draft.value.copyWith(
            lastWindowStart: value.startMinute,
            lastWindowEnd: value.endMinute,
          );
  }

  Future<void> _editExcludedRange(int? index) async {
    final value = await showDialog<ExcludedTimeRange>(
      context: context,
      builder: (context) => TimeRangeDialog(
        title: index == null ? '添加排除时段' : '编辑排除时段',
        initial: index == null
            ? const ExcludedTimeRange(startMinute: 720, endMinute: 780)
            : _draft.value.excludedRanges[index],
      ),
    );
    if (value == null) return;
    final ranges = [..._draft.value.excludedRanges];
    if (index == null) {
      ranges.add(value);
    } else {
      ranges[index] = value;
    }
    // 保持列表有序，数据库中的 sort_order 和设置页显示顺序一致。
    ranges.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    _draft.value = _draft.value.copyWith(excludedRanges: ranges);
  }

  void _removeRange(int index) {
    final ranges = [..._draft.value.excludedRanges]..removeAt(index);
    _draft.value = _draft.value.copyWith(excludedRanges: ranges);
  }

  Future<void> _save() async {
    _isSaving.value = true;
    try {
      await widget.store.saveSettings(_draft.value);
      if (!mounted) return;
      context.showMessage('设置已保存，历史状态已按新规则更新');
    } catch (error) {
      if (!mounted) return;
      context.showError('设置保存失败：$error');
    } finally {
      if (mounted) _isSaving.value = false;
    }
  }
}

class _ExportRange {
  const _ExportRange({required this.isAll, this.start, this.end});

  final bool isAll;
  final DateTime? start;
  final DateTime? end;
}

enum _ImportAction { overwrite, skip, cancel }

/// 设置页顶部的应用信息卡片，展示与应用启动图标一致的品牌图标。
class _AboutAppCard extends StatelessWidget {
  const _AboutAppCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const AppLogo(size: 64, borderRadius: 16),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('签到系统', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('记录每日签到与有效工时', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeRangeDialog extends SignalStatefulWidget {
  const TimeRangeDialog({
    super.key,
    required this.title,
    required this.initial,
  });

  final String title;
  final ExcludedTimeRange initial;

  @override
  State<TimeRangeDialog> createState() => _TimeRangeDialogState();
}

class _TimeRangeDialogState extends State<TimeRangeDialog> {
  late final Signal<TimeOfDay> _start;
  late final Signal<TimeOfDay> _end;
  final _error = signal<String?>(null);

  @override
  void initState() {
    super.initState();
    _start = signal(_fromMinute(widget.initial.startMinute));
    _end = signal(_fromMinute(widget.initial.endMinute));
  }

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _error.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('开始时间'),
            trailing: Text(_start.value.format(context)),
            onTap: () => _pick(start: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('结束时间'),
            trailing: Text(_end.value.format(context)),
            onTap: () => _pick(start: false),
          ),
          if (_error.value != null)
            Text(
              _error.value!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('确定')),
      ],
    );
  }

  Future<void> _pick({required bool start}) async {
    final value = await showCupertinoTimePicker(
      context: context,
      initialTime: start ? _start.value : _end.value,
    );
    if (value == null) return;
    if (start) {
      _start.value = value;
    } else {
      _end.value = value;
    }
  }

  void _submit() {
    final start = _toMinute(_start.value);
    final end = _toMinute(_end.value);
    if (end <= start) {
      _error.value = '结束时间必须晚于开始时间';
      return;
    }
    Navigator.pop(
      context,
      ExcludedTimeRange(startMinute: start, endMinute: end),
    );
  }

  TimeOfDay _fromMinute(int value) =>
      TimeOfDay(hour: value ~/ 60, minute: value % 60);
  int _toMinute(TimeOfDay value) => value.hour * 60 + value.minute;
}
