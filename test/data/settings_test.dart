import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/reminder.dart';
import 'package:nudge/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(DatabaseConnection(NativeDatabase.memory())));
  tearDown(() => db.close());

  test('defaults before anything is saved', () async {
    expect(await db.reminderSettings(), const ReminderSettings());
  });

  test('reminder settings round-trip and overwrite', () async {
    const s = ReminderSettings(
      enabled: true,
      time: ReminderTime(21, 45),
      offerDismissed: true,
    );
    await db.saveReminderSettings(s);
    expect(await db.reminderSettings(), s);

    await db.saveReminderSettings(s.copyWith(enabled: false));
    expect((await db.reminderSettings()).enabled, isFalse);
    expect((await db.reminderSettings()).time, const ReminderTime(21, 45));
  });

  test('watchReminderSettings emits changes', () async {
    final expectation = expectLater(
      db.watchReminderSettings().map((s) => s.enabled),
      emitsInOrder([false, true]),
    );
    await pumpEventQueue();
    await db.saveReminderSettings(const ReminderSettings(enabled: true));
    await expectation;
  });

  test('deleteAllData resets settings', () async {
    await db.saveReminderSettings(const ReminderSettings(enabled: true));
    await db.deleteAllData();
    expect(await db.reminderSettings(), const ReminderSettings());
  });
}
