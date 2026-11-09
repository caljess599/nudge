import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/contacts/fake_contacts_source.dart';
import 'package:nudge/core/calendar_date.dart';
import 'package:nudge/core/due_dates.dart';
import 'package:nudge/data/database.dart';
import 'package:nudge/debug/seed.dart';

void main() {
  late AppDatabase db;
  final today = CalendarDate(2026, 11, 20);

  setUp(() => db = AppDatabase(DatabaseConnection(NativeDatabase.memory())));
  tearDown(() => db.close());

  test('seeds three rings with some people due today', () async {
    await seedFakeData(db, today: today, random: Random(1));

    final rings = {for (final r in await db.allRings()) r.id: r};
    final members = await db.allMembers();
    expect(rings, hasLength(3));
    expect(members, hasLength(19));
    final fakeKeys = {for (final c in fakePhoneContacts) c.key};
    expect(members.every((m) => fakeKeys.contains(m.contactKey)), isTrue);

    final due = members.where((m) => isEligible(m, rings[m.ringId]!, today));
    expect(due, hasLength(6));
  });

  test('stops when the fake contacts run out', () async {
    await seedFakeData(db, today: today, random: Random(1));
    await seedFakeData(db, today: today, random: Random(2));
    await seedFakeData(db, today: today, random: Random(3));
    final members = await db.allMembers();
    expect(members, hasLength(fakePhoneContacts.length));
    expect(members.map((m) => m.contactKey).toSet(), hasLength(40));
  });
}
