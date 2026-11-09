import 'package:flutter/foundation.dart';

import '../core/models.dart';
import '../data/database.dart';
import 'contacts_source.dart';

enum LinkState {
  /// Found in the address book.
  linked,

  /// Full access, but the contact no longer exists (merged or deleted).
  needsRelinking,

  /// iOS limited access and this contact isn't shared with Nudge.
  notShared,

  /// No contacts access, or not loaded yet.
  unknown,
}

/// The phone's contacts as seen by Nudge, kept in memory and matched to
/// members by `contact_key`.
///
/// On every load it also reconciles members with the address book:
/// - refreshes `cached_name` when a contact was renamed,
/// - follows Android lookup keys that changed after a merge or re-sync,
/// - marks members whose contact is gone as needing relinking. They are
///   never deleted; their cached name keeps showing.
class ContactDirectory extends ChangeNotifier {
  final ContactsSource source;
  final AppDatabase db;

  ContactsAccess? _access;
  Map<String, PhoneContact> _byKey = const {};
  Set<String> _missingKeys = const {};
  Future<void>? _loading;

  ContactDirectory({required this.source, required this.db});

  /// Null until the first [refresh] completes.
  ContactsAccess? get access => _access;

  bool get isLoaded => _access != null;

  /// All visible contacts, sorted by name.
  List<PhoneContact> get contacts => _byKey.values.toList()
    ..sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );

  PhoneContact? contactFor(Member member) => _byKey[member.contactKey];

  LinkState stateOf(Member member) {
    final access = _access;
    if (access == null || !access.canRead) return LinkState.unknown;
    if (_byKey.containsKey(member.contactKey)) return LinkState.linked;
    if (_missingKeys.contains(member.contactKey)) {
      return LinkState.needsRelinking;
    }
    return access == ContactsAccess.limited
        ? LinkState.notShared
        : LinkState.unknown;
  }

  /// Reloads using the current access, without prompting.
  Future<void> refresh() => _load(() => source.checkAccess());

  /// Prompts for access if it hasn't been decided yet, then loads.
  Future<ContactsAccess> requestAccess() async {
    await _load(() => source.requestAccess());
    return _access!;
  }

  Future<void> openSettings() => source.openSettings();

  /// Points [member] at [contact], e.g. after the original was deleted.
  /// Throws if [contact] already belongs to another member.
  Future<void> relink(Member member, PhoneContact contact) async {
    await db.saveMember(
      member.copyWith(contactKey: contact.key, cachedName: contact.displayName),
    );
    _missingKeys = {..._missingKeys}..remove(member.contactKey);
    _byKey = {..._byKey, contact.key: contact};
    notifyListeners();
  }

  Future<void> _load(Future<ContactsAccess> Function() getAccess) {
    // Coalesce overlapping loads (e.g. app start and resume together).
    return _loading ??= () async {
      try {
        final access = await getAccess();
        if (access.canRead) {
          final all = await source.loadAll();
          _byKey = {for (final c in all) c.key: c};
          _missingKeys = await _reconcile(access);
        } else {
          _byKey = const {};
          _missingKeys = const {};
        }
        _access = access;
        notifyListeners();
      } finally {
        _loading = null;
      }
    }();
  }

  Future<Set<String>> _reconcile(ContactsAccess access) async {
    final missing = <String>{};
    final byKey = {..._byKey};
    for (final member in await db.allMembers()) {
      var contact = byKey[member.contactKey];
      if (contact == null) {
        // With limited access, an unseen contact may just not be shared.
        if (access == ContactsAccess.limited) continue;
        contact = await source.findByKey(member.contactKey);
        if (contact == null) {
          missing.add(member.contactKey);
          continue;
        }
        byKey[contact.key] = contact;
      }
      if (contact.key != member.contactKey ||
          contact.displayName != member.cachedName) {
        try {
          await db.saveMember(
            member.copyWith(
              contactKey: contact.key,
              cachedName: contact.displayName,
            ),
          );
        } on Exception {
          // The new key already belongs to another member (two members
          // merged into one contact). Keep this one visible for relinking.
          missing.add(member.contactKey);
        }
      }
    }
    _byKey = byKey;
    return missing;
  }
}
