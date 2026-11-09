# Nudge: Specification

Nudge is an open-source, cross-platform (Android + iOS) app that helps you keep in touch with people. You organize contacts into **rings**, each with a **period in days**. Once a day, the app "nudges" you with a few people to reach out to.

## Principles

- **On-device only.** No accounts, no server, no analytics. Contact data never leaves the phone.
- **Low guilt.** No streaks, no shame counters, no nagging. Confirming that you reached out is always voluntary.
- **Never lose data.** Use a real on-device database and provide JSON export/import from the start.
- **Privacy on the lock screen.** Notifications are generic. Names appear only inside the app.

## Core concepts

- **Ring:** a named group with `period_days` (integer). Examples: "Close friends" = 14, "Old friends" = 60.
- **Member:** a contact assigned to exactly one ring.
- **Nudge:** the daily set of about 3 members who are due or overdue.

## Data model

**Ring**
- `id`
- `name`
- `period_days` (integer, > 0)

**Member**
- `id`
- `contact_key`: stable contact lookup key (Android lookup key / iOS contact identifier). **UNIQUE**, which enforces one ring per contact at the database level.
- `cached_name`: fallback display name if the contact can't be found
- `ring_id` (foreign key)
- `baseline_date`: set when the member is added, randomly offset within the ring's period so a bulk add doesn't create a wall of overdue people
- `last_contacted` (nullable date)
- `snoozed_until` (nullable date)
- `last_surfaced` (nullable date)

**DailyNudge**
- `date`
- `member_id`
- `status`: `pending` | `done` | `snoozed` | `skipped`

### Derived values (never stored)

- `reference_date = last_contacted ?? baseline_date`
- `next_due = reference_date + ring.period_days`
- Editing a ring's period therefore updates all members instantly, with no migration.
- Moving a member between rings keeps `last_contacted`.

## Daily nudge logic

1. On app open, if no `DailyNudge` rows exist for today, generate them. Otherwise show the saved ones. Picks must be **stable for the whole day**.
2. **Eligible:** `next_due <= today` and not currently snoozed.
3. **Weighting:** weight by how overdue a member is relative to their ring's period (for example `1 + days_overdue / period_days`). Being 10 days late on a 7-day ring counts for more than 10 days late on a 90-day ring.
4. **Cooldown:** members surfaced in the last few days and not acted on get a reduced weight, so ignored people don't clog the list.
5. Pick up to 3 by weighted random sampling without replacement. If fewer than 3 are eligible, show what exists. If none, show a friendly "all caught up" state.
6. The random source must be injectable so tests are deterministic.

## Actions on a nudge

- **Reached out:** sets `last_contacted` to today, or to a date the user picks. Marks the nudge `done`.
- **Snooze:** sets `snoozed_until` a few days out, without resetting the cycle.
- **Skip this cycle:** sets `last_contacted` to today without implying contact (or equivalent), with no guilt.
- **Call / Text:** opens the dialer or messaging app via `tel:` / `sms:`. When the user returns, optionally show a one-tap "Did you reach out to X?" prompt.
- **Recent nudges list:** shows roughly the last 7 days so people can check things off late.

## Contacts

- Request the contacts permission only when the user first tries to add members.
- Build a **custom multi-select picker**: searchable list with checkboxes, adds all selected to a ring in one transaction. The system picker is single-select on Android.
- Contacts already in a ring appear greyed out with the ring name ("In Close friends") and offer "Move to this ring."
- Handle iOS partial access ("selected contacts only") gracefully, with a hint to manage access.
- If a stored contact can't be found (merged or deleted), show it as **needs relinking** and keep the cached name. Never silently drop it.

## Notifications

- One repeating **local** notification per day, around a user-chosen time (default about 9am), with generic text such as "Time for your daily nudge." No exact alarms are required.
- Request the notification permission at runtime (Android 13+). If denied, the app still works through the open-app path.
- Reschedule after device reboot.
- No server and no push notifications.

## Rings UI

- Create, rename, and delete rings. Period presets (Weekly = 7, Biweekly = 14, Monthly = 30) plus a custom number of days.
- Deleting a ring that has members requires choosing where to move them, or blocking the delete.
- Ring detail shows members sorted by next due date.

## Export / Import

- Export all rings, members, and history to a JSON file the user can save or share.
- Import restores from that file. Matching contacts by `contact_key` first, falling back to name.
- Include a schema `version` field in the file.

## Platform notes

- Primary dev and test device: Pixel (Android). iOS builds come later via TestFlight.
- Enable Android Auto Backup for the database where reasonable.
- Provide a debug-only option to seed fake contacts and members (emulators have no contacts).

## Milestones

1. Repo setup: license, `.gitignore`, README, PRIVACY.md, CI skeleton.
2. Database + core logic (due dates, nudge picker, actions) with unit tests.
3. Basic UI for rings and members using fake contact data.
4. Real contacts access and the multi-select picker.
5. Notifications, including reboot rescheduling.
6. Export/import, polish, and release builds.

## Out of scope (for now)

Accounts, cloud sync, social features, analytics, calendar-based ("once per month") schedules, widgets.
