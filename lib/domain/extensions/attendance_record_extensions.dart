import '../models/attendance_record.dart';
import '../services/date_time_service.dart';

extension AttendanceRecordIterable on Iterable<AttendanceRecord> {
  AttendanceRecord? forDate(DateTime date) {
    for (final record in this) {
      if (DateTimeService.isSameDate(record.date, date)) return record;
    }
    return null;
  }
}
