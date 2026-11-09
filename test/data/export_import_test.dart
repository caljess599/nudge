import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/calendar_date.dart';
import 'package:nudge/core/export_format.dart';
import 'package:nudge/core/models.dart';
import 'package:nudge/core/reach_methods.dart';
import 'package:nudge/core/reminder.dart';
import 'package:nudge/data/database.dart';

void main() {
  late AppDatabase source;
  late AppDatabase target;
  final today = CalendarDate(2026, 11, 20);

  setUp(() {
    source = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    target = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  Future<void> fill(AppDatabase db) async {
    final close = await db.createRing('Close friends', 7);
    final family = await db.createRing('Family', 30);
    await db.addMembers(
      close,
      const [
        NewMember(contactKey: 'k-ana', cachedName: 'Ana'),
        NewMember(contactKey: 'k-ben', cachedName: 'Ben'),
        NewMember(contactKey: 'k-cy', cachedName: 'Cy'),
      ],
      today: today.plusDays(-30),
      random: Random(1),
    );
    final [jane] = await db.addMembers(
      family,
      const [NewMember(contactKey: 'k-jane', cachedName: 'Jane Doe')],
      today: today,
      random: Random(1),
    );
    await db.setNickname(jane.id, 'Mom');
    await db.setReachPreference(jane.id, ReachMethod.signal);
    await db.ensureDailyNudges(today.plusDays(-1));
    await db.ensureDailyNudges(today);
    await db.saveReminderSettings(
      const ReminderSettings(enabled: true, time: ReminderTime(20, 0)),
    );
  }

  test(
    'export then import into an empty database restores everything',
    () async {
      await fill(source);
      final text = encodeExport(
        await source.exportData(),
        exportedAt: DateTime.utc(2026, 11, 20),
      );

      await target.replaceAllData(decodeExport(text));

      expect(await target.allRings(), await source.allRings());
      expect(await target.allMembers(), await source.allMembers());
      expect(
        await target.nudgesSince(today.plusDays(-5)),
        await source.nudgesSince(today.plusDays(-5)),
      );
      expect(await target.reminderSettings(), await source.reminderSettings());
    },
  );

  test('import replaces existing data; new rows get fresh ids', () async {
    await fill(source);
    await target.createRing('Old ring', 90);
    final exported = await source.exportData();

    await target.replaceAllData(exported);
    expect((await target.allRings()).map((r) => r.name), [
      'Close friends',
      'Family',
    ]);

    // Autoincrement continues after the imported ids.
    final added = await target.createRing('New', 14);
    expect(added.id, greaterThan(exported.rings.map((r) => r.id).reduce(max)));
  });

  test('a failing import leaves existing data untouched', () async {
    await target.createRing('Keep me', 30);
    // Two rings with the same id: the second insert fails mid-transaction.
    final duplicateIds = ExportData(
      rings: [
        Ring(id: 5, name: 'A', periodDays: 7),
        Ring(id: 5, name: 'B', periodDays: 7),
      ],
      members: const [],
      history: const [],
      reminder: const ReminderSettings(),
    );
    await expectLater(
      target.replaceAllData(duplicateIds),
      throwsA(isA<Exception>()),
    );
    expect((await target.allRings()).map((r) => r.name), ['Keep me']);
  });
}
