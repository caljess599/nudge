import 'dart:math';

import '../core/calendar_date.dart';
import '../core/models.dart';
import '../data/database.dart';

/// Fake contacts for emulators and manual testing. Only reachable from
/// UI guarded by `kDebugMode`, so it is compiled out of release builds.

const _firstNames = [
  'Alex', 'Bea', 'Cam', 'Dana', 'Eli', 'Farah', 'Gus', 'Hana', 'Ivo', //
  'Jules', 'Kai', 'Lena', 'Milo', 'Nia', 'Omar', 'Pia', 'Quinn', 'Rosa',
  'Sami', 'Tess', 'Uma', 'Vic', 'Wren', 'Xavi', 'Yara', 'Zeke',
];

const _lastInitials = 'ABCDEFGHJKLMNPRSTVW';

/// Contact keys of fake contacts all start with this, so they can never
/// collide with real Android lookup keys or iOS identifiers.
const fakeContactKeyPrefix = 'debug-fake:';

/// Adds [count] fake people to [ring]. If [overdue], their due dates are
/// already in the past so they show up on the Today screen; otherwise
/// they're spread over the coming period like real new members.
Future<List<Member>> addFakeMembers(
  AppDatabase db,
  Ring ring,
  int count, {
  required CalendarDate today,
  required Random random,
  bool overdue = false,
}) async {
  final taken = {for (final m in await db.allMembers()) m.contactKey};
  final contacts = <NewMember>[];
  while (contacts.length < count) {
    final name =
        '${_firstNames[random.nextInt(_firstNames.length)]} '
        '${_lastInitials[random.nextInt(_lastInitials.length)]}.';
    final key = '$fakeContactKeyPrefix${random.nextInt(1 << 31)}';
    if (!taken.add(key)) continue;
    contacts.add(NewMember(contactKey: key, cachedName: name));
  }
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
