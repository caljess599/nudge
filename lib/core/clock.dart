import 'calendar_date.dart';

/// Source of "today". Injected so tests can control the date.
abstract interface class Clock {
  CalendarDate today();
}

/// The device's local date.
class SystemClock implements Clock {
  const SystemClock();

  @override
  CalendarDate today() => CalendarDate.fromDateTime(DateTime.now());
}

/// A clock that always returns the same date. Useful in tests.
class FixedClock implements Clock {
  CalendarDate date;

  FixedClock(this.date);

  @override
  CalendarDate today() => date;
}
