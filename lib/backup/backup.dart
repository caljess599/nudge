import 'dart:convert';
import 'dart:typed_data';

import '../contacts/contact_directory.dart';
import '../core/calendar_date.dart';
import '../core/contact_matching.dart';
import '../core/export_format.dart';
import '../data/database.dart';
import 'data_files.dart';

/// Export and import of everything in Nudge as one JSON file.
class Backup {
  final AppDatabase db;
  final DataFiles files;
  final ContactDirectory contacts;

  const Backup({required this.db, required this.files, required this.contacts});

  /// `nudge-backup-2026-11-09.json`
  static String fileName(CalendarDate today) => 'nudge-backup-$today.json';

  /// Returns false if the user cancelled the save screen.
  Future<bool> export({required DateTime now}) async {
    final text = encodeExport(await db.exportData(), exportedAt: now);
    return files.save(
      fileName(CalendarDate.fromDateTime(now)),
      Uint8List.fromList(utf8.encode(text)),
    );
  }

  /// Lets the user pick a file and checks it. Returns null if cancelled.
  /// Throws [FormatException] (with a user-facing message) if the file
  /// isn't a valid backup.
  Future<ExportData?> pickBackup() async {
    final bytes = await files.open();
    if (bytes == null) return null;
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw const FormatException('This isn\'t a Nudge backup file.');
    }
    return decodeExport(text);
  }

  /// Replaces all data with [data]. Contacts are matched by key, then by
  /// name if contacts access has been granted (e.g. on a new phone, where
  /// keys differ). Returns how many people were matched to a contact.
  Future<int> restore(ExportData data) async {
    var restored = data;
    final access = contacts.access ?? await contacts.source.checkAccess();
    if (access.canRead) {
      final phone = await contacts.source.loadAll();
      restored = data.copyWith(
        members: matchMembersToContacts(data.members, [
          for (final c in phone) (key: c.key, name: c.displayName),
        ]),
      );
    }
    await db.replaceAllData(restored);
    // Refresh names and "Needs relinking" against the new data.
    await contacts.refresh();
    final members = await db.allMembers();
    return members.where((m) => contacts.stateOf(m) == LinkState.linked).length;
  }
}
