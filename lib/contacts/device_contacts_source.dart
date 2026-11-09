import 'dart:io';

import 'package:flutter_contacts/flutter_contacts.dart' as fc;

import 'contacts_source.dart';

/// Reads the real address book through `flutter_contacts`. Read-only:
/// Nudge never writes to the user's contacts.
class DeviceContactsSource implements ContactsSource {
  const DeviceContactsSource();

  static const _properties = {
    fc.ContactProperty.phone,
    fc.ContactProperty.identifiers,
  };

  @override
  Future<ContactsAccess> checkAccess() async =>
      _map(await fc.FlutterContacts.permissions.check(fc.PermissionType.read));

  @override
  Future<ContactsAccess> requestAccess() async => _map(
    await fc.FlutterContacts.permissions.request(fc.PermissionType.read),
  );

  @override
  Future<void> openSettings() => fc.FlutterContacts.permissions.openSettings();

  @override
  Future<List<PhoneContact>> loadAll() async {
    final contacts = await fc.FlutterContacts.getAll(properties: _properties);
    return [for (final c in contacts) ?_convert(c)];
  }

  @override
  Future<PhoneContact?> findByKey(String key) async {
    try {
      final contact = await fc.FlutterContacts.get(
        key,
        properties: _properties,
        androidLookup: Platform.isAndroid,
      );
      return contact == null ? null : _convert(contact);
    } on Exception {
      // A malformed or stale key means "not found", not a crash.
      return null;
    }
  }

  @override
  Future<void> openContactCard(PhoneContact contact) =>
      fc.FlutterContacts.native.showViewer(contact.id);

  static PhoneContact? _convert(fc.Contact c) {
    final id = c.id;
    if (id == null) return null;
    final key = (Platform.isAndroid ? c.android?.identifiers?.lookupKey : null);
    final name = c.displayName?.trim();
    return PhoneContact(
      key: key ?? id,
      id: id,
      displayName: (name == null || name.isEmpty) ? '(No name)' : name,
      phones: [
        for (final p in c.phones)
          if (p.number.trim().isNotEmpty)
            PhoneNumber(
              p.number,
              label: _label(p.label),
              isMobile: const {
                fc.PhoneLabel.mobile,
                fc.PhoneLabel.iPhone,
                fc.PhoneLabel.workMobile,
              }.contains(p.label.label),
            ),
      ],
    );
  }

  static String _label(fc.Label<fc.PhoneLabel> label) {
    final custom = label.customLabel?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final name = label.label.name;
    if (label.label == fc.PhoneLabel.custom) return '';
    // "workMobile" -> "Work mobile"
    final words = name.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => ' ${m[0]!.toLowerCase()}',
    );
    return words[0].toUpperCase() + words.substring(1);
  }

  static ContactsAccess _map(fc.PermissionStatus status) => switch (status) {
    fc.PermissionStatus.granted => ContactsAccess.granted,
    fc.PermissionStatus.limited => ContactsAccess.limited,
    fc.PermissionStatus.denied ||
    fc.PermissionStatus.notDetermined => ContactsAccess.canAsk,
    fc.PermissionStatus.permanentlyDenied ||
    fc.PermissionStatus.restricted => ContactsAccess.blocked,
  };
}
