import '../models/attendance_settings.dart';

/// 考勤规则的持久化抽象。
abstract interface class SettingsRepository {
  Future<AttendanceSettings> get();

  Future<void> save(AttendanceSettings settings);
}
