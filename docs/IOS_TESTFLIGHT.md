# iPhone builds and TestFlight

From a Mac with Flutter to friends testing Nudge on their iPhones. Steps
marked **(once)** only need doing the first time.

## 1. Mac setup (once)

- Install **Xcode** from the Mac App Store, open it once, accept the
  licence and install the iOS platform when asked
  (Xcode → Settings → Components).
- Install **CocoaPods with Homebrew**, not with `sudo gem install` (the
  macOS system Ruby can't build it with current Xcode):

  ```bash
  brew install cocoapods
  ```

- Check the iOS section of:

  ```bash
  flutter doctor
  ```

- Try the app in the Simulator: open Simulator (Xcode → Open Developer
  Tool → Simulator), then run `flutter run` and pick the iPhone.

## 2. Commit the files CocoaPods generated (once)

The first iOS build creates or changes these files. They belong in the
repository (`ios/Pods/` itself is ignored):

- `ios/Podfile` and `ios/Podfile.lock`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner.xcworkspace/contents.xcworkspacedata`
- `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig`

```bash
git status --short ios
```

Check nothing unexpected is listed (no `.p8`, `.p12`,
`.mobileprovision` or other signing files), then commit them on a branch
along with step 3.

## 3. Add the privacy manifest to the app (once)

`ios/Runner/PrivacyInfo.xcprivacy` is in the repository, but Xcode only
includes files the project lists. Without it, App Store Connect may
reject the upload ("missing API declaration").

1. Open `ios/Runner.xcworkspace` in Xcode (the workspace, not the
   `.xcodeproj`).
2. In the left sidebar, right-click the yellow **Runner** folder →
   **Add Files to "Runner"…**
3. Select `ios/Runner/PrivacyInfo.xcprivacy`. Leave "Copy items if
   needed" **off** (it's already in place), make sure the **Runner**
   target is ticked, click **Add**.
4. Check: Runner target → **Build Phases** → **Copy Bundle Resources**
   now lists `PrivacyInfo.xcprivacy`.

Commit the resulting `project.pbxproj` change with step 2.

## 4. Apple Developer Program (once)

Enrol at <https://developer.apple.com/programs/> (US$99/year, needed for
TestFlight). Individual enrolment is fine; your name is shown as the
developer. Approval can take from hours to a couple of days.

## 5. Signing (once)

In Xcode: select the **Runner** project → **Runner** target →
**Signing & Capabilities**:

- **Team:** your developer account.
- **Automatically manage signing:** on.
- **Bundle Identifier:** `com.caljess.nudge`.

Xcode creates the certificate and profiles in your keychain and Apple
account. The only repository change is your team ID in `project.pbxproj`,
which isn't secret; commit it. **Never commit** certificates, `.p12`,
`.p8` API keys or `.mobileprovision` files (all are in `.gitignore`).

## 6. Create the app in App Store Connect (once)

<https://appstoreconnect.apple.com> → **Apps** → **+** → **New App**:

- Platform: iOS
- Name: must be unique across the App Store; plain "Nudge" is probably
  taken, so e.g. "Nudge: Keep in Touch". The name under the icon on the
  phone stays "Nudge".
- Bundle ID: `com.caljess.nudge`
- SKU: anything, e.g. `nudge`

## 7. Build and upload (every release)

Each upload needs a **new build number**: the `+N` in `pubspec.yaml`'s
`version` (e.g. `1.0.0+1` → `1.0.0+2`).

```bash
flutter build ipa --release
```

The file is in `build/ios/ipa/`. Upload it with Apple's free
**Transporter** app (Mac App Store): sign in, drag the `.ipa` in, click
**Deliver**. Processing takes roughly 15–30 minutes; Apple emails you
when it's done or if something is wrong.

## 8. Test it yourself first (internal testing)

App Store Connect → your app → **TestFlight** → **Internal Testing** →
create a group and add yourself. Install **TestFlight** on your iPhone,
sign in with the same Apple ID, and install Nudge. Internal builds need
no review.

## 9. Invite friends (external testing)

1. TestFlight → **Test Information**: a short beta description, a
   feedback email, and a privacy policy URL (the GitHub link to
   `PRIVACY.md` works).
2. **External Testing** → create a group → add the build → submit for
   **Beta App Review**. The first build of a version usually takes about
   a day; later builds of the same version often don't need review.
3. Once approved, add testers by email or turn on a **public link**.
   They install **TestFlight**, then Nudge.

Builds expire after 90 days; upload a new one to keep testing.

## What to check on an iPhone

- No permission prompts at launch; contacts are asked for on
  **Add people**, notifications from the Today card.
- "Share only some contacts" (iOS 18): the picker shows the hint, and
  only shared contacts appear.
- The daily reminder arrives around the set time, including while Nudge
  is open, and tapping it opens Today.
- Call and Text open Phone and Messages; WhatsApp, Signal and Telegram
  open the right chat **in the app** (never Safari), or Nudge says the
  app isn't installed.
- Export a backup to Files, then import it.
