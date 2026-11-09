import 'dart:math';

import 'calendar_date.dart';
import 'models.dart';
import 'nudge_picker.dart';

/// Today's nudges and what needs saving.
class DailyNudgePlan {
  final CalendarDate date;
  final List<DailyNudge> nudges;

  /// Members whose `last_surfaced` changed. Empty if [isNew] is false.
  final List<Member> updatedMembers;

  /// True if the nudges were generated now and must be saved.
  final bool isNew;

  const DailyNudgePlan({
    required this.date,
    required this.nudges,
    required this.updatedMembers,
    required this.isNew,
  });

  /// No one is due: show the "all caught up" state.
  bool get allCaughtUp => nudges.isEmpty;
}

/// A random source seeded by the date. Using it means that even if
/// today's saved rows were lost, regenerating them gives the same picks.
Random randomForDay(CalendarDate day) => Random(day.epochDay);

/// Returns today's nudges, generating them only if none exist yet, so
/// picks stay stable for the whole day.
///
/// [existingToday] are the saved nudges for [today]. Nudges for other
/// dates are ignored. [random] defaults to [randomForDay].
DailyNudgePlan planDailyNudges({
  required CalendarDate today,
  required Iterable<DailyNudge> existingToday,
  required Iterable<Member> members,
  required Iterable<Ring> rings,
  Random? random,
  NudgePickerConfig config = const NudgePickerConfig(),
}) {
  final saved = existingToday.where((n) => n.date == today).toList();
  if (saved.isNotEmpty) {
    return DailyNudgePlan(
      date: today,
      nudges: saved,
      updatedMembers: const [],
      isNew: false,
    );
  }

  final picks = pickNudges(
    members: members,
    rings: rings,
    today: today,
    random: random ?? randomForDay(today),
    config: config,
  );
  return DailyNudgePlan(
    date: today,
    nudges: [for (final m in picks) DailyNudge(date: today, memberId: m.id)],
    updatedMembers: [
      for (final m in picks) m.copyWith(lastSurfaced: () => today),
    ],
    isNew: true,
  );
}

/// Nudges from the last [days] days (including today), newest first, so
/// people can check things off late.
List<DailyNudge> recentNudges(
  Iterable<DailyNudge> nudges,
  CalendarDate today, {
  int days = 7,
}) {
  final from = today.plusDays(-(days - 1));
  final recent = nudges.where((n) => n.date >= from && n.date <= today).toList()
    ..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : a.memberId.compareTo(b.memberId);
    });
  return recent;
}
