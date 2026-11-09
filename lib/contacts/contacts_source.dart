/// Read-only access to the phone's address book.
///
/// Screens talk to this interface, never to a plugin directly, so tests
/// and debug builds can supply fake contacts.
abstract interface class ContactsSource {
  /// Current access without prompting.
  Future<ContactsAccess> checkAccess();

  /// Shows the system prompt if access hasn't been decided yet.
  Future<ContactsAccess> requestAccess();

  /// Opens this app's page in system settings so access can be changed.
  Future<void> openSettings();

  /// Every contact visible to the app, with phone numbers.
  Future<List<PhoneContact>> loadAll();

  /// Looks up one contact by a stored key, following Android's lookup
  /// rules so contacts that were merged or re-synced are still found.
  /// Returns null if the contact no longer exists.
  Future<PhoneContact?> findByKey(String key);

  /// Opens the contact in the system contacts app.
  Future<void> openContactCard(PhoneContact contact);
}

enum ContactsAccess {
  /// Full access.
  granted,

  /// iOS 18+: the user shared only some contacts.
  limited,

  /// Not decided yet, or denied but can be asked again.
  canAsk,

  /// Denied permanently or restricted; only system settings can change it.
  blocked;

  bool get canRead => this == granted || this == limited;
}

class PhoneContact {
  /// Stable key stored in `members.contact_key`: the Android lookup key,
  /// or the iOS contact identifier.
  final String key;

  /// Platform contact id used to open the contact card. May change over
  /// time on Android, so it's never stored.
  final String id;

  final String displayName;
  final List<PhoneNumber> phones;

  const PhoneContact({
    required this.key,
    required this.id,
    required this.displayName,
    this.phones = const [],
  });
}

class PhoneNumber {
  final String number;

  /// Human-readable label, e.g. "Mobile". Empty if unknown.
  final String label;
  final bool isMobile;

  const PhoneNumber(this.number, {this.label = '', this.isMobile = false});
}
