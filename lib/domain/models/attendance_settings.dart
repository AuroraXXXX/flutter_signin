class ExcludedTimeRange {
  const ExcludedTimeRange({
    this.id,
    required this.startMinute,
    required this.endMinute,
  });

  final int? id;
  final int startMinute;
  final int endMinute;
}

class AttendanceSettings {
  const AttendanceSettings({
    this.minimumMinutes = 480,
    this.firstWindowStart = 480,
    this.firstWindowEnd = 570,
    this.lastWindowStart = 1020,
    this.lastWindowEnd = 1200,
    this.excludedRanges = const [
      ExcludedTimeRange(startMinute: 720, endMinute: 780),
    ],
  });

  final int minimumMinutes;
  final int firstWindowStart;
  final int firstWindowEnd;
  final int lastWindowStart;
  final int lastWindowEnd;
  final List<ExcludedTimeRange> excludedRanges;

  AttendanceSettings copyWith({
    int? minimumMinutes,
    int? firstWindowStart,
    int? firstWindowEnd,
    int? lastWindowStart,
    int? lastWindowEnd,
    List<ExcludedTimeRange>? excludedRanges,
  }) {
    return AttendanceSettings(
      minimumMinutes: minimumMinutes ?? this.minimumMinutes,
      firstWindowStart: firstWindowStart ?? this.firstWindowStart,
      firstWindowEnd: firstWindowEnd ?? this.firstWindowEnd,
      lastWindowStart: lastWindowStart ?? this.lastWindowStart,
      lastWindowEnd: lastWindowEnd ?? this.lastWindowEnd,
      excludedRanges: excludedRanges ?? this.excludedRanges,
    );
  }
}
