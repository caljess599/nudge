import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/actions.dart';
import 'package:nudge/core/due_dates.dart';
import 'package:nudge/core/models.dart';

import 'test_helpers.dart';

void main() {
  final weekly = Ring(id: 1, name: 'Close friends', periodDays: 7);
  final monthly = Ring(id: 2, name: 'Friends', periodDays: 30);
  final today = d(20);
  final due = member(1, baseline: d(1), snoozedUntil: d(15));
  final nudge = DailyNudge(date: today, memberId: 1);

  group('reached out', () {
    test('sets last_contacted to today and marks the nudge done', () {
      final result = reachedOut(due, today: today, nudge: nudge);
      expect(result.member.lastContacted, today);
      expect(result.member.snoozedUntil, isNull);
      expect(result.nudge!.status, NudgeStatus.done);
      expect(nextDue(result.member, weekly), d(27));
      expect(isEligible(result.member, weekly, today), isFalse);
    });

    test('accepts an earlier date the user picks', () {
      final result = reachedOut(due, today: today, on: d(18));
      expect(result.member.lastContacted, d(18));
      expect(result.nudge, isNull);
    });

    test('never moves last_contacted backwards', () {
      final recent = due.copyWith(lastContacted: () => d(19));
      expect(
        reachedOut(recent, today: today, on: d(10)).member.lastContacted,
        d(19),
      );
    });

    test('rejects a future date', () {
      expect(
        () => reachedOut(due, today: today, on: d(21)),
        throwsArgumentError,
      );
    });
  });

  group('snooze', () {
    test('hides the member for a few days without resetting the cycle', () {
      final result = snooze(due, today: today, nudge: nudge);
      expect(result.member.snoozedUntil, d(23));
      expect(result.member.lastContacted, isNull);
      expect(nextDue(result.member, weekly), nextDue(due, weekly));
      expect(result.nudge!.status, NudgeStatus.snoozed);

      expect(isEligible(result.member, weekly, d(22)), isFalse);
      expect(isEligible(result.member, weekly, d(23)), isTrue);
    });

    test('custom length, and rejects zero days', () {
      expect(snooze(due, today: today, days: 7).member.snoozedUntil, d(27));
      expect(() => snooze(due, today: today, days: 0), throwsArgumentError);
    });
  });

  group('skip this cycle', () {
    test('restarts the cycle from today and records a skip, not a done', () {
      final result = skip(due, today: today, nudge: nudge);
      expect(result.member.lastContacted, today);
      expect(result.member.snoozedUntil, isNull);
      expect(result.nudge!.status, NudgeStatus.skipped);
      expect(nextDue(result.member, weekly), d(27));
    });
  });

  test('an action on another member\'s nudge is rejected', () {
    final other = DailyNudge(date: today, memberId: 2);
    expect(
      () => reachedOut(due, today: today, nudge: other),
      throwsArgumentError,
    );
  });

  group('moving a member between rings', () {
    test('keeps last_contacted and follows the new period', () {
      final m = member(1, ringId: 1, baseline: d(1), lastContacted: d(10));
      final moved = moveToRing(m, monthly);
      expect(moved.ringId, 2);
      expect(moved.lastContacted, d(10));
      expect(moved.baselineDate, m.baselineDate);
      expect(nextDue(m, weekly), d(17));
      expect(nextDue(moved, monthly), d(10, month: 12));
    });

    test('moving to a shorter ring can make the member due now', () {
      final m = member(1, ringId: 2, baseline: d(1), lastContacted: d(10));
      expect(isEligible(m, monthly, today), isFalse);
      expect(isEligible(moveToRing(m, weekly), weekly, today), isTrue);
    });
  });
}
