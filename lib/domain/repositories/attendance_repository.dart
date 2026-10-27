import '../models/attendance_record.dart';

abstract interface class AttendanceRepository {
  Future<List<AttendanceRecord>> getAll();

  Future<AttendanceRecord?> getByDate(DateTime date);

  Future<AttendanceRecord> save(AttendanceRecord record);

  Future<void> saveAll(
    List<AttendanceRecord> records, {
    required bool overwrite,
  });

  Future<void> delete(int id);
}
