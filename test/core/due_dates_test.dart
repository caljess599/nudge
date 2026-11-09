import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/due_dates.dart';
import 'package:nudge/core/models.dart';

import 'test_helpers.dart';

void main() {
  final weekly = Ring(id: 1, name: 'Close friends', periodDays: 7);

  group('due dates', () {
    test('use the baseline until the first contact', () {
      final m = member(1, baseline: d(1));
      expect(referenceDate(m), d(1));
      expect(nextDue(m, weekly), d(8));
    });

    test('use last_contacted once set', () {
      final m = member(1, baseline: d(1), lastContacted: d(5));
      expect(referenceDate(m), d(5));
      expect(nextDue(m, weekly), d(12));
    });

    test('days overdue is zero on the due date, negative before', () {
      final m = member(1, baseline: d(1));
      expect(daysOverdue(m, weekly, d(7)), -1);
      expect(daysOverdue(m, weekly, d(8)), 0);
      expect(daysOverdue(m, weekly, d(18)), 10);
    });

    test('eligible from the due date onwards', () {
      final m = member(1, baseline: d(1));
      expect(isEligible(m, weekly, d(7)), isFalse);
      expect(isEligible(m, weekly, d(8)), isTrue);
      expect(isEligible(m, weekly, d(20)), isTrue);
    });

    test('a snoozed member is not eligible until snoozed_until', () {
      final m = member(1, baseline: d(1), snoozedUntil: d(12));
      expect(isSnoozed(m, d(11)), isTrue);
      expect(isEligible(m, weekly, d(11)), isFalse);
      expect(isSnoozed(m, d(12)), isFalse);
      expect(isEligible(m, weekly, d(12)), isTrue);
    });
  });

  group('editing a ring period', () {
    test('changes every member\'s next due date with no data migration', () {
      final members = [
        member(1, baseline: d(1)),
        member(2, baseline: d(1), lastContacted: d(4)),
      ];
      expect(members.map((m) => nextDue(m, weekly)), [d(8), d(11)]);

      final monthly = weekly.copyWith(periodDays: 30);
      expect(members.map((m) => nextDue(m, monthly)), [
        d(1, month: 12),
        d(4, month: 12),
      ]);
      // Members themselves are unchanged.
      expect(members[1].lastContacted, d(4));
    });

    test('shortening the period can make members due immediately', () {
      final m = member(1, baseline: d(1));
      expect(isEligible(m, weekly.copyWith(periodDays: 30), d(9)), isFalse);
      expect(isEligible(m, weekly.copyWith(periodDays: 3), d(9)), isTrue);
    });

    test('rings reject a period of zero or less', () {
      expect(() => weekly.copyWith(periodDays: 0), throwsArgumentError);
      expect(() => Ring(id: 2, name: 'x', periodDays: -1), throwsArgumentError);
    });
  });

  group('initial baseline', () {
    test('spreads first due dates over the next period, never today', () {
      final today = d(9);
      final random = Random(42);
      final dues = <int>{};
      for (var i = 0; i < 500; i++) {
        final baseline = initialBaseline(today, 14, random);
        final due = baseline.plusDays(14);
        expect(due > today, isTrue);
        expect(due <= today.plusDays(14), isTrue);
        dues.add(due.daysSince(today));
      }
      // All 14 possible offsets get used.
      expect(dues, {for (var i = 1; i <= 14; i++) i});
    });

    test('a one-day ring gets today as the baseline', () {
      expect(initialBaseline(d(9), 1, Random(1)), d(9));
    });
  });

  test('a ring with a different id is rejected in debug mode', () {
    final m = member(1, ringId: 99, baseline: d(1));
    expect(() => nextDue(m, weekly), throwsA(isA<AssertionError>()));
  });

  test('Member.copyWith can clear nullable fields', () {
    final m = member(1, baseline: d(1), snoozedUntil: d(5));
    expect(m.copyWith(snoozedUntil: () => null).snoozedUntil, isNull);
    expect(m.copyWith(ringId: 2).snoozedUntil, d(5));
    expect(m.copyWith(), m);
  });

  test('NudgeStatus covers the spec values', () {
    expect(NudgeStatus.values.map((s) => s.name), [
      'pending',
      'done',
      'snoozed',
      'skipped',
    ]);
  });
}
