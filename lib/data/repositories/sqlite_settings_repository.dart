import 'package:sqflite/sqflite.dart';

import '../../domain/models/attendance_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../services/attendance_database.dart';

/// 使用 SQLite 保存考勤规则和排除时段。
class SqliteSettingsRepository implements SettingsRepository {
  const SqliteSettingsRepository(this._database);

  final AttendanceDatabase _database;

  @override
  Future<AttendanceSettings> get() async {
    final settingsRows = await _database.database.query(
      'attendance_settings',
      where: 'id = 1',
      limit: 1,
    );
    if (settingsRows.isEmpty) {
      // 第一次启动时写入默认规则，后续读取即可得到完整配置。
      const defaults = AttendanceSettings();
      await save(defaults);
      return defaults;
    }

    final rangeRows = await _database.database.query(
      'excluded_time_ranges',
      orderBy: 'sort_order ASC',
    );
    final row = settingsRows.first;
    return AttendanceSettings(
      minimumMinutes: row['minimum_minutes']! as int,
      firstWindowStart: row['first_window_start']! as int,
      firstWindowEnd: row['first_window_end']! as int,
      lastWindowStart: row['last_window_start']! as int,
      lastWindowEnd: row['last_window_end']! as int,
      textSize: _textSizeFromValue(row['text_size'] as String?),
      excludedRanges: rangeRows
          .map(
            (range) => ExcludedTimeRange(
              id: range['id']! as int,
              startMinute: range['start_minute']! as int,
              endMinute: range['end_minute']! as int,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> save(AttendanceSettings settings) async {
    // 设置主表和排除时段必须一起更新，避免两者不一致。
    await _database.database.transaction((transaction) async {
      await transaction.insert('attendance_settings', {
        'id': 1,
        'minimum_minutes': settings.minimumMinutes,
        'first_window_start': settings.firstWindowStart,
        'first_window_end': settings.firstWindowEnd,
        'last_window_start': settings.lastWindowStart,
        'last_window_end': settings.lastWindowEnd,
        'text_size': settings.textSize.name,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await transaction.delete('excluded_time_ranges');
      for (var index = 0; index < settings.excludedRanges.length; index++) {
        final range = settings.excludedRanges[index];
        await transaction.insert('excluded_time_ranges', {
          'start_minute': range.startMinute,
          'end_minute': range.endMinute,
          'sort_order': index,
        });
      }
    });
  }

  TextSizePreset _textSizeFromValue(String? value) {
    return TextSizePreset.values.firstWhere(
      (preset) => preset.name == value,
      orElse: () => TextSizePreset.standard,
    );
  }
}
