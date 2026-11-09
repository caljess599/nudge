import 'dart:async';

import 'package:flutter/material.dart';

import 'core/clock.dart';
import 'data/database.dart';
import 'ui/rings_screen.dart';
import 'ui/today_screen.dart';

/// Makes the database and clock available to every screen.
class AppScope extends InheritedWidget {
  final AppDatabase db;
  final Clock clock;

  const AppScope({
    super.key,
    required this.db,
    required this.clock,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      db != oldWidget.db || clock != oldWidget.clock;
}

class NudgeApp extends StatelessWidget {
  final AppDatabase db;
  final Clock clock;

  const NudgeApp({super.key, required this.db, required this.clock});

  static const _seed = Color(0xFF3B7A6E);

  @override
  Widget build(BuildContext context) {
    return AppScope(
      db: db,
      clock: clock,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [TodayScreen(), RingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 0) {
            // If no one was due earlier today, ring edits may have made
            // someone due since. Saved picks are never replaced.
            final scope = AppScope.of(context);
            unawaited(scope.db.ensureDailyNudges(scope.clock.today()));
          }
          setState(() => _index = i);
        },
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
