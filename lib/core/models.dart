import 'calendar_date.dart';

/// A named group of members who should be contacted every [periodDays] days.
class Ring {
  final int id;
  final String name;
  final int periodDays;

  Ring({required this.id, required this.name, required this.periodDays}) {
    if (periodDays <= 0) {
      throw ArgumentError.value(periodDays, 'periodDays', 'must be > 0');
    }
  }

  Ring copyWith({int? id, String? name, int? periodDays}) => Ring(
    id: id ?? this.id,
    name: name ?? this.name,
    periodDays: periodDays ?? this.periodDays,
  );

  @override
  bool operator ==(Object other) =>
      other is Ring &&
      other.id == id &&
      other.name == name &&
      other.periodDays == periodDays;

  @override
  int get hashCode => Object.hash(id, name, periodDays);

  @override
  String toString() => 'Ring($id, $name, every $periodDays days)';
}

/// A contact assigned to exactly one ring.
///
/// Due dates are never stored: see `due_dates.dart`.
class Member {
  final int id;

  /// Stable contact lookup key (Android lookup key / iOS identifier).
  final String contactKey;

  /// Fallback display name if the contact can't be found.
  final String cachedName;

  final int ringId;

  /// Reference date used until the first contact. Randomly offset within
  /// the ring's period when the member is added.
  final CalendarDate baselineDate;

  final CalendarDate? lastContacted;
  final CalendarDate? snoozedUntil;
  final CalendarDate? lastSurfaced;

  const Member({
    required this.id,
    required this.contactKey,
    required this.cachedName,
    required this.ringId,
    required this.baselineDate,
    this.lastContacted,
    this.snoozedUntil,
    this.lastSurfaced,
  });

  /// Nullable fields take a function so they can be explicitly cleared,
  /// e.g. `copyWith(snoozedUntil: () => null)`.
  Member copyWith({
    int? id,
    String? contactKey,
    String? cachedName,
    int? ringId,
    CalendarDate? baselineDate,
    CalendarDate? Function()? lastContacted,
    CalendarDate? Function()? snoozedUntil,
    CalendarDate? Function()? lastSurfaced,
  }) => Member(
    id: id ?? this.id,
    contactKey: contactKey ?? this.contactKey,
    cachedName: cachedName ?? this.cachedName,
    ringId: ringId ?? this.ringId,
    baselineDate: baselineDate ?? this.baselineDate,
    lastContacted: lastContacted != null ? lastContacted() : this.lastContacted,
    snoozedUntil: snoozedUntil != null ? snoozedUntil() : this.snoozedUntil,
    lastSurfaced: lastSurfaced != null ? lastSurfaced() : this.lastSurfaced,
  );

  @override
  bool operator ==(Object other) =>
      other is Member &&
      other.id == id &&
      other.contactKey == contactKey &&
      other.cachedName == cachedName &&
      other.ringId == ringId &&
      other.baselineDate == baselineDate &&
      other.lastContacted == lastContacted &&
      other.snoozedUntil == snoozedUntil &&
      other.lastSurfaced == lastSurfaced;

  @override
  int get hashCode => Object.hash(
    id,
    contactKey,
    cachedName,
    ringId,
    baselineDate,
    lastContacted,
    snoozedUntil,
    lastSurfaced,
  );

  @override
  String toString() => 'Member($id, $contactKey, ring $ringId)';
}

enum NudgeStatus { pending, done, snoozed, skipped }

/// One member suggested on one day.
class DailyNudge {
  final CalendarDate date;
  final int memberId;
  final NudgeStatus status;

  const DailyNudge({
    required this.date,
    required this.memberId,
    this.status = NudgeStatus.pending,
  });

  DailyNudge copyWith({NudgeStatus? status}) =>
      DailyNudge(date: date, memberId: memberId, status: status ?? this.status);

  @override
  bool operator ==(Object other) =>
      other is DailyNudge &&
      other.date == date &&
      other.memberId == memberId &&
      other.status == status;

  @override
  int get hashCode => Object.hash(date, memberId, status);

  @override
  String toString() => 'DailyNudge($date, member $memberId, ${status.name})';
}
