enum HolidayDateType {
  publicHoliday('public_holiday'),
  transferWorkday('transfer_workday');

  const HolidayDateType(this.jsonValue);

  final String jsonValue;

  static HolidayDateType parse(String value) => switch (value) {
    'public_holiday' => HolidayDateType.publicHoliday,
    'transfer_workday' => HolidayDateType.transferWorkday,
    _ => throw FormatException('不支持的日期类型：$value'),
  };
}

class HolidayDate {
  const HolidayDate({
    required this.date,
    required this.name,
    required this.type,
  });

  final DateTime date;
  final String name;
  final HolidayDateType type;
}

class HolidayCalendarYear {
  const HolidayCalendarYear({
    required this.year,
    required this.region,
    required this.dates,
    required this.source,
    required this.importedAt,
  });

  final int year;
  final String region;
  final List<HolidayDate> dates;
  final String source;
  final DateTime importedAt;

  HolidayDate? entryFor(DateTime date) {
    for (final entry in dates) {
      if (entry.date.year == date.year &&
          entry.date.month == date.month &&
          entry.date.day == date.day) {
        return entry;
      }
    }
    return null;
  }
}
