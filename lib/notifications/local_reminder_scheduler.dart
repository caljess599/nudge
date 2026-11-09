import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/reminder.dart';
import 'reminder_scheduler.dart';

/// Local, on-device notifications via flutter_local_notifications. No
/// server, no push.
class LocalReminderScheduler implements ReminderScheduler {
  static const _id = 1;
  static const _channelId = 'daily_nudge';

  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> init({required void Function() onOpened}) async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Exception catch (e) {
      // Unknown zone name: fall back to UTC; the reminder may be off by
      // the UTC offset until the zone is recognised.
      debugPrint('Nudge: could not read the time zone: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_nudge'),
        // Ask on iOS only when the user turns the reminder on.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => onOpened(),
    );
  }

  @override
  Future<bool> launchedFromNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false;
  }

  @override
  Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      return await _android?.areNotificationsEnabled() ?? false;
    }
    if (Platform.isIOS) {
      final options = await _ios?.checkPermissions();
      return options?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      return await _android?.requestNotificationsPermission() ?? false;
    }
    if (Platform.isIOS) {
      return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  @override
  Future<void> scheduleDaily(ReminderTime time) async {
    final next = nextReminderAt(tz.TZDateTime.now(tz.local), time);
    final when = tz.TZDateTime(
      tz.local,
      next.year,
      next.month,
      next.day,
      next.hour,
      next.minute,
    );
    await _plugin.cancel(id: _id);
    await _plugin.zonedSchedule(
      id: _id,
      title: reminderTitle,
      body: reminderBody,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Daily nudge',
          channelDescription: 'One reminder a day to check your nudges',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          // The text is generic, so it's fine on the lock screen.
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // "Around" the chosen time: Android may delay it slightly to save
      // battery. No exact-alarm permission needed.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() => _plugin.cancel(id: _id);

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
}
