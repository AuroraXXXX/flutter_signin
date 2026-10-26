import '../models/holiday_calendar.dart';

abstract interface class HolidayCalendarService {
  Future<HolidayCalendarYear> fetchYear(int year);

  HolidayCalendarYear parseJson(String json, {required String source});
}
