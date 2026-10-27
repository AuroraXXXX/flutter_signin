import 'attendance_record.dart';

enum AttendanceIssue {
  firstOutsideWindow,
  lastOutsideWindow,
  insufficientDuration,
}

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
  final bool isInProgress;
  final List<AttendanceIssue> issues;
  final List<AttendanceStatus> statuses;

  int get validMinutes => validDuration.inMinutes;

  int get excludedMinutes => excludedDuration.inMinutes;

  bool get isValid => !isInProgress && issues.isEmpty;
}
