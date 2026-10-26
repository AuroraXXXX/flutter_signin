class MonthlyAttendanceSummary {
  const MonthlyAttendanceSummary({
    required this.workdayCount,
    required this.checkedDayCount,
    required this.missedDayCount,
    required this.totalValidMinutes,
    required this.averageValidMinutes,
  });

  final int workdayCount;
  final int checkedDayCount;
  final int missedDayCount;
  final int totalValidMinutes;
  final int averageValidMinutes;
}
