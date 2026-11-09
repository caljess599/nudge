import 'package:flutter/material.dart';

import '../app.dart';
import '../contacts/contacts_source.dart';
import '../core/models.dart';
import '../core/reach_methods.dart';

IconData reachIcon(ReachMethod method) => switch (method) {
  ReachMethod.call => Icons.phone_outlined,
  ReachMethod.text => Icons.sms_outlined,
  ReachMethod.whatsapp ||
  ReachMethod.signal ||
  ReachMethod.telegram => Icons.chat_bubble_outline,
  ReachMethod.link => Icons.link,
};

/// The contact's numbers, mobiles first.
List<PhoneNumber> sortedPhones(PhoneContact? contact) => [
  ...?contact?.phones.where((p) => p.isMobile),
  ...?contact?.phones.where((p) => !p.isMobile),
];

/// Opens [method] for [member]. Uses the member's saved number or link
/// when [method] is their preference; otherwise the contact's number,
/// asking which one if there are several. Returns true if another app
/// was opened.
Future<bool> reachOut(
  BuildContext context, {
  required Member member,
  required PhoneContact? contact,
  required ReachMethod method,
}) async {
  final scope = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  void say(String message) =>
      messenger.showSnackBar(SnackBar(content: Text(message)));

  final saved = member.reachVia == method ? member.reachValue : null;
  String? value = saved;
  if (value == null) {
    if (method == ReachMethod.link) {
      say('No link saved for ${member.displayName}');
      return false;
    }
    final phones = sortedPhones(contact);
    if (phones.isEmpty) {
      say('No phone number for ${member.displayName}');
      return false;
    }
    // Their preferred method with no saved number means "mobile number":
    // use it without asking. Other methods ask if there are several.
    value = phones.length == 1 || member.reachVia == method
        ? phones.first.number
        : await _pickNumber(context, member, phones, method);
    if (value == null) return false;
  }

  final opened = await scope.launcher.open(method, value);
  if (!opened) {
    say(switch (method) {
      ReachMethod.call => 'No app found for phone calls',
      ReachMethod.text => 'No app found for text messages',
      ReachMethod.link => 'Couldn\'t open the link',
      _ => 'Couldn\'t open ${method.label}. Is it installed?',
    });
  }
  return opened;
}

Future<String?> _pickNumber(
  BuildContext context,
  Member member,
  List<PhoneNumber> phones,
  ReachMethod method,
) => showModalBottomSheet<String>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(switch (method) {
            ReachMethod.call => 'Call ${member.displayName}',
            ReachMethod.text => 'Text ${member.displayName}',
            _ => '${method.label}: ${member.displayName}',
          }, style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final p in phones)
          ListTile(
            leading: Icon(p.isMobile ? Icons.smartphone : Icons.phone_outlined),
            title: Text(p.number),
            subtitle: p.label.isEmpty ? null : Text(p.label),
            onTap: () => Navigator.pop(context, p.number),
          ),
      ],
    ),
  ),
);

/// The reach-out buttons for a person:
/// - Preference set to WhatsApp, Signal, Telegram or a link: one labelled
///   button for it.
/// - Otherwise: Call and Text (if they have a number), with the preferred
///   one highlighted.
/// - Always: Open contact card, if the contact is found.
class ReachOutButtons extends StatelessWidget {
  final Member member;
  final PhoneContact? contact;

  /// Called after another app was opened.
  final VoidCallback? onLaunched;

  const ReachOutButtons({
    super.key,
    required this.member,
    required this.contact,
    this.onLaunched,
  });

  Future<void> _go(BuildContext context, ReachMethod method) async {
    final opened = await reachOut(
      context,
      member: member,
      contact: contact,
      method: method,
    );
    if (opened) onLaunched?.call();
  }

  Future<void> _openCard(BuildContext context, PhoneContact contact) async {
    await AppScope.of(context).contacts.source.openContactCard(contact);
    onLaunched?.call();
  }

  @override
  Widget build(BuildContext context) {
    final preferred = member.reachVia;
    final contact = this.contact;
    final hasPhone = contact != null && contact.phones.isNotEmpty;
    final buttons = <Widget>[];

    if (preferred != null &&
        (preferred.isMessagingApp || preferred == ReachMethod.link)) {
      buttons.add(
        FilledButton.tonalIcon(
          icon: Icon(reachIcon(preferred), size: 18),
          label: Text(preferred.label),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: () => _go(context, preferred),
        ),
      );
    } else if (hasPhone || member.reachValue != null) {
      for (final (method, tooltip) in [
        (ReachMethod.call, 'Call'),
        (ReachMethod.text, 'Text'),
      ]) {
        final icon = Icon(reachIcon(method));
        buttons.add(
          preferred == method
              ? IconButton.filledTonal(
                  icon: icon,
                  tooltip: tooltip,
                  onPressed: () => _go(context, method),
                )
              : IconButton(
                  icon: icon,
                  tooltip: tooltip,
                  onPressed: () => _go(context, method),
                ),
        );
      }
    }
    if (contact != null) {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.contact_page_outlined),
          tooltip: 'Open contact card',
          onPressed: () => _openCard(context, contact),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}

/// "WhatsApp · +1 202 555 0101", "Text message", or the default.
String reachSummary(Member member) {
  final method = member.reachVia;
  if (method == null) return 'Not set: Call, Text and contact card';
  final value = member.reachValue;
  if (value == null) {
    return method.usesPhoneNumber
        ? '${method.label} · mobile number'
        : method.label;
  }
  return '${method.label} · $value';
}
