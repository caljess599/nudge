import 'models.dart';

/// A contact in the phone's address book, reduced to what matching needs.
typedef ContactRef = ({String key, String name});

/// Matches members to the phone's contacts, as SPEC.md requires for
/// import: by `contact_key` first, falling back to name. Also used when
/// reconciling with the address book, e.g. after Android Auto Backup
/// restores the database on a new phone.
///
/// Contact keys differ between phones (and can change after a reinstall),
/// so restoring on a new phone mostly relies on the name match.
/// A name only counts if exactly one contact has it and no other member
/// already claimed that contact. Members that can't be matched keep their
/// key and will show "Needs relinking".
///
/// Returns the members with updated keys where a name match was found.
List<Member> matchMembersToContacts(
  List<Member> members,
  List<ContactRef> contacts,
) {
  final keys = {for (final c in contacts) c.key};
  final byName = <String, List<ContactRef>>{};
  for (final c in contacts) {
    byName.putIfAbsent(_normalise(c.name), () => []).add(c);
  }

  // Keys already matched exactly can't be claimed by a name match.
  final claimed = {
    for (final m in members)
      if (keys.contains(m.contactKey)) m.contactKey,
  };

  return [
    for (final m in members)
      if (keys.contains(m.contactKey))
        m
      else
        switch (byName[_normalise(m.cachedName)]) {
          [final only] when claimed.add(only.key) => m.copyWith(
            contactKey: only.key,
          ),
          _ => m,
        },
  ];
}

String _normalise(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
