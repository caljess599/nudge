import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../core/export_format.dart';
import '../core/reminder.dart';
import 'formatting.dart';

String formatReminderTime(BuildContext context, ReminderTime time) =>
    TimeOfDay(hour: time.hour, minute: time.minute).format(context);

/// Turns the reminder on and explains what to do if it was refused.
Future<void> turnOnReminder(BuildContext context) async {
  final scope = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final time = formatReminderTime(context, scope.reminders.settings.time);
  final on = await scope.reminders.enable();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      on
          ? SnackBar(content: Text('Daily reminder set for $time'))
          : SnackBar(
              content: const Text(
                'Notifications are off for Nudge. You can allow them in '
                'system settings.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                // Opens Nudge's page in system settings, which includes
                // its notification switch.
                onPressed: scope.contacts.openSettings,
              ),
            ),
    );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pickTime(BuildContext context) async {
    final reminders = AppScope.of(context).reminders;
    final current = reminders.settings.time;
    final picked = await showTimePicker(
      context: context,
      helpText: 'Daily reminder time',
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null) return;
    await reminders.setTime(ReminderTime(picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final reminders = scope.reminders;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: reminders,
        builder: (context, _) {
          final settings = reminders.settings;
          final theme = Theme.of(context);
          return ListView(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Daily reminder'),
                subtitle: const Text('One notification a day'),
                value: settings.enabled,
                onChanged: (on) =>
                    on ? turnOnReminder(context) : reminders.disable(),
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Time'),
                subtitle: Text(formatReminderTime(context, settings.time)),
                enabled: settings.enabled,
                onTap: () => _pickTime(context),
              ),
              if (reminders.isBlocked)
                ListTile(
                  leading: Icon(
                    Icons.notifications_off_outlined,
                    color: theme.colorScheme.error,
                  ),
                  title: const Text('Notifications are blocked for Nudge'),
                  subtitle: const Text(
                    'Allow them in system settings to get the reminder.',
                  ),
                  trailing: TextButton(
                    onPressed: scope.contacts.openSettings,
                    child: const Text('Settings'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'The reminder only says "$reminderBody" It never shows '
                  'names, and it may arrive a few minutes after the chosen '
                  'time so your phone can save battery.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const Divider(),
              const _YourDataSection(),
              if (kDebugMode) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Debug: show the notification now'),
                  onTap: scope.reminders.scheduler.showNow,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// "Get a daily reminder?" card at the top of Today. Shown once someone
/// is in a ring, until it's answered.
class ReminderOfferCard extends StatelessWidget {
  final int memberCount;

  const ReminderOfferCard({super.key, required this.memberCount});

  @override
  Widget build(BuildContext context) {
    final reminders = AppScope.of(context).reminders;
    return ListenableBuilder(
      listenable: reminders,
      builder: (context, _) {
        final settings = reminders.settings;
        if (!shouldOfferReminder(settings, memberCount: memberCount)) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return Card(
          color: theme.colorScheme.secondaryContainer,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get a daily reminder?',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Nudge can remind you once a day at '
                  '${formatReminderTime(context, settings.time)}. '
                  'The notification never shows names.',
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: reminders.dismissOffer,
                      child: const Text('Not now'),
                    ),
                    FilledButton(
                      onPressed: () => turnOnReminder(context),
                      child: const Text('Turn on'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Export and import (SPEC.md: never lose data).
class _YourDataSection extends StatelessWidget {
  const _YourDataSection();

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await AppScope.of(context).backup
          .export(now: DateTime.now());
      if (saved) {
        messenger.showSnackBar(const SnackBar(content: Text('Backup saved')));
      }
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Couldn\'t save: $e')));
    }
  }

  Future<void> _import(BuildContext context) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ExportData? data;
    try {
      data = await scope.backup.pickBackup();
    } on FormatException catch (e) {
      if (context.mounted) await _explain(context, e.message);
      return;
    }
    if (data == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace everything in Nudge?'),
        content: Text(_describe(context, data!)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final linked = await scope.backup.restore(data);
      await scope.reminders.sync();
      await scope.db.ensureDailyNudges(scope.clock.today());
      final total = data.members.length;
      final unlinked = total - linked;
      final access = scope.contacts.access;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Restored ${peopleCount(total)}.'
            '${access != null && access.canRead && unlinked > 0 ? ' $unlinked need relinking.' : ''}',
          ),
        ),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed, nothing was changed. ($e)')),
      );
    }
  }

  static String _describe(BuildContext context, ExportData data) {
    final when = data.exportedAt;
    final from = when == null
        ? ''
        : ' from '
              '${MaterialLocalizations.of(context).formatMediumDate(when.toLocal())}';
    final rings = data.rings.length == 1
        ? '1 ring'
        : '${data.rings.length} rings';
    return 'This backup$from has $rings and '
        '${peopleCount(data.members.length)}. Your current rings, people '
        'and history will be replaced. Your phone\'s contacts are not '
        'changed.';
  }

  Future<void> _explain(BuildContext context, String message) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Can\'t import this file'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Your data',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.upload_file_outlined),
          title: const Text('Export backup'),
          subtitle: const Text('Save rings, people and history to a file'),
          onTap: () => _export(context),
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Import backup'),
          subtitle: const Text('Replace everything with a backup file'),
          onTap: () => _import(context),
        ),
      ],
    );
  }
}
