import '../models/attendance_record.dart';

/// 签到记录的持久化抽象，业务层不依赖具体数据库实现。
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
