import 'package:flutter/material.dart';

import '../core/calendar_date.dart';
import '../core/due_dates.dart';
import '../core/models.dart';

/// "Weekly", "Every 2 weeks", "Every 45 days", ...
String periodLabel(int days) => switch (days) {
  1 => 'Daily',
  7 => 'Weekly',
  14 => 'Every 2 weeks',
  30 => 'Monthly',
  _ => 'Every $days days',
};

String peopleCount(int n) => n == 1 ? '1 person' : '$n people';

String formatDate(BuildContext context, CalendarDate date) =>
    MaterialLocalizations.of(context).formatMediumDate(date.toLocalDateTime());

/// Gentle, guilt-free wording: "Due 3 days ago", not "3 days overdue".
String dueLabel(
  BuildContext context,
  Member member,
  Ring ring,
  CalendarDate today,
) {
  if (isSnoozed(member, today)) {
    return 'Snoozed until ${formatDate(context, member.snoozedUntil!)}';
  }
  final overdue = daysOverdue(member, ring, today);
  return switch (overdue) {
    0 => 'Due today',
    1 => 'Due yesterday',
    -1 => 'Due tomorrow',
    > 1 => 'Due $overdue days ago',
    _ => 'Due in ${-overdue} days',
  };
}

String lastContactLabel(BuildContext context, Member member) {
  final last = member.lastContacted;
  return last == null
      ? 'No contact logged yet'
      : 'Last contact ${formatDate(context, last)}';
}
