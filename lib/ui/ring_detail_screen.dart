import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../core/actions.dart';
import '../core/calendar_date.dart';
import '../core/due_dates.dart';
import '../core/models.dart';
import '../contacts/contact_directory.dart';
import '../debug/seed.dart';
import 'contact_picker_screen.dart';
import 'formatting.dart';
import 'nickname_dialog.dart';
import 'reach_out.dart';
import 'ring_form_dialog.dart';

class RingDetailScreen extends StatefulWidget {
  final int ringId;

  const RingDetailScreen({super.key, required this.ringId});

  @override
  State<RingDetailScreen> createState() => _RingDetailScreenState();
}

class _RingDetailScreenState extends State<RingDetailScreen> {
  late Stream<Ring?> _ring;
  late Stream<List<Member>> _members;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = AppScope.of(context).db;
    _ring = db.watchRing(widget.ringId);
    _members = db.watchMembersOfRing(widget.ringId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Ring?>(
      stream: _ring,
      builder: (context, snapshot) {
        final ring = snapshot.data;
        if (ring == null) {
          // Loading, or the ring was just deleted.
          return Scaffold(appBar: AppBar());
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(ring.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit ring',
                onPressed: () => _editRing(context, ring),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete ring',
                onPressed: () => _deleteRing(context, ring),
              ),
              if (kDebugMode)
                IconButton(
                  icon: const Icon(Icons.bug_report_outlined),
                  tooltip: 'Debug: add 3 due fake people',
                  onPressed: () => _addFakePeople(context, ring),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Add people'),
            onPressed: () => _addPeople(context, ring),
          ),
          body: StreamBuilder<List<Member>>(
            stream: _members,
            builder: (context, snapshot) {
              final members = snapshot.data;
              if (members == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return _MemberList(ring: ring, members: members);
            },
          ),
        );
      },
    );
  }

  Future<void> _editRing(BuildContext context, Ring ring) async {
    final db = AppScope.of(context).db;
    final result = await showRingForm(
      context,
      initialName: ring.name,
      initialPeriodDays: ring.periodDays,
    );
    if (result == null) return;
    await db.updateRing(
      ring.copyWith(name: result.name, periodDays: result.periodDays),
    );
  }

  Future<void> _deleteRing(BuildContext context, Ring ring) async {
    final db = AppScope.of(context).db;
    final navigator = Navigator.of(context);
    final summaries = await db.ringSummaries();
    final count = summaries.firstWhere((s) => s.ring.id == ring.id).memberCount;
    final others = [
      for (final s in summaries)
        if (s.ring.id != ring.id) s.ring,
    ];
    if (!context.mounted) return;

    if (count == 0) {
      final ok = await _confirm(
        context,
        title: 'Delete "${ring.name}"?',
        body: 'This ring has no people in it.',
        action: 'Delete',
      );
      if (ok != true) return;
      navigator.pop();
      await db.deleteRing(ring.id);
      return;
    }

    if (others.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Can\'t delete this ring yet'),
          content: Text(
            '"${ring.name}" has ${peopleCount(count)}. Create another ring '
            'to move them to first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final target = await showDialog<Ring>(
      context: context,
      builder: (_) =>
          _MoveMembersDialog(ring: ring, count: count, others: others),
    );
    if (target == null) return;
    navigator.pop();
    await db.deleteRingMovingMembers(ring.id, toRingId: target.id);
  }

  Future<void> _addPeople(BuildContext context, Ring ring) async {
    final messenger = ScaffoldMessenger.of(context);
    final added = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => ContactPickerScreen(ring: ring)),
    );
    if (added != null && added > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text('Added ${peopleCount(added)} to ${ring.name}')),
      );
    }
  }

  Future<void> _addFakePeople(BuildContext context, Ring ring) async {
    final scope = AppScope.of(context);
    await addFakeMembers(
      scope.db,
      ring,
      3,
      today: scope.clock.today(),
      random: Random(),
      overdue: true,
    );
  }
}

class _MoveMembersDialog extends StatefulWidget {
  final Ring ring;
  final int count;
  final List<Ring> others;

  const _MoveMembersDialog({
    required this.ring,
    required this.count,
    required this.others,
  });

  @override
  State<_MoveMembersDialog> createState() => _MoveMembersDialogState();
}

class _MoveMembersDialogState extends State<_MoveMembersDialog> {
  late Ring _target = widget.others.first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete "${widget.ring.name}"?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Move its ${peopleCount(widget.count)} to another ring first. '
            'Their contact history is kept.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Ring>(
            initialValue: _target,
            decoration: const InputDecoration(labelText: 'Move to'),
            items: [
              for (final r in widget.others)
                DropdownMenuItem(value: r, child: Text(r.name)),
            ],
            onChanged: (r) => setState(() => _target = r ?? _target),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _target),
          child: const Text('Move and delete'),
        ),
      ],
    );
  }
}

class _MemberList extends StatelessWidget {
  final Ring ring;
  final List<Member> members;

  const _MemberList({required this.ring, required this.members});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.contacts,
      builder: (context, _) => _build(context, scope),
    );
  }

  Widget _build(BuildContext context, AppScope scope) {
    final today = scope.clock.today();
    if (members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No one in this ring yet.\n${periodLabel(ring.periodDays)}\n\n'
            'Tap "Add people" to choose from your contacts.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final sorted = [...members]
      ..sort((a, b) {
        final byDue = nextDue(a, ring).compareTo(nextDue(b, ring));
        return byDue != 0
            ? byDue
            : a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              );
      });
    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${periodLabel(ring.periodDays)} · ${peopleCount(members.length)}'
            ' · soonest due first',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final m in sorted)
          ListTile(
            title: Text(m.displayName),
            subtitle: Text(
              '${dueLabel(context, m, ring, today)} · '
              '${lastContactLabel(context, m)}',
            ),
            trailing: scope.contacts.stateOf(m) == LinkState.needsRelinking
                ? const _NeedsRelinkingChip()
                : null,
            onTap: () => _showMemberSheet(context, m, ring, today),
          ),
      ],
    );
  }
}

Future<void> _showMemberSheet(
  BuildContext context,
  Member member,
  Ring ring,
  CalendarDate today,
) {
  final scope = AppScope.of(context);
  final db = scope.db;
  final contact = scope.contacts.contactFor(member);
  final needsRelinking =
      scope.contacts.stateOf(member) == LinkState.needsRelinking;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              member.displayName,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            subtitle: Text(
              [
                // With a nickname, show who it is in your contacts too.
                if (member.nickname != null) member.cachedName,
                '${dueLabel(sheetContext, member, ring, today)} · '
                    '${lastContactLabel(sheetContext, member)}',
              ].join('\n'),
            ),
            isThreeLine: member.nickname != null,
            trailing: contact == null
                ? null
                : ReachOutButtons(contact: contact),
          ),
          if (needsRelinking)
            ListTile(
              leading: Icon(
                Icons.link_off,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: const Text('Relink to a contact'),
              subtitle: const Text(
                'This contact was deleted or merged on your phone. '
                'Pick the contact it should use now.',
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(
                  MaterialPageRoute<int>(
                    builder: (_) =>
                        ContactPickerScreen(ring: ring, relinking: member),
                  ),
                );
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.check),
            title: const Text('Reached out today'),
            onTap: () async {
              Navigator.pop(sheetContext);
              await db.applyAction(reachedOut(member, today: today));
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Nickname'),
            subtitle: Text(member.nickname ?? 'Not set'),
            onTap: () async {
              Navigator.pop(sheetContext);
              final nickname = await showNicknameDialog(context, member);
              if (nickname != null) await db.setNickname(member.id, nickname);
            },
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_move_outline),
            title: const Text('Move to another ring'),
            onTap: () async {
              Navigator.pop(sheetContext);
              final target = await _pickRing(context, exclude: ring);
              if (target != null) await db.moveMember(member, target);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined),
            title: const Text('Remove from Nudge'),
            subtitle: const Text('Doesn\'t touch your phone\'s contacts'),
            onTap: () async {
              Navigator.pop(sheetContext);
              final ok = await _confirm(
                context,
                title: 'Remove ${member.displayName}?',
                body:
                    'They\'ll be removed from "${ring.name}" and their '
                    'nudge history in Nudge is deleted. Your phone\'s '
                    'contacts are not changed.',
                action: 'Remove',
              );
              if (ok == true) await db.deleteMember(member.id);
            },
          ),
        ],
      ),
    ),
  );
}

class _NeedsRelinkingChip extends StatelessWidget {
  const _NeedsRelinkingChip();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Tooltip(
      message: 'Contact not found. Tap to relink.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_off, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            'Needs relinking',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

Future<Ring?> _pickRing(BuildContext context, {required Ring exclude}) async {
  final db = AppScope.of(context).db;
  final rings = (await db.allRings()).where((r) => r.id != exclude.id);
  if (!context.mounted) return null;
  if (rings.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Create another ring first')));
    return null;
  }
  return showDialog<Ring>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Move to'),
      children: [
        for (final r in rings)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, r),
            child: ListTile(
              title: Text(r.name),
              subtitle: Text(periodLabel(r.periodDays)),
            ),
          ),
      ],
    ),
  );
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(title),
    content: Text(body),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(action),
      ),
    ],
  ),
);
