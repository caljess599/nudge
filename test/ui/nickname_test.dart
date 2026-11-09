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
import 'package:nudge/core/models.dart';
import 'package:nudge/data/database.dart';

import '../notifications/fake_scheduler.dart';
import 'test_launcher.dart';

void main() {
  late AppDatabase db;
  final today = CalendarDate(2026, 11, 20);
  const jane = PhoneContact(key: 'k-jane', id: '1', displayName: 'Jane Doe');

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      NudgeApp(
        db: db,
        clock: FixedClock(today),
        contactsSource: FakeContactsSource(contacts: [jane]),
        launcher: RecordingLauncher(),
        reminderScheduler: FakeReminderScheduler(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Member> addJane(Ring ring, {bool due = false}) async =>
      (await db.addMembers(
        ring,
        const [NewMember(contactKey: 'k-jane', cachedName: 'Jane Doe')],
        today: due ? today.plusDays(-ring.periodDays * 2) : today,
        random: Random(1),
      )).single;

  Future<void> openRing(WidgetTester tester, String name) async {
    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  testWidgets('set a nickname from the member sheet, then clear it', (
    tester,
  ) async {
    final ring = await db.createRing('Family', 30);
    final m = await addJane(ring);
    await pumpApp(tester);
    await openRing(tester, 'Family');

    await tester.tap(find.text('Jane Doe'));
    await tester.pumpAndSettle();
    expect(find.text('Not set'), findsOneWidget);
    await tester.tap(find.text('Nickname'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mom');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect((await db.memberById(m.id))!.nickname, 'Mom');
    expect(find.text('Mom'), findsOneWidget);
    expect(find.text('Jane Doe'), findsNothing);

    // The sheet shows both names.
    await tester.tap(find.text('Mom'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Jane Doe'), findsOneWidget);

    // Clearing goes back to the contact name.
    await tester.tap(find.text('Nickname'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await db.memberById(m.id))!.nickname, isNull);
    expect(find.text('Jane Doe'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancel leaves the nickname unchanged', (tester) async {
    final ring = await db.createRing('Family', 30);
    final m = await addJane(ring);
    await db.setNickname(m.id, 'Mom');
    await pumpApp(tester);
    await openRing(tester, 'Family');

    await tester.tap(find.text('Mom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nickname'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mother');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await db.memberById(m.id))!.nickname, 'Mom');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Today and the picker use the nickname', (tester) async {
    final family = await db.createRing('Family', 30);
    await db.createRing('Friends', 14);
    final m = await addJane(family, due: true);
    await db.setNickname(m.id, 'Mom');
    await pumpApp(tester);

    expect(find.text('Mom'), findsOneWidget);
    expect(find.text('Jane Doe'), findsNothing);

    await openRing(tester, 'Friends');
    await tester.tap(find.text('Add people'));
    await tester.pumpAndSettle();
    // The picker lists contacts by their real name, noting the nickname.
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('In Family as Mom'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
