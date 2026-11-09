import 'dart:math';

import '../contacts/fake_contacts_source.dart';
import '../core/calendar_date.dart';
import '../core/models.dart';
import '../data/database.dart';

/// Fake data for emulators and manual testing. Only reachable from UI
/// guarded by `kDebugMode`, so it is compiled out of release builds.

/// Adds up to [count] fake contacts that aren't in a ring yet to [ring].
/// If [overdue], their due dates are already in the past so they show up
/// on the Today screen; otherwise they're spread over the coming period
/// like real new members. Returns fewer if the fake contacts run out.
Future<List<Member>> addFakeMembers(
  AppDatabase db,
  Ring ring,
  int count, {
  required CalendarDate today,
  required Random random,
  bool overdue = false,
}) async {
  final taken = {for (final m in await db.allMembers()) m.contactKey};
  final available = [
    for (final c in fakePhoneContacts)
      if (!taken.contains(c.key)) c,
  ]..shuffle(random);
  final contacts = [
    for (final c in available.take(count))
      NewMember(contactKey: c.key, cachedName: c.displayName),
  ];
  // Pretending they were added 1.5 periods ago makes them all overdue.
  final addedOn = overdue ? today.plusDays(-(ring.periodDays * 3 ~/ 2)) : today;
  return db.addMembers(ring, contacts, today: addedOn, random: random);
}

/// Three rings with a mix of due and not-yet-due fake people.
Future<void> seedFakeData(
  AppDatabase db, {
  required CalendarDate today,
  required Random random,
}) async {
  for (final (name, period, due, later) in [
    ('Close friends', 14, 2, 4),
    ('Family', 30, 2, 3),
    ('Old friends', 90, 2, 6),
  ]) {
    final ring = await db.createRing(name, period);
    await addFakeMembers(
      db,
      ring,
      due,
      today: today,
      random: random,
      overdue: true,
    );
    await addFakeMembers(db, ring, later, today: today, random: random);
  }
}
