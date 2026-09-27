# Development guide

Everything you need to build, test, and ship Inner Flare. Read [CONTRIBUTING.md](../CONTRIBUTING.md) first for the ground rules. [CLAUDE.md](../CLAUDE.md) has the full architecture, conventions, and troubleshooting reference, and [BRIEF.md](../BRIEF.md) the original product brief.

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # generates Riverpod .g.dart files
./scripts/setup_git_hooks.sh   # one-time: installs pre-commit/pre-push checks
flutter run
```

## Running on a simulator or emulator

### iOS Simulator

```bash
# List available simulators (find a device UDID or name)
xcrun simctl list devices available

# Boot one and open Simulator.app
xcrun simctl boot "iPhone 17 Pro"
open -a Simulator

# Run the app on it (by name or UDID; `flutter devices` must show it first)
flutter devices
flutter run -d "iPhone 17 Pro"
```

If `flutter devices` doesn't pick up a freshly booted simulator right away, give it a few seconds and try again. `flutter doctor -v` also lists connected devices.

### Real iOS device or a locally signed iOS build

The Simulator needs no signing setup, but a physical device (or a signed local release build) does. The Xcode project doesn't hardcode a Team ID: it reads `DEVELOPMENT_TEAM` from `ios/Flutter/Local.xcconfig`, which is gitignored since it's specific to whichever Apple Developer account you build with:

```bash
cp ios/Flutter/Local.xcconfig.example ios/Flutter/Local.xcconfig
# then edit ios/Flutter/Local.xcconfig and set DEVELOPMENT_TEAM to your
# Team ID (Xcode → Runner target → Signing & Capabilities → Team, or
# https://developer.appleid.apple.com/account under Membership)
```

Without this file, `DEVELOPMENT_TEAM` resolves to empty and Xcode falls back to "Sign to Run Locally" / Simulator-only builds.

### Android Emulator

```bash
# List configured emulators
flutter emulators

# Launch one
flutter emulators --launch Medium_Phone_API_36.1

# Run the app on it
flutter devices
flutter run -d emulator-5554   # or whatever device id `flutter devices` shows
```

### macOS desktop

```bash
flutter run -d macos
```

Useful for quick UI/layout checks, but **not** representative of the real biometric/Keychain flow. See "macOS: encrypted storage doesn't work out of the box" below before relying on it.

### Demo mode for recording videos

```bash
scripts/video_mode.sh
```

Runs on a simulator with no debug chrome, demo data, and no Face ID prompt. See [docs/marketing/README.md](marketing/README.md).

## Testing

```bash
flutter test                                          # full suite
flutter test --coverage
flutter test test/widget/dashboard_screen_test.dart   # a single file
```

Widget tests that touch the database use `sqflite_common_ffi`'s **no-isolate** factory (`databaseFactoryFfiNoIsolate`, set up in `test/helpers/test_database.dart`). The isolate-backed one hangs forever inside `testWidgets`' fake-async pumping. See `CLAUDE.md` → Troubleshooting.

## Known issues and platform notes

### macOS: encrypted storage doesn't work out of the box

The database is encrypted with SQLCipher, and the passphrase is stored in the platform's secure key store (`flutter_secure_storage`: iOS Keychain / Android Keystore), gated behind biometrics via `local_auth`. This works cleanly on iOS and Android.

**On macOS** it doesn't, for two stacked reasons:

1. `flutter_secure_storage` needs a `keychain-access-groups` entitlement to write to the Keychain on macOS at all. Without it, every read/write throws `PlatformException(..., -34018, A required entitlement isn't present., ...)`. In the app this surfaces as "Couldn't save."
2. Adding that entitlement requires signing with a **real local development certificate** (a `DEVELOPMENT_TEAM` plus a resolvable signing identity). The default "Sign to Run Locally" ad-hoc signing isn't enough, since Keychain Sharing is a provisioned capability. With an organization Apple Developer team, the Mac also has to be registered as a device under that team, which needs team admin permission.

macOS isn't a shipping target, so the entitlement is deliberately **not** included. `flutter run -d macos` builds and runs, but "Log today" will fail to unlock the database. **Test storage and logging on an iOS Simulator, Android emulator, or a real device.**

If macOS ever becomes a real target: add `<key>keychain-access-groups</key><array/>` to both `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`, then configure a working `DEVELOPMENT_TEAM` + `CODE_SIGN_IDENTITY` for the Runner target in Xcode, using a team that can register this Mac. A personal (free) Apple ID team avoids the admin-approval step.

### iOS deployment target

`ios/Podfile` and the Xcode project target iOS 14.0, not the Flutter default of 13.0, because `file_picker_darwin` requires it. If a `flutter create` regeneration or template update resets this, bump both back to 14.0 or `pod install` will fail with a "requires a higher minimum deployment target" error.

## CI/CD

- **CI** (`.github/workflows/ci.yml`): format check, `flutter analyze`, offline-URL scan, and `flutter test` on every push to `main` and every PR.
- **Android build and release** (`.github/workflows/android-release.yml`): a debug APK on demand (Actions tab → "Run workflow"); pushing a `v*.*.*` tag builds a signed release bundle and attaches it to a GitHub Release. See [android-release.md](deployment/android-release.md).
- **iOS build and release** (`.github/workflows/ios-release.yml`): an unsigned Simulator build on demand; pushing a `v*.*.*` tag builds a signed IPA and uploads it to App Store Connect. See [ios-release.md](deployment/ios-release.md).
- **F-Droid**: builds on F-Droid's own infrastructure, not ours. See [fdroid/README.md](deployment/fdroid/README.md).
- [release-tasklist.md](deployment/release-tasklist.md) has the full Play Store / App Store / F-Droid launch checklist, and [release-process.md](deployment/release-process.md) the release steps.
