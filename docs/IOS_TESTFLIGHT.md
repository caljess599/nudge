# iPhone builds and TestFlight

From a Mac with Flutter to friends testing Nudge on their iPhones. Steps
marked **(once)** only need doing the first time.

## 1. Mac setup (once)

- Install **Xcode** from the Mac App Store, open it once, accept the
  licence and install the iOS platform when asked
  (Xcode → Settings → Components).
- Flutter uses **Swift Package Manager** for the iOS plugins when all of
  them support it, which Nudge's currently do. It falls back to
  **CocoaPods** for any that don't, so it's worth having installed. Use
  Homebrew, not `sudo gem install` (the macOS system Ruby can't build it
  with current Xcode):

  ```bash
  brew install cocoapods
  ```

- Check the iOS section of:

  ```bash
  flutter doctor
  ```

- Try the app in the Simulator: open Simulator (Xcode → Open Developer
  Tool → Simulator), then run `flutter run` and pick the iPhone.

## 2. Commit what the first iOS build changed (once per Mac setup)

The first iOS build updates the Xcode project. What changes depends on
how Flutter set up the plugins:

- **Swift Package Manager** (Nudge's current setup): usually only
  `ios/Runner.xcodeproj/project.pbxproj`, sometimes also
  `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
- **CocoaPods** (if a plugin ever needs it): also `ios/Podfile`,
  `ios/Podfile.lock`, `ios/Runner.xcworkspace/contents.xcworkspacedata`
  and `ios/Flutter/Debug.xcconfig` / `Release.xcconfig`. `ios/Pods/`
  itself is ignored.

List everything, including new files:

```bash
git status --short --untracked-files=all ios
```

Commit those files, and check nothing else is listed: no `.p8`, `.p12`,
`.mobileprovision` or other signing files.

To commit and push without logging in to GitHub in the terminal, use
**GitHub Desktop** (tick the files, **Commit**, then **Push origin**).
For the terminal, sign it in once through the browser with
`gh auth login` (from `brew install gh`); GitHub no longer accepts your
password there.

## 3. Privacy manifest (done)

`ios/Runner/PrivacyInfo.xcprivacy` is part of the Runner target in the
repository, so there's nothing to do. Without it, App Store Connect may
reject uploads ("missing API declaration"). To check, in Xcode: Runner
target → **Build Phases** → **Copy Bundle Resources** lists
`PrivacyInfo.xcprivacy`.

If it's ever missing (e.g. the project file was regenerated), add it
back: open `ios/Runner.xcworkspace`, right-click the yellow **Runner**
folder → **Add Files to "Runner"…**, select
`ios/Runner/PrivacyInfo.xcprivacy`, leave "Copy items if needed" **off**,
keep the **Runner** target ticked, and click **Add**.

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
