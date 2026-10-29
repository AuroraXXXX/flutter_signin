import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../app_store.dart';
import '../../core/formatters.dart';
import '../../core/snackbars.dart';

/// 今日签到页：展示当前记录、考勤评估结果并执行签到操作。
class CheckInPage extends SignalWidget {
  const CheckInPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final record = store.todayRecord.value;
    final evaluation = record == null ? null : store.evaluate(record);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('今日签到')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.list(
              children: [
                _CurrentTimeCard(store: store),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _TimeRow(
                          label: '首次签到',
                          value: record == null
                              ? '--:--'
                              : formatTime(record.firstCheckIn),
                        ),
                        const Divider(height: 28),
                        _TimeRow(
                          label: '末次签到',
                          value:
                              record == null ||
                                  record.lastCheckIn == record.firstCheckIn
                              ? '--:--'
                              : formatTime(record.lastCheckIn),
                        ),
                        const Divider(height: 28),
                        _TimeRow(
                          label: '有效工时',
                          value: evaluation == null || evaluation.isInProgress
                              ? '--'
                              : formatDuration(evaluation.validDuration),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (record == null)
                  const _StatusBanner(label: '今日尚未签到', icon: Icons.schedule)
                else if (evaluation!.isInProgress)
                  _StatusBanner(
                    label: evaluation.issues.isEmpty
                        ? '签到进行中'
                        : evaluation.issues.map(issueLabel).join('、'),
                    icon: evaluation.issues.isEmpty
                        ? Icons.timelapse
                        : Icons.warning_amber,
                    isWarning: evaluation.issues.isNotEmpty,
                  )
                else if (evaluation.isValid)
                  const _StatusBanner(label: '今日签到正常', icon: Icons.check_circle)
                else
                  _StatusBanner(
                    label: evaluation.issues.map(issueLabel).join('、'),
                    icon: Icons.warning_amber,
                    isWarning: true,
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => _checkIn(context),
                    icon: const Icon(Icons.fingerprint),
                    label: Text(record == null ? '首次签到' : '更新末次签到'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkIn(BuildContext context) async {
    try {
      final first = await store.checkIn();
      if (!context.mounted) return;
      context.showMessage(first ? '首次签到成功' : '末次签到时间已更新');
    } catch (error) {
      if (!context.mounted) return;
      context.showError('签到失败：$error');
    }
  }
}

class _CurrentTimeCard extends SignalStatefulWidget {
  const _CurrentTimeCard({required this.store});

  final AppStore store;

  @override
  State<_CurrentTimeCard> createState() => _CurrentTimeCardState();
}

class _CurrentTimeCardState extends State<_CurrentTimeCard>
    with WidgetsBindingObserver {
  final _now = signal(DateTime.now());
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 当前时间卡片独立刷新，避免每秒重建整个签到页面。
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _refreshClock();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _now.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshClock();
  }

  void _refreshClock() {
    final now = DateTime.now();
    widget.store.refreshTodayDate();
    _now.value = now;
  }

  @override
  Widget build(BuildContext context) {
    final now = _now.value;
    final seconds = now.second.toString().padLeft(2, '0');
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              formatDate(now),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${formatTime(now)}:$seconds',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.label,
    required this.icon,
    this.isWarning = false,
  });

  final String label;
  final IconData icon;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isWarning ? colors.error : colors.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
