import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/actions.dart';
import 'package:nudge/core/calendar_date.dart';
import 'package:nudge/core/due_dates.dart';
import 'package:nudge/core/models.dart';
import 'package:nudge/data/database.dart';

void main() {
  late AppDatabase db;
  final today = CalendarDate(2026, 11, 20);

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
  });

  tearDown(() => db.close());

  List<NewMember> contacts(List<String> keys) => [
    for (final k in keys) NewMember(contactKey: k, cachedName: 'Name $k'),
  ];

  group('one ring per contact', () {
    test('adding the same contact_key twice fails at the database', () async {
      final close = await db.createRing('Close friends', 14);
      final old = await db.createRing('Old friends', 60);
      await db.addMembers(
        close,
        contacts(['a']),
        today: today,
        random: Random(1),
      );

      await expectLater(
        db.addMembers(old, contacts(['a']), today: today, random: Random(1)),
        throwsA(isA<SqliteException>()),
      );
      final all = await db.allMembers();
      expect(all, hasLength(1));
      expect(all.single.ringId, close.id);
    });

    test('a bulk add with one duplicate adds nothing', () async {
      final ring = await db.createRing('Friends', 30);
      await db.addMembers(
        ring,
        contacts(['a']),
        today: today,
        random: Random(1),
      );
      await expectLater(
        db.addMembers(
          ring,
          contacts(['b', 'c', 'a']),
          today: today,
          random: Random(1),
        ),
        throwsA(isA<SqliteException>()),
      );
      expect((await db.allMembers()).map((m) => m.contactKey), ['a']);
    });
  });

  group('rings', () {
    test('period must be greater than zero', () async {
      await expectLater(
        db.createRing('Never', 0),
        throwsA(isA<SqliteException>()),
      );
    });

    test(
      'editing the period changes due dates with no member writes',
      () async {
        final ring = await db.createRing('Friends', 30);
        final m = (await db.addMembers(
          ring,
          contacts(['a']),
          today: today,
          random: Random(1),
        )).single;
        final before = await db.memberById(m.id);

        await db.updateRing(ring.copyWith(periodDays: 7));
        final weekly = (await db.allRings()).single;
        final after = await db.memberById(m.id);

        expect(weekly.periodDays, 7);
        expect(after, before);
        expect(nextDue(after!, weekly), m.baselineDate.plusDays(7));
      },
    );

    test('a ring with members cannot be deleted', () async {
      final ring = await db.createRing('Friends', 30);
      await db.addMembers(
        ring,
        contacts(['a']),
        today: today,
        random: Random(1),
      );
      await expectLater(
        db.deleteRing(ring.id),
        throwsA(isA<SqliteException>()),
      );

      final empty = await db.createRing('Empty', 7);
      await db.deleteRing(empty.id);
      expect((await db.allRings()).map((r) => r.id), [ring.id]);
    });
  });

  group('members', () {
    test('new members get baselines within the ring period', () async {
      final ring = await db.createRing('Friends', 10);
      final added = await db.addMembers(
        ring,
        contacts([for (var i = 0; i < 20; i++) 'k$i']),
        today: today,
        random: Random(3),
      );
      for (final m in added) {
        expect(m.baselineDate <= today, isTrue);
        expect(m.baselineDate > today.plusDays(-10), isTrue);
      }
      expect(await db.allMembers(), added);
    });

    test('moving between rings keeps last_contacted', () async {
      final close = await db.createRing('Close friends', 14);
      final old = await db.createRing('Old friends', 60);
      final m = (await db.addMembers(
        close,
        contacts(['a']),
        today: today,
        random: Random(1),
      )).single;
      await db.applyAction(reachedOut(m, today: today));

      await db.moveMember((await db.memberById(m.id))!, old);
      final moved = (await db.memberById(m.id))!;
      expect(moved.ringId, old.id);
      expect(moved.lastContacted, today);
    });

    test('all date fields round-trip', () async {
      final ring = await db.createRing('Friends', 30);
      final m = (await db.addMembers(
        ring,
        contacts(['a']),
        today: today,
        random: Random(1),
      )).single;
      final updated = m.copyWith(
        lastContacted: () => today.plusDays(-2),
        snoozedUntil: () => today.plusDays(3),
        lastSurfaced: () => today.plusDays(-1),
      );
      await db.saveMember(updated);
      expect(await db.memberById(m.id), updated);

      final cleared = updated.copyWith(snoozedUntil: () => null);
      await db.saveMember(cleared);
      expect((await db.memberById(m.id))!.snoozedUntil, isNull);
    });
  });

  group('daily nudges', () {
    Future<void> seed() async {
      final ring = await db.createRing('Friends', 7);
      await db.addMembers(
        ring,
        contacts([for (var i = 0; i < 6; i++) 'k$i']),
        today: today.plusDays(-30),
        random: Random(1),
      );
    }

    test('are generated once and stable for the whole day', () async {
      await seed();
      final first = await db.ensureDailyNudges(today);
      expect(first.isNew, isTrue);
      expect(first.nudges, hasLength(3));

      final again = await db.ensureDailyNudges(today, random: Random(12345));
      expect(again.isNew, isFalse);
      expect(again.nudges.toSet(), first.nudges.toSet());

      for (final n in first.nudges) {
        expect((await db.memberById(n.memberId))!.lastSurfaced, today);
      }
    });

    test('actions update the member and the nudge status', () async {
      await seed();
      final plan = await db.ensureDailyNudges(today);
      final nudge = plan.nudges.first;
      final m = (await db.memberById(nudge.memberId))!;

      await db.applyAction(reachedOut(m, today: today, nudge: nudge));

      expect((await db.memberById(m.id))!.lastContacted, today);
      final saved = await db.nudgesOn(today);
      expect(
        saved.firstWhere((n) => n.memberId == m.id).status,
        NudgeStatus.done,
      );
    });

    test('none eligible: nothing saved, all caught up', () async {
      final ring = await db.createRing('Friends', 7);
      await db.addMembers(
        ring,
        contacts(['a']),
        today: today,
        random: Random(1),
      );
      final plan = await db.ensureDailyNudges(today);
      expect(plan.allCaughtUp, isTrue);
      expect(await db.nudgesOn(today), isEmpty);
    });

    test('nudges are deleted with their member', () async {
      await seed();
      final plan = await db.ensureDailyNudges(today);
      await db.deleteMember(plan.nudges.first.memberId);
      expect(await db.nudgesOn(today), hasLength(2));
    });

    test('nudgesSince returns recent history newest first', () async {
      await seed();
      await db.ensureDailyNudges(today.plusDays(-8));
      await db.ensureDailyNudges(today.plusDays(-1));
      await db.ensureDailyNudges(today);
      final recent = await db.nudgesSince(today.plusDays(-6));
      expect(recent.map((n) => n.date).toSet(), {today, today.plusDays(-1)});
      expect(recent.first.date, today);
    });
  });
}
