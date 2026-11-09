import 'dart:async';

import 'package:flutter/material.dart';

import 'contacts/contact_directory.dart';
import 'contacts/contacts_source.dart';
import 'contacts/reach_out_launcher.dart';
import 'core/clock.dart';
import 'data/database.dart';
import 'notifications/reminder_controller.dart';
import 'notifications/reminder_scheduler.dart';
import 'ui/rings_screen.dart';
import 'ui/today_screen.dart';

/// Makes the database, clock, contacts and launcher available to every
/// screen.
class AppScope extends InheritedWidget {
  final AppDatabase db;
  final Clock clock;
  final ContactDirectory contacts;
  final ReachOutLauncher launcher;
  final ReminderController reminders;

  const AppScope({
    super.key,
    required this.db,
    required this.clock,
    required this.contacts,
    required this.launcher,
    required this.reminders,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      db != oldWidget.db ||
      clock != oldWidget.clock ||
      contacts != oldWidget.contacts ||
      launcher != oldWidget.launcher ||
      reminders != oldWidget.reminders;
}

class NudgeApp extends StatefulWidget {
  final AppDatabase db;
  final Clock clock;
  final ContactsSource contactsSource;
  final ReachOutLauncher launcher;
  final ReminderScheduler reminderScheduler;

  const NudgeApp({
    super.key,
    required this.db,
    required this.clock,
    required this.contactsSource,
    required this.launcher,
    required this.reminderScheduler,
  });

  @override
  State<NudgeApp> createState() => _NudgeAppState();
}

class _NudgeAppState extends State<NudgeApp> with WidgetsBindingObserver {
  static const _seed = Color(0xFF3B7A6E);

  late final ContactDirectory _contacts = ContactDirectory(
    source: widget.contactsSource,
    db: widget.db,
  );

  late final ReminderController _reminders = ReminderController(
    db: widget.db,
    scheduler: widget.reminderScheduler,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Only reads contacts if access was already granted; never prompts.
    unawaited(_contacts.refresh());
    // Re-schedules a saved reminder; never prompts.
    unawaited(_reminders.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Contacts may have been edited, or access changed in Settings.
    unawaited(_contacts.refresh());
    // Notification permission may have changed; time zone may too.
    unawaited(_reminders.sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _contacts.dispose();
    _reminders.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      db: widget.db,
      clock: widget.clock,
      contacts: _contacts,
      launcher: widget.launcher,
      reminders: _reminders,
      child: MaterialApp(
        title: 'Nudge',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed)),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _seed,
            brightness: Brightness.dark,
          ),
        ),
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  ValueNotifier<int>? _openToday;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final requests = AppScope.of(context).reminders.openTodayRequests;
    if (requests != _openToday) {
      _openToday?.removeListener(_showToday);
      // Launching from the notification already starts on Today; this
      // handles taps while the app is open on another screen.
      _openToday = requests..addListener(_showToday);
    }
  }

  @override
  void dispose() {
    _openToday?.removeListener(_showToday);
    super.dispose();
  }

  /// Tapping the daily notification opens Today.
  void _showToday() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    _select(0);
  }

  void _select(int i) {
    if (i == 0) {
      // If no one was due earlier today, ring edits may have made
      // someone due since. Saved picks are never replaced.
      final scope = AppScope.of(context);
      unawaited(scope.db.ensureDailyNudges(scope.clock.today()));
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [TodayScreen(), RingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large),
            label: 'Rings',
          ),
        ],
      ),
    );
  }
}
