import 'package:flutter/foundation.dart';

import '../core/reminder.dart';
import '../data/database.dart';
import 'reminder_scheduler.dart';

/// Keeps the scheduled notification in line with the saved settings and
/// the notification permission.
///
/// [sync] runs on app start, on resume (permission may have changed in
/// system settings) and after every change. Reboots are handled by the
/// plugin's boot receiver, which restores the scheduled notification.
class ReminderController extends ChangeNotifier {
  final AppDatabase db;
  final ReminderScheduler scheduler;

  ReminderSettings _settings = const ReminderSettings();
  bool? _permission;

  /// Increments when the user opens the app from the notification, so
  /// the UI can switch to Today.
  final openTodayRequests = ValueNotifier<int>(0);

  ReminderController({required this.db, required this.scheduler});

  ReminderSettings get settings => _settings;

  /// Null until checked.
  bool? get hasPermission => _permission;

  /// On, but notifications are blocked in system settings.
  bool get isBlocked => _settings.enabled && _permission == false;

  Future<void> start() async {
    await scheduler.init(onOpened: _openToday);
    if (await scheduler.launchedFromNotification()) _openToday();
    await sync();
  }

  /// Reloads settings and permission, then schedules or cancels.
  Future<void> sync() async {
    _settings = await db.reminderSettings();
    _permission = await scheduler.hasPermission();
    if (_settings.enabled && _permission == true) {
      await scheduler.scheduleDaily(_settings.time);
    } else {
      await scheduler.cancel();
    }
    notifyListeners();
  }

  /// Asks for permission and turns the reminder on if granted. Either way
  /// the Today card is answered. Returns whether it's now on.
  Future<bool> enable() async {
    final granted = await scheduler.requestPermission();
    await _save(_settings.copyWith(enabled: granted, offerDismissed: true));
    return granted;
  }

  Future<void> disable() => _save(_settings.copyWith(enabled: false));

  Future<void> setTime(ReminderTime time) =>
      _save(_settings.copyWith(time: time));

  Future<void> dismissOffer() =>
      _save(_settings.copyWith(offerDismissed: true));

  Future<void> _save(ReminderSettings settings) async {
    await db.saveReminderSettings(settings);
    await sync();
  }

  void _openToday() => openTodayRequests.value++;

  @override
  void dispose() {
    openTodayRequests.dispose();
    super.dispose();
  }
}
