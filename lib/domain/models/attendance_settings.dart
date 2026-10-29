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

/// 全应用文字大小预设。使用有限档位，避免设置过于复杂。
enum TextSizePreset {
  small,
  standard,
  large,
  extraLarge;

  String get label => switch (this) {
    TextSizePreset.small => '小',
    TextSizePreset.standard => '标准',
    TextSizePreset.large => '大',
    TextSizePreset.extraLarge => '特大',
  };

  double get scale => switch (this) {
    TextSizePreset.small => 0.9,
    TextSizePreset.standard => 1.0,
    TextSizePreset.large => 1.15,
    TextSizePreset.extraLarge => 1.3,
  };
}

/// 考勤计算所需的全部规则。
class AttendanceSettings {
  const AttendanceSettings({
    this.minimumMinutes = 480,
    this.firstWindowStart = 480,
    this.firstWindowEnd = 570,
    this.lastWindowStart = 1020,
    this.lastWindowEnd = 1200,
    this.textSize = TextSizePreset.standard,
    this.excludedRanges = const [
      ExcludedTimeRange(startMinute: 720, endMinute: 780),
    ],
  });

  final int minimumMinutes;
  final int firstWindowStart;
  final int firstWindowEnd;
  final int lastWindowStart;
  final int lastWindowEnd;
  final TextSizePreset textSize;
  final List<ExcludedTimeRange> excludedRanges;

  AttendanceSettings copyWith({
    int? minimumMinutes,
    int? firstWindowStart,
    int? firstWindowEnd,
    int? lastWindowStart,
    int? lastWindowEnd,
    List<ExcludedTimeRange>? excludedRanges,
    TextSizePreset? textSize,
  }) {
    return AttendanceSettings(
      minimumMinutes: minimumMinutes ?? this.minimumMinutes,
      firstWindowStart: firstWindowStart ?? this.firstWindowStart,
      firstWindowEnd: firstWindowEnd ?? this.firstWindowEnd,
      lastWindowStart: lastWindowStart ?? this.lastWindowStart,
      lastWindowEnd: lastWindowEnd ?? this.lastWindowEnd,
      excludedRanges: excludedRanges ?? this.excludedRanges,
      textSize: textSize ?? this.textSize,
    );
  }
}
