import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../core/actions.dart';
import '../core/calendar_date.dart';
import '../core/models.dart';
import '../data/database.dart';
import 'formatting.dart';
import 'reach_out.dart';

/// How many days of past nudges to show so people can check them off late.
const recentDays = 7;

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  CalendarDate? _today;

  /// Set when Call/Text/contact card opened another app for this nudge,
  /// so we can ask "Did you reach out?" when the user comes back.
  NudgeEntry? _awaitingReturn;
  Stream<List<NudgeEntry>>? _entries;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshIfNewDay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The app may stay open past midnight; pick a new day's nudges on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _refreshIfNewDay();
    final entry = _awaitingReturn;
    _awaitingReturn = null;
    if (entry != null) _askDidReachOut(entry);
  }

  Future<void> _askDidReachOut(NudgeEntry entry) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Did you reach out to ${entry.member.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    // Use the latest saved state in case it changed meanwhile.
    final member = await scope.db.memberById(entry.member.id);
    final nudges = await scope.db.nudgesOn(entry.nudge.date);
    final nudge = nudges
        .where((n) => n.memberId == entry.member.id)
        .firstOrNull;
    if (member == null) return;
    final today = scope.clock.today();
    await scope.db.applyAction(
      reachedOut(
        member,
        today: today,
        nudge: nudge?.status == NudgeStatus.pending ? nudge : null,
      ),
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('Marked as reached out')),
    );
  }

  void _refreshIfNewDay() {
    final scope = AppScope.of(context);
    final today = scope.clock.today();
    if (today == _today) return;
    _today = today;
    // Generates today's picks once; later calls return the saved ones.
    unawaited(scope.db.ensureDailyNudges(today));
    setState(() {
      _entries = scope.db.watchNudgeEntries(today.plusDays(-(recentDays - 1)));
    });
  }

  void _onLaunched(NudgeEntry entry) => _awaitingReturn = entry;

  @override
  Widget build(BuildContext context) {
    final today = _today!;
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: StreamBuilder<List<NudgeEntry>>(
        stream: _entries,
        builder: (context, snapshot) {
          final entries = snapshot.data;
          if (entries == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final todays = entries.where((e) => e.nudge.date == today).toList();
          final earlier = entries
              .where((e) => e.nudge.date != today && !_handledSince(e))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (todays.isEmpty)
                const _AllCaughtUp()
              else
                for (final e in todays)
                  NudgeCard(
                    entry: e,
                    today: today,
                    onReachOutLaunched: _onLaunched,
                  ),
              if (earlier.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Earlier this week',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final e in earlier)
                  NudgeCard(
                    entry: e,
                    today: today,
                    onReachOutLaunched: _onLaunched,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A past pending nudge whose member has since been contacted or skipped
/// (e.g. from a newer nudge) no longer needs checking off.
bool _handledSince(NudgeEntry e) {
  if (e.nudge.status != NudgeStatus.pending) return false;
  final last = e.member.lastContacted;
  return last != null && last >= e.nudge.date;
}

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.spa_outlined, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('All caught up', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'No one is due today. When people in your rings are due, '
            'they\'ll show up here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class NudgeCard extends StatelessWidget {
  final NudgeEntry entry;
  final CalendarDate today;
  final ValueChanged<NudgeEntry>? onReachOutLaunched;

  const NudgeCard({
    super.key,
    required this.entry,
    required this.today,
    this.onReachOutLaunched,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nudge = entry.nudge;
    final member = entry.member;
    final isToday = nudge.date == today;
    final pending = nudge.status == NudgeStatus.pending;

    final details = [
      entry.ring.name,
      if (!isToday) 'Suggested ${formatDate(context, nudge.date)}',
      if (pending) dueLabel(context, member, entry.ring, today),
      lastContactLabel(context, member),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    member.displayName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (!pending) _StatusChip(nudge.status),
                if (pending)
                  ListenableBuilder(
                    listenable: AppScope.of(context).contacts,
                    builder: (context, _) {
                      final contact = AppScope.of(context).contacts
                          .contactFor(member);
                      // A saved link works even without contacts access.
                      return ReachOutButtons(
                        member: member,
                        contact: contact,
                        onLaunched: () => onReachOutLaunched?.call(entry),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(details.join(' · '), style: theme.textTheme.bodySmall),
            if (pending) _NudgeActions(entry: entry, today: today),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final NudgeStatus status;

  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (status) {
      NudgeStatus.done => (Icons.check_circle_outline, 'Reached out'),
      NudgeStatus.snoozed => (Icons.snooze, 'Snoozed'),
      NudgeStatus.skipped => (Icons.skip_next_outlined, 'Skipped'),
      NudgeStatus.pending => (Icons.circle_outlined, 'Pending'),
    };
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

enum _MoreAction { reachedOutOn, skip }

class _NudgeActions extends StatelessWidget {
  final NudgeEntry entry;
  final CalendarDate today;

  const _NudgeActions({required this.entry, required this.today});

  Future<void> _apply(
    BuildContext context,
    ActionResult result,
    String message,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await AppScope.of(context).db.applyAction(result);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reachedOutOn(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      helpText: 'When did you reach out?',
      initialDate: today.toLocalDateTime(),
      firstDate: today.plusDays(-365).toLocalDateTime(),
      lastDate: today.toLocalDateTime(),
    );
    if (picked == null || !context.mounted) return;
    await _apply(
      context,
      reachedOut(
        entry.member,
        today: today,
        on: CalendarDate.fromDateTime(picked),
        nudge: entry.nudge,
      ),
      'Marked as reached out',
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = entry.member;
    final nudge = entry.nudge;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.tonalIcon(
            icon: const Icon(Icons.check),
            label: const Text('Reached out'),
            onPressed: () => _apply(
              context,
              reachedOut(member, today: today, nudge: nudge),
              'Marked as reached out',
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.snooze),
            label: const Text('Snooze'),
            onPressed: () => _apply(
              context,
              snooze(member, today: today, nudge: nudge),
              'Snoozed for $defaultSnoozeDays days',
            ),
          ),
          PopupMenuButton<_MoreAction>(
            tooltip: 'More actions',
            onSelected: (action) => switch (action) {
              _MoreAction.reachedOutOn => _reachedOutOn(context),
              _MoreAction.skip => _apply(
                context,
                skip(member, today: today, nudge: nudge),
                'Skipped this cycle',
              ),
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _MoreAction.reachedOutOn,
                child: Text('Reached out on another day…'),
              ),
              PopupMenuItem(
                value: _MoreAction.skip,
                child: Text('Skip this cycle'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
