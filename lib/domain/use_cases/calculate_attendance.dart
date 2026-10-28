import '../models/attendance_evaluation.dart';
import '../models/attendance_record.dart';
import '../models/attendance_settings.dart';

/// 按签到设置评估一条记录，纯计算，不读写数据库。
class CalculateAttendance {
  const CalculateAttendance();

  AttendanceEvaluation call(
    AttendanceRecord record,
    AttendanceSettings settings, {
    DateTime? now,
  }) {
    // 窗口判断使用本地墙上时间；时长计算则优先使用 UTC 时间。
    final firstMinute = _minuteOfDay(record.firstCheckIn);
    final lastMinute = _minuteOfDay(record.lastCheckIn);
    final isInProgress = record.firstCheckIn.isAtSameMomentAs(
      record.lastCheckIn,
    );
    final issues = <AttendanceIssue>[];
    final statuses = <AttendanceStatus>[];

    // 只有首次签到时，记录只是“进行中”，暂不判断末次时间和最低工时。
    if (isInProgress) {
      if (!_inside(
        firstMinute,
        settings.firstWindowStart,
        settings.firstWindowEnd,
      )) {
        issues.add(AttendanceIssue.firstOutsideWindow);
      }
      final isPastDay =
          now != null &&
          DateTime(now.year, now.month, now.day).isAfter(
            DateTime(record.date.year, record.date.month, record.date.day),
          );
      return AttendanceEvaluation(
        validDuration: Duration.zero,
        excludedDuration: Duration.zero,
        isInProgress: true,
        issues: issues,
        statuses: isPastDay
            ? const [AttendanceStatus.missingCard]
            : (firstMinute > settings.firstWindowEnd
                  ? const [AttendanceStatus.late]
                  : const []),
      );
    }

    if (!_inside(
      firstMinute,
      settings.firstWindowStart,
      settings.firstWindowEnd,
    )) {
      issues.add(AttendanceIssue.firstOutsideWindow);
      if (firstMinute > settings.firstWindowEnd) {
        statuses.add(AttendanceStatus.late);
      }
    }

    if (!_inside(
      lastMinute,
      settings.lastWindowStart,
      settings.lastWindowEnd,
    )) {
      issues.add(AttendanceIssue.lastOutsideWindow);
      if (lastMinute < settings.lastWindowStart) {
        statuses.add(AttendanceStatus.earlyLeave);
      }
    }

    // 真实时长使用 UTC 差值，避免两个本地时间来自不同时区时计算错误。
    final totalDuration = (record.lastCheckInUtc ?? record.lastCheckIn)
        .difference(record.firstCheckInUtc ?? record.firstCheckIn);
    final excludedDuration = _excludedDuration(
      record.firstCheckIn,
      record.lastCheckIn,
      settings.excludedRanges,
    );
    final validDuration = totalDuration - excludedDuration;
    final boundedDuration = validDuration < Duration.zero
        ? Duration.zero
        : validDuration > const Duration(days: 1)
        ? const Duration(days: 1)
        : validDuration;
    if (boundedDuration < Duration(minutes: settings.minimumMinutes)) {
      issues.add(AttendanceIssue.insufficientDuration);
    }

    if (statuses.isEmpty && issues.isEmpty) {
      statuses.add(AttendanceStatus.normal);
    }

    return AttendanceEvaluation(
      validDuration: boundedDuration,
      excludedDuration: excludedDuration,
      isInProgress: false,
      issues: issues,
      statuses: statuses,
    );
  }

  Duration _excludedDuration(
    DateTime first,
    DateTime last,
    List<ExcludedTimeRange> ranges,
  ) {
    final firstSecond = _secondOfDay(first);
    final lastSecond = _secondOfDay(last);
    if (lastSecond <= firstSecond) return Duration.zero;

    // 先求每个排除区间与签到区间的交集，再合并重叠区间，避免重复扣除。
    final intersections =
        ranges
            .map(
              (range) => (
                start: (range.startMinute * 60).clamp(firstSecond, lastSecond),
                end: (range.endMinute * 60).clamp(firstSecond, lastSecond),
              ),
            )
            .where((range) => range.end > range.start)
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    if (intersections.isEmpty) return Duration.zero;

    var total = 0;
    var currentStart = intersections.first.start;
    var currentEnd = intersections.first.end;
    for (final range in intersections.skip(1)) {
      if (range.start <= currentEnd) {
        if (range.end > currentEnd) currentEnd = range.end;
      } else {
        total += currentEnd - currentStart;
        currentStart = range.start;
        currentEnd = range.end;
      }
    }
    return Duration(seconds: total + currentEnd - currentStart);
  }

  int _minuteOfDay(DateTime value) => value.hour * 60 + value.minute;

  int _secondOfDay(DateTime value) =>
      value.hour * 3600 + value.minute * 60 + value.second;

  bool _inside(int value, int start, int end) => value >= start && value <= end;
}
