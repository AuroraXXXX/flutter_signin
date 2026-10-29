import '../models/attendance_record.dart';
import '../models/attendance_settings.dart';
import '../models/holiday_calendar.dart';
import '../models/monthly_attendance_summary.dart';
import '../extensions/attendance_record_extensions.dart';
import '../services/date_time_service.dart';
import 'calculate_attendance.dart';

/// 根据年度作息表汇总某月的工作日和有效工时。
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
    final firstDay = DateTimeService.monthOnly(month);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final currentDay = DateTimeService.dateOnly(now);
    final isCurrentMonth = DateTimeService.isSameMonth(month, now);
    // 当前月只统计到今天，历史月份则统计整月。
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

      final record = records.forDate(day);
      if (record == null) continue;
      checkedDayCount++;
      totalValidMinutes += attendanceCalculator(
        record,
        settings,
      ).validDuration.inMinutes;
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

  // 作息表中的调休工作日优先级高于星期几；未标记日期按周一至周五处理。
  bool _isWorkday(DateTime date, HolidayCalendarYear calendar) {
    final entry = calendar.entryFor(date);
    if (entry != null) {
      return entry.type == HolidayDateType.transferWorkday;
    }
    return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
  }
}
