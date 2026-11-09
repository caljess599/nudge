import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/core/reminder.dart';

void main() {
  const nine = ReminderTime(9, 0);

  group('nextReminderAt', () {
    test('later today if the time has not passed', () {
      expect(
        nextReminderAt(DateTime(2026, 11, 20, 8, 59), nine),
        DateTime(2026, 11, 20, 9, 0),
      );
    });

    test('tomorrow if the time has passed or is now', () {
      expect(
        nextReminderAt(DateTime(2026, 11, 20, 9, 0), nine),
        DateTime(2026, 11, 21, 9, 0),
      );
      expect(
        nextReminderAt(DateTime(2026, 11, 20, 21, 30), nine),
        DateTime(2026, 11, 21, 9, 0),
      );
    });

    test('rolls over month and year ends', () {
      expect(
        nextReminderAt(DateTime(2026, 12, 31, 10), nine),
        DateTime(2027, 1, 1, 9, 0),
      );
      expect(
        nextReminderAt(DateTime(2028, 2, 28, 22), const ReminderTime(7, 15)),
        DateTime(2028, 2, 29, 7, 15),
      );
    });
  });

  test('ReminderTime round-trips through minutes of the day', () {
    expect(const ReminderTime(21, 45).minutesOfDay, 21 * 60 + 45);
    expect(ReminderTime.fromMinutes(21 * 60 + 45), const ReminderTime(21, 45));
    expect(ReminderTime.fromMinutes(0), const ReminderTime(0, 0));
    expect(const ReminderTime(7, 5).toString(), '07:05');
  });

  test('defaults: off, 9:00, card not dismissed', () {
    const s = ReminderSettings();
    expect(s.enabled, isFalse);
    expect(s.time, nine);
    expect(s.offerDismissed, isFalse);
  });

  group('shouldOfferReminder', () {
    const fresh = ReminderSettings();

    test('only once someone is in a ring', () {
      expect(shouldOfferReminder(fresh, memberCount: 0), isFalse);
      expect(shouldOfferReminder(fresh, memberCount: 1), isTrue);
    });

    test('not once dismissed or enabled', () {
      expect(
        shouldOfferReminder(
          fresh.copyWith(offerDismissed: true),
          memberCount: 5,
        ),
        isFalse,
      );
      expect(
        shouldOfferReminder(fresh.copyWith(enabled: true), memberCount: 5),
        isFalse,
      );
    });
  });

  test('notification text is generic', () {
    expect(reminderTitle, 'Nudge');
    expect(reminderBody, 'Time for your daily nudge.');
  });
}
