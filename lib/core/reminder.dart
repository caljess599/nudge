// The daily reminder: settings and scheduling rules. Pure Dart.

/// The notification's text. Deliberately generic: notifications can show
/// on the lock screen, so they never include names or nicknames.
const reminderTitle = 'Nudge';
const reminderBody = 'Time for your daily nudge.';

/// A time of day, e.g. 9:00.
class ReminderTime {
  final int hour;
  final int minute;

  const ReminderTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  factory ReminderTime.fromMinutes(int minutesOfDay) {
    final m = minutesOfDay % (24 * 60);
    return ReminderTime(m ~/ 60, m % 60);
  }

  int get minutesOfDay => hour * 60 + minute;

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

const defaultReminderTime = ReminderTime(9, 0);

class ReminderSettings {
  final bool enabled;
  final ReminderTime time;

  /// The "Get a daily reminder?" card on Today was answered or dismissed.
  final bool offerDismissed;

  const ReminderSettings({
    this.enabled = false,
    this.time = defaultReminderTime,
    this.offerDismissed = false,
  });

  ReminderSettings copyWith({
    bool? enabled,
    ReminderTime? time,
    bool? offerDismissed,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    time: time ?? this.time,
    offerDismissed: offerDismissed ?? this.offerDismissed,
  );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.time == time &&
      other.offerDismissed == offerDismissed;

  @override
  int get hashCode => Object.hash(enabled, time, offerDismissed);
}

/// The next time [time] occurs strictly after [now], as local wall-clock
/// components (year, month, day, hour, minute). If it's already past
/// [time] today, that's tomorrow.
DateTime nextReminderAt(DateTime now, ReminderTime time) {
  final today = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  if (today.isAfter(now)) return today;
  // DateTime normalises day overflow (e.g. Jan 32 -> Feb 1).
  return DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);
}

/// Show the "Get a daily reminder?" card only once there's someone to be
/// reminded about, and only until it's been answered.
bool shouldOfferReminder(
  ReminderSettings settings, {
  required int memberCount,
}) => !settings.enabled && !settings.offerDismissed && memberCount > 0;
