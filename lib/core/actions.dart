import 'calendar_date.dart';
import 'models.dart';

/// The updated member and, if the action was taken on a nudge, the
/// updated nudge. Callers persist both.
class ActionResult {
  final Member member;
  final DailyNudge? nudge;

  const ActionResult(this.member, [this.nudge]);
}

/// Default snooze length, in days.
const defaultSnoozeDays = 3;

/// "Reached out": sets `last_contacted` to [on] (default today) and marks
/// the nudge done. Clears any snooze.
///
/// A date earlier than an existing `last_contacted` never moves it
/// backwards, so checking off an old nudge late can't undo newer contact.
ActionResult reachedOut(
  Member member, {
  required CalendarDate today,
  CalendarDate? on,
  DailyNudge? nudge,
}) {
  final date = on ?? today;
  if (date > today) {
    throw ArgumentError.value(date, 'on', 'cannot be in the future');
  }
  final previous = member.lastContacted;
  final lastContacted = previous == null
      ? date
      : CalendarDate.max(previous, date);
  return ActionResult(
    member.copyWith(
      lastContacted: () => lastContacted,
      snoozedUntil: () => null,
    ),
    _withStatus(nudge, member, NudgeStatus.done),
  );
}

/// "Snooze": hides the member for [days] days without resetting the
/// cycle; `last_contacted` is unchanged.
ActionResult snooze(
  Member member, {
  required CalendarDate today,
  int days = defaultSnoozeDays,
  DailyNudge? nudge,
}) {
  if (days <= 0) throw ArgumentError.value(days, 'days', 'must be > 0');
  return ActionResult(
    member.copyWith(snoozedUntil: () => today.plusDays(days)),
    _withStatus(nudge, member, NudgeStatus.snoozed),
  );
}

/// "Skip this cycle": restarts the cycle from today without implying
/// contact. The nudge is recorded as skipped, not done, so history stays
/// honest. Clears any snooze.
ActionResult skip(
  Member member, {
  required CalendarDate today,
  DailyNudge? nudge,
}) {
  final previous = member.lastContacted;
  final restart = previous == null ? today : CalendarDate.max(previous, today);
  return ActionResult(
    member.copyWith(lastContacted: () => restart, snoozedUntil: () => null),
    _withStatus(nudge, member, NudgeStatus.skipped),
  );
}

/// Moves [member] to [ring], keeping `last_contacted` and everything else.
/// The next due date follows the new ring's period automatically.
Member moveToRing(Member member, Ring ring) => member.copyWith(ringId: ring.id);

DailyNudge? _withStatus(DailyNudge? nudge, Member member, NudgeStatus status) {
  if (nudge == null) return null;
  if (nudge.memberId != member.id) {
    throw ArgumentError.value(nudge, 'nudge', 'is for a different member');
  }
  return nudge.copyWith(status: status);
}
