# Release builds (Pixel only, for now)

Release builds are signed with your own key, which never goes into the
repository. Debug builds (`flutter run`) don't need any of this.

> **Keep the keystore and its passwords safe and backed up.** Android only
> accepts an update signed with the same key as the installed app. If the
> key is lost, the only way back is to uninstall Nudge, which deletes its
> data, so export a backup first (Settings → Export backup).

## 1. Create a keystore (once)

Store it **outside** the repository, e.g. in your home folder:

```bash
keytool -genkey -v -keystore ~/nudge-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nudge
```

`keytool` comes with Java. You don't need to install Java separately:
Android Studio bundles one, which is what Flutter uses for Android builds.
`flutter doctor -v` shows its path ("Java binary at: …"); `keytool` is in
the same folder, e.g. on a Mac:

```bash
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -genkey -v -keystore ~/nudge-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nudge
```

## 2. Point the build at it

Create `android/key.properties` (it's in `.gitignore`; never commit it):

```properties
storeFile=/Users/you/nudge-upload.jks
storePassword=the store password
keyAlias=nudge
keyPassword=the key password
```

Use the absolute path to the keystore. If this file is missing, release
builds fall back to the debug key and Gradle prints a warning.

## 3. Build

```bash
flutter build apk --release
```

The APK is at `build/app/outputs/flutter-apk/app-release.apk`.

## 4. Install

**First release install** (replacing a debug install): the signing key
changes, so Android won't update in place. Export a backup in the app
first, then:

```bash
flutter install
```

`flutter install` **uninstalls the existing app first, deleting its
data**. Afterwards, import your backup.

**Updating an existing release install:** use `adb install -r`, which
replaces the app and keeps its data (only works when both builds are
signed with the same key):

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

If `adb` isn't on your PATH, it's in the Android SDK's `platform-tools`
folder (on a Mac: `~/Library/Android/sdk/platform-tools/adb`).

## Before every commit

Check nothing secret is staged:

```bash
git status --short
```

`key.properties`, `*.jks` and `*.keystore` are ignored by `.gitignore`; if
any of them ever shows up in `git status`, stop and fix the ignore rules.

## Later: F-Droid

F-Droid builds and signs apps itself. When we get there, this setup stays
for local builds, and `package:sqlite3`'s build-time download of a
prebuilt SQLite will need to switch to building from source (see the
`sqlite3` hook options).
