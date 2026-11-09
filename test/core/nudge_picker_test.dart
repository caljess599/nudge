import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/models.dart';
import 'package:nudge/core/nudge_picker.dart';

import 'test_helpers.dart';

void main() {
  final weekly = Ring(id: 1, name: 'Close friends', periodDays: 7);
  final quarterly = Ring(id: 2, name: 'Old friends', periodDays: 90);
  final rings = [weekly, quarterly];
  final ringsById = {for (final r in rings) r.id: r};
  final today = d(20);

  group('weighting by overdueness relative to the period', () {
    test('weight is 1 + days_overdue / period_days', () {
      // Due on the 20th: 0 days overdue.
      expect(overdueWeight(member(1, baseline: d(13)), weekly, today), 1.0);
      // Due on the 13th: 7 days overdue on a 7-day ring.
      expect(overdueWeight(member(1, baseline: d(6)), weekly, today), 2.0);
    });

    test('10 days late on a 7-day ring outweighs 10 days late on 90', () {
      // Both 10 days overdue on the 20th.
      final weeklyLate = member(1, ringId: 1, baseline: d(3));
      final quarterlyLate = member(
        2,
        ringId: 2,
        baseline: today.plusDays(-100),
      );
      final candidates = weighCandidates(
        members: [weeklyLate, quarterlyLate],
        ringsById: ringsById,
        today: today,
      );
      expect(candidates[0].weight, closeTo(1 + 10 / 7, 1e-9));
      expect(candidates[1].weight, closeTo(1 + 10 / 90, 1e-9));
      expect(candidates[0].weight, greaterThan(candidates[1].weight));
    });

    test('more overdue members are picked more often', () {
      final veryLate = member(1, baseline: d(1, month: 10)); // 43 days overdue
      final justDue = member(2, baseline: d(13)); // weight 1
      var veryLateFirst = 0;
      final random = Random(7);
      for (var i = 0; i < 2000; i++) {
        final pick = pickNudges(
          members: [veryLate, justDue],
          rings: rings,
          today: today,
          random: random,
          config: const NudgePickerConfig(count: 1),
        );
        if (pick.single.id == 1) veryLateFirst++;
      }
      // Weights are 1 + 43/7 ≈ 7.14 vs 1, so expect ~88%.
      expect(veryLateFirst / 2000, closeTo(0.88, 0.04));
    });

    test('members not yet due or snoozed are not candidates', () {
      final candidates = weighCandidates(
        members: [
          member(1, baseline: d(14)), // due on the 21st
          member(2, baseline: d(1), snoozedUntil: d(22)),
          member(3, baseline: d(1)),
          member(4, ringId: 99, baseline: d(1)), // ring missing
        ],
        ringsById: ringsById,
        today: today,
      );
      expect(candidates.map((c) => c.member.id), [3]);
    });
  });

  group('cooldown', () {
    const config = NudgePickerConfig(cooldownDays: 3, cooldownFactor: 0.25);
    final base = member(1, baseline: d(13)); // due today, weight 1

    double weightOf(Member m) => weighCandidates(
      members: [m],
      ringsById: ringsById,
      today: today,
      config: config,
    ).single.weight;

    test('reduces weight for members surfaced 1-3 days ago and ignored', () {
      for (final ago in [1, 2, 3]) {
        final m = base.copyWith(lastSurfaced: () => today.plusDays(-ago));
        expect(isInCooldown(m, today, 3), isTrue, reason: '$ago days ago');
        expect(weightOf(m), 0.25);
      }
    });

    test('ends after the cooldown window', () {
      final m = base.copyWith(lastSurfaced: () => today.plusDays(-4));
      expect(isInCooldown(m, today, 3), isFalse);
      expect(weightOf(m), 1.0);
    });

    test('does not apply to members surfaced today', () {
      final m = base.copyWith(lastSurfaced: () => today);
      expect(isInCooldown(m, today, 3), isFalse);
    });

    test('does not apply once the member was acted on', () {
      final surfaced = today.plusDays(-2);
      final snoozed = base.copyWith(
        lastSurfaced: () => surfaced,
        snoozedUntil: () => today,
      );
      expect(isInCooldown(snoozed, today, 3), isFalse);

      // Contacted on or after being surfaced. (Would not normally still be
      // due, but cooldown itself must not apply.)
      final contacted = member(
        1,
        baseline: d(1),
        lastContacted: surfaced,
        lastSurfaced: surfaced,
      );
      expect(isInCooldown(contacted, today, 3), isFalse);
    });

    test('an ignored member drops down the list in favour of others', () {
      final ignored = base.copyWith(lastSurfaced: () => today.plusDays(-1));
      final fresh = member(2, baseline: d(13));
      var ignoredPicked = 0;
      final random = Random(3);
      for (var i = 0; i < 2000; i++) {
        final pick = pickNudges(
          members: [ignored, fresh],
          rings: rings,
          today: today,
          random: random,
          config: const NudgePickerConfig(count: 1),
        );
        if (pick.single.id == 1) ignoredPicked++;
      }
      // 0.25 vs 1 => 20%.
      expect(ignoredPicked / 2000, closeTo(0.2, 0.03));
    });
  });

  group('how many are picked', () {
    final due = [for (var i = 1; i <= 6; i++) member(i, baseline: d(1))];

    test('picks 3 distinct members when more are eligible', () {
      final picks = pickNudges(
        members: due,
        rings: rings,
        today: today,
        random: Random(1),
      );
      expect(picks, hasLength(3));
      expect(picks.map((m) => m.id).toSet(), hasLength(3));
    });

    test('fewer than 3 eligible: shows what exists', () {
      final picks = pickNudges(
        members: [
          ...due.take(2),
          member(10, baseline: d(19)), // not due yet
        ],
        rings: rings,
        today: today,
        random: Random(1),
      );
      expect(picks.map((m) => m.id).toSet(), {1, 2});
    });

    test('none eligible: empty list', () {
      expect(
        pickNudges(
          members: [member(1, baseline: d(19))],
          rings: rings,
          today: today,
          random: Random(1),
        ),
        isEmpty,
      );
      expect(
        pickNudges(members: [], rings: rings, today: today, random: Random(1)),
        isEmpty,
      );
    });
  });

  group('determinism', () {
    final due = [for (var i = 1; i <= 10; i++) member(i, baseline: d(i))];

    test('the same seed gives the same picks', () {
      List<int> run() => pickNudges(
        members: due,
        rings: rings,
        today: today,
        random: Random(2026),
      ).map((m) => m.id).toList();
      expect(run(), run());
    });

    test('input order does not affect the picks', () {
      List<int> run(List<Member> ms) => pickNudges(
        members: ms,
        rings: rings,
        today: today,
        random: Random(5),
      ).map((m) => m.id).toList();
      expect(run(due), run(due.reversed.toList()));
    });
  });

  test(
    'sampleWeighted handles a random value at the very top of the range',
    () {
      final candidates = [
        NudgeCandidate(member(1, baseline: d(1)), weekly, 1),
        NudgeCandidate(member(2, baseline: d(1)), weekly, 1),
      ];
      final picks = sampleWeighted(candidates, 2, _MaxRandom());
      expect(picks.map((c) => c.member.id).toSet(), {1, 2});
    },
  );
}

/// Returns the largest double below 1.0 to probe the boundary.
class _MaxRandom implements Random {
  @override
  double nextDouble() => 0.9999999999999999;
  @override
  bool nextBool() => true;
  @override
  int nextInt(int max) => max - 1;
}
