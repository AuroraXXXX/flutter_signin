import '../models/attendance_record.dart';
import '../models/attendance_settings.dart';
import '../models/holiday_calendar.dart';
import '../models/monthly_attendance_summary.dart';
import 'calculate_attendance.dart';

class CalculateMonthlySummary {
  const CalculateMonthlySummary({
    this.attendanceCalculator = const CalculateAttendance(),
  });

  final CalculateAttendance attendanceCalculator;

  MonthlyAttendanceSummary call({
    required DateTime month,
    required DateTime now,
    required List<AttendanceRecord> records,
    required AttendanceSettings settings,
    required HolidayCalendarYear calendar,
  }) {
    final firstDay = DateTime(month.year, month.month);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final currentDay = DateTime(now.year, now.month, now.day);
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final endDay = isCurrentMonth && currentDay.isBefore(lastDay)
        ? currentDay
        : lastDay;

    var workdayCount = 0;
    var checkedDayCount = 0;
    var totalValidMinutes = 0;

    for (
      var day = firstDay;
      !day.isAfter(endDay);
      day = day.add(const Duration(days: 1))
    ) {
      if (!_isWorkday(day, calendar)) continue;
      workdayCount++;

      final record = _recordFor(records, day);
      if (record == null) continue;
      checkedDayCount++;
      totalValidMinutes += attendanceCalculator(record, settings).validMinutes;
    }

    return MonthlyAttendanceSummary(
      workdayCount: workdayCount,
      checkedDayCount: checkedDayCount,
      missedDayCount: workdayCount - checkedDayCount,
      totalValidMinutes: totalValidMinutes,
      averageValidMinutes: workdayCount == 0
          ? 0
          : (totalValidMinutes / workdayCount).round(),
    );
  }

  bool _isWorkday(DateTime date, HolidayCalendarYear calendar) {
    final entry = calendar.entryFor(date);
    if (entry != null) {
      return entry.type == HolidayDateType.transferWorkday;
    }
    return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
  }

  AttendanceRecord? _recordFor(List<AttendanceRecord> records, DateTime date) {
    for (final record in records) {
      if (record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day) {
        return record;
      }
    }
    return null;
  }
}
