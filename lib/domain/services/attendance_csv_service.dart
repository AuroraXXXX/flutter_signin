import '../models/attendance_record.dart';
import 'attendance_time_service.dart';

class AttendanceCsvException implements Exception {
  const AttendanceCsvException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AttendanceCsvService {
  const AttendanceCsvService();

  static const headers = [
    '签到日期',
    '首次签到时间',
    '末次签到时间',
    '备注',
    '时区',
    '签到来源',
    '考勤类别',
  ];

  String encode(
    Iterable<AttendanceRecord> records, {
    Map<String, List<AttendanceStatus>> statuses = const {},
  }) {
    final lines = <String>[_encodeRow(headers)];
    for (final record in records) {
      final key = _dateKey(record.date);
      lines.add(
        _encodeRow([
          key,
          _time(record.firstCheckIn),
          record.firstCheckIn == record.lastCheckIn
              ? ''
              : _time(record.lastCheckIn),
          record.note,
          record.timezone,
          _sourceValue(record.attendanceSource),
          _statusText(statuses[key] ?? const []),
        ]),
      );
    }
    return '\uFEFF${lines.join('\r\n')}\r\n';
  }

  List<AttendanceRecord> decode(String input) {
    final rows = _parse(input.replaceFirst('\uFEFF', ''));
    if (rows.isEmpty ||
        rows.first.length != headers.length ||
        !_sameValues(rows.first, headers)) {
      throw const AttendanceCsvException('CSV 表头不正确');
    }
    final records = <AttendanceRecord>[];
    final dates = <String>{};
    for (var index = 1; index < rows.length; index++) {
      final rowNumber = index + 1;
      final row = rows[index];
      if (row.every((value) => value.trim().isEmpty)) continue;
      if (row.length != headers.length) {
        throw AttendanceCsvException('第 $rowNumber 行字段数量不正确');
      }
      try {
        final date = _parseDate(row[0]);
        final dateKey = _dateKey(date);
        if (!dates.add(dateKey)) {
          throw AttendanceCsvException('第 $rowNumber 行日期重复：$dateKey');
        }
        final statusText = row[6].split('|').where((value) => value.isNotEmpty);
        statusText.map(_parseStatus).toList();
        if (row[1].isEmpty || row[2].isEmpty) {
          throw const AttendanceCsvException('签到记录必须包含首次和末次时间');
        }
        final first = _combine(date, row[1]);
        final last = _combine(date, row[2]);
        if (last.isBefore(first)) {
          throw const AttendanceCsvException('末次签到时间早于首次签到时间');
        }
        if (!RegExp(r'^[+-]\d{2}:\d{2}$').hasMatch(row[4])) {
          throw const AttendanceCsvException('时区必须是如 +08:00 的格式');
        }
        final source = switch (row[5]) {
          'normal' || '正常签到' => AttendanceSource.normal,
          'resign' || '补签' => AttendanceSource.resign,
          _ => throw const AttendanceCsvException('签到来源必须是正常签到或补签'),
        };
        records.add(
          AttendanceRecord(
            date: date,
            firstCheckIn: first,
            lastCheckIn: last,
            note: row[3],
            attendanceSource: source,
            timezone: row[4],
            firstCheckInUtc: AttendanceTimeService.utcFromLocal(
              first,
              AttendanceTimeService.parseOffsetMinutes(row[4]),
            ),
            lastCheckInUtc: AttendanceTimeService.utcFromLocal(
              last,
              AttendanceTimeService.parseOffsetMinutes(row[4]),
            ),
          ),
        );
      } on AttendanceCsvException {
        rethrow;
      } catch (error) {
        throw AttendanceCsvException('第 $rowNumber 行无法解析：$error');
      }
    }
    return records;
  }

  AttendanceStatus _parseStatus(String value) => switch (value) {
    'normal' || '正常' => AttendanceStatus.normal,
    'late' || '迟到' => AttendanceStatus.late,
    'early_leave' || '早退' => AttendanceStatus.earlyLeave,
    'missing_card' || '缺卡' => AttendanceStatus.missingCard,
    _ => throw AttendanceCsvException('不支持的考勤类别：$value'),
  };

  String _statusText(List<AttendanceStatus> statuses) =>
      (statuses.isEmpty ? [AttendanceStatus.normal] : statuses)
          .map(_statusValue)
          .join('|');

  String _statusValue(AttendanceStatus status) => switch (status) {
    AttendanceStatus.normal => '正常',
    AttendanceStatus.late => '迟到',
    AttendanceStatus.earlyLeave => '早退',
    AttendanceStatus.missingCard => '缺卡',
  };

  String _sourceValue(AttendanceSource source) => switch (source) {
    AttendanceSource.normal => '正常签到',
    AttendanceSource.resign => '补签',
  };

  String _encodeRow(Iterable<String> values) => values.map(_escape).join(',');

  String _escape(String value) => value.contains(RegExp(r'[",\r\n]'))
      ? '"${value.replaceAll('"', '""')}"'
      : value;

  List<List<String>> _parse(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < input.length; i++) {
      final character = input[i];
      if (quoted) {
        if (character == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          field.write(character);
        }
      } else if (character == '"' && field.isEmpty) {
        quoted = true;
      } else if (character == ',') {
        row.add(field.toString());
        field.clear();
      } else if (character == '\n' || character == '\r') {
        if (character == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else {
        field.write(character);
      }
    }
    if (quoted) throw const AttendanceCsvException('CSV 引号未闭合');
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  DateTime _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) throw const FormatException('日期必须是 yyyy/MM/dd');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  DateTime _combine(DateTime date, String value) {
    final parts = value.split(':');
    if (parts.length != 3) throw const FormatException('时间必须是 HH:mm:ss');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';

  bool _sameValues(List<String> first, List<String> second) =>
      first.length == second.length &&
      List.generate(
        first.length,
        (index) => first[index].trim() == second[index],
      ).every((value) => value);
}
