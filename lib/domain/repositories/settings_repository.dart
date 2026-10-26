import '../models/attendance_settings.dart';

abstract interface class SettingsRepository {
  Future<AttendanceSettings> get();

  Future<void> save(AttendanceSettings settings);
}
