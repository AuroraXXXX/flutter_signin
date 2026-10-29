import 'package:sqflite/sqflite.dart';

import '../../domain/models/holiday_calendar.dart';
import '../../domain/repositories/holiday_calendar_repository.dart';
import '../../domain/services/date_time_service.dart';
import '../services/attendance_database.dart';

/// 使用 SQLite 缓存年度节假日和调休数据。
class SqliteHolidayCalendarRepository implements HolidayCalendarRepository {
  const SqliteHolidayCalendarRepository(this._database);

  final AttendanceDatabase _database;

  @override
  Future<HolidayCalendarYear?> getYear(int year) async {
    final yearRows = await _database.database.query(
      'holiday_calendar_years',
      where: 'year = ?',
      whereArgs: [year],
      limit: 1,
    );
    if (yearRows.isEmpty) return null;

    final dateRows = await _database.database.query(
      'holiday_calendar',
      where: 'year = ?',
      whereArgs: [year],
      orderBy: 'date_key ASC',
    );
    final metadata = yearRows.first;
    return HolidayCalendarYear(
      year: year,
      region: metadata['region']! as String,
      source: metadata['source']! as String,
      importedAt: DateTime.parse(metadata['imported_at']! as String),
      dates: dateRows
          .map(
            (row) => HolidayDate(
              date: DateTime.parse(row['date_key']! as String),
              name: row['name']! as String,
              type: HolidayDateType.parse(row['type']! as String),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> saveYear(HolidayCalendarYear calendar) async {
    // 替换整年度数据，避免旧年度条目残留。
    await _database.database.transaction((transaction) async {
      await transaction.delete(
        'holiday_calendar',
        where: 'year = ?',
        whereArgs: [calendar.year],
      );
      await transaction.insert('holiday_calendar_years', {
        'year': calendar.year,
        'region': calendar.region,
        'source': calendar.source,
        'imported_at': calendar.importedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      for (final entry in calendar.dates) {
        await transaction.insert('holiday_calendar', {
          'date_key': DateTimeService.dateKey(entry.date, separator: '-'),
          'year': calendar.year,
          'name': entry.name,
          'type': entry.type.jsonValue,
        });
      }
    });
  }
}
