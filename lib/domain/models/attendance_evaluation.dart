enum AttendanceIssue {
  firstOutsideWindow,
  lastOutsideWindow,
  insufficientDuration,
}

class AttendanceEvaluation {
  const AttendanceEvaluation({
    required this.validMinutes,
    required this.excludedMinutes,
    required this.isInProgress,
    required this.issues,
  });

  final int validMinutes;
  final int excludedMinutes;
  final bool isInProgress;
  final List<AttendanceIssue> issues;

  bool get isValid => !isInProgress && issues.isEmpty;
}
