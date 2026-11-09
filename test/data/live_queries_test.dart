import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/calendar_date.dart';
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

  test('ring summaries include member counts, ordered by period', () async {
    final monthly = await db.createRing('Monthly', 30);
    final weekly = await db.createRing('Weekly', 7);
    await db.createRing('Empty', 90);
    await db.addMembers(
      monthly,
      contacts(['a', 'b']),
      today: today,
      random: Random(1),
    );
    await db.addMembers(
      weekly,
      contacts(['c']),
      today: today,
      random: Random(1),
    );

    final summaries = await db.watchRingSummaries().first;
    expect(summaries.map((s) => '${s.ring.name}:${s.memberCount}'), [
      'Weekly:1',
      'Monthly:2',
      'Empty:0',
    ]);
  });

  test('ring summaries update when members are added', () async {
    final ring = await db.createRing('Friends', 30);
    final counts = db.watchRingSummaries().map((s) => s.single.memberCount);
    final expectation = expectLater(counts, emitsInOrder([0, 2]));
    await pumpEventQueue();
    await db.addMembers(
      ring,
      contacts(['a', 'b']),
      today: today,
      random: Random(1),
    );
    await expectation;
  });

  test('deleteRingMovingMembers moves everyone, then deletes', () async {
    final from = await db.createRing('From', 30);
    final to = await db.createRing('To', 7);
    final added = await db.addMembers(
      from,
      contacts(['a', 'b']),
      today: today,
      random: Random(1),
    );

    await db.deleteRingMovingMembers(from.id, toRingId: to.id);

    expect((await db.allRings()).map((r) => r.id), [to.id]);
    final members = await db.watchMembersOfRing(to.id).first;
    expect(members.map((m) => m.id).toSet(), added.map((m) => m.id).toSet());
    expect(
      () => db.deleteRingMovingMembers(to.id, toRingId: to.id),
      throwsArgumentError,
    );
  });

  test('nudge entries join member and ring, newest first', () async {
    final ring = await db.createRing('Friends', 7);
    await db.addMembers(
      ring,
      contacts(['a', 'b', 'c', 'd']),
      today: today.plusDays(-30),
      random: Random(1),
    );
    await db.ensureDailyNudges(today.plusDays(-1));
    await db.ensureDailyNudges(today);

    final entries = await db.watchNudgeEntries(today.plusDays(-1)).first;
    expect(entries.first.nudge.date, today);
    expect(entries.last.nudge.date, today.plusDays(-1));
    for (final e in entries) {
      expect(e.member.id, e.nudge.memberId);
      expect(e.ring.id, e.member.ringId);
    }
  });

  test('deleteAllData empties every table', () async {
    final ring = await db.createRing('Friends', 7);
    await db.addMembers(
      ring,
      contacts(['a']),
      today: today.plusDays(-30),
      random: Random(1),
    );
    await db.ensureDailyNudges(today);

    await db.deleteAllData();

    expect(await db.allRings(), isEmpty);
    expect(await db.allMembers(), isEmpty);
    expect(await db.nudgesSince(today.plusDays(-30)), isEmpty);
  });
}
