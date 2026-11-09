import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/app.dart';
import 'package:nudge/contacts/contacts_source.dart';
import 'package:nudge/contacts/fake_contacts_source.dart';
import 'package:nudge/core/calendar_date.dart';
import 'package:nudge/core/clock.dart';
import 'package:nudge/core/export_format.dart';
import 'package:nudge/data/database.dart';

import '../notifications/fake_scheduler.dart';
import 'fake_data_files.dart';
import 'test_launcher.dart';

void main() {
  late AppDatabase db;
  late FakeDataFiles files;
  final today = CalendarDate(2026, 11, 20);

  // The phone's contacts. Keys differ from the "old phone" in the backup.
  const ana = PhoneContact(key: 'new-ana', id: '1', displayName: 'Ana Silva');
  const ben = PhoneContact(key: 'k-ben', id: '2', displayName: 'Ben Okoro');

  // These tests open a second database to stand in for another phone.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    files = FakeDataFiles();
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      NudgeApp(
        db: db,
        clock: FixedClock(today),
        contactsSource: FakeContactsSource(contacts: [ana, ben]),
        launcher: RecordingLauncher(),
        reminderScheduler: FakeReminderScheduler(),
        dataFiles: files,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapInSettings(WidgetTester tester, String text) async {
    if (find.text('Settings').evaluate().isEmpty) {
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(find.text(text), 100);
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  /// A backup made on another phone: Ana's key there was 'old-ana'.
  Future<Uint8List> otherPhoneBackup() async {
    final other = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    final ring = await other.createRing('Close friends', 14);
    await other.createRing('Work', 60);
    final [anaMember, _, _] = await other.addMembers(
      ring,
      const [
        NewMember(contactKey: 'old-ana', cachedName: 'Ana Silva'),
        NewMember(contactKey: 'k-ben', cachedName: 'Ben Okoro'),
        NewMember(contactKey: 'old-gone', cachedName: 'Gone Person'),
      ],
      today: today,
      random: Random(1),
    );
    await other.setNickname(anaMember.id, 'Annie');
    final text = encodeExport(
      await other.exportData(),
      exportedAt: DateTime.utc(2026, 11, 1),
    );
    await other.close();
    return Uint8List.fromList(utf8.encode(text));
  }

  testWidgets('export saves a dated backup file of everything', (tester) async {
    await db.createRing('Friends', 30);
    await pumpApp(tester);
    await tapInSettings(tester, 'Export backup');

    expect(find.text('Backup saved'), findsOneWidget);
    final name = files.saved.keys.single;
    expect(name, matches(RegExp(r'^nudge-backup-\d{4}-\d{2}-\d{2}\.json$')));
    final data = decodeExport(utf8.decode(files.saved[name]!));
    expect(data.rings.single.name, 'Friends');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('import replaces data and rematches contacts by name', (
    tester,
  ) async {
    await db.createRing('Old ring', 7);
    files.toOpen = await otherPhoneBackup();
    await pumpApp(tester);
    await tapInSettings(tester, 'Import backup');

    expect(find.text('Replace everything in Nudge?'), findsOneWidget);
    expect(find.textContaining('has 2 rings and 3 people'), findsOneWidget);
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    expect((await db.allRings()).map((r) => r.name), ['Close friends', 'Work']);
    final members = {for (final m in await db.allMembers()) m.cachedName: m};
    // Different key on this phone: matched by name, nickname kept.
    expect(members['Ana Silva']!.contactKey, 'new-ana');
    expect(members['Ana Silva']!.nickname, 'Annie');
    // Same key: matched directly. Missing: kept, needs relinking.
    expect(members['Ben Okoro']!.contactKey, 'k-ben');
    expect(members['Gone Person']!.contactKey, 'old-gone');
    expect(find.text('Restored 3 people. 1 need relinking.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a file that is not a backup is refused; nothing changes', (
    tester,
  ) async {
    await db.createRing('Keep me', 7);
    files.toOpen = Uint8List.fromList(utf8.encode('{"hello": "world"}'));
    await pumpApp(tester);
    await tapInSettings(tester, 'Import backup');

    expect(find.text('Can\'t import this file'), findsOneWidget);
    expect(find.text('This isn\'t a Nudge backup file.'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect((await db.allRings()).single.name, 'Keep me');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelling the confirmation changes nothing', (tester) async {
    await db.createRing('Keep me', 7);
    files.toOpen = await otherPhoneBackup();
    await pumpApp(tester);
    await tapInSettings(tester, 'Import backup');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await db.allRings()).single.name, 'Keep me');
    await tester.pumpWidget(const SizedBox());
  });
}
