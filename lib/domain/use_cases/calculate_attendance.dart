import '../models/attendance_evaluation.dart';
import '../models/attendance_record.dart';
import '../models/attendance_settings.dart';

class CalculateAttendance {
  const CalculateAttendance();

  AttendanceEvaluation call(
    AttendanceRecord record,
    AttendanceSettings settings,
  ) {
    final firstMinute = _minuteOfDay(record.firstCheckIn);
    final lastMinute = _minuteOfDay(record.lastCheckIn);
    final isInProgress = record.firstCheckIn.isAtSameMomentAs(
      record.lastCheckIn,
    );
    final issues = <AttendanceIssue>[];

    if (!_inside(
      firstMinute,
      settings.firstWindowStart,
      settings.firstWindowEnd,
    )) {
      issues.add(AttendanceIssue.firstOutsideWindow);
    }

    if (isInProgress) {
      return AttendanceEvaluation(
        validMinutes: 0,
        excludedMinutes: 0,
        isInProgress: true,
        issues: issues,
      );
    }

    if (!_inside(
      lastMinute,
      settings.lastWindowStart,
      settings.lastWindowEnd,
    )) {
      issues.add(AttendanceIssue.lastOutsideWindow);
    }

    final totalMinutes = record.lastCheckIn
        .difference(record.firstCheckIn)
        .inMinutes;
    final excludedMinutes = _excludedMinutes(
      firstMinute,
      lastMinute,
      settings.excludedRanges,
    );
    final validMinutes = (totalMinutes - excludedMinutes).clamp(0, 1440);
    if (validMinutes < settings.minimumMinutes) {
      issues.add(AttendanceIssue.insufficientDuration);
    }

    return AttendanceEvaluation(
      validMinutes: validMinutes,
      excludedMinutes: excludedMinutes,
      isInProgress: false,
      issues: issues,
    );
  }

  int _excludedMinutes(
    int firstMinute,
    int lastMinute,
    List<ExcludedTimeRange> ranges,
  ) {
    if (lastMinute <= firstMinute) return 0;

    final intersections =
        ranges
            .map(
              (range) => (
                start: range.startMinute.clamp(firstMinute, lastMinute),
                end: range.endMinute.clamp(firstMinute, lastMinute),
              ),
            )
            .where((range) => range.end > range.start)
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    if (intersections.isEmpty) return 0;

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
    return total + currentEnd - currentStart;
  }

  int _minuteOfDay(DateTime value) => value.hour * 60 + value.minute;

  bool _inside(int value, int start, int end) => value >= start && value <= end;
}
