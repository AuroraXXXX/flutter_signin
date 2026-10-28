import '../../domain/models/attendance_evaluation.dart';
import '../../domain/models/attendance_record.dart';

/// UI 使用的日期、时间和考勤状态中文格式化函数。
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

String formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours小时$minutes分${seconds.toString().padLeft(2, '0')}秒';
  }
  if (minutes > 0) return '$minutes分${seconds.toString().padLeft(2, '0')}秒';
  return '$seconds秒';
}

String formatMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  return hours == 0 ? '$remaining分钟' : '$hours小时$remaining分钟';
}

String issueLabel(AttendanceIssue issue) => switch (issue) {
  AttendanceIssue.firstOutsideWindow => '首次签到时间异常',
  AttendanceIssue.lastOutsideWindow => '末次签到时间异常',
  AttendanceIssue.insufficientDuration => '有效时长不足',
};

String statusLabel(AttendanceStatus status) => switch (status) {
  AttendanceStatus.normal => '正常',
  AttendanceStatus.late => '迟到',
  AttendanceStatus.earlyLeave => '早退',
  AttendanceStatus.missingCard => '缺卡',
};
