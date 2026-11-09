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

void main() {
  late AppDatabase db;
  late RecordingLauncher launcher;
  final today = CalendarDate(2026, 11, 20);

  const jane = PhoneContact(
    key: 'k-jane',
    id: '1',
    displayName: 'Jane Doe',
    phones: [
      PhoneNumber('+44 20 7946 0000', label: 'Home'),
      PhoneNumber('+1 202 555 0101', label: 'Mobile', isMobile: true),
    ],
  );
  const local = PhoneContact(
    key: 'k-local',
    id: '2',
    displayName: 'Lou Local',
    phones: [PhoneNumber('202 555 0199', label: 'Mobile', isMobile: true)],
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
        contactsSource: FakeContactsSource(contacts: [jane, local]),
        launcher: launcher,
        reminderScheduler: FakeReminderScheduler(),
        dataFiles: FakeDataFiles(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Member> add(PhoneContact c, {bool due = true}) async {
    final ring =
        (await db.allRings()).firstOrNull ?? await db.createRing('Friends', 7);
    return (await db.addMembers(
      ring,
      [NewMember(contactKey: c.key, cachedName: c.displayName)],
      today: due ? today.plusDays(-30) : today,
      random: Random(1),
    )).single;
  }

  Future<void> openPreference(WidgetTester tester, String name) async {
    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reach out via'));
    await tester.pumpAndSettle();
  }

  testWidgets('set WhatsApp; Today shows it and opens the mobile number', (
    tester,
  ) async {
    final m = await add(jane);
    await pumpApp(tester);
    await openPreference(tester, 'Jane Doe');

    expect(find.text('Reach Jane Doe via'), findsOneWidget);
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    // Defaults to the mobile number, not the first listed.
    expect(find.textContaining('+1 202 555 0101. Follows'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = (await db.memberById(m.id))!;
    expect(saved.reachVia, ReachMethod.whatsapp);
    expect(saved.reachValue, isNull);

    // Back to Today.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Call'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'WhatsApp'));
    await tester.pumpAndSettle();
    expect(launcher.opened, [(ReachMethod.whatsapp, '+1 202 555 0101')]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a specific number can be chosen for Signal', (tester) async {
    final m = await add(jane);
    await pumpApp(tester);
    await openPreference(tester, 'Jane Doe');

    await tester.tap(find.text('Signal'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('+44 20 7946 0000'), 100);
    await tester.ensureVisible(find.text('+44 20 7946 0000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+44 20 7946 0000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = (await db.memberById(m.id))!;
    expect(saved.reachVia, ReachMethod.signal);
    expect(saved.reachValue, '+44 20 7946 0000');
    expect(
      find.text('Signal · +44 20 7946 0000'),
      findsNothing,
    ); // sheet closed
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('warns when a messaging app gets a number without +', (
    tester,
  ) async {
    await add(local);
    await pumpApp(tester);
    await openPreference(tester, 'Lou Local');

    await tester.tap(find.text('Signal'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('needs the number with its country code'),
      100,
    );
    expect(
      find.textContaining('needs the number with its country code'),
      findsOneWidget,
    );

    await tester.tap(find.text('Text message'));
    await tester.pumpAndSettle();
    expect(find.textContaining('country code'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('says so when the app is not installed', (tester) async {
    launcher = RecordingLauncher(unavailable: {ReachMethod.whatsapp});
    final m = await add(jane);
    await db.setReachPreference(m.id, ReachMethod.whatsapp);
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'WhatsApp'));
    await tester.pumpAndSettle();
    expect(
      find.text('Couldn\'t open WhatsApp. Is it installed?'),
      findsOneWidget,
    );
    expect(launcher.opened, isEmpty);

    // No "did you reach out?" prompt when nothing was opened.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.textContaining('Did you reach out'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('custom link is validated, saved and opened', (tester) async {
    final m = await add(jane);
    await pumpApp(tester);
    await openPreference(tester, 'Jane Doe');

    await tester.tap(find.text('Custom link'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'not a link');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter a link'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'm.me/jane.doe');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = (await db.memberById(m.id))!;
    expect(saved.reachVia, ReachMethod.link);
    expect(saved.reachValue, 'https://m.me/jane.doe');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Custom link'));
    await tester.pumpAndSettle();
    expect(launcher.opened, [(ReachMethod.link, 'https://m.me/jane.doe')]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a saved number is used without asking', (tester) async {
    final m = await add(jane);
    await db.setReachPreference(
      m.id,
      ReachMethod.text,
      value: '+44 20 7946 0000',
    );
    await pumpApp(tester);

    // Text is highlighted as the preference; Call still asks.
    await tester.tap(find.byTooltip('Text'));
    await tester.pumpAndSettle();
    expect(launcher.texts, ['+44 20 7946 0000']);

    await tester.tap(find.byTooltip('Call'));
    await tester.pumpAndSettle();
    expect(find.text('Call Jane Doe'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('clearing the preference restores Call and Text', (tester) async {
    final m = await add(jane);
    await db.setReachPreference(m.id, ReachMethod.signal);
    await pumpApp(tester);
    expect(find.byTooltip('Call'), findsNothing);

    await openPreference(tester, 'Jane Doe');
    await tester.tap(find.text('No preference'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await db.memberById(m.id))!.reachVia, isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Call'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
