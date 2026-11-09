import 'package:nudge/core/calendar_date.dart';
import 'package:nudge/core/models.dart';

/// Shorthand for a date in November 2026 (or any month, if given).
CalendarDate d(int day, {int month = 11, int year = 2026}) =>
    CalendarDate(year, month, day);

Member member(
  int id, {
  int ringId = 1,
  required CalendarDate baseline,
  CalendarDate? lastContacted,
  CalendarDate? snoozedUntil,
  CalendarDate? lastSurfaced,
}) => Member(
  id: id,
  contactKey: 'key-$id',
  cachedName: 'Person $id',
  ringId: ringId,
  baselineDate: baseline,
  lastContacted: lastContacted,
  snoozedUntil: snoozedUntil,
  lastSurfaced: lastSurfaced,
);
