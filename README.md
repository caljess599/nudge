# Nudge

A small, private app that nudges you to reach out to the people you care about.

Organize your contacts into **rings** (say, "Close friends" every 14 days, "Old friends" every 60). Once a day, Nudge suggests a few people who are due for a message or call. No streaks, no guilt, no accounts.

> **Status:** early development. Not yet released.

## Features (planned)

- Rings with a custom period in days
- A daily nudge of about three people who are due or overdue
- Multi-select contact picker, with one ring per contact
- Generic daily reminder notification (names only appear inside the app)
- Optional check-offs, snooze, and skip
- JSON export/import of your data

## Privacy

Everything stays on your device. Nudge has no server, no accounts, and no analytics. See [PRIVACY.md](PRIVACY.md).

## Building from source

Requirements:

- [Flutter](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio or the Android SDK for Android builds
- Xcode on a Mac for iOS builds

```sh
git clone https://github.com/<your-username>/nudge.git
cd nudge
flutter pub get
flutter run
```

Run checks:

```sh
flutter analyze
flutter test
```

## Project docs

- [SPEC.md](SPEC.md): product and technical specification
- [CLAUDE.md](CLAUDE.md): conventions for AI-assisted development

## Contributing

Issues and pull requests are welcome. Please do not commit keystores, API keys, or other secrets.

## License

See [LICENSE](LICENSE).
