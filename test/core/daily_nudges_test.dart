import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/daily_nudges.dart';
import 'package:nudge/core/models.dart';

import 'test_helpers.dart';

void main() {
  final rings = [Ring(id: 1, name: 'Close friends', periodDays: 7)];
  final today = d(20);
  final members = [for (var i = 1; i <= 8; i++) member(i, baseline: d(i))];

  List<int> ids(DailyNudgePlan plan) =>
      plan.nudges.map((n) => n.memberId).toList();

  group('stable picks for the same day', () {
    test('saved nudges for today are returned unchanged', () {
      final saved = [
        DailyNudge(date: today, memberId: 5, status: NudgeStatus.done),
        DailyNudge(date: today, memberId: 2),
      ];
      final plan = planDailyNudges(
        today: today,
        existingToday: saved,
        members: members,
        rings: rings,
        random: Random(999),
      );
      expect(plan.isNew, isFalse);
      expect(plan.nudges, saved);
      expect(plan.updatedMembers, isEmpty);
    });

    test('regenerating on the same day gives the same picks', () {
      DailyNudgePlan generate(List<Member> ms) => planDailyNudges(
        today: today,
        existingToday: const [],
        members: ms,
        rings: rings,
      );
      final first = generate(members);
      expect(first.isNew, isTrue);
      expect(first.nudges, hasLength(3));

      // Even after last_surfaced was saved for the picks, and with members
      // in a different order, the day-seeded picks are identical.
      final saved = {for (final m in first.updatedMembers) m.id: m};
      final afterSave = [for (final m in members) saved[m.id] ?? m];
      expect(ids(generate(afterSave.reversed.toList())), ids(first));
    });

    test('nudges saved for other days are ignored', () {
      final plan = planDailyNudges(
        today: today,
        existingToday: [DailyNudge(date: d(19), memberId: 1)],
        members: members,
        rings: rings,
      );
      expect(plan.isNew, isTrue);
      expect(plan.nudges.every((n) => n.date == today), isTrue);
    });

    test('randomForDay is seeded by the date', () {
      expect(
        randomForDay(today).nextInt(1 << 30),
        Random(today.epochDay).nextInt(1 << 30),
      );
    });
  });

  test('new picks are pending and mark members surfaced today', () {
    final plan = planDailyNudges(
      today: today,
      existingToday: const [],
      members: members,
      rings: rings,
      random: Random(1),
    );
    expect(plan.nudges.map((n) => n.status).toSet(), {NudgeStatus.pending});
    expect(plan.updatedMembers.map((m) => m.id), ids(plan));
    expect(plan.updatedMembers.every((m) => m.lastSurfaced == today), isTrue);
  });

  test('none eligible: all caught up', () {
    final plan = planDailyNudges(
      today: today,
      existingToday: const [],
      members: [member(1, baseline: d(19))],
      rings: rings,
    );
    expect(plan.isNew, isTrue);
    expect(plan.allCaughtUp, isTrue);
    expect(plan.updatedMembers, isEmpty);
  });

  test('recentNudges returns the last 7 days, newest first', () {
    final nudges = [
      for (var day = 10; day <= 21; day++)
        DailyNudge(date: d(day), memberId: 1),
      DailyNudge(date: d(20), memberId: 0),
    ];
    final recent = recentNudges(nudges, today);
    expect(recent.first.date, today);
    expect(recent.last.date, d(14));
    expect(recent.where((n) => n.date == today).map((n) => n.memberId), [0, 1]);
    expect(recent, hasLength(8));
  });
}
