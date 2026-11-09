/// A calendar date with no time of day and no time zone.
///
/// Nudge reasons in whole days ("due in 3 days"), so using [DateTime]
/// directly invites off-by-one bugs around midnight and daylight-saving
/// changes. A [CalendarDate] is stored as the number of days since
/// 1970-01-01, which makes day arithmetic exact.
class CalendarDate implements Comparable<CalendarDate> {
  /// Days since 1970-01-01.
  final int epochDay;

  const CalendarDate.fromEpochDay(this.epochDay);

  factory CalendarDate(int year, int month, int day) {
    final utc = DateTime.utc(year, month, day);
    return CalendarDate.fromEpochDay(
      utc.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay,
    );
  }

  /// Parses an ISO 8601 date (`2026-11-09`). Throws [FormatException].
  factory CalendarDate.parse(String text) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) throw FormatException('Not a date: $text');
    final (y, m, d) = (
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
    final date = CalendarDate(y, m, d);
    // Reject impossible dates like 2026-02-30 instead of rolling over.
    if (date.month != m || date.day != d) {
      throw FormatException('Not a valid date: $text');
    }
    return date;
  }

  /// The calendar date of [dateTime] in its own time zone.
  factory CalendarDate.fromDateTime(DateTime dateTime) =>
      CalendarDate(dateTime.year, dateTime.month, dateTime.day);

  DateTime _toUtc() => DateTime.fromMillisecondsSinceEpoch(
    epochDay * Duration.millisecondsPerDay,
    isUtc: true,
  );

  int get year => _toUtc().year;
  int get month => _toUtc().month;
  int get day => _toUtc().day;

  /// Local midnight on this date, for date pickers and formatting.
  DateTime toLocalDateTime() => DateTime(year, month, day);

  CalendarDate plusDays(int days) => CalendarDate.fromEpochDay(epochDay + days);

  /// Whole days from [other] to this date. Positive if this date is later.
  int daysSince(CalendarDate other) => epochDay - other.epochDay;

  bool isBefore(CalendarDate other) => epochDay < other.epochDay;
  bool isAfter(CalendarDate other) => epochDay > other.epochDay;
  bool operator <(CalendarDate other) => epochDay < other.epochDay;
  bool operator <=(CalendarDate other) => epochDay <= other.epochDay;
  bool operator >(CalendarDate other) => epochDay > other.epochDay;
  bool operator >=(CalendarDate other) => epochDay >= other.epochDay;

  static CalendarDate max(CalendarDate a, CalendarDate b) => a >= b ? a : b;

  @override
  int compareTo(CalendarDate other) => epochDay.compareTo(other.epochDay);

  @override
  bool operator ==(Object other) =>
      other is CalendarDate && other.epochDay == epochDay;

  @override
  int get hashCode => epochDay.hashCode;

  /// ISO 8601 date, e.g. `2026-11-09`.
  @override
  String toString() {
    final d = _toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }
}
