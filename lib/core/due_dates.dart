import 'dart:math';

import 'calendar_date.dart';
import 'models.dart';

/// Due dates are derived, never stored, so editing a ring's period or
/// moving a member between rings takes effect immediately.

/// `last_contacted ?? baseline_date`.
CalendarDate referenceDate(Member member) =>
    member.lastContacted ?? member.baselineDate;

/// `reference_date + ring.period_days`.
CalendarDate nextDue(Member member, Ring ring) {
  assert(member.ringId == ring.id, 'member is not in this ring');
  return referenceDate(member).plusDays(ring.periodDays);
}

/// Days past [nextDue]. Zero on the due date, negative before it.
int daysOverdue(Member member, Ring ring, CalendarDate today) =>
    today.daysSince(nextDue(member, ring));

/// Snoozed until (but not including) [Member.snoozedUntil].
bool isSnoozed(Member member, CalendarDate today) {
  final until = member.snoozedUntil;
  return until != null && today < until;
}

/// Due or overdue, and not snoozed.
bool isEligible(Member member, Ring ring, CalendarDate today) =>
    nextDue(member, ring) <= today && !isSnoozed(member, today);

/// Baseline for a newly added member: today minus a random offset in
/// `[0, periodDays)`. Their first due date therefore lands somewhere in
/// the next `periodDays` days, so a bulk add doesn't make everyone due at
/// once and nobody is due on the day they were added.
CalendarDate initialBaseline(
  CalendarDate today,
  int periodDays,
  Random random,
) {
  if (periodDays <= 0) {
    throw ArgumentError.value(periodDays, 'periodDays', 'must be > 0');
  }
  return today.plusDays(-random.nextInt(periodDays));
}
