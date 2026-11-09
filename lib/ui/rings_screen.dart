import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../data/database.dart';
import '../debug/seed.dart';
import 'formatting.dart';
import 'ring_detail_screen.dart';
import 'ring_form_dialog.dart';

class RingsScreen extends StatelessWidget {
  const RingsScreen({super.key});

  Future<void> _createRing(BuildContext context) async {
    final db = AppScope.of(context).db;
    final result = await showRingForm(context);
    if (result == null) return;
    await db.createRing(result.name, result.periodDays);
  }

  @override
  Widget build(BuildContext context) {
    final db = AppScope.of(context).db;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rings'),
        actions: [if (kDebugMode) const _DebugMenu()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New ring'),
        onPressed: () => _createRing(context),
      ),
      body: StreamBuilder<List<RingSummary>>(
        stream: db.watchRingSummaries(),
        builder: (context, snapshot) {
          final rings = snapshot.data;
          if (rings == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (rings.isEmpty) return const _NoRings();
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final s in rings)
                ListTile(
                  leading: const Icon(Icons.donut_large_outlined),
                  title: Text(s.ring.name),
                  subtitle: Text(
                    '${periodLabel(s.ring.periodDays)} · '
                    '${peopleCount(s.memberCount)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RingDetailScreen(ringId: s.ring.id),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NoRings extends StatelessWidget {
  const _NoRings();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.donut_large_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('No rings yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'A ring is a group of people you want to hear from on a '
              'rhythm, like "Close friends" every two weeks.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _DebugAction { seed, reset }

/// Only built when kDebugMode is true.
class _DebugMenu extends StatelessWidget {
  const _DebugMenu();

  Future<void> _run(BuildContext context, _DebugAction action) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _DebugAction.seed:
        await seedFakeData(
          scope.db,
          today: scope.clock.today(),
          random: Random(),
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Added fake rings and people')),
        );
      case _DebugAction.reset:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete all data?'),
            content: const Text(
              'Debug only. Deletes every ring, person and nudge.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await scope.db.deleteAllData();
        messenger.showSnackBar(
          const SnackBar(content: Text('All data deleted')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_DebugAction>(
      icon: const Icon(Icons.bug_report_outlined),
      tooltip: 'Debug tools',
      onSelected: (action) => _run(context, action),
      itemBuilder: (_) => const [
        PopupMenuItem(value: _DebugAction.seed, child: Text('Seed fake data')),
        PopupMenuItem(
          value: _DebugAction.reset,
          child: Text('Delete all data'),
        ),
      ],
    );
  }
}
