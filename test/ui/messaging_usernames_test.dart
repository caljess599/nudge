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
import 'package:nudge/core/reach_methods.dart';
import 'package:nudge/data/database.dart';

import '../notifications/fake_scheduler.dart';
import 'fake_data_files.dart';
import 'test_launcher.dart';

/// Signal/Telegram by username, for people who hide their phone number.
void main() {
  late AppDatabase db;
  late RecordingLauncher launcher;
  final today = CalendarDate(2026, 11, 20);
  const signalLink = 'https://signal.me/#eu/Example-Opaque_Token123';

  const cousin = PhoneContact(
    key: 'k-cousin',
    id: '1',
    displayName: 'Cara Cousin',
    phones: [PhoneNumber('+1 202 555 0123', label: 'Mobile', isMobile: true)],
  );
  // No phone number at all in contacts.
  const noPhone = PhoneContact(
    key: 'k-np',
    id: '2',
    displayName: 'Nell NoPhone',
  );

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    launcher = RecordingLauncher();
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      NudgeApp(
        db: db,
        clock: FixedClock(today),
        contactsSource: FakeContactsSource(contacts: [cousin, noPhone]),
        launcher: launcher,
        reminderScheduler: FakeReminderScheduler(),
        dataFiles: FakeDataFiles(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Member> add(PhoneContact c) async {
    final ring =
        (await db.allRings()).firstOrNull ?? await db.createRing('Family', 7);
    return (await db.addMembers(
      ring,
      [NewMember(contactKey: c.key, cachedName: c.displayName)],
      today: today.plusDays(-30),
      random: Random(1),
    )).single;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    // The page's list; text fields have their own Scrollable too.
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openPreference(WidgetTester tester, String name) async {
    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reach out via'));
    await tester.pumpAndSettle();
  }

  Future<void> enterUsername(
    WidgetTester tester,
    String method,
    String text,
  ) async {
    await tester.tap(find.text(method));
    await tester.pumpAndSettle();
    await tapVisible(tester, _segment('Username'));
    final field = find.byType(TextField);
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  Future<void> backToToday(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
  }

  testWidgets('Signal username link: saved, shown, and opened as-is', (
    tester,
  ) async {
    final m = await add(cousin);
    await pumpApp(tester);
    await openPreference(tester, 'Cara Cousin');
    await enterUsername(tester, 'Signal', '  $signalLink ');

    final saved = (await db.memberById(m.id))!;
    expect(saved.reachVia, ReachMethod.signal);
    expect(saved.reachValue, signalLink);

    await backToToday(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Signal'));
    await tester.pumpAndSettle();
    expect(launcher.opened, [(ReachMethod.signal, signalLink)]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a non-Signal link is refused with an explanation', (
    tester,
  ) async {
    final m = await add(cousin);
    await pumpApp(tester);
    await openPreference(tester, 'Cara Cousin');
    await enterUsername(tester, 'Signal', 'https://example.com/#eu/x');

    expect(
      find.textContaining('starting with https://signal.me/'),
      findsOneWidget,
    );
    expect((await db.memberById(m.id))!.reachVia, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Telegram username from a t.me link is saved as @name', (
    tester,
  ) async {
    final m = await add(cousin);
    await pumpApp(tester);
    await openPreference(tester, 'Cara Cousin');
    await enterUsername(tester, 'Telegram', 'https://t.me/cara_cousin');

    expect((await db.memberById(m.id))!.reachValue, '@cara_cousin');
    await backToToday(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Telegram'));
    await tester.pumpAndSettle();
    expect(launcher.opened, [(ReachMethod.telegram, '@cara_cousin')]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('works for a contact with no phone number at all', (
    tester,
  ) async {
    final m = await add(noPhone);
    await db.setReachPreference(m.id, ReachMethod.signal, value: signalLink);
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Signal'));
    await tester.pumpAndSettle();
    expect(launcher.opened, [(ReachMethod.signal, signalLink)]);
    expect(find.textContaining('No phone number'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reopening shows the saved username; can switch back', (
    tester,
  ) async {
    final m = await add(cousin);
    await db.setReachPreference(m.id, ReachMethod.signal, value: signalLink);
    await pumpApp(tester);

    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cara Cousin'));
    await tester.pumpAndSettle();
    expect(find.text('Signal · username link'), findsOneWidget);
    await tester.tap(find.text('Reach out via'));
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.ensureVisible(field);
    expect(find.text(signalLink), findsOneWidget);

    // Back to phone number: the mobile number is used again.
    await tapVisible(tester, _segment('Phone number'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = (await db.memberById(m.id))!;
    expect(saved.reachVia, ReachMethod.signal);
    expect(saved.reachValue, isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

/// A segment of the Phone number / Username switch.
Finder _segment(String label) => find
    .descendant(
      of: find.byType(SegmentedButton<bool>),
      matching: find.text(label),
    )
    .first;
