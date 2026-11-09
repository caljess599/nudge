import 'contacts_source.dart';

/// Contact keys of fake contacts all start with this, so they can never
/// collide with real Android lookup keys or iOS identifiers.
const fakeContactKeyPrefix = 'debug-fake:';

bool isFakeContactKey(String key) => key.startsWith(fakeContactKeyPrefix);

const _fakeNames = [
  'Alex Lee', 'Bea Moreno', 'Cam Okafor', 'Dana Schmidt', 'Eli Cohen', //
  'Farah Haddad', 'Gus Lindqvist', 'Hana Sato', 'Ivo Petrov', 'Jules Martin',
  'Kai Nakamura', 'Lena Novak', 'Milo Esposito', 'Nia Mensah', 'Omar Farouk',
  'Pia Rossi', 'Quinn Murphy', 'Rosa Diaz', 'Sami Heikkinen', 'Tess Walker',
  'Uma Lal', 'Vic Duarte', 'Wren Adler', 'Xavi Ruiz', 'Yara Haddad',
  'Zeke Stone', 'Ada Brooks', 'Ben Ortiz', 'Cleo Park', 'Dev Shah',
  'Edie Clarke', 'Finn Byrne', 'Gia Romano', 'Hugo Weber', 'Iris Tan',
  'Jon Price', 'Kira Volkova', 'Leo Moreau', 'Maya Patel', 'Noor Aziz',
];

/// 40 fake contacts with 555-01xx numbers (reserved for fiction).
final List<PhoneContact> fakePhoneContacts = [
  for (var i = 0; i < _fakeNames.length; i++)
    PhoneContact(
      key: '$fakeContactKeyPrefix${i.toString().padLeft(2, '0')}',
      id: '$fakeContactKeyPrefix$i',
      displayName: _fakeNames[i],
      phones: [
        PhoneNumber(
          '+1 202 555 01${i.toString().padLeft(2, '0')}',
          label: 'Mobile',
          isMobile: true,
        ),
        if (i % 4 == 0)
          PhoneNumber(
            '+1 202 555 02${i.toString().padLeft(2, '0')}',
            label: 'Work',
          ),
      ],
    ),
];

/// An in-memory address book for tests.
class FakeContactsSource implements ContactsSource {
  ContactsAccess access;
  ContactsAccess? accessAfterRequest;
  final List<PhoneContact> contacts;
  final List<PhoneContact> opened = [];

  /// Old key -> current key, like Android lookup keys that change after a
  /// merge or re-sync but still resolve through `findByKey`.
  final Map<String, String> lookupAliases = {};
  int requests = 0;
  int settingsOpened = 0;

  FakeContactsSource({
    List<PhoneContact>? contacts,
    this.access = ContactsAccess.granted,
    this.accessAfterRequest,
  }) : contacts = contacts ?? List.of(fakePhoneContacts);

  @override
  Future<ContactsAccess> checkAccess() async => access;

  @override
  Future<ContactsAccess> requestAccess() async {
    requests++;
    if (access == ContactsAccess.canAsk) {
      access = accessAfterRequest ?? ContactsAccess.granted;
    }
    return access;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<List<PhoneContact>> loadAll() async =>
      access.canRead ? List.of(contacts) : const [];

  @override
  Future<PhoneContact?> findByKey(String key) async {
    if (!access.canRead) return null;
    final current = lookupAliases[key] ?? key;
    for (final c in contacts) {
      if (c.key == current) return c;
    }
    return null;
  }

  @override
  Future<void> openContactCard(PhoneContact contact) async =>
      opened.add(contact);
}

/// Debug builds: the real address book plus the fake contacts, so the
/// picker can be exercised on an emulator with no contacts. Fake ones are
/// only shown once contacts access is granted, like real ones.
class DebugContactsSource implements ContactsSource {
  final ContactsSource real;

  const DebugContactsSource(this.real);

  @override
  Future<ContactsAccess> checkAccess() => real.checkAccess();

  @override
  Future<ContactsAccess> requestAccess() => real.requestAccess();

  @override
  Future<void> openSettings() => real.openSettings();

  @override
  Future<List<PhoneContact>> loadAll() async => [
    ...await real.loadAll(),
    if ((await real.checkAccess()).canRead) ...fakePhoneContacts,
  ];

  @override
  Future<PhoneContact?> findByKey(String key) async {
    if (!isFakeContactKey(key)) return real.findByKey(key);
    for (final c in fakePhoneContacts) {
      if (c.key == key) return c;
    }
    return null;
  }

  @override
  Future<void> openContactCard(PhoneContact contact) async {
    // Fake contacts have no card to open.
    if (!isFakeContactKey(contact.key)) await real.openContactCard(contact);
  }
}
