# InnerFlare

A menstrual cycle tracking companion for iOS and Android. Fully offline — no
network calls, no cloud sync, no accounts. All data stays on-device in a
SQLite database encrypted at rest, unlocked with biometrics where the device
supports it.

See `BRIEF.md` for the original product/technical brief, `CLAUDE.md` for full
architecture, conventions, and troubleshooting notes, and
`docs/deployment/android-release.md` for the Android build/release pipeline.

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # generates Riverpod .g.dart files
./scripts/setup_git_hooks.sh   # one-time: installs pre-commit/pre-push checks
flutter run
```

## Running on a simulator/emulator

### iOS Simulator

```bash
# List available simulators (find a device UDID or name)
xcrun simctl list devices available

# Boot one and open Simulator.app
xcrun simctl boot "iPhone 17 Pro"
open -a Simulator

# Run the app on it (by name or UDID — `flutter devices` must show it first)
flutter devices
flutter run -d "iPhone 17 Pro"
```

If `flutter devices` doesn't pick up a freshly-booted simulator right away,
give it a few seconds and try again — `flutter doctor -v` also lists
connected devices.

### Running on a real iOS device / a locally-signed iOS build

The Simulator needs no signing setup, but a physical device (or a signed
local release build) does. The Xcode project doesn't hardcode a Team ID —
it reads `DEVELOPMENT_TEAM` from `ios/Flutter/Local.xcconfig`, which is
gitignored since it's specific to whichever Apple Developer account you
build with:

```bash
cp ios/Flutter/Local.xcconfig.example ios/Flutter/Local.xcconfig
# then edit ios/Flutter/Local.xcconfig and set DEVELOPMENT_TEAM to your
# Team ID (Xcode → Runner target → Signing & Capabilities → Team, or
# https://developer.appleid.apple.com/account under Membership)
```

Without this file, `DEVELOPMENT_TEAM` resolves to empty and Xcode falls
back to "Sign to Run Locally" / Simulator-only builds.

### Android Emulator

```bash
# List configured emulators
flutter emulators

# Launch one (this repo already has "Medium_Phone_API_36.1" configured)
flutter emulators --launch Medium_Phone_API_36.1

# Run the app on it
flutter devices
flutter run -d emulator-5554   # or whatever device id `flutter devices` shows
```

### macOS desktop

```bash
flutter run -d macos
```

Useful for quickly checking UI/layout changes, but **not** representative of
the real biometric/Keychain flow — see "Known issues" below before relying
on it to test the encrypted storage or logging feature.

## Testing

```bash
flutter test                              # full suite
flutter test --coverage
flutter test test/widget/dashboard_screen_test.dart   # a single file
```

Widget tests that touch the database use `sqflite_common_ffi`'s
**no-isolate** factory (`databaseFactoryFfiNoIsolate`, set up in
`test/helpers/test_database.dart`) — the isolate-backed one hangs forever
inside `testWidgets`' fake-async pumping. See `CLAUDE.md` → Troubleshooting
for details.

## Known issues / platform notes

### macOS: encrypted storage doesn't work out of the box

The database is encrypted with SQLCipher, and the encryption passphrase is
stored in the platform's secure key store (`flutter_secure_storage` — iOS
Keychain / Android Keystore), gated behind biometrics via `local_auth`. This
works cleanly on iOS and Android.

**On macOS specifically**, it does not, for two stacked reasons discovered
while testing this locally:

1. `flutter_secure_storage` needs a `keychain-access-groups` entitlement to
   write to the Keychain on macOS at all. Without it, every read/write
   throws `PlatformException(..., -34018, A required entitlement isn't
   present., ...)` — this is what surfaces in the app as "Couldn't save."
2. Adding that entitlement in turn requires macOS to sign the app with a
   **real local development certificate** (a `DEVELOPMENT_TEAM` + resolvable
   signing identity) — the default "Sign to Run Locally" ad-hoc signing this
   project uses isn't enough, since Keychain Sharing is a provisioned
   capability. If your Apple Developer team is an organization account, this
   also requires the specific Mac to be registered as a device under that
   team, which needs admin permission on the team account.

Because macOS isn't a shipping target for this app (iOS and Android are),
the entitlement is deliberately **not** included — `flutter run -d macos`
builds and runs fine, but tapping "Log today" there will fail to unlock the
database with the error above. **Test the encrypted-storage and logging
flow on an iOS Simulator, Android emulator, or a real device instead** —
all three work without any of this friction.

If macOS ever becomes a real target: add `<key>keychain-access-groups</key>
<array/>` to both `macos/Runner/DebugProfile.entitlements` and
`Release.entitlements`, then configure a working `DEVELOPMENT_TEAM` +
`CODE_SIGN_IDENTITY` for the Runner target in Xcode (Signing & Capabilities)
using a team that can register this Mac as a device — a personal/free
Apple ID team sidesteps the admin-approval requirement an organization team
has.

### iOS deployment target

`ios/Podfile` and the Xcode project target iOS 14.0, not the Flutter default
of 13.0 — `file_picker_darwin` requires it. If a future `flutter create`
regeneration or template update resets this, bump both back to 14.0 or the
build will fail during `pod install` with a "requires a higher minimum
deployment target" error.

## CI/CD

- **CI** (`.github/workflows/ci.yml`): format check, `flutter analyze`,
  offline-URL scan, and `flutter test` on every push to `main` and every PR.
- **Android build & release** (`.github/workflows/android-release.yml`):
  builds a debug APK you can sideload on demand (Actions tab → "Run
  workflow"); pushing a `v*.*.*` tag builds a signed release bundle and
  attaches it to a GitHub Release. See `docs/deployment/android-release.md`.
- **iOS build & release** (`.github/workflows/ios-release.yml`): builds an
  unsigned iOS Simulator build on demand; pushing a `v*.*.*` tag builds a
  signed IPA and uploads it to App Store Connect (needs Apple signing
  secrets configured first). See `docs/deployment/ios-release.md`.
- **F-Droid**: not CI of ours — see `docs/deployment/fdroid/README.md`.
- See `docs/deployment/release-tasklist.md` for the full Play
  Store/App Store/F-Droid launch checklist.

## Contributing

See `CONTRIBUTING.md` for the development workflow and the ground rules
(offline-only, encrypted-at-rest) that PRs are held to, and
`CODE_OF_CONDUCT.md` for community expectations.

## License

InnerFlare is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License v3.0 or later — see
`LICENSE`. Third-party dependencies are under their own (permissive)
licenses — see `NOTICE.md`, or Settings → "Open source licenses" in the
app itself for the complete, auto-generated list.
