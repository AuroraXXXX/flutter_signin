import 'attendance_record.dart';

enum AttendanceIssue {
  firstOutsideWindow,
  lastOutsideWindow,
  insufficientDuration,
}

/// 对单条签到记录应用考勤规则后的结果。
class AttendanceEvaluation {
  const AttendanceEvaluation({
    required this.validDuration,
    required this.excludedDuration,
    required this.isInProgress,
    required this.issues,
    required this.statuses,
  });

  final Duration validDuration;
  final Duration excludedDuration;
  // 只有一次签到时，记录仍处于进行中，不应立即判定工时不足。
  final bool isInProgress;
  final List<AttendanceIssue> issues;
  final List<AttendanceStatus> statuses;

  int get validMinutes => validDuration.inMinutes;

  int get excludedMinutes => excludedDuration.inMinutes;

  bool get isValid => !isInProgress && issues.isEmpty;
}
