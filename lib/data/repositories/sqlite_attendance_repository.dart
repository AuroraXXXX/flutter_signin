import '../../domain/models/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../services/attendance_database.dart';

class SqliteAttendanceRepository implements AttendanceRepository {
  const SqliteAttendanceRepository(this._database);

  final AttendanceDatabase _database;

  @override
  Future<List<AttendanceRecord>> getAll() async {
    final rows = await _database.database.query(
      'attendance_records',
      orderBy: 'date_key DESC',
    );
    return rows.map(_fromMap).toList();
  }

  @override
  Future<AttendanceRecord?> getByDate(DateTime date) async {
    final rows = await _database.database.query(
      'attendance_records',
      where: 'date_key = ?',
      whereArgs: [_dateKey(date)],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromMap(rows.first);
  }

  @override
  Future<AttendanceRecord> save(AttendanceRecord record) async {
    final now = DateTime.now().toIso8601String();
    final values = <String, Object?>{
      'date_key': _dateKey(record.date),
      'first_check_in': record.firstCheckIn.toIso8601String(),
      'last_check_in': record.lastCheckIn.toIso8601String(),
      'note': record.note,
      'is_manual': record.isManual ? 1 : 0,
      'updated_at': now,
    };

    if (record.id == null) {
      values['created_at'] = now;
      final id = await _database.database.insert('attendance_records', values);
      return record.copyWith(id: id);
    }

    await _database.database.update(
      'attendance_records',
      values,
      where: 'id = ?',
      whereArgs: [record.id],
    );
    return record;
  }

  @override
  Future<void> delete(int id) async {
    await _database.database.delete(
      'attendance_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  AttendanceRecord _fromMap(Map<String, Object?> map) {
    final firstCheckIn = DateTime.parse(map['first_check_in']! as String);
    return AttendanceRecord(
      id: map['id']! as int,
      date: DateTime(firstCheckIn.year, firstCheckIn.month, firstCheckIn.day),
      firstCheckIn: firstCheckIn,
      lastCheckIn: DateTime.parse(map['last_check_in']! as String),
      note: map['note']! as String,
      isManual: map['is_manual'] == 1,
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
