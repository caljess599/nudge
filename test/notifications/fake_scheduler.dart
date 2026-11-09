import 'package:nudge/core/reminder.dart';
import 'package:nudge/notifications/reminder_scheduler.dart';

/// Records scheduling instead of talking to the platform.
class FakeReminderScheduler implements ReminderScheduler {
  bool permission;
  bool grantOnRequest;
  bool launchedFromTap;
  int requests = 0;

  /// The currently scheduled daily time, or null if nothing is scheduled.
  ReminderTime? scheduled;
  void Function()? _onOpened;

  FakeReminderScheduler({
    this.permission = false,
    this.grantOnRequest = true,
    this.launchedFromTap = false,
  });

  /// Simulates tapping the notification while the app is running.
  void tapNotification() => _onOpened?.call();

  @override
  Future<void> init({required void Function() onOpened}) async =>
      _onOpened = onOpened;

  @override
  Future<bool> launchedFromNotification() async => launchedFromTap;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<bool> requestPermission() async {
    requests++;
    if (grantOnRequest) permission = true;
    return permission;
  }

  @override
  Future<void> scheduleDaily(ReminderTime time) async => scheduled = time;

  @override
  Future<void> cancel() async => scheduled = null;

  int shownNow = 0;

  @override
  Future<void> showNow() async => shownNow++;
}
