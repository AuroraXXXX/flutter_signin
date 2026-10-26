class AttendanceRecord {
  const AttendanceRecord({
    this.id,
    required this.date,
    required this.firstCheckIn,
    required this.lastCheckIn,
    this.note = '',
    this.isManual = false,
  });

  final int? id;
  final DateTime date;
  final DateTime firstCheckIn;
  final DateTime lastCheckIn;
  final String note;
  final bool isManual;

  AttendanceRecord copyWith({
    int? id,
    DateTime? date,
    DateTime? firstCheckIn,
    DateTime? lastCheckIn,
    String? note,
    bool? isManual,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      firstCheckIn: firstCheckIn ?? this.firstCheckIn,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      note: note ?? this.note,
      isManual: isManual ?? this.isManual,
    );
  }
}
