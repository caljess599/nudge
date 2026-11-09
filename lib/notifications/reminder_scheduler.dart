import '../core/reminder.dart';

/// Schedules the one daily reminder. Injected so tests don't touch the
/// platform.
abstract interface class ReminderScheduler {
  /// Sets up the plugin and time zone. [onOpened] runs when the user taps
  /// the notification while the app is running.
  Future<void> init({required void Function() onOpened});

  /// Whether the app was started by tapping the notification.
  Future<bool> launchedFromNotification();

  /// Whether notifications may be shown (always true before Android 13).
  Future<bool> hasPermission();

  /// Shows the system prompt where needed. Returns whether it's granted.
  Future<bool> requestPermission();

  /// Replaces any existing reminder with one repeating daily at [time].
  Future<void> scheduleDaily(ReminderTime time);

  Future<void> cancel();

  /// Debug builds: shows the reminder immediately, to check how it looks.
  Future<void> showNow();
}
