import '../../domain/models/attendance_evaluation.dart';

String formatDate(DateTime value) =>
    '${value.year}年${value.month.toString().padLeft(2, '0')}月'
    '${value.day.toString().padLeft(2, '0')}日';

String formatShortDate(DateTime value) =>
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

String formatMinuteOfDay(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:'
    '${(minute % 60).toString().padLeft(2, '0')}';

String formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  return hours == 0 ? '$remaining分钟' : '$hours小时$remaining分钟';
}

String issueLabel(AttendanceIssue issue) => switch (issue) {
  AttendanceIssue.firstOutsideWindow => '首次签到时间异常',
  AttendanceIssue.lastOutsideWindow => '末次签到时间异常',
  AttendanceIssue.insufficientDuration => '有效时长不足',
};
