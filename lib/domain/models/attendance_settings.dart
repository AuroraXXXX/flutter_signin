/// 不计入有效工时的每日时间段，例如午休。
class ExcludedTimeRange {
  const ExcludedTimeRange({
    this.id,
    required this.startMinute,
    required this.endMinute,
  });

  final int? id;
  // 时间以当天 00:00 起经过的分钟数表示，例如 08:00 是 480。
  final int startMinute;
  final int endMinute;
}

/// 考勤计算所需的全部规则。
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
