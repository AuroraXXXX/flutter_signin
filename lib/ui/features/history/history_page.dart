import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../domain/models/attendance_record.dart';
import '../../../domain/models/monthly_attendance_summary.dart';
import '../../app_store.dart';
import '../../core/cupertino_picker_sheet.dart';
import '../../core/formatters.dart';

/// 历史记录页，包含月份统计和单日记录详情。
class HistoryPage extends SignalWidget {
  const HistoryPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final records = store.monthlyRecords.value;
    final month = store.selectedHistoryMonth.value;
    // 月度统计依赖所选年份的作息表，作息表未加载时 summary 可能为 null。
    final summary = store.monthlySummary.value;
    return Scaffold(
      appBar: AppBar(title: const Text('签到历史')),
      body: CustomScrollView(
        key: const PageStorageKey('history-list'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            sliver: SliverToBoxAdapter(
              child: _MonthlySummaryCard(
                month: month,
                summary: summary,
                isLoading: store.isCalendarLoading.value,
                error: store.calendarError.value,
                onSelectMonth: () => _selectMonth(context),
                onRetry: () =>
                    store.loadCalendarForSelectedMonth(forceSync: true),
              ),
            ),
          ),
          if (records.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('该月暂无签到记录')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              sliver: SliverList.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final evaluation = store.evaluate(record);
                  final isNormal = evaluation.isValid;
                  return Card(
                    child: ListTile(
                      onTap: () => _showDetails(context, record),
                      leading: CircleAvatar(
                        backgroundColor: isNormal
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.errorContainer,
                        child: Icon(
                          isNormal ? Icons.check : Icons.priority_high,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(formatDate(record.date)),
                          if (record.isManual) ...[
                            const SizedBox(width: 8),
                            const Chip(
                              label: Text('补签'),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${formatTime(record.firstCheckIn)} - '
                        '${formatTime(record.lastCheckIn)}  ·  '
                        '${formatDuration(evaluation.validDuration)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final now = DateTime.now();
    final value = await showCupertinoMonthPicker(
      context: context,
      initialMonth: store.selectedHistoryMonth.value,
      minimumMonth: DateTime(2002),
      maximumMonth: DateTime(now.year, now.month),
    );
    if (value != null) await store.selectHistoryMonth(value);
  }

  Future<void> _showDetails(BuildContext context, AttendanceRecord record) {
    final evaluation = store.evaluate(record);
    final status = evaluation.isInProgress
        ? '进行中'
        : evaluation.isValid
        ? '正常'
        : evaluation.issues.map(issueLabel).join('、');
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDate(record.date),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              _DetailRow(label: '首次签到', value: formatTime(record.firstCheckIn)),
              _DetailRow(label: '末次签到', value: formatTime(record.lastCheckIn)),
              _DetailRow(
                label: '排除时长',
                value: formatDuration(evaluation.excludedDuration),
              ),
              _DetailRow(
                label: '有效工时',
                value: formatDuration(evaluation.validDuration),
              ),
              _DetailRow(label: '状态', value: status),
              if (evaluation.statuses.isNotEmpty)
                _DetailRow(
                  label: '考勤类别',
                  value: evaluation.statuses.map(statusLabel).join('、'),
                ),
              if (record.note.isNotEmpty)
                _DetailRow(label: '备注', value: record.note),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.month,
    required this.summary,
    required this.isLoading,
    required this.error,
    required this.onSelectMonth,
    required this.onRetry,
  });

  final MonthlyAttendanceSummary? summary;
  final DateTime month;
  final bool isLoading;
  final String? error;
  final VoidCallback onSelectMonth;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (summary == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('暂时无法计算月度统计'),
              const SizedBox(height: 4),
              Text(error ?? '缺少该年度作息表'),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.sync),
                label: const Text('重新同步'),
              ),
            ],
          ),
        ),
      );
    }
    final value = summary!;
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: OutlinedButton.icon(
                      onPressed: onSelectMonth,
                      icon: const Icon(Icons.calendar_month),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      label: Text(
                        '${month.year}年${month.month.toString().padLeft(2, '0')}月',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('月平均有效签到时长'),
                      const SizedBox(height: 6),
                      Text(
                        formatMinutes(value.averageValidMinutes),
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryValue(label: '应上班', value: '${value.workdayCount}天'),
                _SummaryValue(label: '有签到', value: '${value.checkedDayCount}天'),
                _SummaryValue(label: '漏签', value: '${value.missedDayCount}天'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
