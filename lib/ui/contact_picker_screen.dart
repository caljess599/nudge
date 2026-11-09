import 'dart:math';

import 'package:flutter/material.dart';

import '../app.dart';
import '../contacts/contact_directory.dart';
import '../contacts/contacts_source.dart';
import '../core/models.dart';
import '../data/database.dart';
import 'formatting.dart';

/// Searchable contact list.
///
/// - Add mode (default): pick any number of contacts and add them all to
///   [ring] in one transaction. Contacts already in a ring are greyed out;
///   those in another ring offer "Move here".
/// - Relink mode ([relinking] set): tap one contact to point that member
///   at it.
///
/// Asks for contacts access when opened, if it hasn't been decided yet.
/// Pops with the number of people added (or 1 after a relink).
class ContactPickerScreen extends StatefulWidget {
  final Ring ring;
  final Member? relinking;

  const ContactPickerScreen({super.key, required this.ring, this.relinking});

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  final _search = TextEditingController();
  final _selected = <String>{};
  bool _asked = false;
  bool _saving = false;

  late final AppScope _scope = AppScope.of(context);
  late final Stream<List<Member>> _members = _scope.db.watchAllMembers();
  late final Stream<List<RingSummary>> _rings = _scope.db.watchRingSummaries();

  bool get _relinkMode => widget.relinking != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureAccess());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// The user just asked to add people, which is when SPEC.md says to
  /// request access. Ask at most once per visit to this screen.
  Future<void> _ensureAccess() async {
    final contacts = _scope.contacts;
    if (!contacts.isLoaded) await contacts.refresh();
    if (contacts.access == ContactsAccess.canAsk && !_asked) {
      _asked = true;
      await contacts.requestAccess();
    }
  }

  Future<void> _addSelected(List<PhoneContact> visible) async {
    setState(() => _saving = true);
    final byKey = {for (final c in visible) c.key: c};
    final toAdd = [
      for (final key in _selected)
        if (byKey[key] case final c?)
          NewMember(contactKey: c.key, cachedName: c.displayName),
    ];
    try {
      await _scope.db.addMembers(
        widget.ring,
        toAdd,
        today: _scope.clock.today(),
        random: Random(),
      );
      if (mounted) Navigator.of(context).pop(toAdd.length);
    } on Exception {
      // Someone was added elsewhere meanwhile; nothing was saved.
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Couldn\'t add them. Please try again.');
    }
  }

  Future<void> _moveHere(Member member, String fromRing) async {
    await _scope.db.moveMember(member, widget.ring);
    _snack('Moved ${member.cachedName} from $fromRing');
  }

  Future<void> _relinkTo(PhoneContact contact) async {
    try {
      await _scope.contacts.relink(widget.relinking!, contact);
      if (mounted) Navigator.of(context).pop(1);
    } on Exception {
      _snack('${contact.displayName} is already in a ring');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = _relinkMode
        ? 'Relink ${widget.relinking!.cachedName}'
        : 'Add to ${widget.ring.name}';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListenableBuilder(
        listenable: _scope.contacts,
        builder: (context, _) {
          final directory = _scope.contacts;
          return switch (directory.access) {
            null => const Center(child: CircularProgressIndicator()),
            ContactsAccess.canAsk => _AccessMessage(
              message:
                  'Nudge needs access to your contacts to add people. '
                  'Contacts stay on your device.',
              buttonLabel: 'Allow access',
              onPressed: directory.requestAccess,
            ),
            ContactsAccess.blocked => _AccessMessage(
              message:
                  'Contacts access is turned off for Nudge. You can turn it '
                  'on in Settings.',
              buttonLabel: 'Open Settings',
              onPressed: directory.openSettings,
            ),
            ContactsAccess.granted ||
            ContactsAccess.limited => _buildList(context, directory),
          };
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, ContactDirectory directory) {
    return StreamBuilder<List<Member>>(
      stream: _members,
      builder: (context, membersSnap) => StreamBuilder<List<RingSummary>>(
        stream: _rings,
        builder: (context, ringsSnap) {
          final members = membersSnap.data;
          final rings = ringsSnap.data;
          if (members == null || rings == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final memberByKey = {for (final m in members) m.contactKey: m};
          final ringNames = {for (final s in rings) s.ring.id: s.ring.name};
          final all = directory.contacts;
          final visible = _filter(all);

          return Column(
            children: [
              if (directory.access == ContactsAccess.limited)
                _LimitedAccessBanner(onSettings: directory.openSettings),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search contacts',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: all.isEmpty
                    ? const Center(child: Text('No contacts found'))
                    : visible.isEmpty
                    ? const Center(child: Text('No matches'))
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, i) => _row(
                          context,
                          visible[i],
                          memberByKey[visible[i].key],
                          ringNames,
                        ),
                      ),
              ),
              if (!_relinkMode) _addBar(context, all),
            ],
          );
        },
      ),
    );
  }

  List<PhoneContact> _filter(List<PhoneContact> contacts) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return contacts;
    final digits = query.replaceAll(RegExp(r'[^0-9]'), '');
    return [
      for (final c in contacts)
        if (c.displayName.toLowerCase().contains(query) ||
            (digits.length >= 3 &&
                c.phones.any(
                  (p) => p.number
                      .replaceAll(RegExp(r'[^0-9]'), '')
                      .contains(digits),
                )))
          c,
    ];
  }

  Widget _row(
    BuildContext context,
    PhoneContact contact,
    Member? member,
    Map<int, String> ringNames,
  ) {
    final phone = contact.phones.isEmpty ? null : contact.phones.first.number;

    if (member != null) {
      final inThisRing = member.ringId == widget.ring.id;
      final ringName = ringNames[member.ringId] ?? 'another ring';
      return CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading,
        value: inThisRing,
        onChanged: null,
        title: Text(contact.displayName),
        subtitle: Text(inThisRing ? 'Already in this ring' : 'In $ringName'),
        secondary: inThisRing || _relinkMode
            ? null
            : TextButton(
                onPressed: () => _moveHere(member, ringName),
                child: const Text('Move here'),
              ),
      );
    }

    if (_relinkMode) {
      return ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(contact.displayName),
        subtitle: phone == null ? null : Text(phone),
        onTap: () => _relinkTo(contact),
      );
    }

    return CheckboxListTile(
      controlAffinity: ListTileControlAffinity.leading,
      value: _selected.contains(contact.key),
      title: Text(contact.displayName),
      subtitle: phone == null ? null : Text(phone),
      onChanged: (checked) => setState(
        () => checked == true
            ? _selected.add(contact.key)
            : _selected.remove(contact.key),
      ),
    );
  }

  Widget _addBar(BuildContext context, List<PhoneContact> all) {
    final count = _selected.length;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: count == 0 || _saving ? null : () => _addSelected(all),
            child: Text(
              count == 0 ? 'Select people' : 'Add ${peopleCount(count)}',
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessMessage extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final Future<void> Function() onPressed;

  const _AccessMessage({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}

class _LimitedAccessBanner extends StatelessWidget {
  final Future<void> Function() onSettings;

  const _LimitedAccessBanner({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      leading: const Icon(Icons.info_outline),
      content: const Text(
        'You\'ve shared only some contacts with Nudge. To add someone '
        'else, allow more contacts in Settings.',
      ),
      actions: [
        TextButton(onPressed: onSettings, child: const Text('Settings')),
      ],
    );
  }
}
