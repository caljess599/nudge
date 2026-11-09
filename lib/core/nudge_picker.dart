import 'dart:math';

import 'calendar_date.dart';
import 'due_dates.dart';
import 'models.dart';

/// Tuning for the daily pick. Defaults follow SPEC.md.
class NudgePickerConfig {
  /// How many members to suggest per day.
  final int count;

  /// A member surfaced 1..[cooldownDays] days ago and not acted on since
  /// is in cooldown.
  final int cooldownDays;

  /// Weight multiplier for members in cooldown (0 < factor <= 1).
  final double cooldownFactor;

  const NudgePickerConfig({
    this.count = 3,
    this.cooldownDays = 3,
    this.cooldownFactor = 0.25,
  }) : assert(count >= 0),
       assert(cooldownDays >= 0),
       assert(cooldownFactor > 0 && cooldownFactor <= 1);
}

/// An eligible member and their sampling weight.
class NudgeCandidate {
  final Member member;
  final Ring ring;
  final double weight;

  const NudgeCandidate(this.member, this.ring, this.weight);

  @override
  String toString() => 'NudgeCandidate(${member.id}, weight $weight)';
}

/// `1 + days_overdue / period_days`: being 10 days late on a 7-day ring
/// counts for more than 10 days late on a 90-day ring.
double overdueWeight(Member member, Ring ring, CalendarDate today) {
  final overdue = max(0, daysOverdue(member, ring, today));
  return 1 + overdue / ring.periodDays;
}

/// Whether [member] was surfaced recently and ignored.
///
/// Cooldown covers 1..[cooldownDays] days ago. Today is excluded so that
/// regenerating today's picks (e.g. if the saved rows were lost) gives the
/// same result. Any later contact, skip or snooze counts as acting on it.
bool isInCooldown(Member member, CalendarDate today, int cooldownDays) {
  final surfaced = member.lastSurfaced;
  if (surfaced == null) return false;
  final ago = today.daysSince(surfaced);
  if (ago < 1 || ago > cooldownDays) return false;

  final contacted = member.lastContacted;
  if (contacted != null && contacted >= surfaced) return false;
  final snoozed = member.snoozedUntil;
  if (snoozed != null && snoozed > surfaced) return false;
  return true;
}

/// Eligible members with their weights, ordered by member id so the
/// result doesn't depend on the order the caller passed them in.
List<NudgeCandidate> weighCandidates({
  required Iterable<Member> members,
  required Map<int, Ring> ringsById,
  required CalendarDate today,
  NudgePickerConfig config = const NudgePickerConfig(),
}) {
  final candidates = <NudgeCandidate>[];
  for (final member in members) {
    final ring = ringsById[member.ringId];
    if (ring == null || !isEligible(member, ring, today)) continue;
    var weight = overdueWeight(member, ring, today);
    if (isInCooldown(member, today, config.cooldownDays)) {
      weight *= config.cooldownFactor;
    }
    candidates.add(NudgeCandidate(member, ring, weight));
  }
  candidates.sort((a, b) => a.member.id.compareTo(b.member.id));
  return candidates;
}

/// Weighted random sampling of up to [count] candidates without
/// replacement. Returns fewer if fewer are given, and an empty list if
/// none are (the "all caught up" state).
List<NudgeCandidate> sampleWeighted(
  List<NudgeCandidate> candidates,
  int count,
  Random random,
) {
  final pool = List.of(candidates);
  final picked = <NudgeCandidate>[];
  while (picked.length < count && pool.isNotEmpty) {
    final total = pool.fold<double>(0, (sum, c) => sum + c.weight);
    var target = random.nextDouble() * total;
    var index = pool.length - 1;
    for (var i = 0; i < pool.length; i++) {
      target -= pool[i].weight;
      if (target < 0) {
        index = i;
        break;
      }
    }
    picked.add(pool.removeAt(index));
  }
  return picked;
}

/// Picks today's members. See [weighCandidates] and [sampleWeighted].
List<Member> pickNudges({
  required Iterable<Member> members,
  required Iterable<Ring> rings,
  required CalendarDate today,
  required Random random,
  NudgePickerConfig config = const NudgePickerConfig(),
}) {
  final candidates = weighCandidates(
    members: members,
    ringsById: {for (final r in rings) r.id: r},
    today: today,
    config: config,
  );
  return [
    for (final c in sampleWeighted(candidates, config.count, random)) c.member,
  ];
}
