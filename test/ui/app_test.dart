import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/app.dart';
import 'package:nudge/contacts/fake_contacts_source.dart';
import 'package:nudge/core/calendar_date.dart';
import 'package:nudge/core/clock.dart';
import 'package:nudge/core/models.dart';
import 'package:nudge/data/database.dart';
import 'package:nudge/ui/today_screen.dart';

import '../notifications/fake_scheduler.dart';
import 'test_launcher.dart';

void main() {
  late AppDatabase db;
  final today = CalendarDate(2026, 11, 20);

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
        contactsSource: FakeContactsSource(contacts: const []),
        launcher: RecordingLauncher(),
        reminderScheduler: FakeReminderScheduler(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Unmount before the database closes so no stream outlives it.
  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  Future<List<Member>> addPeople(
    Ring ring,
    List<String> names, {
    required bool overdue,
  }) => db.addMembers(
    ring,
    [for (final n in names) NewMember(contactKey: 'key-$n', cachedName: n)],
    today: overdue ? today.plusDays(-ring.periodDays * 2) : today,
    random: Random(1),
  );

  testWidgets('empty app shows the all-caught-up and no-rings states', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('All caught up'), findsOneWidget);

    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();
    expect(find.text('No rings yet'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('creates a ring with a preset period', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New ring'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Book club');
    await tester.tap(find.text('Monthly'));
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Book club'), findsOneWidget);
    expect(find.text('Monthly · 0 people'), findsOneWidget);
    expect((await db.allRings()).single.periodDays, 30);
    await unmount(tester);
  });

  testWidgets('custom period is validated', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New ring'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Rare');
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    // Starts from the previously selected preset (every 2 weeks).
    expect(find.widgetWithText(TextFormField, '14'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).last, '');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number of days'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).last, '9999');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('At most 3650 days'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).last, '45');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Every 45 days · 0 people'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('today shows up to 3 due people and records actions', (
    tester,
  ) async {
    final ring = await db.createRing('Close friends', 7);
    await addPeople(ring, ['Ana', 'Ben', 'Cy', 'Di'], overdue: true);
    await addPeople(ring, ['Later'], overdue: false);

    await pumpApp(tester);
    // Answer the reminder offer so all three cards fit on screen.
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    final cards = find.byType(NudgeCard);
    expect(cards, findsNWidgets(3));
    expect(find.text('Later'), findsNothing);

    // Reached out on the first card.
    await tester.tap(find.text('Reached out').first);
    await tester.pumpAndSettle();
    expect(find.text('Marked as reached out'), findsOneWidget);

    var nudges = await db.nudgesOn(today);
    final done = nudges.where((n) => n.status == NudgeStatus.done).single;
    expect((await db.memberById(done.memberId))!.lastContacted, today);

    // Snooze the next pending one.
    await tester.tap(find.text('Snooze').first);
    await tester.pumpAndSettle();

    // Skip the last via the overflow menu.
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this cycle'));
    await tester.pumpAndSettle();

    nudges = await db.nudgesOn(today);
    expect(nudges.map((n) => n.status).toSet(), {
      NudgeStatus.done,
      NudgeStatus.snoozed,
      NudgeStatus.skipped,
    });
    expect(find.text('Snoozed'), findsOneWidget);
    expect(find.text('Skipped'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('earlier pending nudges can be checked off late', (tester) async {
    final ring = await db.createRing('Friends', 7);
    await addPeople(ring, ['Ana'], overdue: true);
    await db.ensureDailyNudges(today.plusDays(-2));
    // Nobody else is due, and Ana already has a pending nudge from 2
    // days ago; today she is picked again.
    await pumpApp(tester);

    expect(find.text('Earlier this week'), findsOneWidget);
    expect(find.text('Ana'), findsNWidgets(2));

    await tester.tap(find.text('Reached out').first);
    await tester.pumpAndSettle();
    // Once contacted, the older pending nudge is hidden.
    expect(find.text('Earlier this week'), findsNothing);
    expect(find.text('Ana'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('ring detail sorts by due date and follows period edits', (
    tester,
  ) async {
    final ring = await db.createRing('Friends', 30);
    final [overdue] = await addPeople(ring, ['Zoe'], overdue: true);
    final [later] = await addPeople(ring, ['Amy'], overdue: false);
    await db.saveMember(later.copyWith(lastContacted: () => today));
    expect(overdue.cachedName, 'Zoe');

    await pumpApp(tester);
    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    // Zoe is overdue so she's listed before Amy despite the name.
    final zoeY = tester.getTopLeft(find.text('Zoe')).dy;
    final amyY = tester.getTopLeft(find.text('Amy')).dy;
    expect(zoeY, lessThan(amyY));
    expect(find.textContaining('Due in 30 days'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit ring'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Due in 7 days'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('deleting a ring with people asks where to move them', (
    tester,
  ) async {
    final from = await db.createRing('Old friends', 90);
    final to = await db.createRing('Close friends', 14);
    final added = await addPeople(from, ['Ana', 'Ben'], overdue: false);

    await pumpApp(tester);
    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Old friends'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete ring'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Move its 2 people'), findsOneWidget);
    await tester.tap(find.text('Move and delete'));
    await tester.pumpAndSettle();

    expect((await db.allRings()).map((r) => r.id), [to.id]);
    final moved = await db.allMembers();
    expect(moved.map((m) => m.ringId).toSet(), {to.id});
    expect(moved.length, added.length);
    // Back on the rings list.
    expect(find.text('Close friends'), findsOneWidget);
    expect(find.text('Old friends'), findsNothing);
    await unmount(tester);
  });

  testWidgets('the only ring with people cannot be deleted', (tester) async {
    final ring = await db.createRing('Friends', 30);
    await addPeople(ring, ['Ana'], overdue: false);

    await pumpApp(tester);
    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete ring'));
    await tester.pumpAndSettle();

    expect(find.text('Can\'t delete this ring yet'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(await db.allRings(), hasLength(1));
    await unmount(tester);
  });

  testWidgets('a member can be moved to another ring', (tester) async {
    final from = await db.createRing('Friends', 30);
    final to = await db.createRing('Family', 14);
    final [ana] = await addPeople(from, ['Ana'], overdue: false);
    await db.saveMember(ana.copyWith(lastContacted: () => today));

    await pumpApp(tester);
    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to another ring'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();

    final moved = (await db.memberById(ana.id))!;
    expect(moved.ringId, to.id);
    expect(moved.lastContacted, today);
    expect(
      find.text(
        'No one in this ring yet.\nMonthly\n\nTap "Add people" to choose from your contacts.',
      ),
      findsOneWidget,
    );
    await unmount(tester);
  });
}
