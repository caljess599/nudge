import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/app.dart';
import 'package:nudge/contacts/fake_contacts_source.dart';
import 'package:nudge/core/calendar_date.dart';
import 'package:nudge/core/clock.dart';
import 'package:nudge/core/reminder.dart';
import 'package:nudge/data/database.dart';

import '../notifications/fake_scheduler.dart';
import 'test_launcher.dart';

void main() {
  late AppDatabase db;
  late FakeReminderScheduler scheduler;
  late FakeContactsSource contacts;
  final today = CalendarDate(2026, 11, 20);

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    scheduler = FakeReminderScheduler();
    contacts = FakeContactsSource(contacts: const []);
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      NudgeApp(
        db: db,
        clock: FixedClock(today),
        contactsSource: contacts,
        launcher: RecordingLauncher(),
        reminderScheduler: scheduler,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addSomeone() async {
    final ring = await db.createRing('Friends', 30);
    await db.addMembers(
      ring,
      const [NewMember(contactKey: 'k', cachedName: 'Ana')],
      today: today,
      random: Random(1),
    );
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
  }

  testWidgets('no offer until someone is in a ring; never prompts at launch', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Get a daily reminder?'), findsNothing);
    expect(scheduler.requests, 0);

    await addSomeone();
    await tester.pumpAndSettle();
    expect(find.text('Get a daily reminder?'), findsOneWidget);
    expect(scheduler.requests, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Turn on asks for permission and schedules 9:00', (tester) async {
    await addSomeone();
    await pumpApp(tester);
    expect(find.textContaining('9:00 AM'), findsOneWidget);

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(scheduler.requests, 1);
    expect(scheduler.scheduled, defaultReminderTime);
    expect(find.text('Get a daily reminder?'), findsNothing);
    expect(find.text('Daily reminder set for 9:00 AM'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Not now hides the card without asking', (tester) async {
    await addSomeone();
    await pumpApp(tester);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Get a daily reminder?'), findsNothing);
    expect(scheduler.requests, 0);
    expect((await db.reminderSettings()).offerDismissed, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('denied permission explains where to allow it', (tester) async {
    scheduler.grantOnRequest = false;
    await addSomeone();
    await pumpApp(tester);
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Notifications are off for Nudge'),
      findsOneWidget,
    );
    expect(scheduler.scheduled, isNull);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(contacts.settingsOpened, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('settings: switch on, change the time, switch off', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSettings(tester);

    await tester.tap(find.text('Daily reminder'));
    await tester.pumpAndSettle();
    expect(scheduler.scheduled, defaultReminderTime);

    // Change the time using the time picker's keyboard input.
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '7');
    await tester.enterText(fields.at(1), '30');
    await tester.tap(find.text('PM'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(scheduler.scheduled, const ReminderTime(19, 30));
    expect(find.text('7:30 PM'), findsOneWidget);

    await tester.tap(find.text('Daily reminder'));
    await tester.pumpAndSettle();
    expect(scheduler.scheduled, isNull);
    expect((await db.reminderSettings()).time, const ReminderTime(19, 30));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('blocked in system settings shows a warning', (tester) async {
    await db.saveReminderSettings(const ReminderSettings(enabled: true));
    scheduler.permission = false;
    await pumpApp(tester);
    await openSettings(tester);
    expect(find.text('Notifications are blocked for Nudge'), findsOneWidget);
    expect(scheduler.scheduled, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a saved reminder is rescheduled when the app starts', (
    tester,
  ) async {
    await db.saveReminderSettings(
      const ReminderSettings(enabled: true, time: ReminderTime(8, 15)),
    );
    scheduler.permission = true;
    await pumpApp(tester);
    expect(scheduler.scheduled, const ReminderTime(8, 15));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping the notification opens Today', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();
    expect(find.text('No rings yet'), findsOneWidget);

    scheduler.tapNotification();
    await tester.pumpAndSettle();
    expect(find.text('All caught up'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
