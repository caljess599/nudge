import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/reminder.dart';
import 'package:nudge/data/database.dart';
import 'package:nudge/notifications/reminder_controller.dart';

import 'fake_scheduler.dart';

void main() {
  late AppDatabase db;
  late FakeReminderScheduler scheduler;
  late ReminderController controller;

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    scheduler = FakeReminderScheduler();
    controller = ReminderController(db: db, scheduler: scheduler);
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  test('off by default: nothing scheduled, no permission prompt', () async {
    await controller.start();
    expect(scheduler.scheduled, isNull);
    expect(scheduler.requests, 0);
  });

  test('enable asks for permission and schedules 9:00', () async {
    await controller.start();
    expect(await controller.enable(), isTrue);
    expect(scheduler.requests, 1);
    expect(scheduler.scheduled, defaultReminderTime);
    final saved = await db.reminderSettings();
    expect(saved.enabled, isTrue);
    expect(saved.offerDismissed, isTrue);
  });

  test('denied permission: stays off, card answered', () async {
    scheduler.grantOnRequest = false;
    await controller.start();
    expect(await controller.enable(), isFalse);
    expect(scheduler.scheduled, isNull);
    final saved = await db.reminderSettings();
    expect(saved.enabled, isFalse);
    expect(saved.offerDismissed, isTrue);
  });

  test('changing the time reschedules', () async {
    await controller.start();
    await controller.enable();
    await controller.setTime(const ReminderTime(19, 30));
    expect(scheduler.scheduled, const ReminderTime(19, 30));
  });

  test('disable cancels', () async {
    await controller.start();
    await controller.enable();
    await controller.disable();
    expect(scheduler.scheduled, isNull);
    expect((await db.reminderSettings()).enabled, isFalse);
  });

  test('app start reschedules a saved reminder', () async {
    await db.saveReminderSettings(
      const ReminderSettings(enabled: true, time: ReminderTime(8, 0)),
    );
    scheduler.permission = true;
    await controller.start();
    expect(scheduler.scheduled, const ReminderTime(8, 0));
  });

  test('permission revoked in system settings: blocked, cancelled', () async {
    await controller.start();
    await controller.enable();
    scheduler.permission = false;
    await controller.sync(); // e.g. on resume
    expect(controller.isBlocked, isTrue);
    expect(scheduler.scheduled, isNull);

    scheduler.permission = true;
    await controller.sync();
    expect(controller.isBlocked, isFalse);
    expect(scheduler.scheduled, defaultReminderTime);
  });

  test('opening from the notification asks to show Today', () async {
    scheduler.launchedFromTap = true;
    await controller.start();
    expect(controller.openTodayRequests.value, 1);
    scheduler.tapNotification();
    expect(controller.openTodayRequests.value, 2);
  });
}
