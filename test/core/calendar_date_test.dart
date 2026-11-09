import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/calendar_date.dart';

void main() {
  test('epoch day round-trips through year/month/day', () {
    final date = CalendarDate(2026, 11, 9);
    expect(CalendarDate.fromEpochDay(date.epochDay), date);
    expect([date.year, date.month, date.day], [2026, 11, 9]);
    expect(date.toString(), '2026-11-09');
    expect(CalendarDate(1970, 1, 1).epochDay, 0);
  });

  test('day arithmetic crosses month, year and leap day boundaries', () {
    expect(CalendarDate(2026, 12, 31).plusDays(1), CalendarDate(2027, 1, 1));
    expect(CalendarDate(2028, 2, 28).plusDays(1), CalendarDate(2028, 2, 29));
    expect(CalendarDate(2026, 3, 1).daysSince(CalendarDate(2026, 2, 1)), 28);
    expect(CalendarDate(2026, 1, 1).plusDays(-1), CalendarDate(2025, 12, 31));
  });

  test('fromDateTime ignores the time of day', () {
    expect(
      CalendarDate.fromDateTime(DateTime(2026, 3, 29, 23, 59)),
      CalendarDate(2026, 3, 29),
    );
    expect(
      CalendarDate.fromDateTime(DateTime(2026, 3, 29, 0, 0)),
      CalendarDate(2026, 3, 29),
    );
  });

  test('comparisons', () {
    final a = CalendarDate(2026, 11, 9);
    final b = a.plusDays(1);
    expect(a < b && a <= b && b > a && b >= a && a <= a, isTrue);
    expect(CalendarDate.max(a, b), b);
    expect([b, a]..sort(), [a, b]);
  });
}
