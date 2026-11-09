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
import 'fake_data_files.dart';
import 'test_launcher.dart';

void main() {
  late AppDatabase db;
  late FakeContactsSource contacts;
  late RecordingLauncher launcher;
  final today = CalendarDate(2026, 11, 20);

  const ana = PhoneContact(
    key: 'k-ana',
    id: '1',
    displayName: 'Ana Silva',
    phones: [PhoneNumber('+1 202 555 0101', label: 'Mobile', isMobile: true)],
  );
  const ben = PhoneContact(
    key: 'k-ben',
    id: '2',
    displayName: 'Ben Okoro',
    phones: [
      PhoneNumber('+1 202 555 0202', label: 'Work'),
      PhoneNumber('+1 202 555 0203', label: 'Mobile', isMobile: true),
    ],
  );
  const cy = PhoneContact(key: 'k-cy', id: '3', displayName: 'Cy Tran');

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    contacts = FakeContactsSource(contacts: [ana, ben, cy]);
    launcher = RecordingLauncher();
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      NudgeApp(
        db: db,
        clock: FixedClock(today),
        contactsSource: contacts,
        launcher: launcher,
        reminderScheduler: FakeReminderScheduler(),
        dataFiles: FakeDataFiles(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  Future<void> openRing(WidgetTester tester, String name) async {
    await tester.tap(find.text('Rings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  Future<Member> addMember(
    Ring ring,
    String key,
    String name, {
    bool due = false,
  }) async => (await db.addMembers(
    ring,
    [NewMember(contactKey: key, cachedName: name)],
    today: due ? today.plusDays(-ring.periodDays * 2) : today,
    random: Random(1),
  )).single;

  testWidgets('access is only requested when adding people', (tester) async {
    contacts.access = ContactsAccess.canAsk;
    await db.createRing('Friends', 14);
    await pumpApp(tester);
    await openRing(tester, 'Friends');
    expect(contacts.requests, 0);

    await tester.tap(find.text('Add people'));
    await tester.pumpAndSettle();
    expect(contacts.requests, 1);
    expect(find.text('Ana Silva'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('adds several selected contacts at once', (tester) async {
    final ring = await db.createRing('Friends', 14);
    await pumpApp(tester);
    await openRing(tester, 'Friends');
    await tester.tap(find.text('Add people'));
    await tester.pumpAndSettle();

    expect(find.text('Select people'), findsOneWidget);
    await tester.tap(find.text('Ana Silva'));
    await tester.tap(find.text('Cy Tran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add 2 people'));
    await tester.pumpAndSettle();

    final members = await db.allMembers();
    expect(members.map((m) => m.cachedName).toSet(), {'Ana Silva', 'Cy Tran'});
    expect(members.every((m) => m.ringId == ring.id), isTrue);
    expect(find.text('Added 2 people to Friends'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('search filters by name and number', (tester) async {
    await db.createRing('Friends', 14);
    await pumpApp(tester);
    await openRing(tester, 'Friends');
    await tester.tap(find.text('Add people'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'oko');
    await tester.pumpAndSettle();
    expect(find.text('Ben Okoro'), findsOneWidget);
    expect(find.text('Ana Silva'), findsNothing);

    await tester.enterText(find.byType(TextField), '0101');
    await tester.pumpAndSettle();
    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('Ben Okoro'), findsNothing);
    await unmount(tester);
  });

  testWidgets('people in a ring are greyed out; others can be moved here', (
    tester,
  ) async {
    final friends = await db.createRing('Friends', 14);
    final family = await db.createRing('Family', 30);
    await addMember(friends, 'k-ana', 'Ana Silva');
    final ben = await addMember(family, 'k-ben', 'Ben Okoro');

    await pumpApp(tester);
    await openRing(tester, 'Friends');
    await tester.tap(find.text('Add people'));
    await tester.pumpAndSettle();

    expect(find.text('Already in this ring'), findsOneWidget);
    expect(find.text('In Family'), findsOneWidget);
    await tester.tap(find.text('Move here'));
    await tester.pumpAndSettle();

    expect((await db.memberById(ben.id))!.ringId, friends.id);
    expect(find.text('Already in this ring'), findsNWidgets(2));
    await unmount(tester);
  });

  testWidgets('blocked access offers to open Settings', (tester) async {
    contacts.access = ContactsAccess.blocked;
    await db.createRing('Friends', 14);
    await pumpApp(tester);
    await openRing(tester, 'Friends');
    await tester.tap(find.text('Add people'));
    await tester.pumpAndSettle();

    expect(find.textContaining('turned off'), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(contacts.settingsOpened, 1);
    await unmount(tester);
  });

  testWidgets('denying access shows a retry, the app keeps working', (
    tester,
  ) async {
    contacts
      ..access = ContactsAccess.canAsk
      ..accessAfterRequest = ContactsAccess.canAsk;
    await db.createRing('Friends', 14);
    await pumpApp(tester);
    await openRing(tester, 'Friends');
    await tester.tap(find.text('Add people'));
    await tester.pumpAndSettle();

    expect(find.text('Allow access'), findsOneWidget);
    // Going back still works.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Add people'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('limited access shows a hint about sharing more', (tester) async {
    contacts.access = ContactsAccess.limited;
    await db.createRing('Friends', 14);
    await pumpApp(tester);
    await openRing(tester, 'Friends');
    await tester.tap(find.text('Add people'));
    await tester.pumpAndSettle();

    expect(find.textContaining('shared only some contacts'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a deleted contact shows Needs relinking and can be relinked', (
    tester,
  ) async {
    final ring = await db.createRing('Friends', 14);
    final gone = await addMember(ring, 'k-deleted', 'Dee Old');
    await pumpApp(tester);
    await openRing(tester, 'Friends');

    expect(find.text('Dee Old'), findsOneWidget);
    expect(find.text('Needs relinking'), findsOneWidget);

    await tester.tap(find.text('Dee Old'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relink to a contact'));
    await tester.pumpAndSettle();
    expect(find.text('Relink Dee Old'), findsOneWidget);
    await tester.tap(find.text('Cy Tran'));
    await tester.pumpAndSettle();

    final relinked = (await db.memberById(gone.id))!;
    expect(relinked.contactKey, 'k-cy');
    expect(relinked.cachedName, 'Cy Tran');
    expect(find.text('Needs relinking'), findsNothing);
    await unmount(tester);
  });

  testWidgets('Call from Today, then "Did you reach out?" on return', (
    tester,
  ) async {
    final ring = await db.createRing('Friends', 7);
    final member = await addMember(ring, 'k-ana', 'Ana Silva', due: true);
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Call'));
    await tester.pumpAndSettle();
    expect(launcher.calls, ['+1 202 555 0101']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Did you reach out to Ana Silva?'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect((await db.memberById(member.id))!.lastContacted, today);
    expect((await db.nudgesOn(today)).single.status, NudgeStatus.done);
    await unmount(tester);
  });

  testWidgets('Text asks which number when there are several', (tester) async {
    final ring = await db.createRing('Friends', 7);
    await addMember(ring, 'k-ben', 'Ben Okoro', due: true);
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Text'));
    await tester.pumpAndSettle();
    expect(find.text('Text Ben Okoro'), findsOneWidget);
    await tester.tap(find.text('+1 202 555 0203'));
    await tester.pumpAndSettle();
    expect(launcher.texts, ['+1 202 555 0203']);
    await unmount(tester);
  });

  testWidgets('contacts without a phone only get the contact card button', (
    tester,
  ) async {
    final ring = await db.createRing('Friends', 7);
    await addMember(ring, 'k-cy', 'Cy Tran', due: true);
    await pumpApp(tester);

    expect(find.byTooltip('Call'), findsNothing);
    await tester.tap(find.byTooltip('Open contact card'));
    await tester.pumpAndSettle();
    expect(contacts.opened.single.key, 'k-cy');
    await unmount(tester);
  });
}
