/// 月度考勤统计结果。
class MonthlyAttendanceSummary {
  const MonthlyAttendanceSummary({
    required this.workdayCount,
    required this.checkedDayCount,
    required this.missedDayCount,
    required this.totalValidMinutes,
    required this.averageValidMinutes,
  });

  final int workdayCount;
  // 统计区间内所有存在签到记录的日期，包括休假日签到。
  final int checkedDayCount;
  // 已过去的应上班日期中没有签到记录的天数，不包含今天。
  final int missedDayCount;
  final int totalValidMinutes;
  final int averageValidMinutes;
}
