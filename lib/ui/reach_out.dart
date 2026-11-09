import 'package:flutter/material.dart';

import '../app.dart';
import '../contacts/contacts_source.dart';

enum ReachOutKind { call, text, contactCard }

/// Opens the dialer, messaging app, or system contact card for [contact].
/// If the contact has several numbers, asks which one first.
///
/// Returns true if another app was opened.
Future<bool> reachOut(
  BuildContext context,
  PhoneContact contact,
  ReachOutKind kind,
) async {
  final scope = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);

  if (kind == ReachOutKind.contactCard) {
    await scope.contacts.source.openContactCard(contact);
    return true;
  }

  final number = await _pickNumber(context, contact, kind);
  if (number == null) return false;
  final opened = kind == ReachOutKind.call
      ? await scope.launcher.call(number)
      : await scope.launcher.text(number);
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          kind == ReachOutKind.call
              ? 'No app found for phone calls'
              : 'No app found for text messages',
        ),
      ),
    );
  }
  return opened;
}

Future<String?> _pickNumber(
  BuildContext context,
  PhoneContact contact,
  ReachOutKind kind,
) async {
  final phones = contact.phones;
  if (phones.isEmpty) return null;
  if (phones.length == 1) return phones.single.number;
  // Mobiles first: they're the ones that can receive texts.
  final sorted = [...phones]
    ..sort((a, b) => (b.isMobile ? 1 : 0) - (a.isMobile ? 1 : 0));
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              kind == ReachOutKind.call
                  ? 'Call ${contact.displayName}'
                  : 'Text ${contact.displayName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final p in sorted)
            ListTile(
              leading: Icon(
                p.isMobile ? Icons.smartphone : Icons.phone_outlined,
              ),
              title: Text(p.number),
              subtitle: p.label.isEmpty ? null : Text(p.label),
              onTap: () => Navigator.pop(context, p.number),
            ),
        ],
      ),
    ),
  );
}

/// Call / Text / contact-card icon buttons. Call and Text only appear if
/// the contact has a phone number.
class ReachOutButtons extends StatelessWidget {
  final PhoneContact contact;

  /// Called after another app was opened.
  final void Function(ReachOutKind kind)? onLaunched;

  const ReachOutButtons({super.key, required this.contact, this.onLaunched});

  Future<void> _go(BuildContext context, ReachOutKind kind) async {
    if (await reachOut(context, contact, kind)) onLaunched?.call(kind);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = contact.phones.isNotEmpty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasPhone) ...[
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            tooltip: 'Call',
            onPressed: () => _go(context, ReachOutKind.call),
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            tooltip: 'Text',
            onPressed: () => _go(context, ReachOutKind.text),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.contact_page_outlined),
          tooltip: 'Open contact card',
          onPressed: () => _go(context, ReachOutKind.contactCard),
        ),
      ],
    );
  }
}
