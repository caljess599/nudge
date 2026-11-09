import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/contacts/contact_directory.dart';
import 'package:nudge/contacts/contacts_source.dart';
import 'package:nudge/contacts/fake_contacts_source.dart';
import 'package:nudge/contacts/reach_out_launcher.dart';
import 'package:nudge/core/calendar_date.dart';
import 'package:nudge/core/models.dart';
import 'package:nudge/data/database.dart';

void main() {
  late AppDatabase db;
  late FakeContactsSource source;
  late ContactDirectory directory;
  late Ring ring;
  final today = CalendarDate(2026, 11, 20);

  const ana = PhoneContact(key: 'k-ana', id: '1', displayName: 'Ana');
  const ben = PhoneContact(key: 'k-ben', id: '2', displayName: 'Ben');

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    source = FakeContactsSource(contacts: [ana, ben]);
    directory = ContactDirectory(source: source, db: db);
    ring = await db.createRing('Friends', 30);
  });

  tearDown(() => db.close());

  Future<Member> add(String key, String name) async => (await db.addMembers(
    ring,
    [NewMember(contactKey: key, cachedName: name)],
    today: today,
    random: Random(1),
  )).single;

  test('nothing is read until access is granted', () async {
    source.access = ContactsAccess.canAsk;
    await directory.refresh();
    expect(source.requests, 0);
    expect(directory.access, ContactsAccess.canAsk);
    expect(directory.contacts, isEmpty);

    expect(await directory.requestAccess(), ContactsAccess.granted);
    expect(source.requests, 1);
    expect(directory.contacts.map((c) => c.displayName), ['Ana', 'Ben']);
  });

  test('a renamed contact refreshes the cached name', () async {
    final m = await add('k-ana', 'Old name');
    await directory.refresh();
    expect((await db.memberById(m.id))!.cachedName, 'Ana');
    expect(directory.stateOf(m), LinkState.linked);
  });

  test('a deleted contact needs relinking and the member is kept', () async {
    final m = await add('k-gone', 'Cy');
    await directory.refresh();
    expect(directory.stateOf(m), LinkState.needsRelinking);
    final kept = (await db.memberById(m.id))!;
    expect(kept.cachedName, 'Cy');
  });

  test('a changed Android lookup key is followed, not flagged', () async {
    final m = await add('k-ana-old', 'Ana');
    source.lookupAliases['k-ana-old'] = 'k-ana';
    await directory.refresh();
    final updated = (await db.memberById(m.id))!;
    expect(updated.contactKey, 'k-ana');
    expect(directory.stateOf(updated), LinkState.linked);
  });

  test('two members merged into one contact: one needs relinking', () async {
    await add('k-ana', 'Ana');
    final dup = await add('k-ana-dup', 'Ana (work)');
    source.lookupAliases['k-ana-dup'] = 'k-ana';
    await directory.refresh();
    expect(directory.stateOf(dup), LinkState.needsRelinking);
    expect(await db.allMembers(), hasLength(2));
  });

  test('limited access: unseen contacts are not shared, not missing', () async {
    source.access = ContactsAccess.limited;
    final m = await add('k-hidden', 'Dee');
    await directory.refresh();
    expect(directory.stateOf(m), LinkState.notShared);
  });

  test('no access: state is unknown, never needs relinking', () async {
    source.access = ContactsAccess.blocked;
    final m = await add('k-gone', 'Cy');
    await directory.refresh();
    expect(directory.stateOf(m), LinkState.unknown);
  });

  test('relink points the member at a new contact', () async {
    final m = await add('k-gone', 'Cy');
    await directory.refresh();
    await directory.relink(m, ben);
    final relinked = (await db.memberById(m.id))!;
    expect(relinked.contactKey, 'k-ben');
    expect(relinked.cachedName, 'Ben');
    expect(directory.stateOf(relinked), LinkState.linked);
  });

  test('relinking to a contact already in a ring fails', () async {
    await add('k-ben', 'Ben');
    final m = await add('k-gone', 'Cy');
    await directory.refresh();
    await expectLater(directory.relink(m, ben), throwsA(isA<Exception>()));
  });

  test('nicknames survive contact renames, key changes and relinks', () async {
    final m = await add('k-ana-old', 'Ana');
    await db.setNickname(m.id, ' Mom ');
    expect((await db.memberById(m.id))!.nickname, 'Mom');

    // Contact renamed and its lookup key changed.
    source.contacts[0] = const PhoneContact(
      key: 'k-ana',
      id: '1',
      displayName: 'Ana Silva-Jones',
    );
    source.lookupAliases['k-ana-old'] = 'k-ana';
    await directory.refresh();
    var updated = (await db.memberById(m.id))!;
    expect(updated.contactKey, 'k-ana');
    expect(updated.cachedName, 'Ana Silva-Jones');
    expect(updated.nickname, 'Mom');
    expect(updated.displayName, 'Mom');

    await directory.relink(updated, ben);
    updated = (await db.memberById(m.id))!;
    expect(updated.cachedName, 'Ben');
    expect(updated.nickname, 'Mom');

    await db.setNickname(m.id, '  ');
    expect((await db.memberById(m.id))!.displayName, 'Ben');
  });

  test('dialableNumber keeps + and digits', () {
    expect(dialableNumber('+1 (202) 555-0101'), '+12025550101');
    expect(dialableNumber(' 202.555.0101 '), '2025550101');
  });
}
