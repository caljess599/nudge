# CLAUDE.md

Project: **Nudge**, an open-source app that reminds you to reach out to people, organized into "rings" with a period in days. The full product spec is in `SPEC.md`. Read it before making design decisions.

## Stack

- Framework: **Flutter**
- Database: `drift` (SQLite)
- Contacts: `flutter_contacts`
- Notifications: `flutter_local_notifications`
- Targets: Android first (Pixel), iOS later

## Rules

- **Never commit secrets:** no keystores, `key.properties`, API keys, `google-services.json`, or `.env` files. Check `.gitignore` before the first commit and before adding any new tooling.
- **All data stays on-device.** No network calls, analytics, or crash-reporting SDKs without explicit approval.
- **Avoid proprietary dependencies** (Google Play Services, Firebase) so the app stays F-Droid compatible. Ask before adding any.
- **Enforce one ring per contact in the database** (unique constraint on `contact_key`), not only in the UI.
- **Derive due dates, don't store them:** `next_due = (last_contacted ?? baseline_date) + ring.period_days`.
- Keep core logic (due dates, nudge picker) in pure Dart with no Flutter or database imports, so it's easy to unit test. Inject the random source and the clock.
- Notifications are generic. Never put contact names in notification text.

## Workflow

- Work in the milestones listed in `SPEC.md`, one at a time. Stop after each milestone for review.
- Work on a feature branch per milestone and open a PR rather than pushing to `main`.
- Write unit tests alongside core logic. Run `flutter analyze` and `flutter test` before every commit.
- Small, focused commits with clear messages.
- Ask before adding dependencies, changing permissions in the Android manifest or iOS `Info.plist`, or touching signing configuration.

## Testing

- Emulators have no contacts. Keep a debug-only seed feature for fake contacts.
- Real-device behavior (permissions, notification timing) must be verified on the Pixel. Say what needs manual testing at the end of each milestone.
