import '../models/holiday_calendar.dart';

/// 作息表的远程获取和 JSON 解析抽象。
abstract interface class HolidayCalendarService {
  Future<HolidayCalendarYear> fetchYear(int year);

  HolidayCalendarYear parseJson(String json, {required String source});
}
