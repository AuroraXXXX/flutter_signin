import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_factory.dart';

class AttendanceDatabase {
  AttendanceDatabase._(this.database);

  final Database database;

  static Future<AttendanceDatabase> open({String? path}) async {
    final factory = createDatabaseFactory();
    final databasePath =
        path ?? p.join(await factory.getDatabasesPath(), 'attendance.db');
    final database = await factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE attendance_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date_key TEXT NOT NULL UNIQUE,
              first_check_in TEXT NOT NULL,
              last_check_in TEXT NOT NULL,
              note TEXT NOT NULL DEFAULT '',
              is_manual INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE attendance_settings (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              minimum_minutes INTEGER NOT NULL,
              first_window_start INTEGER NOT NULL,
              first_window_end INTEGER NOT NULL,
              last_window_start INTEGER NOT NULL,
              last_window_end INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE excluded_time_ranges (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              start_minute INTEGER NOT NULL,
              end_minute INTEGER NOT NULL,
              sort_order INTEGER NOT NULL
            )
          ''');
          await _createHolidayTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createHolidayTables(db);
          }
        },
      ),
    );
    return AttendanceDatabase._(database);
  }

  static Future<void> _createHolidayTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE holiday_calendar_years (
        year INTEGER PRIMARY KEY,
        region TEXT NOT NULL,
        source TEXT NOT NULL,
        imported_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE holiday_calendar (
        date_key TEXT PRIMARY KEY,
        year INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY (year) REFERENCES holiday_calendar_years(year)
      )
    ''');
    await db.execute(
      'CREATE INDEX holiday_calendar_year_idx ON holiday_calendar(year)',
    );
  }
}
